# Desktop continuation — initial model selector, 2026-10-04 01:17

## Result

Corrected only the integrated browser journey's opening model selector and added
an explicit visibility assertion for the initial synthetic session metadata model
`hermes-agent`. All later rejection, confirmation, Stop, owner, reload, picker and
mutation-count assertions are unchanged.

Fresh compiled Chromium at **390px and 1280px** now passes the route-return and
reload assertions for exact saved owner, canonical history, recovered model label
and unchanged mutation counts. Both tests then fail at the reopened picker's
selected provider/model assertion: it displays `Display beta (beta) — shared`,
not `Display alpha (alpha) — alpha/model-99`. Full integrated success and final
explicit resumed-send/count guarantees remain unverified. No production repair
was attempted in this occurrence.

## Ownership and scope

The [goal ledger](../plans/2026-10-03-desktop-port-goal.md) and
[previous receipt](2026-10-04-desktop-cron-0046-model.md) released prior ownership.
`hermes cron list` showed this occurrence running and hourly autogoal completed;
native delegation/terminal lists were empty and OS QA census had no competing
Flutter/build/browser fixture. One direct owner leased the browser spec's initial
selector/oracle, this receipt, ledger, generated build and wing scratch evidence.
No process-local subagents were spawned. Independent review remains open.

All other production/tests/fixture/server sources, ROADMAP and upstream references
were read-only. Existing dirty work was preserved. No installs, native retry,
full-suite replay, actual inference, private auth access, personal runtime
mutation, commits, card changes or scheduler mutation.

## Indexed source and failure evidence

1. [Fixture session initialization](../../serve_web.mjs) defines the initial
   `e2e-hermes-session` model as `hermes-agent` (lines 73–75). The preceding
   presentation fix makes that authoritative model text visible in the composer;
   the generic `Hermes model` opening selector was obsolete.
2. [Integrated journey:115–117](../../playwright/tests/regression/desktop-daily-workflow.spec.mjs)
   now explicitly checks `hermes-agent` before opening the picker. Parent comparison
   against the pre-edit dirty source confirms this is the only source change.
3. [Integrated journey:157–190](../../playwright/tests/regression/desktop-daily-workflow.spec.mjs)
   reached canonical Stop/Reconnect, route return and reload at both widths. The
   sequential assertions passed for saved-pointer equality, exact profile/session
   metadata reads, page-zero omission of the off-page owner, canonical message IDs,
   corresponding history reads, model display and unchanged mutation arrays.
   These are observed assertions in failed tests, not two passing whole journeys.
4. [Integrated journey:192](../../playwright/tests/regression/desktop-daily-workflow.spec.mjs)
   is the first failure at both widths. Error contexts show a loaded 303-model
   dialog with `Selected: Display beta (beta) — shared`; session status still shows
   `alpha/model-99`. Model text restoration does not establish a recovered
   acknowledged provider/model lock, and this is not evidence of a server model reset.
5. [Picker:33–59](../../lib/features/hermes_chat/widgets/session_model_picker_sheet.dart)
   chooses volatile acknowledged session lock first, otherwise catalog current
   provider/model and fallback selection. Source search found session locks added
   after confirmation in
   [providers channel](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart)
   and cleared during profile connection in
   [profiles channel](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart).
   This is a bounded source lead, not a complete advertised runtime-read authority
   trace or authorization for a new restoration implementation.

The test writes its final stage receipt attachment only after full completion;
therefore no complete stage/count attachment was produced. Parsed failure locations
and retained semantic error contexts establish progression, not final resumed
send or final zero-duplicate counts. Escape/resume assertions after line 192 did
not execute. Upstream tests/runtime were not exercised.

## Executed verification

Scratch root:
`/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-0117-selector/`.
Exact command arrays, timestamps, artifact and cleanup are in `results.json`;
`parsed-browser.json` records both first failures and one attempt each.

| Command | Observed result |
| --- | --- |
| `node --check playwright/tests/regression/desktop-daily-workflow.spec.mjs` | Exit 0, 07:19:30 UTC. |
| `flutter build web --release --no-pub -t lib/main_e2e.dart` | Exit 0, 07:19:30–07:20:19 UTC. Existing flutter_tts Wasm dry-run warnings remain. |
| `./node_modules/.bin/playwright test playwright/tests/regression/desktop-daily-workflow.spec.mjs --workers=1 --retries=0 --reporter=list,json --output=<scratch>/integrated-artifacts` | Exit 1, 07:20:19–07:21:02 UTC. 0 passed / 2 failed / 0 skipped / 0 flaky; one attempt each, first failure at line 192. |
| Parent source/diff/result/port/census checks | Exit 0; 239 bounded source files compared, only initial selector/oracle changed; no later assertion changed. Both ports refused connections; QA census empty. `checks.json`, `owned-spec.diff`, `source-before.json`, `source-after.json`. |

Node v26.7.0 (different from repository's intended Node 22); system Chromium
152.0.7977.75 on Linux. Fresh `build/web/main.dart.js` SHA-256:
`2b62868fb5bb4734768c07ea1f1ceea5840cc6df55b2cfae83798909c37abab5`.
No Dart implementation changed; no analyzer/full Dart suite/legacy browser replay
was performed. The previously reported 2,400-test full suite is not this run's gate.

## Cleanup and continuation

Durable terminal `proc_f92ab3e2963e`, PID 1875142, persistence confirmed. Host
async notification was unsupported; one bounded 180-second process wait returned
runner exit 1 within the 360-second outer deadline. Fixture PID 1876602 was
terminated/reaped (143); ports 46069/41007 refused connections (111/111). Parent
fresh port checks and QA census agree. No owned QA resource remains.

**P1 — bounded read-only runtime-pair authority trace, then a precise regression
proposal.** Trace advertised session runtime/provider-model reads through the
unmodified Agent source/nearest tests, Wing client/channel callers and synthetic
fixture; separate catalog defaults, session metadata and acknowledged lock. Next
lease should own only ledger/new assessment receipt and scratch evidence first.
Exit criteria: indexed exact operation/auth/profile/session/readback contract,
identity/revocation/stale-response fences, and exact regression/write scope or
explicit unsupported-contract blocker. No synthetic lock from model-name text,
no repeated lock mutation or shadow persistence, and no weakened picker assertion.
A production edit requires a separately leased genuine regression RED afterward.

**P2 — native/live acceptance stays open.** No native development metadata retry,
actual provider generation or milestone/card acceptance in this occurrence. This
is the first reopened-picker failure, not three repeated unchanged failures. Lease
released after scoped document checks. No same-tick qualification retry.

## Requested supplemental verification

Following an explicit verification request and fresh empty QA census, literal
`npm run test` completed with **exit 0: 2,400 tests passed** (`05:07 +2400: All
tests passed!`). Host verification evidence is `passed`, kind `test`, scope `full`,
canonical command `npm run test`. No code repairs were needed.

Full log: `/home/xel/.hermes/profiles/wing/cache/terminal-output/out-1791098656-1872147-fe10.log`.
Verification-only lease released. This Dart suite does not execute or fix the
separate compiled-browser reopened-picker failure; final resume/count and
native/live acceptance remain open.

Run summary: not_available — host accounting was not exposed.
