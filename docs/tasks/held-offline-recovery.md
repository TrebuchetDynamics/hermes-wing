# Retained offline candidates: recovery order

This is an execution handoff for the six existing tasks in [TODO](../../TODO.md#now--next),
not a new product plan, acceptance waiver, worker dispatch or integration receipt.
Their accepted sources, scopes, ownership and mandatory checks remain authoritative.

## Evidence and frontier

### Latest inspected frontier

The tab attempt-2 report now names reviewed local commit `3b7871db5a9005c4fc43f01bf245f596f735b454`
(tree `e3deb307f61e59193e498c0df077f5ec3e23ced4`, parent
`cd54859949e74504c7ab5cd70c4e76c222e097eb`). Its retained worker report records a
terminal 1,995-case Chat/router pass, fresh deterministic build/browser checks and
independent review. The earlier uncommitted/ENOSPC row below is historical, not an
instruction to repeat already completed offline phases on unchanged inputs.
The slot was integrating at inspection; no terminal canonical integration receipt
was observed. Recheck that state and exact source before any adoption or claim.

Parser and SSH reports have moved to
`autowork-execution/slot-history/PLANGAP-001-2f/1/slot-data/attempt-1/report.json`
and `autowork-execution/slot-history/WING-001-b3/1/slot-data/attempt-1/report.json`.
Their set-aside candidates remain dirty and uncommitted. The earlier direct
`slot-data` links below identify historical locations; use these verified retained
paths for recovery. The train readiness report is retained under
`autowork-execution/slot-history/MT-RERUN-TRAIN/3/slot-data/attempt-1/report.json`.

Next input: the existing coordinator reconciles the reviewed tab commit with the
preserved parser/SSH deltas and qualifies the resulting combined source. Retained
worker passes are not whole-train, canonical, Android or live acceptance. Do not
repin receipts, reimplement those candidates, modify an integrating assignment or
add a task-completion dependency merely to consume reviewed offline source.


Resolve private paths below relative to `git rev-parse --git-common-dir`.
Reports describe their own candidates, not passing checks on today's combined source.

| Task | Retained evidence | Next input, not a new product decision |
| --- | --- | --- |
| DOC-PARITY-TAB-CONTRACT | `autowork-execution/slot-data/DOC-PARITY-TAB-CONTRACT/attempt-2/report.json`: reviewed commit `3b7871db5a9005c4fc43f01bf245f596f735b454`, terminal worker Chat/router and fresh build/browser checks reported passing | Existing coordinator verifies the integrating slot and exact commit/receipt inputs, then reconciles combined source. Earlier focused-only/ENOSPC phases are historical; no canonical or Android acceptance is implied. |
| PLANGAP-001-2f | `autowork-execution/slot-history/PLANGAP-001-2f/1/slot-data/attempt-1/report.json`: three uncommitted tooling files on `36f4155f87e4c6ddaa1123a1c9baba0989081663`; 13 focused tests reported passing, independent review without actionable findings | Reconcile retained parser delta and the already-owned layout/gateway test repairs before final analyzer/full gates. Do not change MCP plan disposition or rename IDs. |
| WING-001-b3 | `autowork-execution/slot-history/WING-001-b3/1/slot-data/attempt-1/report.json`: uncommitted feedback/SSH fixture candidate on `36f4155f87e4c6ddaa1123a1c9baba0989081663`; 169 focused passes and 9 opt-in skips reported; full run timed out with failures | Combine existing parser and Chat repairs before final full validation. Its three SSH provider fixtures already contain reported passing port/cleanup repairs; reuse rather than assign a duplicate owner. |
| MT-RERUN-TRAIN | `autowork-execution/slot-history/MT-RERUN-TRAIN/3/slot-data/attempt-1/report.json`: input `6fe161de1699b564a8e5a873f74c8a032bdb9759` has no runtime/test/dependency delta from failed input `fe0cc6b4029400683f4e96ae104ff46c7ccb1fb2`; format still failed on layout syntax | Existing integration owner assembles the retained source repairs and runs all canonical gates on that combined input. Another docs-only baseline does not repair it. |
| PARITY-NATIVE-LINUX | `autowork-execution/slot-data/PARITY-NATIVE-LINUX/attempt-1/report.json`: readiness-only invocation at `2ddbb51b69044c71411e32168750a9a92db4c731`, no qualification run | Consume source-bound green Chat repair, then reconcile prior native candidate and run every required mapped scenario. |
| VERIFY-CHAT-TRANSCRIPT-NATIVE | `autowork-execution/slot-data/VERIFY-CHAT-TRANSCRIPT-NATIVE/attempt-1/report.json`: readiness-only invocation at `2ddbb51b69044c71411e32168750a9a92db4c731`; eight dirty files retained in `.worktrees/autowork-VERIFY-CHAT-TRANSCRIPT-NATIVE-set-aside-1` | Consume source-bound green Chat repair, then reconcile that candidate; refresh native request/source/teardown receipts. Historical mounted cases are not restart proof. |

At the earlier handoff, the six slots were held and none of their recorded worker
process birth identities matched a live process. The tab slot has since advanced
to integrating as recorded above. This is not a permanent
ownership release: recheck slot, process birth and worktree state before adoption.
Do not edit another worker's checkout or copy its entire source/ledger snapshot.
Use the existing coordinator's integration path, preserving each task's delta and
all unrelated dirty files. This document grants no additional integration authority.

### Recovery sequence

- [ ] Verify and reconcile the reviewed tab commit through its existing
  integrating coordinator; reuse input-matched completed checks. Preserve all
  listener/owner, layout, large-text, disclosure, reading-position and native-serve
  exclusion assertions. Use disk scratch only for genuinely required new checks.
- [ ] Reconcile the parser candidate, then the SSH feedback candidate, through
  their existing owners. Compare duplicate layout/gateway formatter hunks; keep
  one compatible repair, not competing copies. Parser scope remains tooling only.
- [ ] Existing integration owner assembles these attributable deltas into one
  source input before final whole-repository validation. Record HEAD/tree plus
  any dirty overlay hashes; an integrated candidate is not task completion.
  Obtain the mandatory green Chat/router receipt and independent source review.
- [ ] Run final train and downstream native qualification on matching repaired
  inputs. Do not wait for Android/live acceptance or the entire tab task to be
  marked done just to consume its reviewed offline repair. Conversely, the earlier 198/74/11
  focused passes alone did not satisfy the mandatory green Chat-suite prerequisite;
  the later terminal worker pass qualifies its own matched source only.

This is a source-readiness sequence, not new task-completion dependencies. In
particular the accepted [parser plan](../plans/2026-10-18-plan-traceability-ids.md#scope)
requires no product/device predecessor. The owner's first Android priorities and
the deferred live tail remain unchanged. A coordinator must supply combined
source; workers must not invent green receipts, resolve other tasks or waive gates.

## Disk-backed scratch without shared cleanup

The tab report establishes repeated exhaustion of shared `/run/user/1000`, with
only about 19 MiB remaining task-owned there. Do not delete other tasks' files or
try to solve that by cleaning shared RAM. The inspected checkout filesystem was
ext4 with more than 2 GiB available; `build/` is Git-ignored. Recheck both facts in
the executing workspace. Planned setup from that workspace's root:

```sh
git check-ignore build/autowork-tmp/probe &&
mkdir -p build/autowork-tmp &&
export TMPDIR="$(mktemp -d "$PWD/build/autowork-tmp/recovery.XXXXXX")" &&
df -PT "$TMPDIR" &&
python3 -c 'import os, shutil; assert shutil.disk_usage(os.environ["TMPDIR"]).free >= 2 * 1024**3, "need at least 2 GiB free"'
```

Confirm the resolved mount is disk-backed, not tmpfs, before starting Flutter or
review tools. Propagate this same `TMPDIR` to child tools and keep all new temporary
files/copies beneath it; keep the runner's original report destination unchanged.
Retain prior evidence read-only and bind new receipts to current input hashes.
Do not run `flutter clean`, delete the retained candidate or prune shared caches.
Clean up only this newly allocated directory after all its owned processes exit
and durable report/receipt references are secured. This is local check scratch,
not a dependency, credential, service or runner-settings change.

## Terminal gates within command limits

The train report records a 1700-second timeout; the SSH/parser reports record
1800-second wrappers. Do not put the entire format/analyze/test/build/browser/audit
chain inside a single 1800-second timeout or repeat the unchanged failed input.
Run the existing required commands separately, with disk scratch, serial fixture
ports in the assigned range, and a frozen source/dependency manifest.

For a full test command longer than one foreground tool call, use the harness's
supported tracked background execution, retaining its PID/start identity, complete
log and terminal exit file under `TMPDIR`; inspect progress in bounded calls and
await the terminal result before closeout. The worker/session must remain alive
and own that job. This is not permission to bypass the runner's limits or detach
unobserved work. If the harness cannot retain such a job, the coordinator must
supply supported complete execution before final qualification; do not claim that
an interrupted run or a narrower selection passed the original command.
Disjoint focused batches help diagnose failures but do not replace the required
full command or its aggregate. All full offline gates from
[CONTRIBUTING](../../CONTRIBUTING.md#required-checks) remain required, including
fresh web build before browser E2E. Product/native/live acceptance remains separate.

## Task-contract completeness

The owner requested a task-gap pass. Planner's call: repair supported contract
metadata in place, not create replacement tasks or another audit queue.

- `DOC-PARITY-TAB-RECONNECT-CONTRACT` now declares its shared reconciliation,
  presentation and regression write footprint; its predecessor dependency remains.
- `MT-RERUN-TRAIN` and `PARITY-NATIVE-LINUX` expose their existing ownership as a
  separate field instead of burying it in Dependencies. This does not transfer
  assignment or authorize an independent worker.
- `MT-VERIFY-BROWSER-GATES` retains the same integration owner, build-before-E2E
  sequence, source binding and receipt-only write boundary; Checks and Touches are
  now explicit. Existing implementation owners still repair source failures.
- `VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART` names focused checks and the actual
  fixture/launcher footprint. Its future launcher must prove two distinct processes;
  the historical mounted-process receipt cannot pass restart acceptance.
- Newly generated held `-LIVE` bodies receive missing Goal/Sources from their
  unchanged indexed authority. Their original criteria, status, dependencies, order
  and access restrictions remain intact; no runtime qualification is marked done.

These are metadata and handoff corrections, not executed product checks. The
producer of incomplete future live-task bodies is outside this Wing-documentation
repair; do not describe a recurring generator defect as fixed. Missing Agent
contracts and unimplemented canonical consumers cannot be solved by live testing
alone, and their completed source studies are not permission to implement them.
