# Desktop port continuous-work goal

## Owner decisions

Accepted in the Telegram interview, 2026-10-03:

1. Desktop-first fidelity on Flutter desktop/wide web. Preserve mobile usability;
   Android-specific adaptations follow matched Desktop flows.
2. Full local Desktop functionality through a separately designed bounded native
   integration. Remote mode may expose fewer capabilities. This is not approval
   for arbitrary shell/filesystem/config access or Agent modifications.
3. Next milestone: local connect → explicit profile/model → Chat generation →
   approval/stop → leave → restore exactly the same session without duplicate sends.
   Supporting shell fixes follow this workflow, not isolated cosmetic priority.
4. Owner requested start work and a recurring 10-minute continuation job.

## Boundaries

Repository: `/home/xel/git/gormes/hermes-wing`.
Active Hermes profile: wing; never edit other profiles' data.
Agent, Desktop and Conduit references including tooling/hooks remain read-only.
Preserve unrelated dirty edits, no commits/push/releases or acceptance-card changes.
No personal credential copying, secret scanning, personal runtime changes,
package installs or security bypasses. Live qualification must use an approved
isolated target and supported private auth provisioning; do not switch the owner's
`openai-codex` / `gpt-6.1-sol` selection to an easier provider/model.
Fixtures/widget tests are not live generation/native acceptance.

## Current checkpoint

Status: blocked at the latest recorded continuation checkpoint, 2026-10-04 03:22.
Job `6f218a559ed2` was paused and read back paused in the
[isolated-target preflight receipt](../quality/2026-10-04-desktop-cron-0322-auth-preflight.md).
This summarizes recorded evidence, not a fresh scheduler or environment check.
The occurrence released its lease; no automatic resume is authorized.

Unblocking requires an owner-approved isolated target and supported private auth,
separately reviewed exact provider/model read and native recovery authority,
separately authorized native development prerequisites, then explicit continuation
ownership and resume. The preflight found no supplied live-launcher inputs and
missing libsecret/GStreamer development metadata. The package-provisioning question
was cancelled, not approved; no installation is authorized. Do not retry unchanged
browser/native/full-suite gates or treat source review as runtime acceptance.

The harness/design/documentation wave remains integrated. Independent re-review
`deleg_04bb2580` resolved both original P2s through source and bounded executable
probes; native two-process Flutter acceptance has not run. Historical receipt:
[initial workflow wave](../quality/2026-10-03-desktop-daily-workflow-wave.md).
The prior sidebar toggle wave is implemented, independently source-reviewed and
locally verified (2,397 tests), not runtime/card accepted.
Receipt: `docs/quality/2026-10-03-desktop-port-first-wave.md`.
Known earlier preflight: `docs/quality/2026-10-03-native-chat-qualification.md`;
recheck prerequisites rather than treating historical blockers as live facts.

## Initial wave ownership

- Native harness lane: write only
  `integration_test/linux_desktop_daily_workflow_test.dart` and
  `scripts/run_linux_desktop_daily_workflow_e2e.sh` (both new).
  Consume production channel/fixture/other sources read-only. Establish a
  deterministic owned-Xvfb journey and explicit recovery coverage. No production
  edits until a reproduced gap is handed back to the primary owner.
- Native design lane: write only
  `docs/plans/2026-10-03-desktop-local-integration-design.md`.
  Trace local Desktop execution authority and propose bounded native contracts;
  source-backed design, no code/runtime mutation.
- Documentation lane: write only `ROADMAP.md`, `docs/adr/client.md`,
  `docs/product/hermes-desktop-parity.md`, and
  `docs/plans/2026-10-03-desktop-daily-workflow.md`.
  Record accepted interview decisions, workflow acceptance and explicit gaps;
  do not promote source/fixture evidence to actual Agent runtime acceptance.
- Primary owner: this goal ledger, integration review and a new quality receipt.
  May repair producer files only after producer ownership is released.

## Continuation policy

The recurring job is a fresh bounded worker, not a keepalive of this conversation.
At each tick, read this ledger, workdir instructions, current Git state and latest
receipts. First check outstanding native delegation/terminal handles through
available runtime tools. Never start a second writer for any owned file or a
second Flutter/build command while one is active. An active chat-owned wave means
inspect/record safe read-only prerequisites or wait for its receipt; do not steal
its files. No status polling loops or duplicate dispatches.

After this wave releases ownership, select one dependency-ready, bounded task
from the daily-workflow plan. Record exact write scope and in-progress lease in
this file BEFORE mutation; record source references, commands/exits, failures,
log paths and the next action AFTER. Use scratch logs under the wing profile.
Do not infer completion from a plan, process exit or a child summary.

Missed ticks are skipped, not backfilled. Avoid same-tick retries. If the same
blocker/failure repeats on three consecutive occurrences, pause the job using its
listed actual ID and record the precise blocker. Pause on missing owner authority,
required secret provisioning or ambiguous concurrent ownership; never bypass.
Stop/pause when the milestone's required evidence is complete or the owner says
stop. Completion of this milestone requires a new owner-approved next scope; the
job must not turn a 1:1 goal into unbounded unrelated edits.

Cadence: every 10 minutes. Output local by default to avoid a message every tick;
owner can inspect receipts. The schedule cannot guarantee progress while the
scheduler/provider is unavailable or an owner-only blocker remains unresolved.

## Execution ledger

- Cron created and resumed, then read back as enabled/scheduled: job
  `6f218a559ed2`, every 10m, local delivery, continuity enabled. First scheduled
  occurrence: 2026-10-03T20:20:24.215114-06:00. No occurrence execution claimed.
- Primary wave dispatched: `deleg_4968bbf7`; harness `sa-0-66e3439f`, native
  design `sa-1-b2166296`, documentation `sa-2-28c6af76`. Completion delivered
  into the primary conversation. Producers retain the scopes above until their
  returned results are integrated and the primary owner releases this checkpoint.
  Cron must not overlap those files while the checkpoint is active.
- 2026-10-03 21:28 continuation: primary release confirmed in current checkpoint,
  latest wave receipt and primary session release message. Runtime tools list no
  live subagents or terminal jobs; process census shows no Flutter/Dart/Xvfb work.
  Single-owner bounded verification lease: write only this execution ledger and
  `docs/quality/2026-10-03-desktop-cron-2128-restoration.md`; scratch logs under the
  wing profile. Read-only targets: exact-session restoration, adversarial recovery
  and selection-write race tests. Acceptance: observed focused test exit/counts,
  unchanged production/test sources, and released lease with next checkpoint.
  No full suite, native build, installation, live inference or upstream mutation.
  Lease status: released after focused gate. `flutter test --no-pub
  --concurrency=1 --reporter=json` on the three named gateway restoration/race
  targets: exit 0, JSON parsed 49 passed/0 failed/0 skipped; source hashes unchanged.
  Logs: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2128-restoration/`.
  Receipt: `docs/quality/2026-10-03-desktop-cron-2128-restoration.md`.
  Fresh native metadata checks remain blocked (libsecret plus three GStreamer
  packages each exit 1); no launcher retry/install. Scheduler lists this occurrence
  running and job active, but reports a 32m catch-up dispatch contrary to skip-missed
  policy; no scheduler edit or additional execution attempted. Next: exclusive
  fresh compiled wide/compact browser workflow/reload gate, not repeated unchanged
  suites. Native provisioning and private live auth remain owner-only blockers.
  Close checks: scoped `git diff --check` plus Python receipt/ledger whitespace and
  local-link existence validation: exit 0. No QA processes remain from this run;
  synchronous test process exited and no services/displays were started.
- 2026-10-03 21:43 continuation: ledger, primary session release and wave receipt
  agree ownership is released; delegation/process tools return no live handles,
  filtered process census finds no Flutter/Dart/Xvfb/fixture/Playwright command.
  Single-owner verification lease RELEASED after observed gate: write only this ledger and
  `docs/quality/2026-10-03-desktop-cron-2143-browser.md`; generated build output
  under `build/web`, browser artifacts/logs and bounded runner under wing scratch.
  Read-only production/test/server/config sources. Acceptance: fresh compiled E2E
  target, eight existing wide/compact production Chat/restoration journeys with
  retries disabled, parsed counts/readback, unchanged source digest, and cleanup.
  Build deadline 180s; browser deadline 240s; whole runner deadline 480s. One
  synchronous owner launches and cleans its exclusive loopback fixture in finally;
  no subagents, installs, native retries, inference, cards or upstream mutation.
  If the deadline/failure occurs, record it once rather than same-tick retry.
  Observed build exit 0 and browser exit 0: eight tests passed, zero failed/skipped/
  flaky, one attempt each. Parent parsed eight attached fixture receipts: each
  Chat width has 5 submits/3 approvals/1 Stop/0 unexpected mutations; all six
  restoration cases have 0 mutations and exact canonical/saved-owner assertions.
  Source manifests unchanged (499 files); HEAD remained ca149a82189c8c9e5abd98b376bfeae1e43f6f3f.
  Scratch logs/artifacts: wing cache `scratch/desktop-cron-2143-browser/`;
  source/artifact hashes and exact commands are in the new receipt. Fixture PID
  1457397 terminated/reaped (-15), both ports refuse connections, no QA remains.
  Existing flutter_tts Wasm/Cupertino warnings persisted; Node v26.7.0 differs
  from intended Node 22. No native/provider/card acceptance or upstream edits.
  Next: exclusive explicit session-model picker compiled-browser/readback gate;
  separate scenarios still do not prove the complete integrated native milestone.
  Close checks: scoped git diff --check and Python whitespace/local-link validation
  exit 0; status delta contains only this new receipt, no removed dirty entries.
  No failure retry, scheduler mutation, persistent QA resource or pending child.
- 2026-10-03 22:00 continuation: current checkpoint and primary session release
  agree prior wave scopes are released; native delegation/terminal tools list no
  live handles and process census finds no Flutter/Dart/fixture/Playwright/Xvfb.
  Single-owner bounded picker verification lease RELEASED after observed gate: write only this
  ledger and `docs/quality/2026-10-03-desktop-cron-2200-picker.md`, generated
  `build/web` output and wing scratch logs/runner/browser artifacts. Production,
  tests, fixture and upstream references remain read-only. Run three nearest
  picker widget/owner-isolation targets, then fresh compiled Chromium picker
  search/filter/rejection/explicit retry/readback/reopen/Escape at both widths.
  Acceptance: parsed test/results and both fixture receipts, unchanged sources,
  cleanup of exclusive loopback fixture, and released lease. Command bounds:
  widget 120s, build 180s, browser 120s; whole foreground runner 480s. No children,
  full suites, native retries, installs, inference, cards or scheduler mutations.
  Observed widget/build/browser exits 0: parsed 26 widget tests and two Chromium
  tests passed, zero failed/skipped/flaky/retries. Both fixture receipts confirm
  three deliberate exact raw-pair lock attempts, session runtime readback and
  unchanged counts after Escape. Source manifests remain identical (499 files).
  Receipt: `docs/quality/2026-10-03-desktop-cron-2200-picker.md`; logs/artifacts:
  wing scratch `desktop-cron-2200-picker/`. Fixture PID 1473650 terminated/reaped
  (-15); both ports refuse connections. No pending child or persistent QA resource.
  Next: bounded read-only integrated fixture/source composition assessment for
  explicit profile/model plus Chat/approval/Stop/exact-session reload in one
  scenario, before proposing a precise regression write scope. Existing isolated
  passing scenarios do not prove integrated native/live milestone completion.
  Evidence-helper parsing errors were repaired without gate retries. Native and
  private-auth prerequisites were not retried or bypassed.
- 2026-10-03 22:16 continuation: prior release confirmed by ledger and primary
  conversation; delegation/terminal tools return no live handles; filtered process
  census has no competing Flutter/Dart/fixture/Playwright/Xvfb task. Single-owner
  source-composition assessment lease RELEASED after source/document gate: write only this ledger and
  `docs/quality/2026-10-03-desktop-cron-2216-composition.md`; scratch evidence under
  wing cache `desktop-cron-2216-composition/`. All implementation/tests/fixtures,
  ROADMAP and upstreams read-only. No Flutter/build/runtime/inference/install or
  subagent dispatch. Acceptance: source-backed integrated regression proposal with
  precise fixture identity/count gaps, exact next write scope and verification
  commands, unchanged inspected source hashes, scoped document checks, release.
  Dependency topology: one owner; assessment precedes any regression mutation.
  Observed source finding: scenario seeds reset shared state; lifecycle rejects
  model writes, so isolated passing suites cannot compose into integrated proof.
  Existing daily wrapper already supplies off-page exact metadata/read receipts.
  Receipt: `docs/quality/2026-10-03-desktop-cron-2216-composition.md`, with indexed
  source references and ranked proposal. Next bounded producer scope: lifecycle
  fixture plus new Node behavioral test and new compiled browser daily-workflow
  regression; claim those exact files before edits, preserve legacy behavior,
  observe failing combined-scenario test then passing fixture/browser receipts.
  Source/document verification command exit 0: 7 before/after source hashes match,
  11 local links exist, whitespace and scoped git diff --check pass; Git status
  adds only the owned receipt and removes no prior dirty entries. Evidence:
  wing scratch `desktop-cron-2216-composition/checks.json` and source manifests.
  No Flutter or QA process started, no test gate repeated, no scheduler change,
  personal auth inspection or upstream mutation. Native/live gates remain open.
- 2026-10-03 22:31 continuation: release confirmed from ledger and primary release
  message; delegation/process tools list no live handles; process census shows no
  competing Flutter/Dart/browser/fixture/display command. Single-owner dependency
  topology, fixture prerequisite only. Lease RELEASED after observed focused gate: this ledger,
  `playwright/support/hermes_lifecycle_fixture.mjs`, new
  `playwright/support/hermes_desktop_daily_fixture_test.mjs`, and
  `docs/quality/2026-10-03-desktop-cron-2231-fixture.md`. No shared server,
  production, ROADMAP, native harness or upstream edits. Acceptance: observed
  red-before-green combined model/lifecycle HTTP regression, strict owner/pair
  and mutation rejection, legacy scenario preserved, wrapper restoration reads,
  bounded child cleanup. Node test timeout 60s; logs under wing scratch
  `desktop-cron-2231-fixture/`. Browser journey is next ordered scope, not included
  in this occurrence; no Flutter/build/install/inference/subagent dispatch.
  Observed intended red exit 1 (403 versus expected 409), then green exit 0;
  final Node HTTP/SSE fixture regressions: exit 0, 3 passed/0 failed/skipped.
  Both JS syntax checks exit 0. Combined fixture receipts: 2 submits/1 correlated
  approval/1 authoritative Stop/2 model attempts; exact metadata/history reads
  add no mutations. Wrong owners/pairs/domain writes and receipt bound rejected;
  legacy reset preserved. Receipt: `docs/quality/2026-10-03-desktop-cron-2231-fixture.md`.
  Logs: wing scratch `desktop-cron-2231-fixture/`, including red/green/final logs,
  `final-results.json` and `source-final.json`. Final wrapper PIDs 1512136/1512153/
  1512200 exited 143 and public ports closed. Source self-review only; independent
  review and compiled browser UI remain open. Next: exact new browser regression
  scope in receipt, exclusive fresh build and wide/compact continuous journey.
  No native/live acceptance, production/shared server edit or missed-tick retry.
- 2026-10-03 22:42 continuation: admission census observed another worktree
  `flutter test --concurrency=1` (PID 1517074, compiler 1517119, tester 1521572).
  Native delegation/process tools list no handles in this occurrence; those empty
  lists do not establish system-wide exclusivity. Browser implementation/build
  deferred at admission; no same-tick qualification retry. A subsequent bounded
  PID attribution check found the process already absent (exit 1); its owner and
  test outcome were not observed, and no completion claim is made.
  Single-owner read-only prerequisite/documentation lease RELEASED: only this
  ledger and `docs/quality/2026-10-03-desktop-cron-2242-admission.md`, plus wing
  scratch evidence. No production/tests/fixture/ROADMAP/upstream mutations,
  Flutter commands, service launch, install, inference or subagents. Acceptance:
  source-indexed browser assertion/selector prerequisites, unchanged inspected
  source hashes during the document gate, local links/whitespace checks and release.
  Observed documentation gate exit 0: five inspected source hashes unchanged,
  seven receipt links resolve, whitespace and scoped git diff --check pass.
  Evidence: wing scratch `desktop-cron-2242-admission/checks.json` and source
  manifests. No owned QA resources or pending workers remain; no runtime result
  attributed to the competing test process. First admission block after the
  successful fixture occurrence, not a three-occurrence repeated failure.
  Next implementation scope remains the exact new browser spec from the 22:31
  receipt; a future occurrence must freshly establish exclusive ownership.
- 2026-10-03 22:55 continuation: primary release confirmed by ledger and primary
  session release message; live delegation/terminal lists empty and OS census
  shows no competing Flutter/Dart/browser/fixture/display command. Single-owner
  ordered browser regression lease RELEASED after failed gate: only this ledger, new
  `playwright/tests/regression/desktop-daily-workflow.spec.mjs`, and new
  `docs/quality/2026-10-03-desktop-cron-2255-integrated.md`; generated `build/web`
  and wing scratch `desktop-cron-2255-integrated/` evidence/runner/artifacts.
  Production, existing tests/fixtures/server, ROADMAP and upstreams read-only.
  Acceptance: fresh compiled E2E artifact; continuous 390/1280px daily journey,
  exact saved owner/runtime/history and zero restoration mutations; nearest legacy
  Chat/picker/restoration tests with retries disabled; parsed receipts and cleanup.
  Bounds: build 180s, browser 240s, fixture startup 15s, outer runner 480s.
  No children, installs, native retries, inference, auth access or scheduler edits.
  This adds regression coverage for existing behavior, not a production behavior
  change or a fabricated red/green cycle. Record any failed gate once; no same-tick
  qualification retry. Review owner is this direct owner; independent review open.
  Lease status: RELEASED after the observed failed browser gate and cleanup.
  Node fixture regressions exit 0 (3 passed); syntax and fresh web build exit 0.
  Integrated Chromium exit 1: 0 passed/2 failed/0 skipped/flaky, one attempt each.
  Both widths reached exact off-page owner and model confirmation but expected
  first-lock receipt was absent. Source tracing: shared fixture capability omits
  model-lock profile scoping; the exact-endpoint-gated caller omits the query while
  the combined fixture requires it before recording attempts. No production bug
  or exact browser HTTP status is claimed. Planned legacy browser cases did not run.
  No same-tick retry, assertion weakening or fixture/server repair attempted.
  Receipt: `docs/quality/2026-10-03-desktop-cron-2255-integrated.md`; logs/artifacts
  in wing scratch `desktop-cron-2255-integrated/`, including parsed JSON results.
  All 501 scoped execution-source hashes unchanged. Fixture PID 1539422 reaped
  (143); public ports closed (111/111); final census shows no owned QA command.
  Next: scoped test-first correction of daily fixture's exact model-lock capability
  declaration in `serve_web.mjs` plus Node discovery assertion, preserving existing
  dirty server edits and legacy behavior; then fresh integrated/legacy browser gate.
  First occurrence of this mismatch; native/live qualification still open.
- Supplemental verification requested explicitly after the failed browser report:
  fresh OS census shows no competing Flutter/Dart/browser/fixture task. Single-owner
  verification-only lease RELEASED after requested gate: this ledger, existing 22:55 receipt and
  wing scratch logs; no implementation edits. Requested `npm run test` exited 0
  (05:04:33–05:09:15 UTC); parsed summary: 2,397 passed, 0 skipped, no error markers.
  Foreground timeout bound 540s; synchronous command exited, no QA command remains.
  Logs: wing scratch `desktop-cron-2255-integrated/npm-test.log`, command result
  `npm-test-result.json` and parsed `npm-test-parsed.json`. Browser-spec Node syntax
  and scratch runner Python syntax checks passed. This Dart suite does not execute
  Playwright or repair the fixture capability mismatch; browser gate still failed.
  Next checkpoint remains the scoped fixture advertisement/discovery correction.
- Primary autogoal v0.2 task lease RELEASED: fixed only the daily scenario's
  `session_model_lock` profile-scope advertisement in `serve_web.mjs` and add
  discovery assertions in `playwright/support/hermes_desktop_daily_fixture_test.mjs`.
  Parent owns this ledger and new `docs/quality/2026-10-03-autogoal-model-scope.md`.
  Existing browser spec is read-only. Verification: Node RED/GREEN, fresh web
  build, integrated 390/1280px plus nearest legacy browser tests with zero retries.
  Preserve prior server edits; no production Dart/upstream/dependency changes.
  Cron must not claim these files or Flutter/build ownership while this lease
  is active. No competing QA processes or live native subagents observed at admission.
  Observed Node RED exit 1 (missing profile_scoped; 2 pass/1 fail), GREEN exit 0
  (3 passed). Fresh compiled web build exit 0; integrated browser exit 1
  (0 pass/2 fail, 390/1280px), now beyond model lock at canonical stopped-outcome
  semantic assertion `desktop-daily-workflow.spec.mjs:155`. No second-task fix.
  Nearest legacy browser gate exit 0: 10 passed/0 failed/skipped/flaky. Initial
  legacy fixed-port admission failed errno 98 before launch; ephemeral owned
  ports then used. Integrated/legacy servers reaped and public ports closed.
  Receipt: `docs/quality/2026-10-03-autogoal-model-scope.md`; logs wing scratch
  `autogoal-model-scope/`. Next dependency-ready slice: reproduce and attribute
  the canonical stopped-outcome after Reconnect failure before any production
  change. Model discovery correction is verified; complete workflow remains open.
- 2026-10-03 23:33 continuation: admission observes primary `npm run test` /
  `flutter test --concurrency=1` (PID 1579580, cwd this worktree); latest primary
  session contains its direct dispatch. No Flutter/build/browser command permitted
  in this occurrence. Process/delegation tools expose no occurrence-owned handles.
  Single-owner read-only failure-attribution lease RELEASED: write only this ledger
  and new `docs/quality/2026-10-03-desktop-cron-2333-stop-attribution.md`; scratch
  evidence under wing cache `desktop-cron-2333-stop-attribution/`. Implementation,
  tests, fixture, ROADMAP, upstreams and prior artifacts remain read-only.
  Acceptance: source/artifact attribution of failed stopped-outcome assertion,
  ranked bounded next regression with exit criteria, unchanged inspected source
  hashes, scoped document/link checks and released lease. No QA launch, inference,
  install, subagents, same-tick runtime retry or scheduler changes.
  Observed prior wide error context shows replacement Synthetic untouched session
  and Hermes model after Reconnect, not merely a missing semantic group. Source
  trace: Chat calls ordinary channel.connect; page-zero default selection and
  inventory-filtered detached recovery omit the explicit off-page owner. Exact
  post-failure saved-pointer/run-read receipts are absent; persistence overwrite
  remains a source prediction. No production repair or minimized RED run here.
  Receipt: `docs/quality/2026-10-03-desktop-cron-2333-stop-attribution.md`.
  Python artifact/document gate exit 0: two prior failures parsed, ten source hashes
  unchanged, fourteen links resolve, whitespace/scoped diff check pass. Evidence:
  wing scratch `desktop-cron-2333-stop-attribution/checks.json`. No QA resources
  started or left pending. Next: exclusively leased real Chat Reconnect/off-page
  owner regression, observed RED then smallest owner-aware recovery fix, followed
  by fresh integrated/legacy browser gate. Primary test result is not claimed;
  native/live prerequisites remain open and were not retried.
- 2026-10-03 23:49 continuation: prior primary suite completion is recorded in
  its current conversation (2,397 passed); OS census and occurrence process/
  delegation lists show no competing Flutter/build/browser task. Single-owner
  minimized RED-only lease RELEASED after setup failure: this ledger, new
  `test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart`, and
  `docs/quality/2026-10-03-desktop-cron-2349-reconnect-red.md`; scratch evidence
  under wing cache `desktop-cron-2349-reconnect-red/`. All production, existing
  tests, fixtures, ROADMAP and upstreams read-only. Ordered prerequisite to fix:
  real Chat Reconnect with production channel/directory, exact off-page A and
  non-default coder profile. Reuse existing deterministic HTTP restoration
  harness; provoke an unsupported-transport error without any submit to isolate
  Reconnect identity from Stop behavior. Acceptance: formatter, focused test
  observed intended identity failure (not compile/setup error), unchanged
  consumed sources and document checks. Test deadline 120s, no browser/native
  build, installation, inference, subagents, full suite or same-tick gate retry.
  Production fix/model/uncertain-Stop/adversarial/browser qualification remain
  next ordered scope, not claimed by this bounded RED-only occurrence.
  Observed focused test exit 1 (0 pass/1 fail) in setup: selection object lacks
  value equality; exact-field oracle repaired, not rerun. Intended Reconnect RED
  not observed. Formatter exit 0; analyzer exit 1, one unused import removed,
  final analyzer not rerun. No production edit or assertion weakening. Receipt:
  `docs/quality/2026-10-03-desktop-cron-2349-reconnect-red.md`; scratch command/
  failure logs under the named directory. First setup failure, not a third
  repeated blocker. Next: fresh exclusive run of corrected regression, then
  owner-aware connection fix only after genuine post-click RED. Source/document
  close gate records hashes, links, diff and QA census; no services were started.
- Explicit supplemental verification request after this report: fresh OS census
  shows no competing Flutter/build/browser command. Verification lease RELEASED:
  this ledger, existing 23:49 receipt, new reconnect test setup repairs only and
  wing scratch logs. Run requested `npm run test` once, deadline 540s; inspect
  exact failures. No production scope expansion, browser/native build or installs.
  This explicit request permits the supplemental gate, not silent same-tick retry.
  Observed npm exit 1: 2,397 passed/1 failed in new regression setup. Unsupported
  send throws without channel error; expected-throw and pagination-read trigger
  repairs still fail before Chat mounts. Intended owner-loss RED not observed.
  Final format/analyzer both exit 0; suite remains failed. Supplemental receipt
  logs every attempt. No production edits or assertion weakening. Next checkpoint:
  trace harness pagination admission/error publication before further setup repair,
  not repeat full suite or claim runtime recovery. No services started/retained.
- Follow-up verification request: fresh census shows no competing QA command.
  Bounded single-owner lease RELEASED after verified repair: this ledger, 23:49 receipt, existing new
  reconnect regression and scratch logs. Root-cause inspection found the reused
  harness nests pagination fields while HermesSessionPage reads top-level fields;
  loadMoreSessions is correctly ineligible, so no injected request occurs. Correct
  only this new test's response interceptor to advertise actual top-level paging,
  assert admission, then observe the real Reconnect RED. Existing harness read-only.
  If genuine RED occurs, separately record connection-file lease before any fix.
  Verification: focused test, formatter/analyzer, requested npm suite; no browser/
  native/inference/install or subagents. Foreground commands bounded to 540s.
  Genuine RED observed after paging and same-origin synthetic credential setup:
  `credential-owner-red.log` exit 1, post-click active newer-B/default and saved
  newer-B/coder, zero mutations. Exact A metadata/history were not read. Production
  lease now additionally owns only
  `lib/features/hermes_chat/screens/state/hermes_chat_connection.dart`, preserving
  its prior dirty session-panel guard. Fix saved-directory reconnect through its
  existing exact preferred-session activation seam; keep direct credential path
  for connections without a directory owner. Regression assertions unchanged.
  Acceptance: focused RED/GREEN, auth/restoration targets, analyzer, requested
  full npm suite, source/diff checks and released ownership. Browser gate remains
  next ordered validation, not included in this verification repair scope.
  Final repair: existing directory exact-owner activation now handles Reconnect
  when a contact/session exists; direct credential fallback remains unchanged.
  Genuine RED exit 1 preceded production edit. After fixing provider teardown
  double disposal in the new test, GREEN exit 0: 53 focused tests. Final format
  exit 0 (two files/zero changes), analyzer exit 0 (no issues), requested npm suite
  exit 0 (2,398 passed/0 error markers/skips), 06:06:38–06:11:27 UTC. Logs named
  `fix-focused.log`, `fix-focused-static-results.json`, `npm-test-fixed.log`,
  `npm-test-fixed-result.json`, `fixed-verification.json` in the same scratch root.
  GREEN exact active/saved older-A/coder, canonical history and scoped metadata
  reads, zero mutations. Four consumed read-only sources unchanged; prior dirty
  production guard preserved. Receipt's final repair section supersedes earlier
  setup failures. No upstream/native/browser/provider/card acceptance or QA service.
  Next: exclusive fresh compiled integrated/legacy browser gate (both widths),
  not repeat the unchanged full Dart suite. Independent/native/live gates open.
- 2026-10-04 00:26 continuation: scheduler readback lists this job running and
  hourly autogoal completed; goal/previous-session ownership is released. Native
  delegation/terminal lists are empty; OS census finds no competing Flutter/Dart/
  fixture/Playwright/Xvfb task. Single-owner verification-only lease RELEASED:
  this ledger and new `docs/quality/2026-10-04-desktop-cron-0026-browser.md`, generated
  `build/web` and wing scratch `desktop-cron-0026-browser/` runner/log/artifacts.
  All production/tests/fixture/server/ROADMAP/upstreams remain read-only. Acceptance:
  fresh compiled E2E target, continuous 390/1280px journey and ten nearest legacy
  browser cases with zero retries, parsed receipts, unchanged execution sources,
  exact cleanup receipt and released lease. Bounds: build 180s, integrated 240s,
  legacy 180s, whole runner 540s; durable notified terminal with persisted handle
  and runner-owned process/port cleanup. No subagents, full suite, installation,
  native retry, inference, auth access, cards or scheduler mutation. One attempt
  per gate; failure is recorded without a same-tick qualification retry.
  Durable runner dispatched as `proc_24ec75011900`, PID 1745920, persist_on_release
  confirmed. This cron host does not support async completion notifications;
  fallback is one bounded `process_manage wait` (550s), not polling. Runner has
  a 540s deadline and owns cleanup; cancellation uses that exact terminal handle.
  Wait returned runner exit 1; host clamped wait to 180s but completion arrived in
  that call. Fixture regressions exit 0 (3 passed); fresh web build exit 0. Both
  integrated widths now pass canonical Stop/Reconnect recovery and saved-pointer
  equality on route return, then fail model-display assertion at spec:168 (0 pass/
  2 fail). Composer says Hermes model while exact-session metadata/status reports
  alpha/model-99. No reload/final resumed send reached, no complete replay claim.
  Nearest legacy browser gate exit 0 (10 passed); all 12 cases one attempt/no skips/
  flaky. 499 bounded source hashes unchanged. No production/test/fixture edit.
  Receipt: `docs/quality/2026-10-04-desktop-cron-0026-browser.md`; scratch runner,
  results/parsed-results, artifact hash/error contexts and close census retained.
  Integrated PID 1747172 reaped (143), legacy PID 1748422 reaped (-15), four public
  ports closed (111); final census empty. Next: exact-session model-display RED
  and smallest presentation fix, separately trace runtime-pair read authority
  before promising reopened picker restoration. First new model-return failure,
  not third repeated Stop blocker. Native/live/independent acceptance still open.
- 2026-10-04 00:46 continuation: scheduler lists only this occurrence running;
  hourly autogoal completed. Prior scopes released; process/delegation lists empty,
  OS census has no competing Wing Flutter/build/browser owner. Single-owner ordered
  lease RELEASED after bounded widget/browser gates: this ledger, new
  `test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart`,
  conditional presentation-only `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart`
  after intended RED, and new `docs/quality/2026-10-04-desktop-cron-0046-model.md`.
  Scratch logs under wing cache `desktop-cron-0046-model/`. Preserve prior dirty
  layout edits; all other production/tests/ROADMAP/upstreams read-only. Acceptance:
  recovered exact-session metadata label on real channel/remounted Chat, no
  synthesized lock/mutation, wrong-session label fencing, focused RED/GREEN,
  format/analyzer/nearest tests. Browser gate is next ordered occurrence if time
  bound prevents it; no integrated/native/live completion claim from widget proof.
  Test command deadline 120s, analyzer 120s; no full suite/build/install/inference,
  subagents, cards or scheduler mutation. Stop on setup/gate failure without retry.
  Intended RED exit 1: both widths retain exact A/coder/metadata but chip lacks
  recovered model after remount. Five-line display-only fallback then GREEN exit 0:
  29 focused tests, format zero changes, analyzer no issues. No lock synthesized.
  Verification lease additionally owns generated `build/web` and scratch durable
  runner/artifacts for one fresh integrated browser gate, no legacy/full-suite
  replay. Build bound 180s, browser 150s, outer 360s; runner reaps its fixture and
  verifies ports closed. Persisted terminal handle and bounded wait required.
  Browser runner `proc_e3047e6f3ffb`, PID 1823570, persist_on_release confirmed;
  host lacks async notify, using one bounded process wait (180s), not polling.
  Runner self-deadline 360s; cancellation uses the exact handle.
  Observed runner exit 1: build exit 0, integrated 0 passed/2 failed/one attempt
  each at initial picker selector spec:115. Actual initial metadata/composer model
  is hermes-agent; test still waits for Hermes model. Original route-return/reload/
  reopened-picker/resume assertions were not reached in this gate. No selector
  edit or same-tick retry. Receipt: `docs/quality/2026-10-04-desktop-cron-0046-model.md`.
  Fixture PID 1824948 reaped (143), ports 40129/50373 closed (111), census empty.
  Two consumed test source hashes unchanged; owned layout diff adds only five
  lines, prior dirty edits preserved. Lease RELEASED. Next exact bounded scope:
  initial model oracle/selector in existing integrated browser spec, retain all
  behavioral/count assertions, then fresh compiled integrated gate. Independently
  trace runtime-pair read authority before picker restoration. Native/live/full
  suite/independent acceptance remain open; no scheduler change/pause threshold.
- Explicit supplemental request: run `npm run test` once. Fresh QA census empty;
  scheduler now shows hourly autogoal running, but it has no declared overlapping
  lease or active Flutter command in the goal ledger. Exclusive verification lease
  ACTIVE: this ledger, existing 00:46 receipt, scratch npm logs/runner; implementation
  read-only. Durable terminal with 540s test deadline and persisted handle; no
  browser rebuild/retry, mutation, install or new inference. Record exact npm result
  and release before another Flutter owner is admitted.
  Runner handle `proc_96094e7d58a7`, PID 1837870, persistence confirmed; async notify
  unavailable. Bounded process wait, respecting host's 180s per-call clamp; total
  runner deadline 540s, cancellation exact handle. No process-status polling.
  Initial runner failed before test dispatch: tool TMPDIR resolved outside the wing
  scratch root, absent log directory. No npm test ran. Corrected to explicit wing
  scratch path; actual runner `proc_91e26d965917`, PID 1838839, same bounds/persistence.
  This is runner setup repair, not a repeated test gate.
  Actual npm run exit 0, 06:54:04–06:59:30 UTC, 2,400 tests passed. No code repair.
  Logs `npm-test.log`/`npm-test-result.json` in wing scratch `desktop-cron-0046-model/`;
  receipt supplemental section updated. Verification lease RELEASED, no pending
  runner or service. Separate failed Playwright selector remains next checkpoint.
- Repeated explicit verification request: fresh QA census empty, no new ledger
  owner. Direct-command verification lease ACTIVE: ledger/receipt only; run literal
  `npm run test` with foreground timeout 600s for host verification recognition.
  No implementation edits, build, browser retry or new scope. Prior durable wrapped
  run really passed; this direct invocation addresses the host's unverified flag.
  Literal `npm run test` returned exit 0: 2,400 passed; host verification evidence
  now `passed`, kind test, scope full, canonical command npm run test. Log:
  wing cache `terminal-output/out-1791097245-1789145-b820.log`. Lease RELEASED,
  no code repairs; separate browser initial-selector failure unchanged.
- 2026-10-04 01:17 continuation: current ledger and latest receipt release all
  prior scopes. Scheduler lists this occurrence running and hourly autogoal
  completed; delegation/terminal tools list no live handles; OS QA census empty.
  Single-owner bounded selector lease RELEASED after observed gate: this ledger,
  `playwright/tests/regression/desktop-daily-workflow.spec.mjs` initial metadata
  model assertion/opening selector ONLY, new
  `docs/quality/2026-10-04-desktop-cron-0117-selector.md`, generated `build/web`
  and wing scratch `desktop-cron-0117-selector/` runner/log/artifacts. All other
  sources, ROADMAP and upstreams read-only. Dependency: prior display fix precedes
  initial oracle correction, then compiled integrated gate. Acceptance: exact
  initial fixture metadata model `hermes-agent`, all rejection/confirmation/
  restoration/reload/picker/resume/count oracles preserved, one fresh 390/1280px
  compiled gate with zero retries, parsed first failure or full receipts, source
  checks and cleanup. Syntax 30s, build 180s, browser 150s, outer runner 360s;
  durable terminal with persisted handle and cleanup ownership; bounded wait if
  host notifications unavailable. No full suite/native retry/inference/install,
  auth scanning, subagents, cards or scheduler mutation. Review owner: direct
  owner source/diff review; independent review remains open.
  Runner `proc_f92ab3e2963e`, PID 1875142, persist_on_release confirmed; async
  notification unsupported by this cron host. One bounded process wait observes
  completion (host clamp 180s; outer runner deadline 360s); cancellation uses the
  exact handle. Runner owns fixture process/port cleanup in finally.
  Observed syntax/build exits 0; compiled integrated browser exit 1, 0 pass/2 fail,
  no skips/flaky/retries. Both widths pass initial metadata assertion, model
  rejection/confirmation, approval/Stop/Reconnect and route-return/reload exact
  owner/history/model display plus unchanged mutation arrays, then first fail at
  reopened picker spec:192. Dialog selects beta/shared despite session model
  alpha/model-99. Final Escape/resume/count oracles not reached; no final attached
  stage receipt exists. No production change or synthetic lock restoration.
  Receipt: `docs/quality/2026-10-04-desktop-cron-0117-selector.md`; scratch named
  above holds commands/results/error contexts and scoped source comparison.
  Parent gate exit 0: 239 source files compared, only opening selector/oracle
  changed; all later assertions preserved. Fixture PID 1876602 reaped (143), ports
  46069/41007 closed (111/111), fresh QA census empty. Lease RELEASED; next scope
  is bounded read-only exact runtime-pair read authority tracing before a precise
  regression/production lease. Native/live/independent acceptance remains open.
  First reopened-picker failure; no same-tick retry or pause threshold reached.
- Explicit supplemental verification request: fresh OS QA census empty; scheduler
  shows this occurrence running and hourly autogoal completed; no new ledger owner.
  Verification-only lease RELEASED: ledger, existing 01:17 receipt and scratch logs;
  implementation read-only. Run literal `npm run test` once with 600s foreground
  timeout for requested host verification. No browser retry/build or scope expansion.
  This explicit request permits the supplemental full gate, not an unchanged
  scheduled retry. Record observed exit/counts and release ownership afterward.
  Literal npm run test exit 0: 2,400 passed, host verification evidence passed /
  test / full. Log: wing cache terminal-output/out-1791098656-1872147-fe10.log.
  No code repairs or browser retry. Receipt supplemental section updated; lease
  RELEASED. Separate reopened-picker and native/live gates remain open.
- Repeated explicit verification request for stale host evidence: fresh QA census
  empty; literal npm run test requested again, deadline 600s. Verification-only
  synchronous lease: no source changes; ledger updated before dispatch, no writes
  after this command so host freshness remains intact. This lease releases when
  the foreground command terminates; observed result/log will be reported in the
  final response, not inferred here. No build/browser retry or scope expansion.
- 2026-10-04 01:47 continuation: prior occurrence's final session reports literal
  npm gate passed and synchronous lease released on command exit. Scheduler lists
  only this occurrence running; hourly autogoal completed. Process/delegation lists
  empty, OS census finds no competing QA command. Single-owner read-only authority
  assessment lease RELEASED after source/document gate: this ledger, new
  `docs/quality/2026-10-04-desktop-cron-0147-runtime-pair.md`, and wing scratch
  `desktop-cron-0147-runtime-pair/` evidence. All production/tests/fixtures/ROADMAP
  and upstreams read-only. Acceptance: indexed exact session runtime read authority,
  Wing caller/decoder/picker and nearest test trace, bounded regression proposal
  or unsupported-contract blocker; unchanged source hashes and document checks.
  No Flutter/build/browser/full-suite/inference/install/auth access/subagents or
  scheduler mutation. Dependency topology: one owner, source prerequisite before
  any separately leased RED/production change. No repeated browser retry.
  Source trace resolves the read boundary: Agent 158fd638da exposes authenticated
  exact session GET but its allowlisted projection omits provider/runtime/lock;
  confirmed model POST persists server-side lock without advertising pair readback.
  Synthetic metadata spreads a runtime field that unmodified reference GET does
  not expose. Desktop restores from a local desktop-owned override table; borrowing
  that mechanism would violate Wing's no-shadow-state boundary. No decoder or
  production repair authorized. AST source check exit 0, not handler/test execution.
  Receipt: `docs/quality/2026-10-04-desktop-cron-0147-runtime-pair.md`; scratch
  `authority-source-check.json`, source manifest and document gate evidence.
  Next bounded slice: separately leased metadata-only model authority widget
  regression, zero synthesized confirmation/lock/send; retain integrated failure
  oracle. Exact restored pair requires a supported advertised read or separately
  reviewed native contract. No full/browser suite, live/native acceptance or
  upstream changes. Lease RELEASED after source/document checks; no QA resources
  or pending delegates started.
- 2026-10-04 02:04 continuation: scheduler lists only this occurrence running;
  hourly autogoal completed without a product handoff. Goal leases released,
  native process/delegation lists empty and OS QA census empty. Single-owner
  metadata-only authority regression lease RELEASED after focused/close gates: this ledger, new
  `test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart`, and
  new `docs/quality/2026-10-04-desktop-cron-0204-authority.md`; wing scratch
  `desktop-cron-0204-authority/` logs/manifests. All production, existing tests,
  browser oracles, ROADMAP and upstreams read-only. Acceptance: real production
  channel restores exact A/coder with model-only metadata, duplicate model IDs
  across providers do not create a confirmed pair, open/draft/cancel/reopen at
  390/1280px emits zero mutations; format/analyzer/focused test results recorded.
  This pins existing behavior, not an intentionally false RED or production fix.
  Bounds: focused tests 120s, analyzer 120s, no full suite/build/browser/native
  retry/install/inference/auth access/subagents or scheduler mutations. Direct
  owner review; independent review remains open. Exact-pair read/native/live
  acceptance remain blocked independently; release this lease after close checks.
  Observed focused test exit 0: 18 passed/0 failed/errors/skipped, including both
  new authority cases. Formatter exit 0 (one file formatted); analyzer exit 0,
  no issues. Real Chat remount/open/draft/cancel/reopen preserves older-A/coder,
  metadata shared-model, no confirmed lock and zero recorded mutations despite
  identical model IDs across providers. No production/browser/upstream changes.
  Parent manifest gate exit 0: 460 pre-existing execution sources unchanged.
  Preparation helper KeyError occurred before writes/test dispatch; direct write
  resolved it, no failed qualification gate retry. Receipt:
  `docs/quality/2026-10-04-desktop-cron-0204-authority.md`; scratch has exact
  commands/exits/JSON counts/source manifest. Lease RELEASED on closing document/
  link/diff/census gate; synchronous commands exited, no QA service/child started.
  Next: source-backed review of existing native design's model-read authority/
  security criteria, not an unchanged browser retry or synthetic pair restoration.
  Supported exact-pair read, full browser final stages, native/live/independent
  acceptance remain open. No installs, auth access, cards or scheduler mutation.
- Explicit supplemental verification request after 02:04 report: fresh QA census
  empty; scheduler shows only this occurrence running and hourly autogoal completed.
  Single-owner verification-only lease: ledger and scratch npm log, implementation
  read-only. Run literal `npm run test` once, foreground deadline 600s. This lease
  releases on synchronous command exit. No build/browser retry or new code scope;
  observed exit/count/log reported in final response, no post-test source writes.
- 2026-10-04 02:25 continuation: previous session final reports the requested
  2,402-test npm gate passed and ownership released. Scheduler shows only this
  occurrence running, hourly autogoal completed; native delegation/terminal lists
  empty and filtered OS QA census empty. Single-owner read-only native-design
  review lease RELEASED after closing gate: only this ledger and new
  `docs/quality/2026-10-04-desktop-cron-0225-native-model-review.md`; wing scratch
  `desktop-cron-0225-native-model-review/` evidence. Native design, implementation,
  tests, browser oracles, ROADMAP and references remain read-only. Acceptance:
  source-indexed model-read authority/security gaps in the existing proposal,
  ranked bounded continuation with exact exit criteria, unchanged consumed sources,
  local-link/whitespace/scoped diff checks and ownership release. No Flutter/build/
  browser/native retry/full suite, auth access, installs, inference, subagents,
  cards or scheduler mutations. One direct research owner; no parallel writers.
  No new native contract approved by this review.
  Observed source review: proposed native lazy resume is a child/watch path and
  cold lazy response falls back to profile model without stored pair restoration;
  warm reattach can expose pending display identity. Cold/eager resume may schedule
  Agent-owned crash continuation, so zero client submits alone cannot prove zero
  new server turns. No transport or config change authorized. Four-branch Python
  AST check exit 0, static evidence only; no upstream handler/test execution.
  Receipt: `docs/quality/2026-10-04-desktop-cron-0225-native-model-review.md`;
  source pins/branch check/close evidence in wing scratch named above. Next bounded
  scope: separately leased native-design clarification of restoration authority,
  resume/model semantics and crash-marker/server-turn test gates; production,
  browser oracle and ROADMAP stay read-only. Exact pair/native/live acceptance
  remain open. Lease RELEASED on closing source/document gate; no QA resources
  or children started, no repeated test gate or scheduler mutation.
- 2026-10-04 02:40 continuation: preceding lease/session release confirmed;
  scheduler lists only this occurrence running, hourly autogoal completed. Native
  process/delegation lists and filtered OS QA census empty. Single-owner design-only
  lease RELEASED after observed close gate: this ledger, restoration authority row/direct API caveat/native
  resume/model bullets and phased gates in
  `docs/plans/2026-10-03-desktop-local-integration-design.md`, plus new
  `docs/quality/2026-10-04-desktop-cron-0240-design.md`; wing scratch evidence.
  Acceptance: incorporate prior reviewed authority/resume/server-turn constraints,
  preserve topology and all implementation/browser/ROADMAP/upstream sources,
  validate scoped document diff/links/source pins, then release. No code, Flutter,
  runtime/auth/inference/install, subagents or scheduler changes. One direct owner;
  no implementation authorization or new transport decision. Next gates remain
  separately reviewed exact-pair authority and isolated native qualification.
  Observed document/source gate exit 0: nine source hashes unchanged, 68 local
  links resolve, reference statuses unchanged and scoped whitespace/diff clean.
  Exact design comparison changes six existing scoped lines plus one authority
  caveat; topology/auth and browser oracle preserved. Receipt:
  `docs/quality/2026-10-04-desktop-cron-0240-design.md`; scratch
  `desktop-cron-0240-design/close.json` and `design.diff`. Lease RELEASED after
  close gate. No QA resources/children or commands needing cleanup were started.
  Next: independent read-only review of clarified pair/resume admission criteria;
  no production adapter or live call authorized by this document update.
- 2026-10-04 02:56 continuation: fresh board readback observes independent review
  task `t_3da6fa16`, run 14, running with PID 2018191 in this worktree. Its exact
  contract owns only a new autogoal quality receipt and profile-local verifier
  artifacts; goal ledger/proposal/production/tests/upstreams are read-only there.
  Do not duplicate the already-dispatched independent review or run Flutter.
  Single-owner admission-record lease ACTIVE: this ledger and new
  `docs/quality/2026-10-04-desktop-cron-0256-ownership.md`, plus wing scratch
  admission evidence only. Acceptance: record actual board/scheduler/process
  observations, unchanged proposal/reference statuses, scoped document checks and
  release. No design review, code/test/build/runtime/auth/install/inference,
  subagents, card changes or scheduler mutation. Review completion is not claimed;
  next dependency is the existing independent worker's returned acceptance package.
  Admission-record lease RELEASED after closing document gate: proposal hash and
  all three reference statuses unchanged, three receipt links resolve, whitespace
  and scoped git diff --check pass (exit 0). Evidence: wing scratch
  `desktop-cron-0256-ownership/admission.json` and `close.json`. No QA resources
  or children started. Known disjoint ownership requires deferral, not an
  ambiguous-ownership pause; review outcome remains unobserved.
- 2026-10-04 03:09 continuation: live reconciliation observes `t_3da6fa16`
  run 14 done/completed; returned review package exists. Scheduler lists only this
  occurrence running, hourly picker completed; process/delegation lists and filtered
  OS QA census empty. Single-owner parent-validation lease RELEASED: this ledger,
  new `docs/quality/2026-10-04-desktop-cron-0309-review-validation.md` and wing scratch
  `desktop-cron-0309-review-validation/` only. Review package/proposal/production/
  tests/oracles/ROADMAP/upstreams stay read-only. Acceptance: inspect verifier,
  independently recheck pins and positive/five negative controls in scratch, parse
  exact matrix coverage, source/reference immutability and scoped document checks.
  Commands bounded to 60s; no Flutter/build/QA service, installs, inference, auth
  access, subagents, cards or scheduler changes. No production/native contract
  authorized; review verdict alone cannot close runtime gates. Lease RELEASED
  after observed parent gate: 28 pins independently matched; positive/closing
  verifier exit 0 (25 gates/98 references/20 unexecuted native cases); five private
  scratch controls exit 1 for expected reasons. Package unchanged, verdict
  SOURCE_CONSISTENT_RUNTIME_WITHHELD, runtime_accepted false. Matrix statuses:
  11 source-consistent/4 blocked/10 not-checked. Receipt:
  `docs/quality/2026-10-04-desktop-cron-0309-review-validation.md`; scratch
  `desktop-cron-0309-review-validation/validation.json` and `close.json`.
  No production/oracle/design/upstream edits or QA resources. Next: separately
  scoped supported pair-read/native auth/target prerequisite review; do not retry
  unchanged browser/native/full-suite gates. Independent source review is cleared,
  not exact-pair restoration, security/native/live or milestone acceptance.
- 2026-10-04 03:22 continuation: scheduler lists only this occurrence running,
  hourly autogoal completed; board has no running Wing lane, native delegation/
  terminal lists empty and OS QA census empty. Single-owner prerequisite lease
  RELEASED: this ledger, new `docs/quality/2026-10-04-desktop-cron-0322-auth-preflight.md`
  and wing scratch `desktop-cron-0322-auth-preflight/` only. All implementation,
  tests, proposal, ROADMAP, browser oracles and upstreams stay read-only.
  Acceptance: fresh presence-only approved live-input and native metadata probes,
  indexed launcher/admission criteria, exact missing-input blocker, scoped document
  checks and release. No manifest/credential contents or personal runtime accessed;
  no Flutter/build/service/inference/install/subagent dispatch. Commands bounded
  to 30s. Missing required provisioning pauses actual listed job per policy;
  no automatic resume or unchanged workflow gate retry.
  Observed presence-only preflight: all four required live launcher inputs absent;
  GTK metadata exit 0, libsecret and three GStreamer metadata checks each exit 1.
  No private manifest/credential contents inspected, no launcher/build retried.
  `hermes -p wing cron pause 6f218a559ed2` exit 0; exact job read back paused
  while this occurrence remains running. This is missing-provisioning policy,
  not an invented three-failure count. Hourly autogoal unchanged. Receipt:
  `docs/quality/2026-10-04-desktop-cron-0322-auth-preflight.md`; evidence under
  wing scratch `desktop-cron-0322-auth-preflight/`. Lease RELEASED after scoped
  document/source check; no QA resources or children started. Next checkpoint:
  owner-approved isolated target/private auth and supported exact-pair/native
  recovery authority, separately authorized native prerequisites, then explicit
  resume and fresh exact lease. No automatic resume or milestone acceptance.
