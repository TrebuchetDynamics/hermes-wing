# Shell and fresh-draft prerequisite frontier — evidence-limited stop

**Goal:** Continue only the accepted PARITY CLONE-02/04 prerequisite frontier.
**Spec:** [LINUXQA-006-0ca2ba5b](../../tasks/items/LINUXQA-006-0ca2ba5b.md),
[accepted frontier](../plans/2026-10-21-desktop-literal-clone.md#frontera-inmediata-decidida-por-el-planificador),
[delegated continuation](plan-clone03-local-round7.md#delegated-continuation--2026-10-28).
**Disposition:** No supported building slice; no successor planning task. This is
manual planning closure, not completed implementation or verified acceptance.

## Checklist and docs map

- [x] Read the planning record, PARITY goal, Sources and continuation dependency.
- [x] Read both finished Tool Call Display reports in place and current consumers/tests.
- [x] Check availability of the required reference without fetching or substituting a pin.
- [x] Compare retained reference findings with live Wing behavior; distinguish missing proof.
- [x] Choose zero building tasks rather than duplicate work or invent a shell contract.
- [x] Save the stop question and open remaining-proof task; close the current plan manually.
- [x] Review saved contracts, local links, native task validation and scoped diff.

Existing owners are the round-7 reconciliation, accepted clone plan, route support
and PARITY goal. This document owns only this planning pass's new source-availability
finding and stopping disposition. No product, tests, assets, dependencies or ADRs
change. No new capability wording or support claim is introduced.

## Sources and finished work

Wing baseline: `e5e98512` (the existing planning-continuation integration).
Required official Desktop pin: `14e1e43a23761b369641208e204365cd6cb9399d`.
There is no Plan round note on the current record: apply the default **1 of 10**
for this bounded frontier only, not a reset of the stopped round-7 Settings chain.

The sole dependency, [PARITYCONTINUATION-001-f26b9bbd](../../tasks/items/PARITYCONTINUATION-001-f26b9bbd.md),
is already manually closed for the delegated continuation choice. Preserve that
choice and closure; no new product interview or qualification follows from it.

Read in place under the Git common directory's
`autowork-execution/slot-data/CLONE03TOOLVIEW-001-ee4f6811/`:

- `attempt-1/report.json`: candidate `23cfbc0d3aa6ab3082cdcc5d249047b6cd6b850c`;
  not final acceptance. The retained [round-7 reconciliation](plan-clone03-local-round7.md#finished-batch-and-integration)
  explains the integration-found leak and repair.
- `attempt-2/report.json`: final candidate `289fe75fcab17b36678d54ed43571ffd5ce56538`;
  reports locked preparation, generated localization, analysis and 322 passing
  tests across 18 modules, including quoted-credential/path/non-finite regressions.
  These are attributed Linux-host widget results, not rerun or upgraded here.
- Neither report supplies shell/pane/titlebar source bytes. Prior source-binding
  check counts do not make unavailable objects readable today.

No slot-data directory or slot record for LINUXQA-006-0ca2ba5b was found in the
named common execution directory. No saved ledger patch for this ID was supplied
or replayed. Do not apply unrelated dropped-ledger proposals. No worker/candidate
for this ID was found awaiting integration in that bounded inspection.

## Reference availability and live consumer comparison

The worktree has no `hermes-agent/` checkout. The canonical repository's existing
read-only `hermes-agent/` is at `158fd638da1629c8e62caf9ade1515d162def8ab`, **not**
the required pin. The historical `$HOME/.hermes/hermes-agent` location cited by
round 7 is absent. A second existing local Agent reference also failed the
required-pin object probe; it was not used as a product substitute.

At the canonical reference, these offline probes were executed with
`GIT_NO_LAZY_FETCH=1` and `git -c gc.auto=0`:

- `cat-file -t 14e1e43a23761b369641208e204365cd6cb9399d`: exit 128,
  `fatal: git cat-file: could not get object info`.
- `ls-tree -r --name-only 14e1e43a23761b369641208e204365cd6cb9399d apps/desktop`:
  exit 128, `fatal: not a tree object`.
- `show <pin>:apps/desktop/src/app/routes.ts`,
  `show <pin>:apps/desktop/src/app/chat/intro-visibility.ts` and
  `show <pin>:apps/desktop/src/store/titlebar-app-actions.ts`: exit 128 for
  each, reporting the path is not in that revision.

No fetch, checkout, repin, reference write or Agent execution was attempted.
These failures establish unavailable evidence in the inspected references, not
that the files or behavior do not exist at the accepted pin.

| Retained exact-pin observation (not freshly revalidated) | Current Wing evidence inspected | Disposition |
| --- | --- | --- |
| Round 7's complete store reads describe interface mode shadowing saved preferences, per-zone tab defaults and a Settings/Layout/HUD action cluster. Its bounded consumer grep was incomplete because a promised blob was unavailable. | `lib/shared/widgets/app_shell.dart:53-79` chooses compact below 600 logical pixels and delegates desktop destination activation to the existing overlay helper. `app_shell_presentation.dart:24-36` owns Workflow/Utilities, not that pane-zone cluster. `shell_preferences_provider.dart:5-132` owns sidebar expansion and session density. | Shell composition remains a prerequisite, but retained summaries do not define its complete event/ownership/focus contract. A Settings-only or tab-hiding switch would repeat the rejected incomplete approach. |
| Round 7 records Intro Splash requiring an empty primary fresh draft with neither active nor selected session. | `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart:1521-1554` returns no-session guidance when `activeSessionId == null`, or suggestions for an existing empty session. | Neither branch establishes that fresh-draft lifecycle. Do not relabel guidance or schedule a fake Intro Splash toggle. |
| The accepted frontier requires cancel/close to preserve context, focus and draft. | `lib/router/widgets/chat_workspace_overlay.dart:29-82` already pushes eligible overlays from Chat and restores guarded navigator focus. `test/router/chat_workspace_overlay_test.dart:288-444` asserts retained Chat/controller/session/scroll, focus and zero incidental channel mutations. `test/shared/widgets/app_shell_desktop_structure_test.dart:24-193` pins adaptive widths, draft retention and existing sidebar composition. | Keep these guards; their existence is not a new deliverable or proof of final shell parity. No regression was reproduced in this pass. |

These tests were read, not executed. The existing assertions remain authoritative
for current Wing behavior; none is proposed for removal or rebasing without the
missing reference comparison. There is no newly invented red/green oracle.

## Planner decision and remaining proof

**Planner's call:** save **zero** building tasks. A full CLONE-02 task would be
underspecified without the exact-pin routes, pane-zone/titlebar consumers and
nearest tests. A fresh-draft task would also need creation/cancellation/ownership
semantics absent from the retained summary. Repeating delivered Settings, density,
backdrop, timeline or Tool Call Display would be duplicate work. Substituting the
available older reference or fetching it would violate this task's explicit scope.

The concrete next prerequisite is readable accepted-pin shell composition and
nearest-test evidence, followed by a comparison at the current Wing consumers.
That is not an owner-supplied design, coordinator receipt or new product decision.
No request to fetch, repin, alter Agent, provide credentials or manufacture an
input is implied. Resume evidence can come from a reachable existing read-only
copy under the same constraints; broader source-recovery actions remain outside
this task's authorization.

[PARITY](../../tasks/goals/PARITY.md) remains **partial**. Complete shell/fresh-draft,
Settings, indexed archive and full tool inputs/history/renderer outcomes, matched
exact-pin visuals and separate compiled-browser, native Linux/Android/macOS/Windows,
real assistive-technology and live Agent/provider/authentication proof remain
unfinished as recorded in [round 7](plan-clone03-local-round7.md#planner-decision-and-remaining-proof).
Preserve all prior manual and owner-deferred live/Files closures and saved state.
An empty queue, manual plan closure or source inspection is neither proof nor waiver.

With no new building task, the supplied stopping rule is recorded by
[Q-LINUXQA-006-0ca2ba5b](../../BLOCKERS.md#q-linuxqa-006-0ca2ba5b--planning-stopped)
and open PARITY Needs decision record
[LINUXQA-007-51ccc2d0](../../tasks/items/LINUXQA-007-51ccc2d0.md), **no successor plan**. The prior delegated CLONE-02/04 priority is still settled; this
records an evidence-limited stop, not another automatic planning loop or blanket
skill hold. No file-overlap dependency or shared-resource bypass is introduced.

## Validation and handoff

- Native CLI release `b42a75df`: prepare_api 4; `tasks prepare --check .` reports
  READY and no in-flight task entries, with an existing task-reading runner and
  live coordinator lease. Existing unrelated goal-without-work/legacy-consumer
  diagnostics are not `tasks validate` errors and are outside this named frontier.
- A fresh read-only scout inspected retained reports/source limitations and found
  no recoverable complete shell contract in those artifacts. This was a bounded
  evidence inspection, not an exhaustive archive search or implementation review.
- Fresh-context read-only saved-record/source review: **nothing important left**.
  It checked the stopping rule, preserved prior decisions, current consumers and
  task links. No implementation approval or qualification is inferred.
- Supplied CLI `tasks validate --worktree .`: **pass**, 317 tasks, 36 goals, no
  drafts; pending task-file edits are the intended batch, not validation failures.
- Scoped local-link/source-anchor and current source/test-path check: **pass**;
  `git diff --check`: **pass**. Repeat these after the final prose update.
- Docs Sync `docs.py stale .` and `docs.py check .`: exit 0, **no manifest at
  docs/roles.json; nothing to check**. Dedicated scoped link/source readback, not
  manifest coverage, supplies the documentation check.
- One local planning commit and post-commit selection readback are reported in the
  final handoff. No Flutter/browser/native/live test is claimed by planning.

This batch returns to the same authorized runner. A local planning commit is not
canonical integration, dispatch, publication, runtime admission or PARITY proof.
