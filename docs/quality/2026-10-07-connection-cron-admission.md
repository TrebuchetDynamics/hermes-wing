# CONNECTION-PATHS cron admission gate — 2026-10-07

## Outcome

**Admission remains refused; the recurring job must remain paused.** This is a
Wing-side evidence receipt, not a dispatcher repair, independent review of a
repair, canary, or authorization to resume the job. The inspected installed
main-only CLI refused before manifest access or worker launch (exit 2). Do not
substitute a dummy ownership guard, cooperative fixture lock, launch-only lock,
branch/worktree, or alternate scheduler to turn that refusal into admission.

The current task evidence records six main-only helper tests passing, including
the native-refusal case. Those tests establish the refusal behavior only; they do
not establish safe admission. The native dispatcher resolves workspaces before
spawning, its public claim hooks are non-veto observers, review claims do not use
those hooks, and board locks do not span worker release. No inspected supported
toolset-only hook covers the required repository fence. Therefore this pass does
not claim overlap rejection, stale/crashed-owner recovery, failure cleanup,
full-lifecycle custody, or successful installed native admission.

## Required admission contract

Before one port writer can be admitted, a supported toolset-only integration
must fence a single canonical-main writer across all of the following, not just
launch:

1. Workspace setup and task startup.
2. Editing and review, including review claims that bypass public claim hooks.
3. Checked local commit and worker release.

Its regression evidence must prove overlapping launch rejection, recovery from a
stale/crashed owner, and failure cleanup. The installed native path must then be
exercised; a cooperative lock fixture is insufficient. Preserve existing Wing
candidate edits and one-writer ownership. Hermes Agent, installed Agent runtimes,
and reference copies remain read-only. No push, service mutation, scheduler
replacement, branch/worktree substitution, or launch-only bypass is in scope.

The recorded source-level gaps explain why the current observer and board-lock
seams cannot prove that contract. Without an existing supported hook that can
span the full lifecycle, the correct disposition is to retain the native refusal
and paused cron and report the missing contract—not to patch around it. The
separate hermes-toolset repair, if supported, must be performed under that
repository's own instructions and independently reviewed before Wing admission
proof is reconsidered.

## Evidence boundary

This receipt preserves the task's supplied current evidence; the installed CLI,
hermes-toolset, scheduler, and worker lifecycle were not re-exercised by this
Wing documentation-only task. No dispatcher source patch, canary, scheduler
resumption, or Agent modification occurred. Consequently, no newly reproduced
admission pass is claimed here. The prior exact exit code, helper-test result,
and dispatcher-hook observations are attributed to the current task evidence,
not presented as fresh commands run for this receipt.

The accepted [restart plan](../plans/2026-10-03-desktop-port-goal.md#cron-restart-interview)
requires a manually triggered occurrence only after safe admission, a reviewed
implementation commit on canonical main, relevant passing checks, and observed
worker release. A job status of `ok`, documentation-only commit, or fixture lock
test is insufficient. Keep the job paused until all those conditions and the
installed full-lifecycle proof are actually observed. After any future
resumption, a hard execution refusal must pause the job and notify the owner.
See the [main-only execution policy](../product/autogoal-workflows.md#main-only-execution-policy).

## Remaining work

- Missing prerequisite: a supported toolset-only veto/custody hook covering
  setup through worker release. The current inspected hooks do not provide it.
- Pending, not qualified: independently reviewed toolset repair; overlap,
  stale/crashed-owner recovery and failure-cleanup regression checks; installed
  native-path admission; reviewed checked local commit and worker release; and
  the separately gated single-occurrence canary.
- No live qualification or cron resumption was attempted by this Wing-only
  documentation pass.
