# Owner-bound session rename journey

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_afa78f46`. Backlog task: `DOC-SESSION-ACTIONS-EVIDENCE`.
Goal: `SESSIONS`. This receipt qualifies one deterministic rename slice, not all
session actions or live/native Desktop parity.

## Delivered regression

`test/features/hermes_chat/screens/hermes_chat_session_rename_journey_test.dart`
adds three Linux-hosted Flutter widget journeys at a 1280 × 1000 viewport.
The production `HermesChatScreen`, Riverpod channel provider, `HermesApiChannel`
and `HermesApiClient` run together. Only the HTTP function seam and local
endpoint/directory support services are deterministic fakes. Every HTTP write
verb is intercepted; no live endpoint, credentials, platform build or device is
used. The screen runs in the existing localized MaterialApp/provider harness,
not the full application router.

1. Rename a non-active session through its menu and dialog. Whitespace is
   trimmed. The recorder requires exactly one PATCH to
   `/api/sessions/target?profile=default` on `https://example.invalid`, with
   exactly the requested title. The fixture returns a deliberately different
   server-confirmed title. The UI displays that response rather than its draft,
   while the current conversation remains `keep`.
2. Disconnect and reconnect the same production channel, clearing session state.
   A new authoritative session-list read returns the persisted fixture title.
   Opening the target row reads that session's history with the explicit original
   profile. Selected session, displayed title and history agree. The total write
   count remains one: no create, send or mutation replay occurs.
3. Cancel produces no extra requests and preserves the current conversation.
   In a separate journey, production profile selection replaces `default` with
   `b`, which contains the same target session ID. Saving the old dialog produces
   no requests to either owner, preserves both server titles and keeps profile
   `b`'s current conversation visible.

No production correction was required. Existing ownership coverage is reused in
`hermes_chat_session_mutation_owner_test.dart` (compact and wide presentations,
owner loss/return, origin/channel replacement, capability/grant loss, late results,
unmount and the other mutation actions). The focused channel ownership tests
retain response-fencing coverage for rename, delete and overlapping rename.

## Executed checks

Commands run from the repository root:

- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_rename_journey_test.dart`
  — PASS, 3 tests. Evidence: `.task-evidence/t_afa78f46/journey.log`.
- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart`
  — PASS, 136 tests. Evidence: `.task-evidence/t_afa78f46/owners.log`.
- `flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'session mutation ownership'`
  — PASS, 3 tests. Evidence: `.task-evidence/t_afa78f46/channel-owners.log`.
- `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_session_rename_journey_test.dart`
  — PASS, unchanged.
- `flutter analyze` — PASS, no issues. Evidence:
  `.task-evidence/t_afa78f46/analyze.log`. Analysis includes the current shared
  working tree; it is not packaged-runtime qualification.

Initial harness runs failed before the UI journey: a non-supported default-profile
advertisement and a missing history `object: list` envelope. The fixture was
corrected to the existing production contracts; the final three journeys pass.
No contract, capability gate or production validation was relaxed.

Additional scoped checks:

- `git diff --no-index --check /dev/null test/features/hermes_chat/screens/hermes_chat_session_rename_journey_test.dart`
  and `git diff --no-index --check /dev/null docs/quality/session-rename-journey.md`
  — PASS. These checks include the newly authored, untracked files.
- `git diff --check -- goals.json TODO.md` — PASS.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate .`
  — PASS, `ok`, after helper task/evidence/render updates.

## Boundaries and remaining coverage

Actual platform: Linux-hosted Flutter tests. Live Agent execution, network HTTP
transport, native desktop interaction/relaunch, full router navigation, browser
build/E2E, Android, packaging and full session search/fork/delete parity are
NOT_CHECKED by this card. The fixture's title persistence is deterministic owned
test state, not evidence about a live Agent database. Cancel and cross-profile
same-ID submission are newly exercised through the real client/channel; broader
ownership transitions remain covered by the nearest existing tests.

The local read-only reference checkouts were confirmed at Agent
`158fd638da1629c8e62caf9ade1515d162def8ab` and Desktop
`withdrawn reference revision`. No upstream code was changed. Wing's
current rename implementation and client response parsing remain authoritative
for this regression; no upstream contract change is proposed.

The goal helper records task completion and executed checks and renders the
Goal coverage block. Other session qualification remains open. Only the new
regression and this receipt belong in the card's local agent-branch commit;
pre-existing shared ledger and implementation edits are not included.
