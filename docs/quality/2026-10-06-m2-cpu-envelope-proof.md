# M2 single-CPU early-stop worst-case envelope assessment

Card: `t_02e4e461`. Task: `DOC-M2-CPU-ENVELOPE-PROOF`. Goal: M2.
Finding: first unestablished term is **B_setup**, a component of B, before
protected quota/accounting and the observer have been established.
Exact cumulative mechanism: UNAVAILABLE / cpu_budget_unavailable.
Candidate NOT_ADMITTED; F01/F02 UNAVAILABLE; authoritative_counts_unavailable.
Android/full M2 remain unverified. Mechanism/control execution: NOT_CHECKED.

## Scope and construction identity

This advances the [predecessor proof seam](2026-10-06-m2-cpu-enforcement-feasibility.md#outcome-and-exactly-one-conditional-next-proof-seam)
by tracing a revision-bound scheduler implementation, not by repeating its API
comparison. The [inclusive contract](2026-10-06-m2-synthetic-isolation-contract.md#unchanged-limits-and-exact-cumulative-cpu-semantics)
requires cumulative user plus system CPU from before setup through teardown:

    B + L + K <= 20000000 cumulative CPU microseconds

No tolerance, rounded forgiveness, average, reset or hidden helper is allowed.
The prospective construction is fair-class execution, one effective logical CPU,
fresh hierarchical accounting, cpu.max with quota Q and period P, no configured
burst, and a protected observer that triggers early at a lower threshold H.
These are proof hypotheses, not configured resources. Q, P, H, the delivered
kernel/configuration, architecture, scheduler tunables, trusted closure, observer
cadence and effective resource membership are **UNAVAILABLE**. The predecessor
supplies no fixed values or delivered source/binary pin. We do not select them.
One worker's affinity is insufficient: the single-CPU hypothesis must include
all worker descendants/threads and every invocation-attributable trusted task.
An observer on another CPU introduces additional aggregate consumption.

The inspected comparison is upstream Linux **v6.12**, resolved through the public
GitHub commit API to **adc218676eef25575469234709c2d87185ca223a**. This is a public
source revision, explicitly **NOT a deployed kernel pin** or evidence that its
configuration is present. The [citation receipt](../../.task-evidence/t_02e4e461/citations.json)
retains the resolution response, fixed revision URLs, response lengths/SHA-256,
line/character locations and exact excerpts. Full response fingerprints identify
retrieved source bytes; only excerpts are retained, not executable artifacts.

Read boundaries: [runtime ADR](../adr/runtime-and-delivery.md#decision),
[security ADR](../adr/security-and-privacy.md#decision),
[SECURITY](../../SECURITY.md), [threat model](../security/threat-model.md#trust-boundaries),
CONTEXT/CONTRIBUTING and the ADR index. Agent owns domain state; Wing Link gains no
operation. Agent/Desktop/Conduit were excluded from discovery and untouched.
No implementation, provisioning, kernel edits, SDK/JVM/APK, device, private state,
credentials, install, sudo, adapter/control execution or runtime activation.

## Disjoint phases and first unsupported term

Let C(t) be true cumulative invocation-attributable user plus system CPU across
all accounted tasks, including exited/detached tasks. This is the quantity to
bound, not merely the displayed cpu.stat sample. Boundaries are logical events,
not assumptions that their time or cost has already been established:

- t0: immediately before the first invocation-attributable setup operation,
  including creation of the fresh account and allocation/sealing/hashing.
- t1: trusted observer commits the first stop decision (threshold, direct exit,
  refusal or deadline). No claim that a polling sample is contemporaneous.
- t2: untrusted worker and all descendants/threads cease execution permanently;
  trusted closure remains alive to finish. Requesting SIGKILL is not this event.
- t3: all reaping, remaining capture/parser/serializer, receipt publication,
  handle/input release and scratch/mount/account cleanup are finished.

B bounds C(t1)-C(t0); L bounds C(t2)-C(t1); K bounds C(t3)-C(t2).
CPU executing exactly across a boundary is partitioned at that event, not charged
twice. Trusted work overlaps all phases and is charged where it executes, not
added again because of its name. Capture/parsing before t2 belongs to B or L;
only the remaining work belongs to K. Natural exit still needs a trusted terminal
decision and descendant confirmation. Never reaching t1/t2/t3 is failure of the
corresponding bound, not a completed invocation.

**Earliest missing proof: B_setup**, the portion from t0 to establishment of the
protected rate/accounting/observer boundary. The synthetic contract explicitly
requires a fresh account before allocation/first exec and charges setup to the
first invocation (lines 72–82). Its fixed closure/pins remain unavailable (lines
33–54); the predecessor explicitly has no pre-allocation path (lines 89–94).
No source for a fixed trusted bootstrap/observer is delivered in those contracts.
Therefore there is no bound on this charged prefix below the budget, nor proof
that it is included in the account used for H. This is **UNESTABLISHED**, not a
claim of physically infinite CPU consumption or impossibility for all kernels.

Concrete failure of the proposed inference: Q/P can restrict work only after
effective control. An uncharged or unbounded bootstrap prefix plus a small
post-bootstrap sample can still exceed the inclusive ceiling. Migrating the
supervisor later, clearing a counter or renaming it a manager cannot remove that
prefix. Starting H only after setup cannot bound B_setup. A wholly single-CPU
lifetime would give a coarse CPU upper bound from an independently enforced wall
lifetime, but the contract's 120-second end-to-end limit is not a 20-second CPU
proof, and neither effective whole-closure affinity nor a hard lifetime is
established here. No measured setup average substitutes for this proof.

## Revision-bound replenishment and accounting trace

The following citations are to the comparison revision only; line numbers and
exact excerpts are in citations.json. Their consequences are additional unmet
obligations even if B_setup were supplied.

### Replenishment and local runtime

[Linux fair.c](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/kernel/sched/fair.c):

- `__refill_cfs_bandwidth_runtime`, line 5748: `cfs_b->runtime += cfs_b->quota;`
  followed by `min(cfs_b->runtime, cfs_b->quota + cfs_b->burst)`. Replenishment
  replaces a lifetime exhaustion interpretation with renewed period credit.
- `__assign_cfs_rq_runtime`, line 5772, transfers global credit to
  `cfs_rq->runtime_remaining` in a target-runtime batch. A local slice is not
  an extra entitlement to ignore; initial/local credit and returned credit
  need a conservation argument over the full interval.
- `init_cfs_bandwidth`, line 6573, initially sets `quota = RUNTIME_INF`,
  `burst = 0`, and adds a random timer offset. Merely creating a group is not
  proof that finite control precedes setup. Default zero burst is not proof of
  the effective policy for a delivered group.
- `sched_cfs_period_timer`, line 6518, uses `hrtimer_forward_now` and an overrun
  loop; repeated looping can scale period, quota and burst together. A fixed
  input cpu.max string does not by itself prove constant internal Q/P history
  or a worst-case replenishment count in this implementation.

[Bandwidth documentation](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/Documentation/scheduler/sched-bwc.rst),
lines 111 and 161, says runtime moves between global and CPU-local silos in
batches, and `Once a slice is assigned to a cpu it does not expire.` Its typical
slice/retention numbers are **not chosen margins**. One CPU eliminates summing
multiple simultaneously active worker runqueues only under effective containment;
it does not eliminate retained credit or period-boundary bursts.

For an ideal exact-credit model, an interval intersecting N replenishment windows
would require bounding initial/local available credit plus those replenishments.
Multiplying Q/P by elapsed wall time omits window phase and carried credit. A
real proof must additionally bound deferred charging/rescheduling and any dynamic
parameter history. This is an obligation decomposition, **not a proven numeric
formula** for Linux. No Q, P, N or slack is assigned here.

### Scheduler and reporting granularity

fair.c `update_curr`, line 1216, obtains an elapsed execution delta and calls
`account_cfs_rq_runtime`. `__account_cfs_rq_runtime`, line 5812, explicitly says
`dock delta_exec before expiring quota (as it could span periods)`, subtracts that
delta, and calls `resched_curr` if credit cannot be extended. It records elapsed
work and requests a reschedule; it is not an instantaneous CPU cutoff at H.

[Linux core.c](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/kernel/sched/core.c)
`resched_curr` sets need-resched/preempt flags locally or sends a remote reschedule
IPI. The retained function contains no numeric maximum to the actual scheduling
point. Deriving one requires the effective preemption/interrupt/tick configuration,
architecture, permitted kernel paths and observer scheduling environment. The
batch slice is **not** a bound on execution to the next accounting/preemption
point. Single-CPU serialization does not establish protected observer latency.

[Linux rstat.c](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/kernel/cgroup/rstat.c)
`cgroup_base_stat_cputime_show` flushes hierarchical stats, reads sum_exec_runtime,
adjusts user/system values and divides nanoseconds by NSEC_PER_USEC before showing
usage/user/system microseconds. Integer conversion can discard sub-microsecond
remainders; it cannot be interpreted as true C(t) with zero discrepancy. It also
cannot establish that the currently running task's pending delta is already
charged. [Linux cputime.c](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/kernel/sched/cputime.c)
has configuration-dependent virtual/tick accounting paths. The retained
`cputime_adjust` context includes tick accounting and its variable precision.
This trace does not conflate per-thread-group adjusted time with cgroup totals,
or infer a worst-case error from reporting units. No conversion remainder is
accepted as forgiveness; a future conservative bound must cover it in B.

Thus even after setup, B needs true-consumption coverage through sampling,
observer dispatch and committed decision: pending accounting, conversion,
replenishment/credit, and all trusted observation CPU. H alone is not B.

## Stop and trusted closure coverage

[Versioned cgroup documentation](https://github.com/torvalds/linux/blob/adc218676eef25575469234709c2d87185ca223a/Documentation/admin-guide/cgroup-v2.rst)
retains freeze and kill excerpts: freezing `may take some time`; kill covers
concurrent forks/migrations but is process-directed and rejects a threaded group.
These semantics do not supply finite latency or CPU-work bounds for t2 or t3.
No claim is made that the complete kill implementation was proved from API text.

| Charged work | Phase | Missing bound/identity |
| --- | --- | --- |
| Setup, fresh-account creation, allocation, copy, sealing, hashing, supervisor startup | B_setup within B | First gap: fixed pre-allocation charge/enforcement path and finite inclusive prefix |
| Worker, all descendants/threads including short-lived, exited and detached tasks | B and L | Non-escapable hierarchical membership, class/CPU policy and true accounting through permanent quiescence |
| Observer sampling, decision, protected dispatch | B then L | Fixed source/closure, bounded sampling/accounting discrepancy and dispatch; outside watchdog work still charged |
| Stop/freeze/kill requests, continuing worker syscalls, exit and last descendant execution | L | Finite worst-case stop work and time-to-quiescence, including deferred preemption and replenishment |
| Trusted reaping and adopted-child confirmation | K, or B/L if done earlier | Fixed supervision and bounded reap algorithm/kernel paths; populated=0 is not reaping |
| Capture, parser and serializer; bounded receipt publication | All phases by execution time | Complete loader/library/runtime closure and CPU complexity/iteration/error bounds, not only byte limits |
| Close retained handles, release input, scratch/mount removal and account cleanup | K, or earlier phase if actually done there | Fixed cleanup paths, bounded retries/kernel work, final account retained through the last charged operation |

A trusted observer inside the throttled/frozen/killed worker group may not finish;
a sibling/outside observer or writer may survive but is not budget-exempt. The
single-CPU/Q/P argument must cover its CPU too. The account cannot disappear before
the last cleanup/serializer operation, and the writer cannot publish success
before [termination/custody/cleanup confirmation](2026-10-06-m2-synthetic-isolation-contract.md#descendant-termination-and-cleanup-proof).
Bounded bytes, task count and scratch space alone do not prove finite iteration,
syscall, retry, observer or teardown costs. No finite L or K is supplied here.

## Outcome and one conditional evidence seam

B_setup is the first unestablished term. The later scheduler/observer and L/K
obligations are independently open; the inequality is NOT_PROVED. No present
admission follows from fair class, single CPU, zero burst or an early threshold.
UNAVAILABLE / cpu_budget_unavailable; candidate NOT_ADMITTED; F01/F02 UNAVAILABLE;
authoritative_counts_unavailable remain unchanged. The [live observer](../../integration_test/support/m2_observer.dart)
retains `not_admitted`, `continuation_unavailable`, `qualifies=false`.
C05 and all mechanism/control tests are NOT_CHECKED. No Android evidence or full
[M2 qualification](../../ROADMAP.md#m2--leave-and-return-without-losing-ownership)
is supplied. A positive CPU proof alone would not waive immutable custody,
independent inode-policy review or complete descendant cleanup prerequisites.

Exactly one smallest conditional next evidence seam: obtain a **source-bound
pre-allocation bootstrap charge/coverage certificate** for the proposed fixed
trusted closure. It must bind the delivered kernel revision/configuration and
complete bootstrap/loader/runtime source and byte identities; identify t0, the
fresh inclusive charge path for creating the account itself, every setup/helper
thread and CPU; prove a finite B_setup reserve under non-escapable class/affinity
and bounded setup/error paths before worker launch. An outside manager must have
its attributable work conservatively included, not silently exempted. Absent this
certificate retain refusal. Supplying it resolves only this earliest seam; it
does not establish the later sampling/granularity/L/K inequality. This is not a
dispatch, implementation/provisioning request or grant of execution rights.

## Executed document integrity and delivery

Exact commands run from repository root are retained with exits in the task-local
receipts; the commands for the final document checks are:

    python3 .task-evidence/t_02e4e461/fetch_sources.py
    python3 .task-evidence/t_02e4e461/check_integrity.py snapshot
    python3 .task-evidence/t_02e4e461/check_integrity.py verify
    python3 .task-evidence/t_02e4e461/update_ledger.py
    git diff --check

[Source snapshot](../../.task-evidence/t_02e4e461/source-snapshot.json) binds exact
inspected local source bytes and authored fixed assessment/helpers/citations.
[Validation](../../.task-evidence/t_02e4e461/validation.json) checks local links and
anchors, lexical ceiling/phase/source/outcome coverage, unchanged fingerprints,
and whitespace (including newly authored untracked files). These executed checks
are **document integrity only, not mathematical validation or CPU enforcement**.
The initial retrieval failed on a function qualifier mismatch; the preserved
failed receipt and successful corrected retrieval distinguish failure from evidence.
The first integrity verify also failed because its linked validation receipt had
not yet been initialized; after creating that explicit NOT_CHECKED placeholder,
the rerun passed. Both failed command receipts are retained and recorded as failed
ledger evidence, not mathematical counterexamples or mechanism-test failures.
[Ledger receipt](../../.task-evidence/t_02e4e461/ledger.json) records only the named
task plus executed evidence/render, preserves unrelated objects/prior evidence,
and keeps M2 unverified through the helper's supported load/dump API.
Only authored files enter the local agent branch; shared TODO/goals are excluded.
Native same-card review is the final delivery step; approval is not claimed.
No Flutter/platform suites or mechanism controls ran. Questions: none.
Defaults applied: source-only, no secrets/sudo, no execution rights or relaxed limits.
