# M2 additional scratch inode-policy review

Task: `DOC-M2-INODE-POLICY-EVIDENCE`. Goal: M2.
Outcome: **UNAVAILABLE / `scratch_inode_policy_unavailable`**. The proposed
additional inode ceiling is not an admitted enforcement contract. Candidate
remains NOT_ADMITTED; F01/F02 remain UNAVAILABLE; `authoritative_counts_unavailable`
and Android/full M2 remain unverified.

## Decision and scope

This is a source-only review of the additional policy proposed in the
[synthetic isolation contract](2026-10-06-m2-synthetic-isolation-contract.md#unchanged-limits-and-exact-cumulative-cpu-semantics),
using the unchanged prerequisite statement in the
[CPU feasibility assessment](2026-10-06-m2-cpu-enforcement-feasibility.md#outcome-and-exactly-one-conditional-next-proof-seam).
The proposal is a maximum of 1024 simultaneously allocated tmpfs inodes per
attempt, including root, directories, regular files and links, with no
unaccounted writable mount. It is explicitly not a previously accepted limit.
This review does not change the 67108864-byte scratch ceiling, memory ceiling,
CPU ceiling, process ceiling, or any admission/authority boundary.

No mount was created, control executed, adapter implemented, kernel provisioned,
APK inspected, private state accessed, or runtime activated. This document does
not qualify Android or M2. A CPU envelope, even if separately established, does
not satisfy this independent inode, immutable-custody, descendant-termination,
or cleanup prerequisite.

## Source review and bounded contract mapping

The public [Linux tmpfs documentation](https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html)
describes `nr_inodes` as the maximum number of inodes for a tmpfs instance,
notes that its default is derived from physical memory, and says zero removes
the inode limit. It also says extended attributes use the inode allowance,
and that the `nr_inodes` setting can be changed on remount. This supports the
shape of an explicit per-instance ceiling; it does not establish that a delivered
mount has the intended effective value, that the intended ceiling counts the
contract's named object classes exactly as expected, or that untrusted descendants
cannot change it or use another writable mount.

| Contract question | Source evidence / review | Required for admission | Finding |
| --- | --- | --- | --- |
| Is a byte cap sufficient? | The synthetic contract correctly identifies that zero-length files can consume inode objects without consuming the byte allowance. Tmpfs documents separate `size`/`nr_blocks` and `nr_inodes` limits. | Enforce both the unchanged 67108864-byte bound and an independently reviewed inode bound. | Byte cap alone is insufficient. |
| What bound is proposed? | The synthetic contract proposes at most 1024 simultaneously allocated tmpfs inodes, including the root and created directories, regular files and links. | Fix a per-attempt maximum and define precisely which live inode objects count, including initial filesystem usage and any metadata/xattrs. | Proposal is review input, not accepted policy. |
| Does tmpfs expose a hard inode ceiling? | The tmpfs documentation calls `nr_inodes` the maximum and says `nr_inodes=0` removes the limit. | Bind the effective nonzero setting on the actual isolated tmpfs instance before any worker allocation. | API documentation is not proof of a configured/effective mount or enforcement on a delivered kernel. |
| Can the limit drift? | The documentation says sizing parameters can be changed on remount. | Prevent worker/descendant remount or mount-namespace/hierarchy changes; independently verify the effective setting and mount identity through teardown. | No fixed launcher, namespace policy, privileges, or non-remountability proof is supplied. |
| Are initial/root and all scratch objects charged? | The contract demands root and initial usage be counted, and its C08 proposes creating zero-length files/directories through inode 1025. The cited generic option description does not define the exact initial-usage accounting or a measured rejection boundary for that proposed topology. | Source-bound count semantics and a fixed independent oracle must show initial usage plus every permitted creation is within 1024, and the next allocation is refused without an alternate path. | Not established; no control ran and no matching kernel/configuration is pinned. |
| Are bytes/inodes also memory-bounded? | The synthetic contract separately requires aggregate memory accounting and says tmpfs charges must fit it. The tmpfs documentation explains that contents reside in virtual memory and may use swap unless disabled. | Establish effective memory/swap accounting for the mount and trusted helpers; the inode ceiling cannot replace the byte/memory controls. | Independent memory and no-swap prerequisites remain; this review does not qualify them. |

### Descendant and cleanup boundary

For the proposed ceiling to be meaningful, it must apply to the only writable
scratch tmpfs instance exposed to the worker boundary. No descendant may create,
remount, bind, or otherwise access a second writable filesystem or move outside
the accounted mount namespace. The counter must cover the root/initial state and
all concurrently allocated inode objects until their actual release; deleting a
name or observing a low byte count is not by itself evidence that all references
and descendant access have ended.

The synthetic contract's separate
[descendant termination and cleanup proof](2026-10-06-m2-synthetic-isolation-contract.md#descendant-termination-and-cleanup-proof)
therefore remains mandatory: kill the complete non-escapable boundary, confirm
`populated=0`, reap adopted children, close retained handles, release input,
remove/unmount scratch and mounts, and finish within the existing deadline with
final inclusive accounting. Cgroup emptiness alone does not prove reaping or
scratch removal; supervisor exit, EOF, unlinking, or a successful kill request
alone does not prove complete cleanup. Inode exhaustion must be an expected
bounded refusal only when the fixed policy and independent observation establish
the limit; otherwise the outcome is UNAVAILABLE, and any unconfirmed teardown
remains the contract's cleanup/termination failure rather than a successful
inode-limit result.

## Outcome and next prerequisite

**UNAVAILABLE / `scratch_inode_policy_unavailable`.** The documentation supports
the general existence of a per-tmpfs inode maximum, but not a reviewed bounded
contract for the proposed 1024 ceiling in the absent fixed runtime. The exact
kernel/build/configuration and mount path, effective `nr_inodes`, initial/root
accounting, mutation resistance, sole-mount containment, memory accounting, and
independent limit/cleanup observations have not been bound or qualified. No
host-derived default or quota alternative is accepted by implication. The
synthetic C08 remains NOT_CHECKED; no inode enforcement or admission claim follows.

Next evidence, if separately authorized after this source review: bind an exact
kernel and delivered closure; establish pre-allocation creation of a fresh,
non-remountable isolated tmpfs with the explicit 1024 ceiling and complete
initial/object accounting; prove descendants cannot escape or alter/multiply
writable mounts; and establish independent limit-refusal plus full bounded
termination/reap/unmount cleanup evidence. Until those proof obligations are met,
refuse before worker launch. This is a statement of evidence needed, not permission
to implement or execute controls, provision devices, or relax any limit.

## Sources and boundaries inspected

- [CPU feasibility assessment](2026-10-06-m2-cpu-enforcement-feasibility.md#outcome-and-exactly-one-conditional-next-proof-seam): preserves inode policy as a distinct pending prerequisite after CPU review.
- [Synthetic isolation contract](2026-10-06-m2-synthetic-isolation-contract.md#unchanged-limits-and-exact-cumulative-cpu-semantics): proposed 1024 inode ceiling, 64 MiB byte cap, memory relationship, and C08; see also its descendant/cleanup section.
- [Linux tmpfs documentation](https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html): general `nr_inodes`, default/zero behavior, remountability, and extended-attribute notes. It is unversioned documentation, not a delivered kernel pin or runtime qualification.
- [Security and privacy ADR](../adr/security-and-privacy.md#decision), [SECURITY](../../SECURITY.md), and [threat model](../security/threat-model.md#trust-boundaries): security and trust boundaries remain unchanged.

This source/document review is not kernel certification, a control execution, or
Android/device evidence. M2 remains unverified.

## Fixed-source companion assessment

The following assessment is retained from the merged main branch alongside the
source review above; both preserve the same UNAVAILABLE admission outcome.

Card: `DOC-M2-INODE-POLICY-EVIDENCE`. Goal: M2.
Outcome: **UNAVAILABLE / `scratch_inode_policy_unavailable`**. The proposed
1,024-inode ceiling is not an admitted limit or a reviewed bounded enforcement
contract. Candidate remains NOT_ADMITTED; F01/F02 remain UNAVAILABLE;
`authoritative_counts_unavailable`; Android/full M2 remain unverified.

### Scope and fixed sources

This is a source-only review of the [CPU feasibility assessment](2026-10-06-m2-cpu-enforcement-feasibility.md#outcome-and-exactly-one-conditional-next-proof-seam),
the [synthetic isolation contract](2026-10-06-m2-synthetic-isolation-contract.md#unchanged-limits-and-exact-cumulative-cpu-semantics),
and its [descendant termination and cleanup proof](2026-10-06-m2-synthetic-isolation-contract.md#descendant-termination-and-cleanup-proof). The [source index](../../.task-evidence/DOC-M2-INODE-POLICY-EVIDENCE/sources.json)
records the exact reviewed local files and hashes. The cited predecessors supply
the proposed policy and its gaps; neither supplies a pinned effective tmpfs
implementation, mount configuration, or executed enforcement evidence.

No adapter, control, APK, provisioning, private-state inspection, runtime
activation, authority change, limit change or platform/runtime qualification was
performed. The review does not authorize any of those actions.

### Proposed accounting boundary

The synthetic contract proposes a fresh sandbox-only tmpfs capped at 67,108,864
bytes and **at most 1,024 simultaneously allocated inodes**. Its proposed count
explicitly includes the root, directories, regular files and links. It separately
requires review of effective `nr_inodes` semantics, initial inode consumption,
hard enforcement and memory charges before admission. The scratch byte quota does not
substitute for this inode ceiling: many zero-length objects can consume inodes
without approaching the byte limit. The proposed 1,024 value is a ceiling for
review, not evidence that a particular mount enforces it.

The candidate policy needs an authoritative definition of what is counted over the
whole attempt, including objects that are not directory entries but remain
allocated (for example, unlinked objects retained by open references). Root and
mount-initial allocations must be included in the same ceiling rather than
silently subtracted. It also needs evidence that the configured ceiling is the
effective hard allocation limit, that exhaustion refuses creation before the
ceiling is exceeded, and that tmpfs metadata/inode allocations fit the unchanged
aggregate 1-GiB memory bound. None of these semantics is proven for a delivered
kernel/mount by the cited source set. No numeric allowance for initial usage,
rounding or overshoot can be inferred or invented here.

### Descendants and cleanup are separate obligations

The inode ceiling must apply to all writers with access to the scratch mount, not
just the direct worker: supervisor/setup work charged to the attempt, every child,
thread and detached descendant, and trusted capture/cleanup tasks that can create
scratch objects. A process list or direct-child exit cannot prove that writers have
ceased. The synthetic contract separately requires fresh non-escapable accounting,
whole-boundary termination, `populated=0`, adopted-child reaping, closed handles,
input release, and scratch/mount removal before publishing a result. Cgroup
emptiness alone does not prove reaping or mount cleanup; conversely, removing a
mount is not proof that no descendant retained access or that every allocated
inode was accounted before teardown.

A bounded contract would therefore need to bind the effective scratch mount and
its inode-counting/enforcement behavior to a fixed reviewed kernel/configuration,
account for initial and retained inode allocations, keep all writers inside the
same non-escapable boundary, and confirm descendants are dead/reaped and the
mount is removed within the existing end-to-end deadline. CPU, byte, memory and
process ceilings remain independent constraints. A finite CPU envelope—even if
later established—does not establish any of these inode, custody or cleanup facts.

### Outcome and admission effect

**UNAVAILABLE / `scratch_inode_policy_unavailable`.** The proposed 1,024-inode
number lacks evidence for effective hard enforcement and complete initial/live
allocation accounting; descendant-wide writer containment and bounded cleanup
also remain unestablished in the cited contract. This is a precise source-evidence
gap, not a finding that tmpfs inode limits are impossible. Do not treat the
host's default, a byte quota, an observed post-run count, or a CPU proof as a
replacement. No inode control should be executed to discover whether the policy
happens to hold.

The synthetic contract's C08 is explicitly conditional on independent policy
review; its required attempt to create inode 1,025 is NOT_CHECKED and must not run
until a reviewed policy and all launch prerequisites exist. Its current terminal
interpretation remains UNAVAILABLE, not `BOUND_REFUSAL / inode_limit` and not a
pass. Effective descendant kill/reap and bounded cleanup are independently
UNAVAILABLE, so no result here advances candidate admission. Limits and prior
refusals are unchanged; M2 remains unverified.

A future source-only review can revisit this result only with fixed authoritative
kernel/mount evidence and a concrete accounting/cleanup contract. This document
selects no implementation, does not approve the 1,024 recommendation and does not
create execution rights. Android qualification and all other M2 evidence remain
separate.
