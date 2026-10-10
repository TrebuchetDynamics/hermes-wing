# Autogoal: usable workflows delivered to main

## Main-only execution policy

The owner's latest instruction supersedes the earlier branch/PR workflow:
work only on `main` in the canonical checkout. Do not create development branches,
branch-based worktrees or pull requests. Keep one writer and use parallel agents
only for read-only investigation or review. Use immutable filesystem snapshots
for qualification; preserve existing detached QA work rather than deleting it.

Commit coherent usable outcomes with their tests and necessary docs. Shipping
requires relevant passing checks and a normal fast-forward push to `main`, never
force-push or a remote-protection bypass. Retain a verified private archive before
deleting legacy refs; unmerged archived work is not delivered functionality.

## Faster development plan

### Accepted delivery cadence

The owner selected **small usable improvements, delivered individually** during
this planning interview. This accepts the delivery cadence, not implementation,
commit, push, installation or release actions for this session. Keep the existing
CONNECTION-PATHS focus, main-only policy, task IDs and safety gates.

### Proposed next execution cycle

Use the existing tasks. Do not create another backlog or automation layer.

1. Reconcile the current CONNECTION-LINK-REMOVAL owner and source once. Inspect
   its partial work before implementing anything again. An in-progress ledger
   entry alone does not prove a live worker.
2. Repair the smallest retirement integration gap, including obsolete test
   expectations where the accepted retirement decision changed the contract.
   Preserve authorization, recovery and ownership assertions. The canonical
   workspace log at `.task-evidence/apk-92beb1dc/workspace-tests.log` identifies
   four failures: README assets, Wing Link documentation and two distribution
   cases. These observations do not establish their causes. Run the failing
   targets first and distinguish real product defects from stale expectations.
3. Integrate one usable direct-Agent improvement. The Agent-only Profiles work
   is a reuse candidate, not a proven standalone delivery. Keep its source and
   fixture corrections together. Do not restore Wing Link fallback to obtain a
   passing test. Exclude unrelated accumulated changes.
4. Freeze the candidate. Run the required delivery gates once on that source.
   If a check fails, repair its cause and rerun affected checks. Reuse passing
   evidence only under the source and environment rules below. Never waive a
   failed gate or test a moving tree.
5. Hand off the verified improvement for the separately authorized main delivery.
   Offer an APK for a user-visible Android change. Do not rebuild an unchanged
   APK merely to refresh status. Then take the next focused slice rather than
   collecting unrelated work into a large batch.

This sequence is proposed engineering guidance. It does not claim that the
Profiles candidate is dependency-ready or supersede a live task owner. The next
open focused entry is CONNECTION-OFFICIAL-DESKTOP-PORT. Reconcile partial
CONNECTION-LINK-REMOVAL and CONNECTION-SAVED-WORKFLOWS work before dispatching it.

### Work and verification limits

- Keep one implementation writer in canonical main. Read-only helpers can trace
  the official reference, diagnose failing tests and identify integration risks
  in parallel. The parent owns edits, integration and the final result.
- During edits, use focused regressions and analysis. Avoid concurrent duplicate
  full suites. MT-RERUN-TRAIN and MT-VERIFY-BROWSER-GATES retain broader integration
  acceptance and existing ownership.
- Trace only the affected official Desktop/Agent seam. Avoid repeated whole-repo
  audits and documentation-only receipts when a usable task already exists.
- Treat live authentication, live SSH and physical Android proof as separate
  qualification limits. Continue authorized fixture work without rediscovering
  or re-asking the owner's recorded deferral decisions.
- Record elapsed implementation, focused-check and final-gate time in existing
  task evidence. Measure usable outcomes delivered, not cards closed or tests
  counted. Compare actual runs before claiming a speed improvement.

Acceptance for this process is observable: one bounded user-visible outcome,
source-bound passing checks, a scoped delivery handoff and explicit remaining
platform/live gaps. No throughput improvement has been measured yet.

## User-demand sequencing

The owner selected **reliable away-and-return chat, job status, then notifications**
after the current connection slice. See the
[product acceptance](prd.md#user-demand-emphasis). Finish or reconcile the existing
connection card before dispatching a successor. Do not expand or replace its scope.
The next delivered improvements should make absence/recovery and Agent-owned job
outcomes understandable, before unrelated parity breadth or cosmetic work.

Reuse M1 recovery and M2 qualification task owners. Preserve completed fixture
proofs, live-auth deferrals and separate physical-device requirements. The first
successor should repair a demonstrated gap in foreground-return reconciliation or
status through a public control, with no mutation replay, rather than repeat a
completed synthetic restart receipt. Notifications follow reliable status; the
existing notification contract remains proposed and requires its own supported
Agent/platform and privacy decisions. Do not create a shadow job store or keep
Agent work alive by pretending the phone remains connected.

Current ledger focus remains CONNECTION-PATHS during the connection slice. This
accepted follow-on order does not start another worker, change a live lease, or
approve notification infrastructure. Reconcile existing M1/M2 work before choosing
or registering the smallest missing implementation slice.

## Primary milestone

Current owner-requested order: **P0 Desktop welcome and connection fidelity**, then
**P1 the integrated daily-use journey**. `TODO.md` owns the P0–P4 task grouping.
`goals.json` now focuses CONNECTION-PATHS so the welcome repair can be selected
before unrelated work. Restore M1 focus after that entry/connection outcome is
qualified and delivered. Existing leases and completed evidence are unchanged.
This sequencing correction supersedes the earlier M1-first selection rule below.

M1 remains the substantive daily-use milestone:

connect → select profile/model → generate → approve → Stop → relaunch → restore → send again.

The daily-use milestone follows the [leading acceptance outcome](prd.md#leading-acceptance-outcome)
and [daily workflow plan](../plans/2026-10-03-desktop-daily-workflow.md).
`goals.json` records the primary focus. Maintain it through `goals.py focus`,
not by editing JSON or making the picker reinterpret competing priorities.

Pick the next task that removes a demonstrated gap in the current ledger focus.
During P0, choose reference-guided welcome and connection work before unrelated
Android qualification or shell polish. During P1, keep successive daily-use slices
linked to M1. Select unrelated work only after documenting why focused slices cannot
safely proceed: exact live ownership, missing authority or an unavailable required
environment. Respect existing leases. Do not restart a healthy worker to change order.

Current open M1 slices include `PARITY-LIVE-WORKFLOW`, its ordered recovery
successor `VERIFY-LIVE-WORKFLOW-RECOVERY`.
`PARITY-NATIVE-NO-INFERENCE-SMOKE`, `PARITY-NATIVE-AUTH-RESTART` and
`PARITY-NATIVE-BOOTSTRAP-RESTART` are completed synthetic qualification slices,
not open live work. The [bootstrap restart receipt](../quality/native-no-inference-bootstrap-recovery.md)
adds denial before usable inventory/history and deliberate exact-owner recovery.
The earlier
[restart receipt](../quality/native-no-inference-auth-recovery.md) proves owner
retention and explicit Retry through synthetic 401/403, without real credentials.
The [budget assessment](../quality/live-provider-call-ceiling.md) finds no supported
physical-attempt ceiling in the inspected Agent interfaces. The independent native
slice qualifies credential-free GTK shell restoration with all mutation transports
unsupported; it cannot enable inference or complete the live milestone.
The live slice qualifies the integrated
generation/approval/Stop journey and repairs reproduced Wing defects. The successor
checks read-only reconnect and route return using that same isolated target and
canonical history, without additional inference.
The completed [resumed-send slice](../quality/native-resumed-send.md) proves
deliberate model reselection and one synthetic send to the restored exact session.
It does not prove automatic restoration
of the acknowledged provider/model pair. That authoritative restart read remains
unsupported, as recorded in the [combined receipt](../quality/native-model-relaunch-workflow.md#contract-limit).
Retain that gap rather than invent shadow state or modify Hermes Agent.
The completed [integrated native fixture](../quality/native-integrated-daily-restart.md)
now combines approval, uncertain Stop, canonical recovery and exact-session restart
through the production router and HTTP/SSE channel. Its synthetic Linux GTK pass
does not enable the live driver or complete M1. Reuse its frozen-source evidence
within those limits rather than queueing another identical standalone restart check.

## Vertical-slice contract

Each worker contract includes the existing native handoff fields and these facts:

- **Milestone and demonstrated gap:** task/goal IDs, observed failing step, exact
  source and smallest independently usable outcome.
- **User outcome:** starting state, explicit actions, resulting visible behavior.
  Labels, receipts and documentation are subtasks, not headline product slices.
- **Scope and ownership:** named production/test files, exclusions, owner and
  immutable source snapshot from canonical `main`. List inherited diffs separately.
- **Recovery:** cancellation, retry, stale-owner rejection, restart and no replay
  where relevant. Repair the smallest exposed Wing defect within scope.
- **Acceptance and QA:** discriminating checks, exact platform/backend, expected
  request effects, and source/dependency/environment identity. Retain failures.
- **Delivery handoff:** coherent changed-file set, candidate revision, review and
  required-check evidence, intended main commit and remote ancestry verification.
- **Remaining:** which M1 steps and platform/backend combinations still lack
  qualification or delivery. A finished slice must state this even when its checks pass.

Keep the native 50-turn budget and three attempts. Do not enlarge a card into an
unbounded milestone. If a slice exceeds the budget, retain useful verified work and
register its concrete successor in the same milestone through `goals.py add-task`.
Never weaken acceptance to obtain a pass.

## Three separate outcomes

- **Implemented:** behavior exists in the identified source revision.
- **Qualified:** the named journey passed on the named platform and backend at
  that revision, with matching runtime evidence and recovery checks.
- **Delivered:** the verified change is committed and pushed to `main` without
  bypassing required checks or remote protection. Read back remote `main` and
  verify the commit's ancestry before reporting this.

A fixture pass is not live-provider success. A Chromium pass is not Android or
native Linux qualification. Native review handoff can finish the worker card,
but does not complete M1 or prove main delivery. Existing goal statuses are backlog
coverage, not substitutes for these three claims. A formatter, ledger validator,
receipt checker or unrelated passing test cannot prove a product journey.

## Verification ownership and reuse

Workers run focused regressions and relevant analysis while iterating. One named
integration owner assembles a small coherent candidate and freezes its source
before running the broader [required checks](../../CONTRIBUTING.md#required-checks).
Coordinate heavy builds/tests with that owner. Use bounded parallelism and preserve
required gates rather than spending on concurrent duplicate full suites.

Evidence reuse requires the same relevant source closure, test/harness code,
lockfiles, generated inputs, toolchain, configuration, platform and backend.
Record each check's exact command, input fingerprints, terminal result and retained
log. If these inputs change, rerun affected checks on the frozen candidate.
A documentation-only receipt change does not invalidate unrelated runtime gates
unless that document is a test, generator or build input. Missing provenance means
not reusable. Different platforms or fixture/live backends require separate evidence.

## Main-only delivery

The local [merge-train configuration](../../.hermes/merge-train.json) disables
branch-based automatic delivery (`enabled: false`, `branches: false`). Its retained
`delivery: protected-pr` value describes the disabled legacy helper, not permission
to open a PR or an invented direct-main helper mode. External workers must respect
the main-only instructions before making changes; no Agent runtime or scheduler
is modified by this policy.

One integration owner writes in the canonical checkout on `main`. Other agents
investigate or review read-only. A qualification snapshot is immutable and is not
permission to edit another worker's files. Keep related code, tests and necessary
docs together; do not sweep unowned dirty files into a delivery commit.

Run focused regressions during iteration, then the relevant required gates on a
frozen candidate. When shipping is explicitly requested, commit scoped changes
and push `main` normally. If permissions or protection prevent that push, report
the exact blocker; do not create another branch, bypass checks, rewrite history
or silently change repository protection. No release or deployment is authorized
by this development policy.

## Product progress

Report the user outcome, exact qualified platform/backend, delivery state and
remaining milestone gap. Track recurring failure signatures and measured verification
cost: executed check duration, retries, review time and reported usage when available.
Do not infer cost savings or model usage from a shorter prompt. Card counts and
receipt counts are not product progress.

Example format, not a claim of current execution:

“Session restoration passes native Linux fixture restart testing. Live generation,
approval and Stop remain unqualified. The change is merged into main.”

This policy does not change schedules, activate workers, spend on inference or
modify Hermes Agent. It governs future selection, contracts and delivery handoffs.
