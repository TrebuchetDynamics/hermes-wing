# Owner-bound session delete journey

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_3634d69c`. Backlog task: `DOC-SESSION-DELETE-EVIDENCE`.
Goal: `SESSIONS`. This receipt qualifies one deterministic delete journey.
It does not establish complete session parity or live/native support.

## Delivered regression and acceptance

`test/features/hermes_chat/screens/hermes_chat_session_delete_journey_test.dart`
adds three Linux-hosted Flutter widget tests at a 1280 × 1000 viewport.
They compose the production `HermesChatScreen`, Riverpod channel provider,
`HermesApiChannel` and `HermesApiClient`. The existing HTTP function seam and
local endpoint/directory support services are deterministic fakes.
The screen runs inside a localized MaterialApp, not the full application router.

1. Deliberate confirmation submits exactly one
   `DELETE /api/sessions/target?profile=default` to `https://example.invalid`.
   The request has no body. Opening the dialog alone submits no mutation.
   The fixture confirms `{id: target, deleted: true}` and removes only
   `default`'s target row. Both `b` rows and `default`'s `keep` row remain.
   The current conversation stays `keep`, with its history visible.
2. Disconnect clears the channel's session list. Reconnect performs a fresh
   `GET /api/sessions?profile=default&limit=50&offset=0` and
   `GET /api/sessions/keep/messages?profile=default&limit=500&offset=0&order=latest`.
   These assertions compare query maps, not query serialization order.
   The authoritative fixture list and reconstructed UI contain only `keep`.
   Every reconnect request is a GET. The total mutation count remains one:
   DELETE=1, POST=0, PATCH=0, PUT=0. No create, send, approval, Stop or replay occurs.
3. Cancel submits no request and leaves both owners' rows unchanged.
   A separate test selects profile `b` through the production channel while
   the original dialog remains open. Both profiles contain the same `target` ID.
   Confirming the old dialog submits no request to either owner.
   Profile `b`'s `keep` conversation and `target` row remain visible.
   Each negative journey asserts zero mutations of every intercepted verb.

The fixture owns separate row sets for `default` and `b`. It records all HTTP
requests and intercepts GET, DELETE, POST, PATCH, PUT and streaming POST.
Unexpected routes fail the test. No live session, credentials or network server
was used. Fixture persistence is not evidence about a live Agent database.

## Implementation trace

No production correction was required. The single-row menu invokes the existing
`_deleteSession` path in
`lib/features/hermes_chat/session/hermes_chat_session_actions.dart`.
Its `_withSessionMutationIntent` permanently invalidates intent on owner loss.
The channel's `_deleteSession` in
`lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart`
requires the advertised DELETE endpoint and known session, captures the profile,
and fences response settlement. The client verifies the returned ID and
`deleted` flag before the channel removes its local row.
The new reconnect check independently verifies the fixture's authoritative list.

The predecessor rename composition was read-only guidance. Neither its test nor
receipt was changed. Local upstream checkouts were inspected as read-only
references: Agent `158fd638da1629c8e62caf9ade1515d162def8ab`, Desktop
`withdrawn reference revision`.
This test exercises Wing's advertised HTTP contract, not Desktop's privileged
IPC or the Agent native dashboard transport. No upstream compatibility claim
or upstream modification is made.

## Executed checks

Commands ran from the repository root. Logs are under the ignored directory
`.task-evidence/t_3634d69c/`.

- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_delete_journey_test.dart`
  — PASS, 3 tests (`journey.log`). Two initial runs failed on incomplete expected
  query maps: session-list pagination, then history pagination/order. The final
  harness matches the existing production contract. No validation was relaxed.
- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart`
  — PASS, 136 tests (`owners.log`), including compact/wide owner invalidation,
  cancellation, late results and bulk-delete coverage.
- `flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'session mutation ownership'`
  — PASS, 3 tests (`channel-owners.log`).
- `flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --plain-name deleteSession`
  — PASS, 5 tests (`channel-delete.log`).
- `flutter test --concurrency=1 test/core/hermes/hermes_api_test.dart --name 'deletes a session over DELETE|rejects an unconfirmed delete response'`
  — PASS, 2 tests (`client-delete.log`).
- `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_session_delete_journey_test.dart`
  — PASS, unchanged after formatting the new file.
- `flutter analyze` — PASS, no issues (`analyze.log`). This includes the shared
  working tree, not an isolated packaged runtime.

- `git diff --no-index --check /dev/null test/features/hermes_chat/screens/hermes_chat_session_delete_journey_test.dart`
  and `git diff --no-index --check /dev/null docs/quality/session-delete-journey.md`
  — PASS, no whitespace diagnostics. Exit 1 indicates new-file differences.
- `git diff --check -- goals.json TODO.md` — PASS.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate .`
  — PASS, `ok`, after task/evidence/render updates.

The goal helper marks only this backlog task done, records executed checks and
renders goal coverage. The broader `SESSIONS` goal remains unverified.
Only this new test and receipt belong in the local agent-branch commit.
Co-owned `goals.json` and `TODO.md` changes are not committed wholesale.

## Qualification boundaries

Actual platform: Linux-hosted Flutter widget/unit tests.
Live deletion, real network HTTP, native desktop interaction/relaunch, browser
build/E2E, Android, full router navigation, release packaging and full session
search/resume/fork parity are NOT_CHECKED. No large build output was created by
this card. Existing build outputs and unrelated dirty files were preserved.

The scoped prose follows the project's STE-inspired profile. Commands and
meaning were reviewed against execution and source. Full ASD-STE100 dictionary
compliance was not verified. No owner questions remain for this scope.
