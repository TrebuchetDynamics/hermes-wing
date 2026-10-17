# M2 additional scratch inode-policy evidence

Card: `DOC-M2-INODE-POLICY-EVIDENCE`. Goal: M2.
Outcome: **UNAVAILABLE / `scratch_inode_policy_unavailable`**. The proposed
1,024-inode ceiling is not an admitted limit or a reviewed bounded enforcement
contract. Candidate remains NOT_ADMITTED; F01/F02 remain UNAVAILABLE;
`authoritative_counts_unavailable`; Android/full M2 remain unverified.

## Scope and fixed sources

This is a source-only review of the [CPU feasibility assessment](2026-10-06-m2-cpu-enforcement-feasibility.md#outcome-and-exactly-one-conditional-next-proof-seam),
the [synthetic isolation contract](2026-10-06-m2-synthetic-isolation-contract.md#unchanged-limits-and-exact-cumulative-cpu-semantics),
and its [descendant termination and cleanup proof](2026-10-06-m2-synthetic-isolation-contract.md#descendant-termination-and-cleanup-proof). The [source index](../../.task-evidence/DOC-M2-INODE-POLICY-EVIDENCE/sources.json)
records the exact reviewed local files and hashes. The cited predecessors supply
the proposed policy and its gaps; neither supplies a pinned effective tmpfs
implementation, mount configuration, or executed enforcement evidence.

No adapter, control, APK, provisioning, private-state inspection, runtime
activation, authority change, limit change or platform/runtime qualification was
performed. The review does not authorize any of those actions.

## Proposed accounting boundary

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

## Descendants and cleanup are separate obligations

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

## Outcome and admission effect

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
