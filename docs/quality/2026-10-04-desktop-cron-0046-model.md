# Desktop continuation — model display restoration, 2026-10-04 00:46

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


## Result

Implemented a display-only composer fallback to the active session's recovered
model metadata. Exact provider/model lock state remains untouched. A genuine
widget RED preceded the five-line presentation edit; **29 focused tests pass**,
formatting and analyzer pass. Full browser workflow qualification remains open:
the fresh integrated run stops earlier at an outdated initial picker selector.

## Scope and ownership

The [goal ledger](../plans/2026-10-03-desktop-port-goal.md), primary session release,
empty native delegation/terminal lists and OS census established no competing Wing
writer/build. `hermes cron list` showed only this occurrence running; hourly
autogoal was completed at admission. One owner leased the ledger, this receipt,
[new regression](../../test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart)
and conditional [composer layout](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart).
Generated `build/web` and wing scratch runner/artifacts were subsequently leased
for one fresh compiled browser attempt. No process-local children were spawned.

Prior dirty layout changes are preserved. ROADMAP, other production/test/server/
fixture files and Agent/Desktop/Conduit were read-only. No installs, auth scanning,
personal runtime mutation, inference, commits, cards or scheduler changes. Upstream
Git status was inspected: Agent/Conduit clean; Desktop already has five deletions
under `.claude/`, left untouched. Dirty HEAD is not a content snapshot.

## Indexed source and authority

1. [Composer layout:1280–1293](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart)
   previously displayed only volatile session-lock model, profile assignment or
   `Hermes model`; [active-session bar:667–670](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart)
   already displayed session metadata. The change inserts nonempty exact active
   session metadata between lock and profile assignment. It adds no new state,
   cache, request, provider identity, accepted lock or replay.
2. [Session decoder:31–55](../../lib/core/hermes/models/hermes_session.dart) decodes
   a model string. [Restore:15–54](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart)
   admits exact off-page metadata under current profile/connection/selection guards.
   [Active-session lookup:277–284](../../lib/core/hermes/channel/hermes_channel_state.dart)
   matches the active ID, preventing a different session's metadata label from
   leaking after selection. Existing acknowledged-lock precedence is unchanged.
3. The new regression reuses the production HTTP/channel/directory
   [restoration harness](../../test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart)
   read-only. Synthetic exact A/coder metadata is decoded, Chat is removed/remounted
   inside the same ProviderScope, chip text is asserted at 390/1280px, and selecting
   B removes A's label. Both lock map and mutation recorder remain empty. This is
   a widget remount, not native process relaunch or live server qualification.
4. [Desktop Chat:358–409](official-desktop-reference.md#withdrawn-evidence)
   restores a separate session-local provider/model override for presentation,
   with `persist:false`; it does not justify copying privileged IPC/local storage
   or treating model-name-only metadata as an authoritative runtime pair in Wing.
   Desktop source was inspected; upstream tests/runtime were not executed.

## Executed commands

Scratch root: `<home>/.hermes/profiles/wing/cache/scratch/desktop-cron-0046-model/`.
`red-results.json`, `green-results.json`, `browser-results.json` record exact arrays
and exits; browser records also include UTC timestamps. `owned-layout.diff` binds
only this occurrence's five added lines against the pre-edit dirty layout.

| Command | Observed result |
| --- | --- |
| `dart format test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart` | Exit 0, formatted new test. |
| `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart` | Intended RED exit 1, 0 passed/2 failed: exact recovered A/coder/model and chip present, model text absent after remount. No setup error. `red.log`. |
| `dart format lib/features/hermes_chat/screens/state/hermes_chat_layout.dart test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart` | Exit 0, two files/zero changes. |
| `flutter test --no-pub --concurrency=1` with new model restoration, Chat session picker, Chat session restoration, Reconnect owner, gateway session restoration targets | Exit 0, 29 passed, no failed/skipped markers. `green.log`; exact target array in `green-results.json`. |
| `flutter analyze --no-pub` | Exit 0, no issues. `analyze.log`. |
| `flutter build web --release --no-pub -t lib/main_e2e.dart` | Exit 0, 06:48:41–06:49:32 UTC. Existing flutter_tts Wasm/Cupertino warnings retained. |
| `./node_modules/.bin/playwright test playwright/tests/regression/desktop-daily-workflow.spec.mjs --workers=1 --retries=0 --reporter=list,json --output=<scratch>/integrated-artifacts` | Exit 1, 0 passed/2 failed/0 skipped/flaky, one attempt each. 06:49:33–06:49:59 UTC. Both stop at spec:115, not route return/reload. |
| Scoped `git diff --check` and Python source/diff/result/census assertions | Exit 0. Two consumed test sources unchanged; owned delta is only five added layout lines. Browser counts/attempts parsed in `parsed-browser.json`, no QA commands remain in `close.json`. |

Flutter 3.44.2 / Dart 3.12.2; Chromium 152.0.7977.75 on Linux, Node v26.7.0
(not intended Node 22). Web artifact `build/web/main.dart.js` SHA-256:
`2b62868fb5bb4734768c07ea1f1ceea5840cc6df55b2cfae83798909c37abab5`.
No full Dart suite was run during the initial bounded increment; the explicitly
requested supplemental run below followed. No nearest legacy browser replay or
native build was run.

## Requested supplemental full-suite verification

`npm run test` ran once after an exclusive QA census and an exact ledger lease;
exit **0**, 2026-10-04T06:54:04.154891Z–06:59:30.288998Z. Runner summary:
`05:22 +2400: All tests passed!`. No code repair was required.

Logs: `npm-test.log`, exact command/exit/timestamps `npm-test-result.json` in the
same wing scratch root. Initial durable runner `proc_96094e7d58a7` failed before
npm dispatch because the tool's changed TMPDIR pointed outside the existing wing
scratch directory. The log path was corrected explicitly, not a test retry.
Actual durable runner `proc_91e26d965917`, PID 1838839, exited 0. Async notifications
were unavailable; two 180s bounded wait windows observed completion within the
540s runner deadline. No process-status polling or QA service launch.

The complete Dart suite passes; it does not execute or fix the separate failed
Playwright initial selector. Integrated browser/native/live acceptance remains open.

A repeated explicit request then ran literal `npm run test` directly: exit **0**,
`05:10 +2400: All tests passed!`. The host now returns verification evidence
`status: passed`, `kind: test`, `scope: full`, `canonical_command: npm run test`.
Full log: `<home>/.hermes/profiles/wing/cache/terminal-output/out-1791097245-1789145-b820.log`.
No implementation repair was required; direct-command verification lease released.

## Browser boundary and ranked continuation

**P1 — correct the initial selector, then run the unchanged integrated assertions.**
Both browser failures at
[spec:115](../../playwright/tests/regression/desktop-daily-workflow.spec.mjs)
wait for checkbox `Hermes model`. The actual wide error context shows active
metadata/status and composer checkbox all displaying `hermes-agent`; this is the
new intended metadata display, not an absent picker. Earlier selection, inventory
and exact saved-pointer assertions passed. The regression was kept read-only in
this occurrence; no assertion weakening or same-tick rerun occurred.

Next exact lease: that browser spec's initial model-display assertion/selector,
ledger and new receipt, generated build and scratch QA artifacts. Assert the
initial metadata model explicitly (`hermes-agent` in this deterministic fixture)
and use that model to open the picker; keep confirmation, rejection/retry,
Stop/restore/reload and mutation-count assertions intact. Exit: fresh compiled
390/1280px integrated gate with retries disabled and inspected first failure or
complete receipts, plus cleanup. This occurrence's browser run did not reach the
original route-return failure, reload, reopened picker or resumed send, so none is
claimed fixed end-to-end.

**P2 — provider/model picker restoration remains an independent authority gate.**
If the integrated run reaches the reopened picker assertion, trace exact advertised
Agent runtime-pair read and nearest tests before adding any decoder/state change.
Recovered model text is not an accepted provider/model lock. Do not repeat a lock
write or persist shadow state to satisfy it.

## Cleanup and completion limits

Durable terminal `proc_e3047e6f3ffb`, PID 1823570, persisted across release; host
reported async notifications unavailable, so one bounded 180s process wait was
used. Runner had a 360s outer deadline (build 180s, browser 150s). It exited 1,
reaped fixture PID 1824948 (143), and ports 40129/50373 refused connections (111).
Final OS census is empty; no owned services/displays/workers remain. Lease released.

Presentation behavior is implemented and widget-verified, not complete browser,
native/live or independently accepted parity. The full milestone remains open.
This is the first stale-initial-selector occurrence, not three repetitions of the
previous route-return failure. No job pause threshold was reached.

Run summary: not_available — host accounting was not exposed.
