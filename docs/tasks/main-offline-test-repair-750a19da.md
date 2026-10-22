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

The [caller](../../test/tooling/plan_backlog_traceability_test.dart) lines 54–62
uses the canonical record body only for `closure == 'manual'`. Every other done
record is sent to the historical checkbox lookup with an empty live body. But
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
  Run the focused pair, changed-Dart formatting, analysis, native task validation
  and the unchanged [full offline check](../../AGENTS.md#validation):

  ```sh
  flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1
  ```

  Retain actual exits and remaining inventory. Do not report main green from
  focused passes, hide failures, skip cases, filter the full suite or invent
  coordinator/device/live acceptance. No SDK/runtime/Agent changes are authorized.

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
- [ ] Worker repairs and regression-tests coordinator-closure traceability.
- [ ] Full unchanged offline check records the resulting candidate's verdict.

Only Linux-host tooling tests were exercised in this maintenance pass. No browser,
Android/native app, device, live Agent, provider or delivery qualification follows.
Revisit when the failure inventory or repair candidate changes.
