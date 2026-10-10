# Exact-owner session search and authoritative resume journey

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_8866900e`. Backlog task: `DOC-SESSION-SEARCH-RESUME-QUALIFICATION`.
Goal: `SESSIONS`. This receipt qualifies the existing search/select/reopen
surface with deterministic transport evidence. It does not establish complete
Desktop session parity or live/native acceptance.

## Acceptance evidence

`test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart`
adds four Linux-hosted Flutter widget tests at 1280 × 1000. They compose the
production `HermesChatScreen`, Riverpod providers, `HermesApiChannel` and
`HermesApiClient` in a localized MaterialApp. Only HTTP functions and ancillary
endpoint-store/directory support are fake. Session filtering, row callbacks,
parsing, ownership checks and conversation rendering run production code.
The harness is not the full application router or a network server.

| Card criterion | Executed test | Observable result |
| --- | --- | --- |
| 1: Search selects the exact profile/session and authoritative history | `search selects exact owner and reopens authoritative history without replay` | A nonmatching query hides both rows without changing `keep` or its conversation. A trimmed, case-insensitive matching query shows only `target`. The channel inventory remains the same object. Tapping the real row requests `target` history for `default`, then displays the server title and history with the selected row and message session ID agreeing. |
| 2: Obsolete results cannot replace a newer selection | `late history cannot replace a newer same-profile selection` | Hold the target history response, clear the query, then select `keep` through its real row. Release the old response. The settled channel state remains the same object, the target history never enters the message cache, and the visible conversation remains `keep`. |
| 2: Same-ID profile replacement rejects obsolete success and failure | `same-ID profile replacement rejects obsolete history failure=false` and `failure=true` | Hold `default` target history, use production `selectProfile('b')`, search and select `b`'s same-ID target through the real UI. Releasing the old success or error cannot change the settled state, selected identity, history or UI error feedback. This is profile selection, not profile deletion/recreation. |
| 2: Clear search preserves the current selection | Positive and both replacement tests | The actual clear button sends no requests and preserves the selected session/history. The positive case also checks unchanged session and transcript object identity. |
| 3: No mutations or replay during search, clear, resume/reconnect | All four tests | Every intercepted request is GET. Explicit disconnect clears sessions/messages; reconnect reads the server inventory. Searching and selecting target again displays deliberately changed authoritative history, not the prior transcript. Clearing again preserves that selection and sends no request. |

Reconnection initially selects the first server row (`keep`). The test then
explicitly searches and reopens `target`. This is authoritative explicit resume,
not automatic last-session restoration, process relaunch or detached-run recovery.
The same-ID owner transition uses the production channel's profile-selection
method. The profile-picker UI itself is outside this journey.

All client function seams record requests before rejecting unsupported routes or
writes: GET, POST, PATCH, PUT, DELETE, streaming POST and streaming GET.
The fixture advertises session reads plus existing create/chat operations, so
zero-write assertions do not depend on a disconnected or wholly read-only screen.
Unexpected routes fail. Printed receipts contain only deterministic methods,
routes, query maps and counts. They never print bodies or credentials.

## Intercepted requests

The passing `journey.log` records these complete route totals. Every row uses GET.
Query maps are checked independent of serialization order.

| Route | Query map | Search/reconnect | New selection | Replacement success | Replacement failure |
| --- | --- | ---: | ---: | ---: | ---: |
| `/health` | `{}` | 2 | 1 | 1 | 1 |
| `/v1/capabilities` | `{}` | 2 | 1 | 1 | 1 |
| `/api/profiles` | `{}` | 0 | 0 | 1 | 1 |
| `/api/sessions` | `{profile: default, limit: 50, offset: 0}` | 2 | 1 | 1 | 1 |
| `/api/sessions/keep/messages` | `{profile: default, limit: 500, offset: 0, order: latest}` | 2 | 2 | 1 | 1 |
| `/api/sessions/target/messages` | `{profile: default, limit: 500, offset: 0, order: latest}` | 2 | 1 | 1 | 1 |
| `/api/sessions` | `{profile: b, limit: 50, offset: 0}` | 0 | 0 | 1 | 1 |
| `/api/sessions/keep/messages` | `{profile: b, limit: 500, offset: 0, order: latest}` | 0 | 0 | 1 | 1 |
| `/api/sessions/target/messages` | `{profile: b, limit: 500, offset: 0, order: latest}` | 0 | 0 | 1 | 1 |
| Total requests | | 10 | 6 | 9 | 9 |

Each journey asserts POST=PATCH=PUT=DELETE=0, including streaming POST.
There are zero create, message, approval, Stop or replay mutations.
All requests target the reserved deterministic origin `https://example.invalid`.
No live HTTP request is made.

## Contract and source trace

No production correction was needed. The existing query filter at
`lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart:62` filters
presentation without replacing the channel inventory. Its search field and clear
button are at `:473` and `:481`; the row callback is at `:1797`.
`_sessionMatchesQuery` at `:1330` searches loaded row metadata and preview,
not the complete server transcript corpus.

`lib/features/hermes_chat/session/hermes_chat_session_actions.dart:148` calls
`selectSession` under the settlement-owner guard at `:6`. The guard permanently
invalidates owner loss and fences focus/error feedback.
`lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart:57` captures
session-selection, connection and profile-selection generations, client identity,
profile ID and transcript identity. These fence history success and failure.
`lib/core/hermes/client/hermes_api_client.dart:126` sends explicit profile-bound
list pagination; `:239` sends bounded latest history and validates returned
session identity before accepting it.

Both read-only upstream root instruction files were read. Reference revisions:

- Agent: `158fd638da1629c8e62caf9ade1515d162def8ab`.
  `hermes-agent/gateway/platforms/api_server.py:3295` resolves the requested
  session's resume identity and returns bounded latest history, including
  compression ancestors. The nearest test at
  `hermes-agent/tests/gateway/test_session_api.py:116` checks the default latest
  bounded page and explicit pagination. These sources were inspected, not run.
  The new fixture covers ordinary exact-ID history, not compression lineage.
- Desktop: `withdrawn reference revision`.
  `withdrawn source citation` binds
  debounced search results to connection/profile/query generation.
  `withdrawn source citation` searches title/ID and optionally
  message FTS. Wing's loaded-row metadata filter is a narrower existing surface.
  This receipt does not qualify Desktop IPC, full-text search, corpus-wide
  pagination or equivalent result ranking. No Desktop code was changed.

The rename/delete/fork journey tests and receipts were read as harness guidance
and left unchanged. The nearest filtering/open-owner and channel tests were
inspected and executed as listed below.

Execution source HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
The shared working tree contains unrelated dirty layout/localization work.
These checks exercise that tree, not an isolated release artifact.
SHA-256 of the final scoped test and relevant exercised production files:

| File | SHA-256 |
| --- | --- |
| New search/resume test | `864b27d8673eee8d86bbc0498af98eb7e6fb99937ac5f92072ab7d846857e3b2` |
| Session widgets | `b1c314cf972bea68743a8dae7edb382fc50ff59019693bb0639cc84f0bece390` |
| Session actions | `e4826a2bd5a3559d60740059a3bfb38ca25a4a8720858ba4ffadb705cf3ce2ff` |
| Channel sessions | `148816aead97af644977509989ab4f30e580ec2a628566de2e18ffcc55f0081f` |
| API client | `89a946e0cade3183fb29b45561f4124916a2eb779e3b675773246e1de6bb3511` |
| Pre-existing dirty layout, not edited by this card | `4a4b2a27244cb7025a64db72105ddd1aece3570f308f9c6aa225b0d5d9ae0304` |

## Executed checks

Commands ran sequentially from the repository root. Logs are under ignored
`.task-evidence/t_8866900e/`. Each Flutter test command used `--concurrency=1`.
The five final test invocations passed 115 tests in total.

- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart`
  — PASS, 4 tests, `journey.log`. The first invocation also passed all four.
- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart --name 'session search|session source filter|header selects an older session'`
  — PASS, 4 tests, `filtering.log`. Covers wide/compact source filtering,
  title/preview highlighting and an older-session selection.
- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_settlement_owner_test.dart`
  — PASS, 102 tests, `settlement-owner.log`. Covers compact/wide open focus,
  late success/error feedback, owner loss/return, replacement and unmount;
  the existing file also includes create-settlement cases.
- `flutter test --concurrency=1 test/core/hermes/channel/hermes_session_caller_admission_test.dart --name 'open caller'`
  — PASS, 3 tests, `channel-open.log`.
- `flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --name 'latest session selection|stale session history'`
  — PASS, 2 tests, `channel-selection.log`.
- `dart format test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart`
  — PASS. Only the new file was formatted.
- `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart`
  — PASS, zero changes, `format.log`.
- `flutter analyze` — final PASS, no issues, `analyze-final.log`.
  Initial FAIL, two multiline-if brace lint findings in the new fixture,
  `analyze.log`. Added braces and reran the new journeys, formatter and analyzer.
  No production validation was relaxed.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate .`
  — PASS, `ok`, after supported task/evidence/render updates.
- `git diff --no-index --check /dev/null test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart`
  and `git diff --no-index --check /dev/null docs/quality/session-search-resume-journey.md`
  — PASS, no whitespace diagnostics. Exit 1 denotes new-file differences.
- `git diff --check -- goals.json TODO.md` — PASS, exit 0.
  The whitespace results are recorded in `diff-check.json`.

The goal helper marks `DOC-SESSION-SEARCH-RESUME-QUALIFICATION` done and records
the actual successful checks and initial analyzer failure. With all four listed
qualification tasks done, it sets `SESSIONS` to `met`. That ledger outcome is
bounded to the recorded deterministic qualification tasks. It does not establish
complete session feature parity, full-text search or live/native support.
The co-owned `goals.json` and rendered coverage block in `TODO.md` were updated
only through the supported helper. No whole-file ledger commit was made.

## Qualification limits and delivery

Actually exercised: Linux-hosted deterministic Flutter widgets and channel tests.
Live Agent/provider, network HTTP, native desktop interaction, process relaunch,
automatic remembered-session restoration, detached-run recovery, compression
lineage, full-text/corpus-wide search, browser E2E, Android, full router,
packaging and release are NOT_CHECKED.

No production file, upstream clone, Wing Link file, localization output,
excluded picker/layout file or predecessor journey was edited. No commit,
staging, publish, service restart, device action or new configuration was made.
No large build output was created; existing shared Flutter outputs were reused
and preserved. No owner question remains within the assigned scope.
Native same-card review is the final implementation handoff, not review approval.
