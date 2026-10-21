# Plan traceability for existing hash-suffixed task IDs

## Scope

Status: Accepted

The owner asked to find plan gaps and add missing plans. The narrow uncovered
outcome is **correct task-ID recognition by the existing traceability tests**.
This plan books a future regression fix; it does not authorize editing tests or
application code during the current documentation pass. Preserve current priorities,
all existing identifiers and the project ledger/body grammar.

## Observed failure and root cause

The real baseline command `flutter test --no-pub --reporter expanded
test/tooling/plan_backlog_traceability_test.dart` failed: 31 plan files, 30 mapped
entries. Documentation repair added the missing MCP mapping, Backlog connection
and bare plan backlink from `DEV-001-c7`; the next real run failed **Current plan
has no tasks: docs/plans/2026-10-18-flutter-mcp-architecture.md**.

- [mapping extraction](../../test/tooling/plan_backlog_traceability_test.dart)
  uses uppercase-only `[A-Z][A-Z0-9-]+` at the task-ID extraction.
- [body lookup](../../test/tooling/support/plan_backlog_contract.dart) also uses
  uppercase-only IDs in bold checkbox markers.
- Valid existing IDs such as `DEV-001-c7`, `WING-001-b3` and the PARITYUPDATE IDs
  therefore fail recognition. Renaming, uppercasing or replacing those IDs would
  hide the parser defect and break literal identity preservation.

## Smallest complete implementation

1. Reproduce the failure against a candidate with the corrected plan index.
   Support the actual ledger ID grammar at the existing two extraction points;
   keep marker boundaries and ledger validation. No new parser abstraction.
2. Extend [existing support tests](../../test/tooling/plan_backlog_contract_test.dart)
   for hash-suffixed IDs, retaining the uppercase cases and prefix-neighbor,
   adjacent-body-link, duplicate, checkbox/status, archive-location and invalid-state
   guards. Test both `DEV-001-c7` and a distinct adjacent/prefix-neighbor ID.
3. Run the real inventory check against all current retained plans, not a frozen
   plan count or isolated mock map. Do not weaken direct source-anchor/bare-plan
   backlinks, dispositions or missing/duplicate plan detection.

## Acceptance and verification

- All current plans map to exact indexed task IDs. Ordinary uppercase and valid
  hash-suffixed IDs resolve exactly one appropriate bold live/archive body.
- Open/in-progress must remain unchecked live; done must have checked x/X body in
  the permitted location. Missing/duplicate bodies, invalid status, checked-open,
  unchecked-done, archived-open and adjacent/prefix ID confusion still fail closed.
- No ID/status/dependency/ownership/order, acceptance, live grant, application source
  or dependency changes. The metadata-only repairs are already this planning pass's
  work and must not be booked again.

Planned implementation checks, not current GREEN results:

```sh
flutter test --no-pub test/tooling/plan_backlog_contract_test.dart test/tooling/plan_backlog_traceability_test.dart
dart format --output=none --set-exit-if-changed test/tooling/plan_backlog_traceability_test.dart test/tooling/support/plan_backlog_contract.dart test/tooling/plan_backlog_contract_test.dart
flutter analyze --no-pub
git diff --check
```

The current traceability failure is explicit and expected to remain until this
implementation occurs. A valid docs ledger/readiness result does not erase a red
source-tooling test or certify any product/runtime capability.

## Backlog connection

`PLANGAP-001-2f` in [work queue](../tasks/work-queue.md#current-work-queue) owns this small tooling regression under
`INTEGRATION`; no product/device task is its prerequisite. The
[plan-to-task coverage](README.md#plan-to-task-coverage) indexes it. Sources must
include the exact accepted section and a bare full-plan link. Preserve the current
queue order; no worker, commit, push or scheduler change is authorized here.
