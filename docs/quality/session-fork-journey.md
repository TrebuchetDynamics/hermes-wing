# Owner-bound session branch journey

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_36a391f7`. Backlog task: `DOC-SESSION-FORK-JOURNEY`.
Goal: `SESSIONS`. This receipt proves a bounded deterministic branch/reopen
journey, not complete session parity or live/native qualification.

## Acceptance evidence

The new
`test/features/hermes_chat/screens/hermes_chat_session_fork_journey_test.dart`
contains three Linux-hosted Flutter widget tests at 1280 × 1000. They compose
production `HermesChatScreen`, Riverpod providers, `HermesApiChannel` and
`HermesApiClient` inside a localized MaterialApp. The HTTP function seam,
endpoint store and gateway directory support are deterministic fakes. This is
not the full application router or a real network server.

1. The target row's Branch menu opens the existing confirmation dialog without
   an HTTP request. Deliberate confirmation sends exactly one
   `POST /api/sessions/target/fork?profile=default` to `https://example.invalid`,
   with exactly `{id: fork-child}`. No title or transcript is submitted.
   The deterministic ID factory supplies the proposed child ID; the server
   returns the same ID, a server-chosen title and `parent_session_id: target`.
   The channel selects that returned child and reads its authoritative history.
   The source is not active or locally loaded, so cached source history cannot
   satisfy the displayed-history assertion. Only `default` gains a child;
   profile `b` remains unchanged. The channel has one child row, not duplicates.
2. Cancel sends no request and keeps the current `keep` conversation visible.
   A separate test replaces the owner through production `selectProfile('b')`
   while the original confirmation remains open. Profile `b` contains the same
   target ID. Confirming that stale dialog sends no request to either owner,
   creates no child and preserves profile `b`'s current conversation and target.
3. Disconnect clears the channel's sessions and messages. Before reconnect,
   the fixture changes the child's history. Reconnect reads the server list;
   explicit UI selection of the returned child row reads the updated child
   history. Selected profile, child identity, parent and title agree with the
   server response. Old history disappears. Every reconnect/reopen request is
   GET, and the total mutation count remains one. This qualifies explicit
   authoritative reopen, not automatic last-session restoration or relaunch.

All HTTP function seams intercept GET, POST, PATCH, PUT, DELETE and streaming
POST. Unexpected routes fail. Request counts include any attempted write, even
one rejected by the fixture. The final `journey.log` prints only deterministic
methods, routes and query maps, never credentials or request bodies.

## Intercepted requests and counts

The positive journey records 11 requests: GET=10, POST=1, PATCH=0, PUT=0,
DELETE=0. Its complete route totals are:

| Method and route | Query map | Count |
| --- | --- | --- |
| GET `/health` | `{}` | 2 |
| GET `/v1/capabilities` | `{}` | 2 |
| GET `/api/sessions` | `{profile: default, limit: 50, offset: 0}` | 2 |
| GET `/api/sessions/keep/messages` | `{profile: default, limit: 500, offset: 0, order: latest}` | 2 |
| POST `/api/sessions/target/fork` | `{profile: default}` | 1 |
| GET `/api/sessions/fork-child/messages` | `{profile: default, limit: 500, offset: 0, order: latest}` | 2 |

Cancel records four GET requests: health, capabilities, the default session
list and default keep history, each once. Replacement records those four GETs,
then one GET each for `/api/profiles`, the profile `b` session list and profile
`b` keep history: seven requests total. List/history pagination maps match the
positive journey with the selected profile substituted. Both negative journeys
assert POST=PATCH=PUT=DELETE=0 and no requests after the final dialog action.
There are zero extra create, send, approval, Stop or replay mutations.

## Contract and source trace

No production correction was needed. The existing action at
`lib/features/hermes_chat/session/hermes_chat_session_actions.dart:257`
captures owner-bound intent before confirmation and calls `forkSession` only
after submission admission. The channel at
`lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart:508`
requires the exact authorized `session_fork` POST endpoint, a known non-streaming
source, and no duplicate in-flight branch. It captures profile identity and
fences settlement, then fetches the accepted child's history. The client at
`lib/core/hermes/client/hermes_api_client.dart:370` sends the proposed ID and
parses the server's session envelope. The fixture advertises the existing exact
HTTP operation and profile-query contract; it invents no new capability.

The read-only Agent checkout is `158fd638da1629c8e62caf9ade1515d162def8ab`.
`hermes-agent/gateway/platforms/api_server.py:3331` creates the requested child,
links the parent, ends the source as branched, copies messages and returns the
child session. Nearest upstream tests in
`hermes-agent/tests/gateway/test_session_api.py:149` and `:265` assert the child
remains listable and carries the explicit branch marker. These were inspected,
not executed. The fixture models only Wing's response/list/history boundary;
it does not qualify real database copying or source end-state persistence.

The Desktop reference checkout is `withdrawn reference revision`.
Both upstream root instructions were read. Scoped searches of Desktop's Chat
renderer and main session module did not identify an equivalent fork request
implementation. No Desktop IPC, native dashboard transport or reference-parity
claim is made. Delete/rename journeys and receipts were read-only harness guidance.

Execution source HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
The shared tree includes unrelated dirty UI/localization edits; the local
agent-branch commit contains only this new test and receipt, not those edits.
SHA-256 of exercised scoped files:

| File | SHA-256 |
| --- | --- |
| New fork journey test | `83bf4efabbe5e4c8541f2de7213c83d812978a05c2bc3706f532f9bfaab6b7be` |
| Session actions | `e4826a2bd5a3559d60740059a3bfb38ca25a4a8720858ba4ffadb705cf3ce2ff` |
| Channel session implementation | `148816aead97af644977509989ab4f30e580ec2a628566de2e18ffcc55f0081f` |
| API client | `89a946e0cade3183fb29b45561f4124916a2eb779e3b675773246e1de6bb3511` |
| Shared dirty Chat layout, unchanged by this card | `4a4b2a27244cb7025a64db72105ddd1aece3570f308f9c6aa225b0d5d9ae0304` |

## Executed checks

Commands ran from the repository root, sequentially after the existing shared
full-suite lane exited. Logs are in ignored `.task-evidence/t_36a391f7/`.

- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_fork_journey_test.dart`
  — PASS, 3 tests, `journey.log`. The initial run failed because the expected
  reconnect sequence incorrectly included eager `/api/profiles` loading.
  The existing channel loads that inventory on profile selection, not connect.
  The fixture expectation was corrected; production validation was not relaxed.
  Initial output is retained in `journey-initial.log`.
- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart`
  — PASS, 136 tests, `owners.log`, including compact/wide branch cancellation,
  owner invalidation and late settlement.
- `flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --name 'fork|session mutation ownership'`
  — PASS, 10 tests, `channel-fork.log`: fork admission, duplicate suppression,
  selection, failure/history recovery and nearest mutation-owner guards.
- `flutter test --concurrency=1 test/core/hermes/hermes_api_test.dart --plain-name 'forks a session over POST'`
  — PASS, 1 test, `client-fork.log`.
- `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_session_fork_journey_test.dart`
  — PASS, zero changes, `format.log`.
- `flutter analyze` — PASS, no issues, `analyze.log`. This analyzes the shared
  working tree, not an isolated packaged application.
- `git diff --no-index --check /dev/null test/features/hermes_chat/screens/hermes_chat_session_fork_journey_test.dart`
  and `git diff --no-index --check /dev/null docs/quality/session-fork-journey.md`
  — PASS, no whitespace diagnostics; exit 1 denotes new-file differences.
- `git diff --check -- goals.json TODO.md` — PASS.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate .`
  — PASS, `ok`, after supported task/evidence/render updates.

The goal helper marks only `DOC-SESSION-FORK-JOURNEY` done and records executed
checks for `SESSIONS`. The helper initially promoted the goal to `met` because
all its listed tasks were done. That automatic status exceeded this receipt's
coverage. A supported `add-task` operation records the remaining existing
search/resume acceptance as `DOC-SESSION-SEARCH-RESUME-QUALIFICATION` (ledger
only, no board dispatch). Recording the genuine initial failure and final pass
keeps `SESSIONS` at `partial`, with that qualification still open. Co-owned
`goals.json` and `TODO.md` are not committed wholesale.

## Qualification boundaries

Actual platform: Linux-hosted deterministic Flutter widget/unit tests.
Live Agent/provider, network HTTP, native desktop interaction/relaunch,
automatic remembered-session restoration, browser build/E2E, Android,
full router, packaging, upstream runtime and complete session parity are
NOT_CHECKED. No new production imports or delivery boundary were introduced.
No large build output was created by this card; existing shared Flutter build
outputs were reused and preserved. No upstream, Wing Link, localization,
excluded UI files or predecessor journeys were modified. No owner questions
remain within this scope. Native same-card review is the final implementation
handoff; approval is a later review outcome, not claimed here.
