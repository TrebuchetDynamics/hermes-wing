# Main repair evidence refresh: 8a393cc1

Evidence supplement for [MAIN-REPAIR-001](../../tasks/items/MAIN-REPAIR-001.md).
Its [accepted repair handoff](main-offline-test-repair.md) remains authoritative;
this supplement does not change acceptance, close the task or admit another repair.

## Current bundle

Inspected in place under the Git common directory, without copying raw artifacts:
`autowork-execution/main-evidence/8a393cc1bb255ad88b3f99678138aa0ac9ff1d82/`.

- `main_check.json`: `state=red`, `result_class=TEST_FAILURE`, checked revision
  `8a393cc1bb255ad88b3f99678138aa0ac9ff1d82`, previous green
  `66c8a28e02863bc49f0c83d284e9cce712cdc04f`, red since
  `c746ad997d6d5c7f48eb3e69a63ba36f1df9554a`. The full intervening commit list
  is retained there; latest commits are `8a393cc1` (manual live-task closures),
  `c746ad99` (integration) and `2d3d661d` (earlier check evidence).
- `main-check.log`: terminal line 4709 is
  `26:13 +4137 ~9 -5: Some tests failed.`
- `main-check.exit`: `1`; `main-check-reruns.log`: empty;
  `flaky_history.json`: `{}`. There are no isolated reruns or three-revision
  flaky passes in this bundle. The framework's `Bad state: No element` is a
  reported test exception, not a crash before results.

The same five test names remain covered by MAIN-REPAIR-001:

| Test | Current evidence |
| --- | --- |
| `test/tooling/plan_backlog_traceability_test.dart`: every retained plan has an explicit canonical backlog disposition | Lines 213–216 now fail with `FormatException: PARITY-LIVE-WORKFLOW-LIVE needs exactly one task body; found 0`, at `support/plan_backlog_contract.dart:65` via `plan_backlog_traceability_test.dart:54`. This is **not** the older 34-versus-35 plan-count failure described in the accepted handoff. |
| `test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart`: Contact departure confirmation system back at 1280.0 and 390.0 | Lines 1413–1435 and 1457–1479 report no confirmation dialog at test line 368. The existing focused-composer Back investigation and owner/work-retention assertions remain applicable. |
| `test/router/chat_workspace_overlay_test.dart`: shell /settings retains mounted chat/full location via back at 390.0 and 1200.0 | Lines 3570–3597 and 3612–3636 report absent Chat/category-chat at test lines 611/613. Preserve the separate Voice-category behavior and mounted-chat/full-location assertions. |

## Traceability diagnosis changed after manual closure

Read [the traceability caller](../../test/tooling/plan_backlog_traceability_test.dart),
[its helper](../../test/tooling/support/plan_backlog_contract.dart),
[nearest helper tests](../../test/tooling/plan_backlog_contract_test.dart) and
[PARITY-LIVE-WORKFLOW-LIVE](../../tasks/items/PARITY-LIVE-WORKFLOW-LIVE.md).
Commit `8a393cc1` changes that native task to `status=done`, with explicit manual
closure provenance and an owner waiver of the live follow-up, not live proof.
The caller treats every done record as archive-backed and calls `planTaskBody`
instead of using its canonical native record body. The helper then requires a
historical checkbox body that this native follow-up does not have. Do not reopen
that task, manufacture an archive receipt, mark a goal verified, or undo the
owner's closure merely to satisfy this stale assumption.

When MAIN-REPAIR-001 is mutable again, retain its ID and every acceptance item.
Its existing retained-plan acceptance covers this changed failure in the same test.
The worker should reconcile native/manual closure with frozen archive-backed
history, preserving identity, malformed-record rejection, exact body isolation,
backlinks and historical archive guards. In addition to its existing Touches,
inspect and, if needed, declare `test/tooling/support/plan_backlog_contract.dart`
and `test/tooling/plan_backlog_contract_test.dart`; these are the precise shared
helper and nearest regression paths, not broader product scope. Keep its existing
focused checks and add the helper regression target if changed. The full check
remains the unchanged [documented offline check](../../AGENTS.md#validation):

```sh
flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1
```

Relevant earlier source commits remain `cfe5662b` (literal-clone plan), `6c82c059`
(composer Back), `7f2f166e` (Voice category), and `3ecdaea0` / `dba56cad`
(category intents and URL identities). Their changed Wing paths are already in
the task's Touches; do not absorb unrelated live-task files changed by the waiver.

## Pending candidate: preserve the frozen entry

The saved `slot-data/MAIN-REPAIR-001/attempt-1/report.json` names candidate
`17a3034c8f6a7a223c40754fc4638285cea4b8b3`. Its reported changed files are the
plan index, literal-clone plan, original repair handoff and two Back fixtures.
It reports 159 focused passes on Flutter 3.44.2 / Dart 3.12.2, formatting and
analysis passes, and no worker full-suite run. These are historical worker claims,
not a fresh check of this revision or proof that the new closure failure is fixed.
Neither the traceability helper nor its caller is changed by that candidate.

At this inspection the slot is `reported`, the supported canonical repository
status lists MAIN-REPAIR-001 as `implemented` with one candidate awaiting
integration, and candidate `17a3034c` is not an ancestor of this checkout's HEAD
`e381a80fcfb137de5f25946a8b081174b79260b3`. Its record is therefore left untouched,
including Evidence, Touches, Checks and first-in-Now placement. No duplicate task,
forced restart, integration bypass or closure is introduced. This separate file
also avoids editing the handoff already changed by that pending candidate.
No saved ledger patch is present in this task's attempt directory.

The precise remaining blocker to a task-record refresh is the pending candidate's
integration disposition. After that disposition, refresh the existing record
through `autowork tasks field` from this evidence if it remains open; do not undo
any newer closure or planning. Normal review and merged-tree full-check results,
not the focused report, determine completion.

## Maintainer validation boundary

This pass changes only this evidence supplement. Run native task-store validation,
local-link/source-reference checks and `git diff --check` before committing.
No Flutter, browser, native/device or live-Agent check is performed or claimed.
The detached-checkout `autowork status .` command refused inspection; read-only
`autowork status` against the canonical repository supplied the state above.
No branch switch or canonical write was made.
