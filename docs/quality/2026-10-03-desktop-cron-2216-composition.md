# Desktop continuation — integrated workflow composition assessment

Occurrence: 2026-10-03 22:16 local. Source assessment only; no implementation, Flutter execution, inference or acceptance transition.

## Ownership and result

The [goal ledger](../plans/2026-10-03-desktop-port-goal.md), primary release message and [wave receipt](2026-10-03-desktop-daily-workflow-wave.md) agree the previous scopes are released. Runtime delegation/process tools returned no live handles. Process census found no competing Flutter/Dart/fixture/Playwright/Xvfb task. One owner leased only this receipt, the ledger and wing scratch evidence; ROADMAP and all implementation/reference files remained read-only.

**The existing scenarios cannot be concatenated into one integrated proof.** Their seed controls reset shared server state, and lifecycle mode explicitly rejects session-model writes. This is a fixture composition gap, not a reproduced production defect. The existing native fixture wrapper already provides off-page exact-session recovery and should be reused instead of building another restoration backend.

## Indexed source evidence

| Source | Inspected behavior | Consequence |
| --- | --- | --- |
| [Shared server](../../serve_web.mjs), lines 64–100, 177–189, 227–260 | Lifecycle/model/restoration state is reset by scenario seeds. Picker seed enables catalog plus first-lock rejection; lock receipt is attached to the fixed `e2e-hermes-session`. | Seeding picker after lifecycle destroys run state; seeding lifecycle after picker destroys the confirmed model. Never seed again between workflow stages. |
| [Lifecycle handler](../../playwright/support/hermes_lifecycle_fixture.mjs), lines 14–24, 48–77, 127–141 | Default-profile run identity, bounded submit/approval/Stop receipts, exact approval request ID, delayed terminal Stop; all non-run domain mutations return 403. | An integrated model-lock operation needs an explicit scenario-only allowlist, not removal of the mutation guard. Receipt must include owner and selected runtime, not just a pair of display strings. |
| [Production Chat journey](../../playwright/tests/regression/production-chat-journey.spec.mjs), lines 87–102, 127–150, 165–194 | Real add/contact/session UI; approval, denial, delayed terminal Stop, transport recovery and exact prompt counts. No model picker or page reload. | Borrow UI actions and canonical reconciliation assertions; its current success is not integrated model/relaunch evidence. |
| [Picker journey](../../playwright/tests/regression/session-model-picker.spec.mjs), lines 8–13, 33–62 | Standalone connect hook; rejected first lock, deliberate retry, session runtime readback, reopen and Escape. | Use the actual saved-contact UI in a new integrated journey, not this connect hook. Preserve raw provider/model identity and no-mutation cancellation. |
| [Restoration journey](../../playwright/tests/regression/session-restoration.spec.mjs), lines 30–43, 88–134, 173–185 | Real saved pointer; page-two selection, reload, exact metadata/history and zero mutations. No runs or model lock. | Carry pointer/readback assertions into the integrated scenario; do not change or weaken its read-only contract. |
| [Daily fixture wrapper](../../scripts/support/desktop_daily_workflow_fixture.mjs), lines 68–107, 133–159, 179–219 | Lifecycle seed activates bounded inventory/metadata receipts; target is genuinely re-paged after untouched session. Loopback-owned child and shutdown. | Reuse this runner fixture for compiled browser assessment. It already separates off-page pointer recovery from inventory defaults. Wrapper reset rules currently disable restoration on picker seed. |
| [Native harness](../../integration_test/linux_desktop_daily_workflow_test.dart), lines 19–23, 41–92, 103–209 | Explicitly separate model and lifecycle tests; production channel identity and no-replay assertions across native process phases. | Comments correctly disclaim combined proof. Native process execution remains unobserved; do not edit this harness just to rename coverage. |
| [Model lock caller](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart), lines 172–221 | Advertised operation gate, current session membership, profile/connection fences, accepted exact-session response stored in `sessionModelLocks`. | Test session-only confirmed identity, not profile inventory assignment. A fixture upgrade must not add production capability fallbacks. |
| [E2E readback](../../lib/main_e2e.dart), lines 146–158 | Assigned provider/model fields come from model inventory assignment. | These fields do not prove a session lock. Prefer canonical session metadata/runtime response plus picker reopen; do not add a misleading readback hook. |

Reference locations and root guides were checked read-only. Conduit root `AGENTS.md` was absent; no deep Conduit inspection, upstream tool execution, parser scan or graph generation was needed. No new upstream runtime authority claim is made.

## Ranked bounded next work

### 1. Integrated deterministic browser regression — dependency-ready proposal

One owner should claim exactly:

- `playwright/support/hermes_lifecycle_fixture.mjs`: add a bounded explicit lifecycle seed variant, e.g. an exact allowlisted `scenario: desktop-daily` value in the existing test-only POST control. Default no-body lifecycle behavior must remain unchanged. Enable the existing synthetic model catalog/first-lock rejection without another reset. Permit only the fixed target session-model route in that variant, require exact default-profile context and valid synthetic raw pair, and retain the guard for every other mutation. Record bounded owner-scoped lock attempts/readback; preserve legacy receipt shape outside the variant.
- `playwright/support/hermes_desktop_daily_fixture_test.mjs` (new): executable behavioral Node regressions for seed preservation, wrong profile/session/pair rejection, forbidden mutations, one rejected then accepted explicit lock, and unchanged existing lifecycle behavior. Reuse existing synthetic catalog/lock handling in `serve_web.mjs` where practical; if correct behavior needs another shared-source edit, stop and amend the exact lease before touching it.
- `playwright/tests/regression/desktop-daily-workflow.spec.mjs` (new): a single continuous journey per 390px/1280px context, using the existing daily fixture wrapper and production add/contact/picker/chat/navigation UI. No connect/send/restore hooks, no local-storage writes, and no second seed during the journey.

Ordered acceptance:

1. Pin the fixture's current rejection/reset boundary in behavioral tests; observe the intended failing combined-scenario assertion before fixture changes. Do not weaken existing suites or alter production code.
2. Add through the actual connection UI; explicitly activate the default-profile contact and choose `e2e-hermes-session` from page two. Prove the saved gateway/profile/session tuple and selected canonical origin, not its label alone. This proves explicit default-profile activation, not cross-profile switching.
3. Search/select `alpha/model-99`; first confirmation fails, second deliberate confirmation succeeds. Require exactly two owner-scoped attempts and accepted raw runtime on exact session metadata. Unconfigured/provider-profile writes remain forbidden.
4. Send one synthetic prompt, approve exact `approval_run_1`, verify canonical completed history. Send one second synthetic prompt, Stop `run_2`; require `stopping` readback and blocked Send until the explicit test-only terminal control plus user Reconnect yield `cancelled` and canonical stopped history.
5. Leave through real shell navigation and return; reload the page in the same browser context without seeding or writing preferences. Require the unchanged saved tuple, off-page exact metadata/history reads and accepted session runtime. Reopen picker to prove restored confirmed identity rather than catalog default.
6. Compare mutation counters before/after leave/reload: no new submits, approvals, Stop, locks or sessions. Then one deliberate third send/approval proves post-reconciliation usability. Final counts: 3 submits, 2 approvals, 1 Stop, 2 lock attempts, no unexpected mutations; assert exact session/profile/request IDs and canonical user turns. Model readback demonstrates synthetic session state, not effective real-provider routing.

Verification commands after exclusive ownership, with logs in wing scratch:

```sh
node --test playwright/support/hermes_desktop_daily_fixture_test.mjs
node --check playwright/support/hermes_lifecycle_fixture.mjs
node --check playwright/tests/regression/desktop-daily-workflow.spec.mjs
flutter build web --release --no-pub -t lib/main_e2e.dart
PORT=<owned-port> HERMES_E2E_PORT=<owned-api-port> node scripts/support/desktop_daily_workflow_fixture.mjs
CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:<owned-port>/ \
  HERMES_E2E_PORT=<owned-api-port> PLAYWRIGHT_JSON_OUTPUT_FILE=<scratch-report> \
  ./node_modules/.bin/playwright test playwright/tests/regression/desktop-daily-workflow.spec.mjs \
  --workers=1 --retries=0 --reporter=list,json --output=<scratch-artifacts>
```

These are proposed commands, **not executed**. Use one bounded runner (build 180s, focused browser 240s, whole command 480s), owned bind readiness, captured JSON receipts and finally cleanup/reaped child groups/closed ports. Rerun the changed lifecycle/picker/restoration browser regressions against their intended fixture configurations after the producer tests pass; no unchanged full Flutter suite. Regression collection/configuration must not accidentally start a second fixture. Stop at any production failure and hand back the reproduction before expanding the lease. Independent review must check scenario isolation, strict identity and non-replay assertions.

### 2. Native reuse — gated, not ready

Only after matching browser/fixture evidence and a separate native lease, consider composing the native model test into its two-process workflow using the same validated seed. Native prerequisite changes and the reviewed local-integration/security decision remain separate gates. Do not retry the unchanged blocked launcher or install packages.

### 3. Approved actual inference — owner-gated

The synthetic fixture cannot satisfy real generation, provider routing, private authentication or full local functionality. A named isolated unmodified Agent target with supported private auth, explicit network/cost/tool consent and owner-selected `openai-codex` / `gpt-6.1-sol` remains required. No auth discovery or personal runtime mutation occurred here.

## Verification and limits

Only source inspection and document/source-binding checks ran in this occurrence. Scratch: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2216-composition/`. `source-before.json`, `source-after.json`, `status-before.log` and `checks.json` bind the inspected files and document gate. The final ledger records observed exit codes and lease release. No browser/native test was run, no QA service/display was started, and no cleanup resource remains.

This proposal is an actionable regression scope under the existing workflow, not an accepted native design, implementation result, card transition or milestone completion. Do not repeat prior passing isolated suites as a substitute for the combined regression.

Run summary: not_available — host accounting was not exposed.
