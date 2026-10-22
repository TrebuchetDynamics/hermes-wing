# Main traceability repair: 750a19da

Owning task: [MAIN-REPAIR-002](../../tasks/items/MAIN-REPAIR-002.md).
This is one bounded tooling repair, not renewed connection implementation or
native/live qualification. The older [MAIN-REPAIR-001](../../tasks/items/MAIN-REPAIR-001.md)
is coordinator-verified and stays closed.

## Main evidence inspected in place

Relative to the Git common directory, read
`autowork-execution/main-evidence/750a19da075cc61d64e6327c9b42812c9f7d6ceb/`:

- `main_check.json`: red, `TEST_FAILURE`, checked revision
  `750a19da075cc61d64e6327c9b42812c9f7d6ceb`, previous green
  `563ce840e582be848094306ccec54b025d65af3d`, red since
  `8cfa3332f8e066a1c05fc523db5f8342a7176711`.
- `main-check.log`: lines 214–222 name only
  `test/tooling/plan_backlog_traceability_test.dart`: **every retained plan has
  an explicit canonical backlog disposition**. The error is
  `tasks/items/CONNECTION-ACCESS-ASSISTANCE.md: missing TOML frontmatter`,
  through `readPlanTaskRecords` at helper line 31 / caller line 21.
  Terminal result: `21:35 +4147 ~9 -1: Some tests failed.`; `main-check.exit`: `1`.
- `main-check-reruns.log`: empty; `flaky_history.json`: `{}`. No isolated reruns
  or three-revision flaky proof exist in this bundle. This is not a check crash.

Commits since that green, as retained in `main_check.json`:
`750a19da`, `c51fe98c`, `735e97f1`, `1c263e7f`, `91af7bd3`, `cd8b3030`,
`8cfa3332`, `eb35748b`, `5df2e0ab`. Their changed files were inspected.
`735e97f1` introduced the bare task note; `8cfa3332` closed the native removal
task and added its receipt. Connection/avatar/Android application changes are
not evidence of a product defect in this traceability failure.
Raw evidence remains in place; do not copy the bundle or worker logs into commits.

## Landed repair and newly exposed failure

`71121604e12141dbd33db583d4657ef290e53a90`, integrated by `e6ae1561`, already
added the missing frontmatter while preserving the delivery note and recording
manual closure. Do not repeat that repair, reopen
[CONNECTION-ACCESS-ASSISTANCE](../../tasks/items/CONNECTION-ACCESS-ASSISTANCE.md),
or upgrade its qualification claims.

On maintenance baseline `98975718`, Flutter 3.44.2 (`c9a6c48423`), Dart 3.12.2,
Linux host, this exact command exited 1:

```sh
flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/plan_backlog_contract_test.dart test/tooling/plan_backlog_traceability_test.dart
```

Offline locked resolution passed without tracked dependency changes. All 15
helper cases passed; the real inventory case failed with
`FormatException: CONNECTION-LINK-REMOVAL needs exactly one task body; found 0`
at helper line 84 / caller line 56. This is a fresh focused reproduction, not an
isolated rerun in the saved bundle or proof that the full suite has only one
remaining failure.

At baseline, the [caller](../../test/tooling/plan_backlog_traceability_test.dart)
lines 54–62 used the canonical record body only for `closure == 'manual'`. Every
other done record was sent to the historical checkbox lookup with an empty live
body. But
[CONNECTION-LINK-REMOVAL](../../tasks/items/CONNECTION-LINK-REMOVAL.md) has
`closure = 'coordinator_verified'`, a canonical body with direct plan backlinks,
and an existing [native receipt](../../tasks/evidence/CONNECTION-LINK-REMOVAL.toml),
not a frozen archive checkbox. The malformed-record and archive/body guards in
[the helper and its tests](../../test/tooling/plan_backlog_contract_test.dart)
should remain enforced; native closure must not be inferred merely from `done`.

The removal attempt-2 report under Git-common
`autowork-execution/slot-data/CONNECTION-LINK-REMOVAL/attempt-2/report.json`
names candidate `5df2e0ab`; closure commit `8cfa3332` names the verified disposition.
The older repair attempt-1 report names `7787cde4` and its 174 focused passes,
including manual closure support. Neither report supplies coordinator-closure
traceability coverage. Their historical failures and live exclusions remain
historical, not fresh failures or permission to redo product work.

## Bounded worker contract

- Reproduce the current inventory failure, then reconcile native coordinator
  closure in the existing caller/helper path with the canonical store's closure
  provenance. Preserve legacy archive lookup and exact-body isolation; do not
  treat every done record or an unsupported closure value as an authoritative
  native closure. Preserve malformed TOML, filename/status, missing/duplicate
  body, hash-suffixed/prefix-neighbor ID and direct-backlink checks.
- Add focused positive and negative regressions for coordinator-closed records
  alongside existing manual/archive cases, including missing body, conflicting
  checkbox body, invalid status/provenance and missing primary-plan backlink.
  Use synthetic task/receipt data where needed, not copied runtime artifacts.
  Traceability is not a replacement for native receipt verification by Autowork.
- Do not edit existing task status, receipts, frozen history, goal qualification,
  plan dispositions or product behavior to make the test pass. The two closed
  connection tasks are read-only source evidence, not mutation targets.
- Update this handoff with the actual repair, source/toolchain and check results.
  Run the focused pair, changed-Dart formatting, analysis and native task
  validation. The dispatch assigns the unchanged
  [full offline check](../../AGENTS.md#validation) to the runner on the merged
  tree before review, not to this worker:

  ```sh
  flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1
  ```

  Retain actual exits and remaining inventory. Do not report main green from
  focused passes, hide failures, skip cases, filter the full suite or invent
  coordinator/device/live acceptance. No SDK/runtime/Agent changes are authorized.

## Worker repair and focused evidence

On task baseline `1a296d27872d9d094f3ca23e3c3433e00353c068`, the focused pair
reproduced the same `CONNECTION-LINK-REMOVAL` missing-body failure: exit 1,
15 helper passes and one inventory failure. The repair in the commit containing
this handoff changes only the three traceability Dart files and this document:

- The caller passes the canonical body and explicit closure provenance to the
  existing helper. Only `manual` and `coordinator_verified` select the record
  body; both require `done`, a nonempty body and no same-ID checkbox conflict.
  An unsupported provenance fails even if a checked archive entry exists.
- Unmarked legacy records still need exactly one matching checked body. A plain
  record body and `done` alone cannot authorize native closure. Existing parser,
  filename/status, exact hashed-ID, prefix-neighbor, duplicate and archive guards
  remain. The primary-plan direct-backlink check is shared with its focused
  negative regression; a neighbor's link or section-only link cannot satisfy it.
- The native regression extends the existing manual case with coordinator
  provenance, ordinary/hash-suffixed IDs and positive/negative body cases. The
  new coordinator and unsupported-provenance cases were observed failing before
  the fix. No task record, receipt, disposition or frozen archive was changed.
  This is body traceability, not receipt validation or verified acceptance;
  Autowork retains authoritative receipt and contract verification.

Final worker checks on Linux, Flutter 3.44.2 (`c9a6c48423`), Dart 3.12.2:

| Command | Exit | Result |
| --- | --- | --- |
| `flutter pub get --offline --enforce-lockfile` | 0 | Offline resolution passed; lockfile unchanged. |
| `flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/plan_backlog_contract_test.dart test/tooling/plan_backlog_traceability_test.dart` | 0 | 18 passed: 17 helper cases and the real retained-plan inventory; no skips or retries. |
| `dart format --output=none --set-exit-if-changed test/tooling/plan_backlog_traceability_test.dart test/tooling/support/plan_backlog_contract.dart test/tooling/plan_backlog_contract_test.dart` | 0 | Three changed Dart files checked; no formatting changes. |
| `autowork-run timeout 900 flutter analyze --no-pub` | 0 | No issues found. |
| `autowork tasks validate --worktree .` | 0 | 293 tasks, 36 goals, no pending entries; existing `FILES-TERMINAL-DOWNLOAD` draft unchanged. |
| `python3 "$TMPDIR/check_repair_docs.py"` | 0 | Scoped local links/anchors and protected-path preservation verified; repeated readback byte-stable. |
| `git diff --check` | 0 | Attributable diff is whitespace-clean. |

Remaining focused failure inventory: none. The unchanged full offline gate has
**not been run by this worker**; the coordinator/runner must retain its actual
merged-tree exit and failure inventory. The saved main verdict remains red;
these focused passes do not establish main green. No browser, native application,
Android/device, live Agent, provider, goal or delivery qualification was exercised
or advanced. Integration and full-suite acceptance remain with the coordinator.

Scoped Docs Sync Maintain updates this evidence owner only. Plan coverage policy
and CONTRIBUTING already describe the separate traceability/ledger checks, so
no policy, product, route or qualification documentation change is needed. The
CHANGELOG proposal is returned in the worker report for coordinator ownership.

## Queue and maintenance disposition

All open tasks were inspected: none owns this traceability failure. Keep one new
repair first in Now, with no dependency on closed MAIN-REPAIR-001 or the independent
Linux campaign. Its mutable files are the failing caller, helper, nearest unit
regression and this handoff. The Linux campaign's Touches are disjoint, but
CONNECTION-LINK-RETIREMENT and draft FILES-TERMINAL-DOWNLOAD retain `**` Touches
that overlap mechanically despite unrelated functional scope. Leave those entries
unchanged and preserve runner serialization/conflict guards; this ordering is not
admission to run overlapping tasks concurrently. Changed task records/receipt
from the recent commits are read-only investigation inputs; no broad application
Touches are justified.
No saved ledger proposal was supplied for this item or found under the inspected
repair/removal slot-data directories; no proposal was replayed.

Maintenance checklist:

- [x] Inspect all five current bundle artifacts in place and recent changed files.
- [x] Preserve the landed frontmatter repair and existing verified/manual closures.
- [x] Reproduce the residual failure on the documented SDK; record exact scope.
- [x] Add one bounded first-in-Now repair through the native task CLI.
- [x] Worker repairs and regression-tests coordinator-closure traceability.
- [ ] Runner's full unchanged offline check records the merged candidate's verdict.

Only Linux-host tooling tests were exercised in this maintenance pass. No browser,
Android/native app, device, live Agent, provider or delivery qualification follows.
Revisit when the failure inventory or repair candidate changes.
