# Desktop continuation — integrated fixture prerequisite

Occurrence: 2026-10-03 22:31 local. Bounded single-owner fixture implementation,
not browser/native/live milestone acceptance.

## Result and scope

Implemented the fixture prerequisite proposed by the
[composition assessment](2026-10-03-desktop-cron-2216-composition.md).
One test-only lifecycle seed accepts exactly `scenario: desktop-daily`, enables
the existing synthetic catalog and first-lock rejection without another reset,
and allows only the default-profile `e2e-hermes-session` model write. Successful
readback is tied to the exact session, not its inventory position. All other
non-run domain mutations retain the rejection guard. No-body lifecycle seeding
still resets to the legacy scenario with model writes forbidden.

Owned implementation files:

- [Lifecycle fixture](../../playwright/support/hermes_lifecycle_fixture.mjs),
  lines 16–34: validate the scenario before reset; lines 60–88: fixed owner/raw-pair
  allowlist, bounded rejected/accepted attempt receipts and exact runtime write.
- [Executable Node regressions](../../playwright/support/hermes_desktop_daily_fixture_test.mjs):
  real loopback HTTP/SSE against the existing daily wrapper and shared server,
  not a mocked handler or fabricated response.

The [daily wrapper](../../scripts/support/desktop_daily_workflow_fixture.mjs)
and [shared server](../../serve_web.mjs) were reused without editing. Production
Flutter, upstream references, ROADMAP and native harness were not edited. Existing
dirty changes were preserved. No installation, inference, credential/runtime
inspection, card transition, commit, scheduler change or delegation occurred.

## Observed verification

Logs and command records:
`/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2231-fixture/`.

| Command | Observed result |
| --- | --- |
| `node --test playwright/support/hermes_desktop_daily_fixture_test.mjs` before fixture edits | Exit 1: intended first-lock assertion returned 403 rather than 409; one failed test. `red.log`. |
| Same command after the smallest implementation | Exit 0: one passed test. `green.log`. |
| Same command after adversarial/legacy coverage and stronger identity/history assertions | Exit 0: 3 passed, 0 failed/cancelled/skipped. `final-regression.log`. |
| `node --check playwright/support/hermes_lifecycle_fixture.mjs` | Exit 0. `final-syntax-fixture.log`. |
| `node --check playwright/support/hermes_desktop_daily_fixture_test.mjs` | Exit 0. `final-syntax-test.log`. |
| `git diff --check` | Exit 0 for tracked worktree. New owned Markdown/JS whitespace and local links separately checked at close. |

Node: v26.7.0 on this Linux host, not the intended Node 22. No Flutter analyzer,
widget suite, build, browser UI or native app execution was needed for this
fixture-only prerequisite and none ran. A transient missing test closure was
reported by the edit tool and repaired before execution; no assertion was removed
or weakened. The expected red/green executions are implementation evidence, not
retries of a failed qualification gate.

The combined HTTP test observes two model confirmations (409 then 200), accepted
exact-session runtime, target omitted from page one, one SSE approval with exact
`approval_run_1` correlation, completed canonical history, a second submit and
Stop with explicit `stopping` then test-controlled `cancelled`, and subsequent
metadata/history reads without added submits/approvals/Stop/model locks. Counts:
2 submits, 1 approval, 1 Stop, 2 lock attempts, 0 unexpected mutations. Canonical
message IDs and all mutation owner tuples are asserted. This tests fixture
composition and read-only reconciliation; it does not exercise Wing navigation,
page reload, Send admission or effective real-provider routing.

Adversarial coverage checks missing/wrong profile, wrong session, unconfigured or
mismatched provider/model, extra fields, malformed seed values, forbidden domain
writes, preservation after invalid seed, and the 128-attempt cap. Legacy reset
removes the accepted runtime and restores model/domain mutation rejection.

Final-run fixture wrapper PIDs 1512136, 1512153 and 1512200 each exited 143 after
SIGTERM; both public ports for each reject subsequent connections. Wrapper source
owns shutdown/reaping of its backend; the final filtered process census found no
remaining fixture/browser/Flutter/display processes. No persistent QA resource or
child lane remains.

`source-final.json` binds both changed files and reused sources. Changed fixture
SHA-256: `af5f4b70260ccb8d6adbda39d075c7d8bf8094a7786920f32d5f340aa0057c39`.
New test SHA-256: `eeb851fcbef1a16f4d1c0097d99024e6f74ff44d27dface7a6b8ba5f9a135fac`.
A dirty HEAD is not a snapshot. Close checks compare the six unedited sources
from the prior composition manifest rather than claiming the whole worktree is
unchanged.

## Review and next checkpoint

Single-owner source review checked fixed-route isolation, validation-before-reset,
exact session lookup, pre-mutation bounds, preserved legacy guards and cleanup.
Independent review is not observed in this cron occurrence; no process-local
subagent was spawned. Parent-inheritance/model routing and OMH handoff tooling
were not used because execution stayed with one direct owner and no coding
handoff occurred.

Next exact bounded scope: new
`playwright/tests/regression/desktop-daily-workflow.spec.mjs`, plus the goal ledger
and its own quality receipt. First claim ownership, then implement the continuous
390px/1280px real saved-contact/profile/session/picker/Chat/approval/Stop/leave/
reload/resume journey against the daily wrapper using one seed only. Require
3 submits, 2 approvals, 1 Stop, 2 lock attempts and no restoration mutations.
Fresh-build the E2E target before Chromium and rerun nearest changed-fixture
legacy Chat/picker/restoration browser checks with retries disabled. Do not modify
production or shared sources without a reproduced gap and amended lease.

This occurrence completes only the fixture prerequisite. Native execution,
reviewed native integration and approved `openai-codex` / `gpt-6.1-sol` inference
remain separate open gates; unchanged blocked native builds were not retried.

Run summary: not_available — host accounting was not exposed.
