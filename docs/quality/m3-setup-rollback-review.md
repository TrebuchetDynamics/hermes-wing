# M3 failed-setup attribution: independent contract/security review

Task: `DOC-M3-ROLLBACK-EVIDENCE`.
Reviewed artifact: [historical attribution and proof gap](m3-setup-rollback-evidence.md),
plus the backlink at the [enrollment/profile checkpoint](m3-enrollment-profile-contract-checkpoint.md).

- Independent read-only `reviewer`, fresh context; run
  `d8721371-3c94-4c44-8d2b-fd9c15546e35`.
- Wing baseline: `45de04652f99c1b09f92ce94a66eb2cbd53a2d00`.
- Unmodified Agent reference: `158fd638da1629c8e62caf9ade1515d162def8ab`.
- Archived Wing Link source/tests: `95fa98eb4ac91f123c0163c84fdd42d545cd7826`.
- Verdict: **accepted as a bounded historical attribution/missing-proof receipt;
  no findings or blockers**. No rollback qualification, platform acceptance,
  independent product security audit or M3 completion is implied.

## Reviewed byte identities (SHA-256)

| Artifact | Digest |
| --- | --- |
| `m3-setup-rollback-evidence.md` | `b5acad6109acc8d5ee3cc31c5aaaeabace0e45a26fe0b4bfa5aba3c1127df4b6` |
| `m3-enrollment-profile-contract-checkpoint.md` after backlink edit | `d4af2e645af93b7bb70525d8f8464e6879849824c2099dcab089a242f83b8ce5` |

The [prior checkpoint review](m3-enrollment-contract-review.md) binds its historical
baseline bytes, not the edited backlink. Its digest was independently checked
against the baseline Git blob and left unchanged; this review binds the new bytes.

## Verified scope and limits

The reviewer independently inspected the archived handler, configuration/readiness
closure, cleanup helper, fake failure tests and sanitized original/retained receipts.
The selected deadline failure is reported in history; source/test assertions support
new-name compensating deletion, not a failure-specific unchanged existing-profile
incarnation/configuration/credential/session receipt. The later successful lifecycle
is not the selected failed attempt. The APK/shared-worktree attribution is not an
invented exact executing-source identity.

Current Wing caller/fencing tests and Agent capability/publication/clone-test seams
were checked against those distinctions. No private data or restored compatibility
operation was found. Fourteen new-document local targets/anchors and sixteen pinned
source paths/line ranges were independently validated against local Git blobs;
reviewed documents had final newlines and no trailing whitespace. External URL
availability was not checked. Local task status and checkpoint ancestry were checked;
author-reported worker activity was not independently attested as lease authority.

No repository edits, tests, profile creation, rollback run, credentials, provider
calls, installs, service actions or upstream changes were performed by the reviewer.
No platform was exercised. Remaining live/runtime proof and exact failure-specific
identity/partial-secret cleanup gaps are retained in the evidence page. The review
covers the receipt and checkpoint backlink, not a re-audit of the unchanged checkpoint
or retired service. The parent remains the sole writer.
