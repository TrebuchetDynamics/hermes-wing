# Retry held package and Linux qualification work

This is a task-contract repair, not a test result or qualification receipt.
The three records remain open with their original Acceptance and exclusions.

## Evidence and disposition

The Git-common `autowork-execution/slots/` records for
`CHECK-PACKAGES-001`, `LINUXQA-001-8163f50f` and
`LINUXQA-001-cbe0b043` all say **held**, attempt 2. Both attempts' reports
and retained verification logs were inspected in place; their private runtime
artifacts were not copied into this checkout. None of these three candidates
is an ancestor of the inspected checkout at `eff6de9f`.

The shared failures now have an implemented prerequisite:
[MAIN-REPAIR-003](../../tasks/items/MAIN-REPAIR-003.md) is closed with
`coordinator_verified`, backed by
[its receipt](../../tasks/evidence/MAIN-REPAIR-003.toml): candidate
`204a0570a73fe280c1b6a806b6501cefb35ab561`, integration
`bd1bcf76bd8bf82ad81a01f3c7aa6dec9b3128e5`, result/review `pass`/`passed`.
The [repair account](main-offline-test-repair-3f354e4e.md#worker-repair-evidence)
separates deterministic secure-store widget settlement from reserved-port
allocation and partial-setup cleanup. These changes are in the current checkout;
the older rejected candidates must not replace them. The receipt does not qualify
the held candidates or waive their new merged-tree checks.

### Package preparation

[CHECK-PACKAGES-001](../../tasks/items/CHECK-PACKAGES-001.md) retains its
[bounded setup repair](main-check-package-recovery.md#bounded-repair), not
product or named-test repair. Attempt 2 report names `302444a5`; its verification
receipt/log is `autowork-execution/e003c1873f6b410095154df603de8696.{json,log}`.
The full check rejected 25 widget failures, starting with all four Android
`primary paths retain owner` combinations (390/1280 width, 1.0/2.0 text).
The report reproduced those four on clean baseline `3f354e4e`, with
`pumpAndSettle` timeouts, before documentation edits. The remaining displayed
failures include compact SSH headings, no-CLI entry, connection help and
generated-key consent; the complete 25-case widget inventory belongs to the
[existing repair](main-offline-test-repair-3f354e4e.md#failing-inventory).

Add the completed repair as a dependency and check the primary-entry module before
retrying the unchanged setup work. Do not reopen MAIN-REPAIR-003, add a duplicate
repair, relabel a failed gate as green, or allow product edits from this setup task.
Real package exits and complete aggregate results must remain separate. Existing
runner logs may supply aggregate evidence; an unpublished coordinator handoff is
not a prerequisite for doing the owned documentation/preparation work. Missing
aggregate results remain explicitly pending until the normal runner gate executes.

### Linux connections

[LINUXQA-001-8163f50f](../../tasks/items/LINUXQA-001-8163f50f.md) retains every
connection/plugin criterion in the
[accepted campaign](../plans/2026-10-21-linux-feature-qualification.md).
Attempt 1 report names `c470c6d3`: direct GTK cases passed but the registered
campaign did not dispatch; saved-storage and deliberate managed-SSH fixture
execution were not accepted. Its review explicitly rejected treating these
**offline** failures as live-only limitations.

Attempt 2 names `efe2347a`. It reports passing registered connections, separate
native-input/persistence/keyring/storage/explicit `--lane linux --run` SSH
receipts, and 140 affected widgets. These are candidate evidence, not integration.
It also names the exact extra fixture, runner, shared package-validator and
existing connection-control files it needed. Correct Touches to those paths,
plus the rejected approval-dismissal regression; this does not request changes
to every listed file or admit missing-feature implementation.

Verification receipt/log
`autowork-execution/307bfd2b42de45e3bd09a99d124bdb53.{json,log}` rejected
21 failures: the Linux `retained malformed dismissal preserves replacement after
connection reset` case and 20 serve/client fixture failures. The latter match the
socket group in the existing MAIN-REPAIR-003 inventory. The log says none of the
five selected isolated reruns passed; the other 16 were not rerun. No flaky
verdict follows. Consume the completed fixture repair, then trace and repair the
remaining approval/recovery interaction within the existing caller-ownership
contract. Preserve the stale malformed sheet versus replacement approval's
in-flight ownership proof; do not delete keyboard/operation-count assertions to
make a changed recovery presentation pass. The connection gate and chat screen
are already named in the candidate report, not speculative feature work.

The current [driver](../quality/linux-qualification-driver.md#inspection) and
`scripts/support/linux_qualification_support.py` already handle stock native-only
plugin import roots and bundled versionless `sky_engine`. Reuse those corrections;
retain containment, source attribution and negative validator tests. No SDK,
package metadata, installed runner or dependency-lock changes are permitted.

### Linux accessibility and lifecycle

[LINUXQA-001-cbe0b043](../../tasks/items/LINUXQA-001-cbe0b043.md) retains all
access/voice-negative/native-input criteria and separate physical/audio/artifact
gates. Attempt 2 report names `1e3adcac`, 12 direct GTK cases and 62 focused
widget/contract passes, but the required campaign stopped before dispatch on
`Missing or escaping package import URI`. A standalone native pass is not a
registered access-lane or compact-return persistence pass.

Verification receipt/log
`autowork-execution/aa354c60e7d74a8eaa08260ed7c9f4d0.{json,log}` rejected the
20-case serve/client socket group. It says none of five selected isolated reruns
passed and the other 15 were not rerun. The worker separately reproduced bind
failures on the unchanged baseline and passed the three named SSH modules on
free assigned-range ports. Those observations do not establish three-revision
flakiness or repair product authentication/recovery. Consume MAIN-REPAIR-003,
check the three modules together, reuse the current package validator, and run
the actual registered access lane including compact-return persistence. Add
`integration_test/support/linux_test_isolation.dart` to Touches because both
attempt reports name its required owned-state correction. Shared driver
registration and package validation need no duplicate access-lane implementation.

## Saved ledger proposals

The only saved proposals found are the two already disposed of in
[package recovery](main-check-package-recovery.md#saved-ledger-proposals):
`slot-data/PARITYUPDATE-005-11/attempt-1/ledger-edit.patch` and
`slot-history/DOC-PARITY-TAB-CONTRACT/8/slot-data/attempt-1/ledger-edit.patch`,
relative to Git-common `autowork-execution/`. Their complete generated rows,
changed paths, current task records and adjacent/current reports were rechecked.
They only update retired TODO coverage / goals ordering, not a missing current
record. Preserve the prior **drop both proposals** disposition and the newer
manual owner-waiver closures of both live successors. No patch is applied,
no completed task is reopened, and no goal proof is inferred.

## Maintainer checklist

- [x] Read each record, Sources/accepted plan, both worker reports and retained rejection logs.
- [x] Check held states, existing verified repair and current shared implementation.
- [x] Repair Dependencies, Touches, Checks and retry notes through the native task CLI;
  keep Acceptance, exclusions, priority, statuses and goal proof unchanged.
- [x] Validate ledger, local links, preserved contracts, disjoint retry write sets and diff.
- [x] Independent read-only review; commit delivery is reported separately, with no push.

Maintainer validation: native `tasks validate --worktree .` returned `ok: true`
with 297 tasks, 36 goals and the unchanged `FILES-TERMINAL-DOWNLOAD` draft.
A read-only inline Python check verified all 11 local links/anchors, unchanged
Acceptance/exclusions/status/priority/ownership, exact report-backed Touches,
held states, candidate non-integration and prerequisite commit ancestry.
The three retry write sets are mutually disjoint and overlap no other non-draft
open Now/Next task. The existing deferred download draft's `**` footprint is
unchanged, not a new executable overlap. `git diff --check` passed.
Independent fresh-context read-only review found no Critical/Important issue;
its only note was that same pre-existing draft wildcard. Exactly these three
records and this evidence note changed; no task was closed or goal qualified.

No Flutter test, browser/native application, device or live Agent was exercised
by this maintainer pass. All runtime counts above are attributed historical
reports, not fresh qualification. Revisit these retry notes after the normal
reviewed merged-tree gates; do not repeatedly rewrite them for the same hold.
