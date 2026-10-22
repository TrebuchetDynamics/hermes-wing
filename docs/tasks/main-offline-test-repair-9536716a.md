# Main repair evidence refresh: 9536716a

Evidence supplement for [MAIN-REPAIR-001](../../tasks/items/MAIN-REPAIR-001.md),
not a second repair task. Preserve every acceptance item in the
[original handoff](main-offline-test-repair.md). The
[8a393cc1 inspection](main-offline-test-repair-8a393cc1.md) remains historical;
its pending-candidate restriction now has the failed disposition below.

## Current main bundle

Read all five artifacts in place under the Git common directory:
`autowork-execution/main-evidence/9536716af87ff72f493e0a19569c4712aa4b0b95/`.
Raw artifacts are not copied into the checkout or commit.

- `main_check.json`: red, `TEST_FAILURE`; checked
  `9536716af87ff72f493e0a19569c4712aa4b0b95`, previous green
  `66c8a28e02863bc49f0c83d284e9cce712cdc04f`, red since
  `c746ad997d6d5c7f48eb3e69a63ba36f1df9554a`. Latest commits:
  `9536716a` (retired conformance closures), `d06c5434` (offline queue),
  `316e006b` / `b2f64e0e` (queue integration). Full intervening history remains
  in the JSON; these documentation commits do not establish product causes.
- `main-check.log`: line 4709 reports
  `25:19 +4137 ~9 -5: Some tests failed.`
- `main-check.exit`: `1`; `main-check-reruns.log`: empty;
  `flaky_history.json`: `{}`. There is no isolated-rerun or three-revision flaky
  proof. The framework's `Bad state: No element` is inside a reported test,
  not a crash before results.

| Existing failing case | Current evidence |
| --- | --- |
| Retained-plan disposition | Lines 213–216: `PARITY-LIVE-WORKFLOW-LIVE needs exactly one task body; found 0`, helper line 65, caller line 54. |
| Contact departure system Back, 1280/390 | Lines 1410–1479: absent confirmation dialog at test line 368. |
| Settings nested Back with mounted Chat, 390/1200 | Lines 3569–3636: absent Chat/category-chat at test lines 611/613. |

The same five names remain owned by MAIN-REPAIR-001. Earlier source commits
`cfe5662b`, `6c82c059`, `7f2f166e`, `3ecdaea0` and `dba56cad` and their changed
paths remain in the original handoff and existing Touches. The closure change in
`8a393cc1` is additional traceability evidence, not authority to edit waived tasks.

## Native closure is not an archive receipt

The [caller](../../test/tooling/plan_backlog_traceability_test.dart) selects
`planTaskBody` for every done task. The
[helper](../../test/tooling/support/plan_backlog_contract.dart) then requires
exactly one checked historical body. But
[PARITY-LIVE-WORKFLOW-LIVE](../../tasks/items/PARITY-LIVE-WORKFLOW-LIVE.md) is a
native follow-up manually closed by the owner, with its own canonical body and
explicitly no live proof. It has no frozen checkbox body to find.

Reconcile that assumption in the existing traceability repair. Declare the helper
and [nearest regression](../../test/tooling/plan_backlog_contract_test.dart) in
Touches and checks. Preserve malformed-record rejection, filename identity,
exact-body isolation, backlinks and historical archive guards. Do not reopen the
waived task, edit the archive, manufacture proof or qualify a goal. The missing
literal-clone disposition is still part of the original acceptance; its candidate
patch remains useful once native/manual records are handled correctly.

## Failed integration, not a pending frozen entry

Read Git-common `autowork-execution/slots/MAIN-REPAIR-001.json` and
`slot-data/MAIN-REPAIR-001/attempt-1/report.json`, plus runner-state artifacts
relative to the supported canonical status command's state directory:

- `review-findings/MAIN-REPAIR-001.json`;
- `full-check/MAIN-REPAIR-001-merged.log`;
- `full-check/MAIN-REPAIR-001.status.json`;
- `full-check/MAIN-REPAIR-001-merged.reruns.{json,log}`.

Candidate `17a3034c8f6a7a223c40754fc4638285cea4b8b3` reports 159 focused passes
on Flutter 3.44.2 / Dart 3.12.2, not a full-suite pass. It changes the two Back
fixtures, plan index, literal-clone plan and original handoff, not the traceability
caller/helper. Its useful fixture assertions and pending-admission disposition
should be reconciled, not reimplemented blindly or discarded.

Integration `8f732bf465c9f257823a14b2b24aeab8b6a7fc33`, based on
`3047a5a1cd4c9ab5b0726fb711dc0a3f75b06ca8`, failed validation. The slot is now
`held`, cause `validation`; supported canonical status reports MAIN-REPAIR-001
failed, zero running workers, and a different task awaiting integration. The
candidate is not an ancestor of this checkout's `bc1a08c17931d47244558983ce4b74dc56a196b3`.
It is therefore permissible to refresh this task's contract, not to close it or
bypass the normal runner gates. No ledger patch exists for this candidate.

The review verdict names traceability plus unchanged SSH fixtures. The full merged
log has **21** failures (terminal line 4790: `24:35 +4121 ~9 -21`), not merely the
truncated verdict's four names. Lines 2161–2285 show address-in-use errors on
loopback ports 20101/20128/20131/20132 in `managed_ssh_serve_test.dart`,
`managed_ssh_serve_reads_test.dart` and `managed_ssh_session_recovery_test.dart`,
with secondary cleanup errors. Later failures also affect channel lifecycle,
restoration, reads and client history/export/adversarial fixtures. The isolated
rerun JSON says `incomplete=true`, `flaky=[]`; its log is empty. Neither the
candidate's docs/widget changes nor this inspection establishes product regression
causation, complete baseline comparison or flakiness.

On resumption, reproduce and retain the actual inventory and resource/isolation
evidence before proposing any additional repair. Do not weaken transport or owner
fences, skip tests, fabricate baseline equivalence or claim main green from focused
passes. The refreshed contract still owns only its original five repairs, and its
unchanged full offline check still reports all failures:

```sh
flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1
```

## Saved ledger proposals

Re-read both complete saved diffs (including their long generated rows), adjacent
reports and archived task Sources. Retain the existing drop disposition in
[held recovery](held-offline-recovery.md#saved-ledger-proposals-after-migration):

- `slot-data/PARITYUPDATE-005-11/attempt-1/ledger-edit.patch`: candidate
  `7f5c64c9793be0e8783302521a5e1f06f27131f6`; only retired generated coverage
  and removal of done transcript work from old priority order.
- `slot-history/DOC-PARITY-TAB-CONTRACT/8/slot-data/attempt-1/ledger-edit.patch`:
  historical candidate `187cdc8c4725103a16f3e34a3416b10950b7f6e8`; only retired
  generated coverage. The current tab report names later `e564642d`.

Both producer tasks, `VERIFY-CHAT-TRANSCRIPT-NATIVE`, `MT-VERIFY-BROWSER-GATES`
and `PLANGAP-001-2f` remain done. Unlike older inspections, the two referenced live
successors are now also manually closed by the owner, without live proof. Replaying
these patches or the old open-successor narrative would undo newer planning.
Drop both proposals; no task/goal closure or verification changes are justified.

## Maintainer checks

- [x] Inspect the current main bundle, failed slot/report, source paths and proposals.
- [x] Keep one existing first-in-Now repair and every acceptance item.
- [x] Correct its native-closure scope, helper Touches, checks and current Evidence.
- [ ] Worker reconciles the retained candidate and reproduces remaining failures.
- [ ] Normal review and full-check gates establish the resulting candidate's verdict.

This maintenance pass validates task schema, local links and whitespace only.
It runs no Flutter, browser, native/device or live-Agent checks and supplies no
product fix, main-green verdict, blocker-resolution receipt or platform qualification.
Revisit when the slot disposition or failure inventory changes.
