# Desktop daily-workflow wave — 2026-10-03

## Status

HOLD for native execution. Concrete harness/design/docs delivered; the new native
journey has not run. Independent review found two medium blockers: launcher-only
TERM does not promptly forward cancellation to owned processes, and the remembered
session remains on page one instead of exercising required off-page recovery.
Revision `deleg_d185eeb0` returned with delivered fixes and bounded executable
cancellation/fixture probes; parent inspected source/logs and reran shell/Node
syntax checks successfully. Independent re-review `deleg_04bb2580` returned clean
for both original P2 findings, with independent cancellation/page/ownership probes
and no remaining actionable P2 findings in scope. Native execution is still not
claimed. Package installation was not approved (question cancelled).
No actual Agent/provider generation, runtime/card or full parity acceptance.

## Delivered artifacts

- `integration_test/linux_desktop_daily_workflow_test.dart`
- `scripts/run_linux_desktop_daily_workflow_e2e.sh`
- `docs/plans/2026-10-03-desktop-local-integration-design.md`
- `docs/plans/2026-10-03-desktop-daily-workflow.md`
- Updated `ROADMAP.md`, `docs/adr/client.md`,
  `docs/product/hermes-desktop-parity.md`.

The harness is intended to exercise production channel/Chat UI against the
existing deterministic Node fixture in two isolated native processes, persisting
exact identity and canonical history while checking 2 submissions, 1 correlated
approval, 1 Stop and no replay. These are implemented assertions, not observed
native results. Model selection is separate because the lifecycle fixture forbids
model writes; this is not one proven integrated model/generation journey.

Native design proposes an in-process bounded host coordinator, not another HTTP
service. This is a source-backed proposal, not approved shipping architecture or
an implementation. It identifies a native dashboard credential-in-URL conflict
that cannot be solved by assuming different auth contracts are interchangeable.

## Evidence observed by parent

Worker logs preserved at:
`/home/xel/.hermes/profiles/wing/cache/scratch/desktop-daily-workflow-harness/`:
`format.log`, `analyze.log`, `restoration-tests.log`, `launcher.log`, `npm-test.log`.

Parent parsed the captured full suite summary:
`05:37 +2397: All tests passed!` — 2,397 passed, no reported failure counter.
Builder reports direct `npm run test` exit 0, scoped analyzer/format/syntax and two
existing restoration tests passing. The parent inspected full-suite output rather
than treating the summary as native proof. Repeated full suite runs were redundant;
no further duplicate suite is needed solely to resolve missing native dependencies.

Fresh parent read-only checks:
- `bash -n scripts/run_linux_desktop_daily_workflow_e2e.sh`: exit 0.
- `git diff --check -- ROADMAP.md docs/adr/client.md docs/product/hermes-desktop-parity.md`:
  exit 0.
- `pkg-config --exists libsecret-1`: exit 1.
- `pkg-config --exists gstreamer-1.0`: exit 1.
- `pkg-config --exists gstreamer-app-1.0`: exit 1.
- `pkg-config --exists gstreamer-audio-1.0`: exit 1.

Launcher worker run exited 2 before app execution for those missing development
packages. No installation attempted. Package provisioning is the next system
change requiring explicit owner approval, followed by exclusive owned-Xvfb native
execution and readback of each phase's actual result.

## Ownership and continuation

Producer wave `deleg_4968bbf7`, revision `deleg_d185eeb0` and both independent
review waves returned and released their file scopes. Parent integrated receipts
and released ownership to bounded continuation under the goal ledger. Re-review
`deleg_04bb2580` closed both original findings at source/probe level. Cron
`6f218a559ed2` may claim dependency-ready work, but native execution remains blocked
and must not be retried until prerequisites change.
Cron `6f218a559ed2` stays scheduled every 10m with local output. It must avoid
active file/build ownership and must not bypass provisioning/auth blockers.
No commits, package/runtime changes or upstream edits were performed by this wave.

## Continuation resume

Readback showed cron had self-paused after three ticks blocked by unreleased
primary ownership (see its local 20:46 output). After review integration, the
primary owner explicitly released the scopes and revised the current checkpoint
to allow only dependency-ready bounded work that does not require installation.
Job `6f218a559ed2` was resumed and read back as enabled/scheduled. Native package/
auth blockers remain in force; no successful post-resume occurrence is claimed.

