# M2 exact cumulative CPU enforcement feasibility

Card: `t_d2b9b4db`. Task: `DOC-M2-CPU-ENFORCEMENT-FEASIBILITY`. Goal: M2.
Finding: mechanism NOT_ESTABLISHED; prelaunch UNAVAILABLE / cpu_budget_unavailable.
Candidate NOT_ADMITTED; F01/F02 UNAVAILABLE; authoritative_counts_unavailable.
Android/full M2 remain unverified. No platform or mechanism execution occurred.

## Decision and scope

None of the reviewed interfaces establishes the unchanged exact inclusive budget.
This is a bounded negative finding about the cited interfaces and available proof,
not a theorem that every possible Linux mechanism is impossible. In particular,
conservative early stopping could satisfy an upper ceiling without permitting the
worker to consume all of it, but requires proven margins that are absent here.
Do not substitute counter precision, successful signal submission, or a rate quota
for that proof. Refuse before allocation/launch; do not implement or execute C05.

The [unchanged contract](2026-10-06-m2-synthetic-isolation-contract.md#unchanged-limits-and-exact-cumulative-cpu-semantics)
is the authority: at most 20000000 microseconds cumulative user plus system CPU,
across every CPU, including trusted supervisor, capture/parser/serializer,
setup/sealing, worker, all descendants/threads, termination/reaping and cleanup.
Setup belongs to the first invocation, inter-command work to the following one,
and final cleanup to the last. A fresh account begins before first allocation;
no reset, subtraction, post-launch migration or uncharged trusted phase. Detaching
or exiting must not erase consumption. The external watchdog is protected from
starvation but is not an exemption for attributable work.

The wall limits remain 30 seconds per invocation, 90 seconds combined and
120 seconds end-to-end, including cleanup, with no extra grace period. Memory
1073741824 bytes, at most 32 processes/threads, scratch 67108864 bytes and the
other predecessor limits are unchanged. The proposed additional inode policy is
still pending independent review. This assessment changes no policy or capability.

The [runtime ADR](../adr/runtime-and-delivery.md#decision),
[security ADR](../adr/security-and-privacy.md#decision),
[SECURITY policy](../../SECURITY.md) and
[threat model](../security/threat-model.md#trust-boundaries) were inspected.
Hermes Agent owns domain state; Wing Link gains no operation or proxy role.
Agent/Desktop/Conduit were excluded from discovery. No product/adapter/test code,
SDK/JVM/APK, provisioning, namespace/cgroup activation, private runtime state,
install, sudo, device, credential, runtime activation or limit relaxation is in scope.

## Authoritative citations and evidence limits

The exact excerpts used, originating response byte lengths/SHA-256, URLs, HTTP
status and extraction offsets are retained in
[citations.json](../../.task-evidence/t_d2b9b4db/citations.json).
These are public documentation observations, not local kernel qualification.
The retrieved unversioned pages describe their documented interfaces; they are
not pins for the installed kernel, delivered adapter or runtime closure.
Response hashes identify retrieved HTML, not executable provenance. Only cited
text slices are retained; a response hash alone cannot reconstruct omitted HTML.

- K: [Linux kernel cgroup v2 documentation](https://docs.kernel.org/admin-guide/cgroup-v2.html),
  excerpts `membership`, `cpu.stat`, `cpu.max`, `freeze`, `cgroup.kill`, `cgroup.events`.
- R: [Linux man-pages getrlimit(2)](https://man7.org/linux/man-pages/man2/getrlimit.2.html),
  excerpts `RLIMIT_CPU` and `inheritance`.
- T: [Linux man-pages timer_create(2)](https://man7.org/linux/man-pages/man2/timer_create.2.html),
  excerpts `process-clock` and `notification`.
- W: [Linux man-pages wait(2)](https://man7.org/linux/man-pages/man2/wait.2.html),
  excerpt `reaping`.

## Mechanism comparison

| Candidate | Documented semantics | Missing exact-budget guarantee |
| --- | --- | --- |
| RLIMIT_CPU (R) | CPU limit in seconds for a process; soft limit sends SIGXCPU, catchable; hard limit sends SIGKILL. Per-process resource-limit attributes are shared by its threads and inherited across fork/exec. | Inheriting the numeric limit does not establish a single consumable account shared across separate child processes or supervisor/capture processes. Separate processes can consume separate allowances. No descendant-wide atomic debit/stop, microsecond dispatch bound or inclusive cleanup reservation is documented. |
| Process/thread CPU timers (T) | CLOCK_PROCESS_CPUTIME_ID measures user/system CPU of all threads in the calling process; CLOCK_THREAD_CPUTIME_ID measures one thread. SIGEV_SIGNAL generates a signal on expiry; SIGEV_THREAD invokes a callback as a new thread. | Neither clock is a process-tree/cgroup account. Notification is not an atomic aggregate execution barrier; callback/handler/kill/reap work also costs CPU. Summing timers requires an additional race-safe lifetime and enforcement mechanism, not supplied by this API. |
| cgroup cpu.stat (K) | Read-only usage_usec, user_usec, system_usec report all processes including descendant cgroups, even when the controller is not enabled. | This is the best reviewed observation boundary, conditional on complete membership. A microsecond reporting unit says nothing about maximum lag, rounding or atomic stop. Polling/reading it does not reserve the unobserved execution interval or stop other CPUs. No one-shot cumulative budget is documented here. |
| cgroup cpu.max (K) | Group may consume up to MAX in each PERIOD; applies to fair-class scheduling and qualifying BPF callbacks. cpu.max.burst is additional bandwidth state. | Period replenishment makes this rate/bandwidth control, not a lifetime counter that reaches permanent exhaustion. Rate times wall duration needs a separately proven phase/burst/runtime-granularity envelope and complete scheduler/accounting coverage. It is not an accepted replacement for cumulative CPU. |
| Freeze then kill (K, W) | Freezing may take time; frozen=1 confirms completion. cgroup.kill sends SIGKILL throughout the tree and handles concurrent forks/migrations. populated=0 means no live process in the subtree. wait removes zombies. | None promises a finite worst-case CPU cost or elapsed delay from request to quiescence, reaping and mount/input cleanup. Empty live membership is not proof of reaping/cleanup. These lifecycle controls cannot supply the missing budget bound by themselves. |

No combination of these rows closes the gap merely by enabling them together.
For example, per-process limits plus group polling still allow concurrent work
between reads and while termination is pending. Rate limiting that work reduces
its possible pace; it does not by itself prove the exact total including teardown.

## Inclusive account and lifecycle analysis

K documents inheritance of cgroup membership at process creation and hierarchical
controller scope; migration does not move existing descendants. Therefore a fresh
non-escapable subtree created before accounted work is a plausible observation
boundary, not proof that the delivered launcher creates it correctly. A future
proof must bind all thread/process identities, deny migration and hierarchy writes,
exclude uncharged helpers and retain the fresh counter through final cleanup.
A snapshot process list cannot capture all short-lived tasks. Process groups, a
single process CPU clock and direct-child exit miss detached descendants.

The setup chicken-and-egg is material: someone must create the fresh account,
allocate resources and start the supervisor. If that someone performs invocation
work outside the account, those costs require a separately proven inclusive charge
and enforcement path. Calling it a manager does not make the CPU disappear.
Neither a counter reset after setup nor migration of an already-running worker is
allowed. No such pre-allocation accounting path is established by this assessment.

At a polling threshold, other CPUs can still be executing while the observer
reads/decides/requests termination. Counter sampling, scheduler dispatch and stop
are distinct events. Delayed accounting and any already-dispatched quantum must
be bounded before consumption, not forgiven after the final counter is read.
K's reporting unit and maximum bandwidth description provide no exact bound for
these intervals. Host contention can delay a management observer; isolation and
priority names alone do not prove its scheduling latency or its own CPU charges.
We do not infer an overshoot size or add a tolerance.

At exhaustion, killing the complete account can also kill its trusted supervisor,
capture or writer before they finish receipts and cleanup. Keeping those alive
in a sibling/outside group avoids that particular failure but does not exempt
their attributable CPU. Conversely, leaving the supervisor within a throttled or
frozen group can prevent timely teardown. An admissible mechanism must reserve
CPU for all teardown and charge it to the same invocation budget without resetting
or moving tasks. SIGKILL submission is not final consumption cessation. K makes
freeze explicitly asynchronous; K's kill semantics do not supply a stop-latency
bound. W distinguishes terminated zombies from reaped children. Neither proves
input release, retained-pipe closure, unmount/removal or a bounded result writer.

The [predecessor cleanup contract](2026-10-06-m2-synthetic-isolation-contract.md#descendant-termination-and-cleanup-proof)
requires populated=0, complete reaping, closed handles, released input and removed
scratch/mounts, plus final inclusive accounting, all within the original deadline.
These remain separate obligations. Documentation for cgroup.kill cannot be cited
as evidence that local delegation, a non-threaded kill target, effective controllers,
namespace supervision or safe bounded cleanup has been established.

## Conservative-envelope alternative and unproven assumptions

A lower trigger is not inherently a relaxed ceiling: stopping early is permitted
if the final inclusive consumption never exceeds 20000000 microseconds. It is not
yet an evidenced mechanism here. A prospective proof must establish:

    B + L + K <= 20000000 microseconds

B is the maximum true inclusive consumption before triggering, including setup,
not merely the last displayed counter. L bounds all further concurrent execution,
accounting lag, observer/dispatch latency and stop work before quiescence. K bounds
all remaining reaping, capture/parsing/serialization and cleanup CPU. Disjoint
phase definitions must prevent omission or double counting. All quantities are
aggregate CPU microseconds, not wall seconds. No numeric values for B, L or K are
claimed. A measured average, a handful of successful controls or a post-exit total
cannot prove the worst-case inequality.

For a rate/deadline construction, the missing proof must additionally cover period
phase/replenishment, any burst/local runtime slack, scheduler classes, number of
simultaneously executing CPUs, all charged trusted work and finite termination
cost. Even with affinity restricted to one CPU and fair scheduling, the cited
APIs do not document the required accounting/stop/cleanup envelope. This is why
we do not dismiss every conservative construction as mathematically impossible,
but also do not admit one based on a rate calculation. There is no verified fixed
kernel/scheduler/closure identity, protected observer schedulability, pre-allocation
accounting path, finite L/K bound or complete lifecycle proof in the source set.

## Outcome and exactly one conditional next proof seam

Exact cumulative mechanism: UNAVAILABLE / cpu_budget_unavailable.
This missing prerequisite is an engineering refusal, not an owner question.
Do not run a benign worker to find out whether an unproven bound happens to hold.
C05 remains NOT_CHECKED. Candidate NOT_ADMITTED, F01/F02 UNAVAILABLE and
`authoritative_counts_unavailable` are unchanged. The
[live observer](../../integration_test/support/m2_observer.dart) still returns
`not_admitted`, `continuation_unavailable`, `qualifies=false` (lines 6–16, 25–32).
[Android M2 exit evidence](../../ROADMAP.md#m2--leave-and-return-without-losing-ownership)
is not supplied by this document or any predecessor receipt.

Exactly one smallest conditional next seam: a separately scoped source-only
worst-case envelope proof for a fixed fair-class, single-CPU cpu.max plus early
stop construction, binding a specific kernel implementation and trusted closure.
Its sole result must be either justified finite B/L/K bounds satisfying the
inclusive inequality from before setup through teardown, or a precise unavailable
finding at the first unbounded term. It must account for replenishment and actual
scheduler/accounting granularity, not reassert the quota API wording. This is a
proof target, not an endorsed mechanism, dispatch, permission to patch a kernel,
provision, implement an adapter or execute a control. Even a positive CPU proof
would not waive immutable custody, inode-policy review, descendant cleanup or the
other [conditional admission prerequisites](2026-10-06-m2-synthetic-isolation-contract.md#exactly-one-smallest-conditional-next-proof-slice).

## Executed document integrity and delivery

Exact commands from the repository root:

    python3 .task-evidence/t_d2b9b4db/fetch_citations.py
    python3 .task-evidence/t_d2b9b4db/check_integrity.py snapshot
    python3 .task-evidence/t_d2b9b4db/check_integrity.py verify
    python3 .task-evidence/t_d2b9b4db/update_ledger.py

[Source snapshot](../../.task-evidence/t_d2b9b4db/source-snapshot.json) binds exact
local source bytes, cited excerpts and fixed authored files, and compares the
predecessor contract/selected sources to its original fingerprints.
[Validation](../../.task-evidence/t_d2b9b4db/validation.json) retains local link/anchor,
lexical numeric/accounting/outcome consistency and authored whitespace checks,
including git diff --check and new-file no-index checks. These checks validate
this document's integrity only, not the correctness of a kernel implementation or
execution enforcement. Command receipts record actual argv and exits.
[Ledger receipt](../../.task-evidence/t_d2b9b4db/ledger.json) records helper-managed
named task/evidence/render updates with M2 kept unverified through supported
module load/dump; unrelated objects and prior evidence are preserved.

Only authored assessment/helpers/receipts enter the local agent branch; shared
TODO/goals are not commit targets. Native same-card review is the final step of
this card's goal; approval follows and is not claimed. No Flutter/platform suites
were run for this source/documentation-only change. Questions: none. Defaults
applied: source-only, no execution rights, no secrets/sudo and no limit relaxation.
