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
