# M2 synthetic isolation and immutable-input proof contract

Card: `t_8ce3dc30`. Task: `DOC-M2-SYNTHETIC-ISOLATION-CONTRACT`. Goal: M2.
Status: PROPOSED source-only contract; enforcement NOT_ESTABLISHED.
Candidate NOT_ADMITTED; F01/F02 UNAVAILABLE; Android/full M2 remain unverified.

## Scope and evidence ceiling

This reviews the [preflight's next proof slice](2026-10-06-m2-inspector-isolation-preflight.md#exactly-one-next-proof-slice)
and [prerequisite map](2026-10-06-m2-inspector-isolation-preflight.md#candidate-enforcement-path-and-prerequisite-map).
The [manifest assessment bounds](2026-10-06-m2-manifest-assessment-contract.md#isolation-and-explicit-hard-bounds)
and [immutable custody](2026-10-06-m2-manifest-assessment-contract.md#immutable-public-input-admission)
remain unchanged. The [runtime ADR](../adr/runtime-and-delivery.md#decision),
[security ADR](../adr/security-and-privacy.md#decision), [SECURITY policy](../../SECURITY.md)
and [threat model](../security/threat-model.md#trust-boundaries) apply.
Hermes Agent owns domain state; Wing Link gains no compatibility operation.
Agent/Desktop/Conduit are excluded from discovery and remain untouched.

Delivered here: a document and task-local document-integrity helpers/receipts only.
No adapter, product source or regression-test implementation, sandbox activation,
SDK/JVM execution, APK acquisition/inspection, private discovery, provisioning,
installs, sudo, network, devices, credentials, runtime authority or follow-up card.
Document review does not grant permission to perform the proposed controls.
The live [observer](../../integration_test/support/m2_observer.dart), lines 6–16
and 25–32, remains `not_admitted`, `continuation_unavailable`, `qualifies=false`.
`authoritative_counts_unavailable` is preserved; no result below supplies counts.
[M2 exit evidence](../../ROADMAP.md#m2--leave-and-return-without-losing-ownership)
still requires actual Android death/relaunch, canonical history and zero duplicate
sends, including credential and wrong-owner cases.

## Fixed adapter and closure admission

The proposed synthetic adapter is one reviewed revision, not an arbitrary command
runner. Before any executable follow-up, an independent reviewer must bind:

- Contract revision/digest; adapter source revision and measured delivered bytes;
  fixed supervisor, synthetic control worker, capture/serializer and policy identities.
- Exact canonical executables, immutable materializations, SHA-256 digests and sizes
  for the complete loader/library/runtime/configuration closure, including dynamic
  loads. Source identity is not delivered binary identity. No invented pins: all
  actual adapter/closure pins and independent provenance are UNAVAILABLE here.
- A fixed allowlisted control ID to argv mapping. Proposed sandbox labels are
  `/control/bin/worker`, `/input/control.bin` and `/work`; these are not host paths.
  No shell, PATH lookup, caller executable, extra flags, external URLs or host paths.
  The SDK and JVM are absent from this synthetic closure and must not be invoked.
- Empty inherited environment and FDs; fixed `C.UTF-8`, `UTC`, sandbox HOME/TMPDIR
  and reviewed runtime locations only. Stdin closed; only deliberate sealed input
  and bounded output handles. No host config, proxy, option injection or caches.
- Pinned namespace/seccomp/capability/no-new-privileges policy and immutable minimal
  mount tree. No usable network interfaces/egress, host PID/proc or namespace
  handles, devices, private mounts, Agent/Wing Link sockets or writable host mounts.
- Effective unprivileged namespace/LSM permission, delegated cgroup v2 controls and
  non-escapable pre-allocation accounting, immutable seals, exact CPU enforcement,
  and descendant termination/cleanup mechanisms as specified below.

Hash/size checks before and after an attempt bind the closure but do not prevent
transient writes. Reviewed custody must exclude external writable aliases for its
entire lifetime. Drift invalidates the attempt; no update, alternate tool, weaker
policy or automatic retry. Missing identity/provenance or mechanism refuses before
worker launch as UNAVAILABLE. A demonstrated containment breach is ISOLATION_FAILURE.
A synthetic worker's claim about itself is not an independent observation.

## Unchanged limits and exact cumulative CPU semantics

Every future attempt uses fresh identities/resources. At most three sequential
fixed invocations, each at most 30 seconds wall time, at most 90 seconds combined,
and at most 120 seconds end-to-end. Monotonic absolute deadlines include hashing,
setup, freeze, execution, capture, parsing, kill/reap and cleanup; teardown has no
extra grace period beyond the total deadline. Reserve cleanup time within it.
If safe bounded cleanup cannot be guaranteed, refuse before allocation/launch.

The 20 CPU seconds per invocation means at most 20000000 microseconds of cumulative
user plus system CPU consumed by the accounted worker boundary: trusted supervisor,
capture/parser/serializer work attributable to that invocation, control worker and
all descendants/threads, on every CPU, including children that exit or detach.
One second on each of two CPUs consumes two CPU seconds. Charge setup and sealing
for the first invocation, inter-command work to the following invocation, and final
reap/cleanup to the last; there is no uncharged trusted-worker phase. A fresh account
starts before allocation/first exec; no reused usage counter, post-launch migration,
subtracting child CPU, hidden helper process or reset during an invocation. An
external management watchdog must be protected from worker starvation; it conveys
no resource exemption for work done on behalf of the worker.

Enforcement must prevent cumulative consumption beyond that unchanged ceiling,
including scheduling/accounting granularity and termination work. Observing a
counter after exceeding it does not enforce it. `RLIMIT_CPU` is per process;
`cpu.max` controls rate; `cpu.stat` polling has overshoot. None is accepted as an
exact aggregate budget, alone or combined without a separately reviewed proof that
covers all accounting/termination costs and guarantees the ceiling. No polling
tolerance, rounding forgiveness or replacement by wall time is permitted. An
accepted counter is observation evidence, not sufficient enforcement evidence.
Current exact cumulative CPU mechanism: UNAVAILABLE. Therefore executable follow-up
must not claim isolation admission, even if other controls could pass. A failure
to supply this prerequisite is a refusal outcome, not a user question or permission
to lower the standard. This contract resolves semantics, not mechanism availability.

Aggregate memory remains at most 1073741824 bytes: supervisor, descendants, sealed
input, tmpfs, capture/parser and output allocations. Require effective cgroup
`memory.max` and `memory.swap.max=0`, with no outside helper or allocation escape.
At most 32 processes/threads in the accounted boundary, charged before creation,
including the supervisor and JVM threads in any later separately admitted SDK run.
No startup exception, PID migration or privilege escalation. CPU/memory/process
observations must include short-lived descendants, not only periodic process lists.

Scratch remains sandbox-only tmpfs at most 67108864 bytes; no host caches or writable
input/tool mounts. Recommended additional conservative inode policy, pending
independent review: at most 1024 simultaneously allocated tmpfs inodes, including
root, directories, regular files and links; no unaccounted writable mount. This is
NOT an already accepted predecessor limit. Effective tmpfs `nr_inodes` semantics,
initial inode consumption, hard enforcement and memory charges must be reviewed
and measured before admission. A byte quota alone cannot bound zero-length files.
Until that review/mechanism exists: UNAVAILABLE / scratch_inode_policy_unavailable;
no executable follow-up may claim admission. Do not silently substitute the host's
default inode limit or label this recommendation approved.

Raw stdout ceilings remain 4096 bytes for each small-query control and 1048576 for
the manifest-sized control; stderr is at most 16384 bytes per invocation. Concurrent
reads count raw bytes before decoding/allocation; the first overflow kills the whole
boundary and discards partial results. Nonempty stderr refuses even within bounds.
No post-exit truncation or blocked-pipe shortcut. Sanitized result is at most 65536
UTF-8 bytes; overflow invalidates rather than truncates. The later SDK parser still
requires UTF-8 only, no DTD/entities/XInclude/resolution, at most 10000 elements,
depth 64, 256 attributes/element, 256 component records and 256 ASCII bytes/name.
Synthetic isolation controls do not qualify that parser or its package grammar.

## Immutable synthetic input and custody

Only reviewed deterministic public non-APK bytes are proposed: a fixed 4096-byte
repetition of ASCII `wing-public-control-v1\n`, truncated to that exact size. A future
reviewer binds independently generated expected size/digest and generator revision;
no digest is supplied or claimed measured here. No archive, manifest, transcript,
secret, APK or private-file input. For size-bound controls the same public pattern
may be generated at exact reviewed sizes within 268435456 bytes; a one-byte-over
admission request must be refused without allocating/copying an oversized input.

The public generator/custodian owns a nonsymlink regular source and symlink-free
parent chain. Descriptor-relative race-resistant validation, exact positive size,
identity and independently expected SHA-256 are required before copy. Prevent
source writers throughout copying; endpoint hashes alone miss transient mutation.
A fixed synthetic fault control may attempt replacement/truncation/growth or a
write-and-restore against this disposable public source only. The result must be
prevented by custody or INPUT_REFUSAL / changed_input with all partial results
invalidated; an undetected accepted mutation is ISOLATION_FAILURE.

Proposed freeze: private accounted memfd, no writable mappings/aliases, verified
`F_SEAL_WRITE`, `F_SEAL_GROW`, `F_SEAL_SHRINK`, `F_SEAL_SEAL` before first exec;
expose only sealed bytes read-only at `/input/control.bin`. Prove kernel rejection
of write, writable shared mapping, growth, truncation and seal-set change using
fixed public fault controls. Do not leak writable/control FDs or mutable host aliases
to the worker. Observe seals and rehash size/digest after each invocation. Kernel
seal support and closure file-access compatibility remain UNAVAILABLE, not inferred
from Python symbols. `chmod`, open FDs, read-only binds, `F_SEAL_FUTURE_WRITE` alone
and matching hashes do not prove freeze. No mutable fallback or numeric-constant
workaround is authorized. All input/copy allocations count toward memory/time/CPU.

## Proposed discriminating synthetic controls

These rows are specifications, NOT_CHECKED on this card. Future controls have fixed
IDs/argv and bounded deterministic workloads; no caller programs, raw diagnostics or
unbounded parent-generated test payloads. A benign control reads only the fixed
public input, emits a fixed short allowlisted token, exits zero and has empty stderr.
It must reach CONTROL_OBSERVED with intact custody and confirmed cleanup under all
bounds; that label never means candidate admission. Each fault runs separately in
a fresh attempt, stops on its first terminal result and cannot borrow another
attempt's resources. Missing prerequisites suppress launch of every row.

| Control | Independent observable enforcement obligation | Required terminal interpretation |
| --- | --- | --- |
| C01 network and IPC | Fixed worker attempts socket/IPC syscalls under deny policy; namespace/policy measurements bind no usable interface, host sockets or IPC handles. No connection to real services is attempted by this card or authorized as a test target. | CONTROL_OBSERVED / access_denied only if access is prevented; missing policy UNAVAILABLE; any usable forbidden channel ISOLATION_FAILURE. |
| C02 private mounts/device escape | Fixed reads target only nonexistent synthetic sentinel labels; independently measured allowlisted mount/FD tree excludes private data/devices/host proc and writable host mounts. No real private path probe. | Denied/absent sentinel plus proven mount containment; sentinel absence alone is insufficient. Missing measurement UNAVAILABLE; leaked mount/access ISOLATION_FAILURE. |
| C03 environment/FD injection | Future harness supplies only public canary environment values and a public canary descriptor; independent launch boundary proves they are removed. Worker emits only fixed present/absent enums, not values/FD paths. | CONTROL_OBSERVED / injection_denied; inability to inspect fixed boundary UNAVAILABLE; inherited canary or option/search-path influence ISOLATION_FAILURE. |
| C04 sealed mutation and custody | Fixed public controls attempt all five mutation operations above and source replacement/write-restore; kernel/custody owner observes rejection, exact identity/seals and stable bytes throughout. | CONTROL_OBSERVED / mutation_denied, or INPUT_REFUSAL / changed_input; missing seals/custody UNAVAILABLE; successful mutation accepted as immutable ISOLATION_FAILURE. |
| C05 cumulative CPU | Fixed single-worker and multi-CPU descendant CPU burners attempt to consume the full budget; trusted inclusive account observes stopped consumption including teardown, no overshoot, under the independently reviewed exact mechanism. | BOUND_REFUSAL / cpu_limit with confirmed cleanup; current mechanism UNAVAILABLE / cpu_budget_unavailable. Counter-only or tolerated overshoot cannot pass. |
| C06 process/thread exhaustion | Fixed worker requests the 33rd accounted task using both fork and threads, including short-lived/detached descendants; controller enforces at most 32 including trusted worker tasks. | BOUND_REFUSAL / task_limit, with rejected creation and inclusive counts; missing effective pids/accounting UNAVAILABLE; escape ISOLATION_FAILURE. |
| C07 memory and scratch bytes | Fixed incremental allocations attempt to exceed aggregate memory; a separate fixed tmpfs writer exceeds 67108864 bytes. Input/tmpfs/capture remain charged, swap disabled; monitor allocation failure/OOM and boundary teardown. | BOUND_REFUSAL / memory_limit or scratch_limit; unaccounted helper/swap/mount or overshoot ISOLATION_FAILURE; unavailable controls UNAVAILABLE. |
| C08 scratch inodes | After independent policy review only, fixed zero-length-file/directory creation attempts inode 1025 with root/initial usage counted; no symlink/device escape. | BOUND_REFUSAL / inode_limit; pending policy UNAVAILABLE / scratch_inode_policy_unavailable, never an approved-limit claim. |
| C09 output and diagnostics | Fixed generators emit exactly each permitted stdout size then size+1 in a separate attempt; stderr zero, one byte, exactly 16384 and 16385; simultaneous stdout/stderr pressure proves bounded concurrent capture. | Exact stdout with empty stderr may be CONTROL_OBSERVED; any stderr BOUND_REFUSAL / diagnostic; overflow BOUND_REFUSAL / output_limit. Deadlock is timeout/refusal, not pass; raw output is discarded. |
| C10 wall deadlines/cancellation | Fixed waiting control and descendant wait cross per-command/combined/end-to-end boundaries; fixed cancellation during copy, launch, capture and teardown invalidates the attempt. Trusted monotonic observer records deadline and termination within total budget. | BOUND_REFUSAL / deadline or cancelled with complete teardown; absent schedulable watchdog UNAVAILABLE; late/unconfirmed termination ISOLATION_FAILURE. |
| C11 detached descendants | Fixed fork/double-fork/setsid and thread controls retain a pipe or wait after direct worker exit. Namespace/cgroup identities remain stable; trusted supervisor kills/reaps all, including adopted children. | CONTROL_OBSERVED / descendants_reaped only with evidence below; direct exit, EOF or process-group kill alone cannot pass. Escape or unconfirmed death ISOLATION_FAILURE. |
| C12 cleanup failure | Fixed public fault refuses unmount/removal confirmation or suppresses a completion acknowledgement in the future trusted test seam; no deliberate real host escape. No partial successful receipt is publishable. | ISOLATION_FAILURE / cleanup_unconfirmed; missing bounded cleanup before launch UNAVAILABLE. A caught exception or success after deadline is not confirmed cleanup. |

A denied operation is an expected control observation, not permission to remove the
policy so the benign worker runs. Limits may make even the benign control unavailable;
never raise them. A missing oracle is UNAVAILABLE, not a passing denial control.

## Descendant termination and cleanup proof

Before first allocation/exec, require a reviewed child-cgroup/namespace identity
with effective controllers and no migration escape. Fixed termination must cover
all descendants, not only a PID or process group: effective delegated `cgroup.kill`
or an independently reviewed equivalent plus PID-namespace supervision/subreaping.
No assumption follows from a root `cgroup.kill` entry or launcher availability.
Require race-safe identities rather than recycled numeric PIDs. The tool cannot
write the control hierarchy, supervisor resources, receipt sink or kill handles.

On direct exit, any refusal, deadline, cancellation or signal: stop further work,
kill the entire boundary, wait for trusted confirmation of `cgroup.events`
`populated=0`, reap adopted children and confirm no unreaped child remains; close
retained pipes/control handles, release input and remove/unmount the fresh scratch
and mounts. Record before/after identities and bounded enum confirmations, not raw
process lists or paths. Cgroup emptiness alone does not prove reaping or mount/input
cleanup; supervisor exit alone does not prove cgroup emptiness. Final CPU/memory
accounting includes this work. Completion/EOF is not a substitute for termination.

The result writer stays outside the tool's writable namespace but within the
accounted trusted boundary; it publishes only after termination, custody and cleanup
are confirmed. Independent trusted observation must survive worker faults. If any
confirmation is missing or late, ISOLATION_FAILURE / termination_unconfirmed or
cleanup_unconfirmed, no assessment, no success inventory and no automatic retry.
Effective descendant kill/reap and bounded cleanup are UNAVAILABLE today. Refuse
before executable admission rather than promise asynchronous best-effort cleanup.

## Bounded sanitized evidence and refusal ordering

Proposed receipt fields only: public contract/closure/control-generator digests
and revisions with independent provenance references; fixed control ID/argv/cwd
labels; public input expected/measured sizes/digests; fresh attempt/resource opaque
identities; independently measured mechanism IDs; bounded numeric wall/CPU/memory/
task/scratch/output counters with units and accounting coverage; exit/signal enums;
seal/custody/termination/reap/cleanup confirmation enums; terminal result/reason and
evidence ceiling. One UTF-8 receipt per attempt, at most 65536 bytes. Unknown fields,
missing observations, counter overflow or serialization overflow invalidate it.
No raw stdout/stderr, binary/manifest data, host paths, arbitrary error messages,
private values/digests, environment contents, credentials or real endpoints.

Order: prelaunch prerequisite failure => UNAVAILABLE; identity/custody mismatch =>
INPUT_REFUSAL; enforced resource/diagnostic/deadline/cancellation => BOUND_REFUSAL;
any containment/drift/unconfirmed-termination/cleanup failure overrides those as
ISOLATION_FAILURE. CONTROL_OBSERVED is restricted to the expected measured outcome
with all required confirmations; it establishes only the named synthetic control.
All outcomes retain candidate NOT_ADMITTED, F01/F02 UNAVAILABLE and
`authoritative_counts_unavailable`. Absence and failed measurement never become a
package rejection fact. Current control execution, sealed input, effective CPU,
inode, kill/reap and cleanup enforcement are NOT_CHECKED/UNAVAILABLE.

## Exactly one smallest conditional next proof slice

Only after independent review of fixed delivered adapter/closure identities,
immutable custody/seals, exact cumulative CPU enforcement, the additional inode
policy and effective descendant termination/bounded cleanup: separately scope one
implementation-and-qualification slice for the synthetic adapter and C01–C12 on
public non-APK controls, under these unchanged ceilings. This names a next slice,
NOT permission to implement, run, provision or enqueue it. Absent any prerequisite,
its result must remain UNAVAILABLE and it cannot claim isolation admission.
Passing it would still require separate complete SDK/JVM closure, parser/sanitizer,
public APK/provenance and manifest assessment admission. It proves no F01/F02,
Flutter mode, installed closure/custody, Android recovery or full M2.

## Executed document-integrity evidence

From repository root, the task-local helpers perform only document checks:

    python3 .task-evidence/t_8ce3dc30/check_integrity.py snapshot
    python3 .task-evidence/t_8ce3dc30/check_integrity.py verify
    python3 .task-evidence/t_8ce3dc30/update_ledger.py

[source-snapshot.json](../../.task-evidence/t_8ce3dc30/source-snapshot.json) binds the
explicit source/predecessor receipt bytes and authored fixed files; shared TODO
uses its exact task block, excluding generated coverage changed by ledger render.
[validation.json](../../.task-evidence/t_8ce3dc30/validation.json) records local links/
anchors, source/authored fingerprints, lexical control/limit markers and authored
whitespace, including new files via `git diff --no-index --check`. Command receipts
retain exact argv/cwd/exits. These prove document integrity only, NOT isolation
enforcement or behavior tests. Predecessor bytes are bound, not reinterpreted as
passed sandbox tests. No application platform was exercised.

The initial verify failed on an overly strict exit-code expectation: Git's
no-index comparison of a new file returns 1 for added content even without
whitespace diagnostics. The checker now accepts 0/1 only with empty diagnostics;
the initial failed command and original authored snapshot are retained. This is
a document-check correction, not a change to any isolation limit.

[ledger.json](../../.task-evidence/t_8ce3dc30/ledger.json) records helper-managed named
task/evidence/render and readback. Document checks may auto-promote the helper's
coarse M2 status; supported goals.load/dump keeps M2 unverified, preserving other
goals/tasks and prior evidence. Shared TODO/goals are excluded from the authored-only
local agent-branch commit. Native same-card review is the final step of this card's
goal; independent approval follows and is not claimed here.
Questions: none. Defaults applied: source-only/refusal-only; recommended inode policy
pending independent review, no runtime rights and no relaxation of predecessor limits.
