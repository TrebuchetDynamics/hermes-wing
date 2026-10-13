# Agent-only delivery retirement

Card: t_587682e1. Implementation candidate based on
`918e7c318bab1d91f348570e2309598d729ecb9c`; independent review and canonical
integration/publication are separate, pending actions.

## Implementation and preserved boundaries

- Deleted the disconnected client/service trees, dedicated service tests/runners,
  both service bootstrap installers and unused Termux bootstrap asset.
- Removed Linux Go bundling, service build/smoke/release jobs, manifest inputs,
  auxiliary exports and shared native runner Go/module-copy prerequisites.
- Kept the shared Agent-only journeys, exact resource/owner fences, secure storage,
  TLS/origin validation, redaction and mutation-replay regressions. Production
  Agent behavior is unchanged; legacy raw records and secure slots remain inert.
- Current guidance now describes direct Agent connections and unavailable former
  management operations. Historical plans/receipts remain; old CLI/design/API
  documents are explicitly archived, not navigable setup alternatives.
- Release inventory/signature/digest/archive controls remain. Archive inspection
  rejects retired management/bootstrap payloads; synthetic client archives pass.
  Source absence and archive guards are falsified with restored dependencies.

## Admission and acceptance map

The original manifest-pinned `pass_workspace.py` command returned
`worker_start_admitted` before the first edit in run 308. The native process
ancestry confirmed this invocation is the card's sole worker. No repinning,
upstream/runtime changes, installed service operations or credential reads occurred.

- Consumer prerequisite: the initial focused Flutter consumer, enrollment/router,
  Local setup and credential-preservation baseline passed before deletion.
- Fresh/saved connections, direct reauthentication, rejected handoffs, cancel/back,
  reconnect and exact identities/no replay: retained Agent/enrollment/router/Local/
  profile/channel/storage tests; full acceptance command is `flutter test --concurrency=1`.
- Zero runtime management imports: tightened enrollment/domain source guards now
  have no retained-subtree or standalone-service exceptions; synthetic imports,
  exports, builders and restored subtree consumers are rejected.
- Zero service/bootstrap/delivery dependencies: `node --test test/tooling/*_test.mjs`,
  including `link_delivery_retirement_test.mjs`, release/CI/packaging contracts and
  deterministic archive-inspection falsification. Deleted Go tests are inapplicable.
- Shared native preparation/ownership/cleanup: Python tooling unittest discovery
  retains Agent/SSH and copied-dependency checks without Go setup. Existing cached
  AsyncSSH 2.24.1/cryptography 50.0.1 were used read-only for the SSH fixture.
- Compilation/browser dependency closure: Flutter analysis, deterministic
  `lib/main_e2e.dart` web build and default `npm run web:e2e`.
- Current docs: changed local links and diff whitespace checked; pre-existing
  ignored `.task-evidence` links are optional receipts, not new broken dependencies.

Final check argv, exit codes and exact local task commit are recorded by
`finish_task.py`. Logs live in the card's ignored `.task-evidence/t_587682e1/`
workspace directory; a missing local log is not proof of a pass elsewhere.
The first full-suite foreground attempt was interrupted at the tool's 420-second
limit, without a final result; it is not passing evidence. Final acceptance uses
an owned background process with explicit timeouts, not an altered test scope.

## Qualification and milestone gaps

Actual tools: Flutter 3.44.2, Dart 3.12.2, Node 26.7.0, Python 3.12.14.
The documented CI Node 22 pin and dependency locks are unchanged; local Node checks
ran on the installed version, not a fabricated Node 22 environment. Web build
reports existing third-party Wasm interop/font warnings, not JavaScript build failure.

This is offline Linux-host tooling and deterministic Flutter/Chromium evidence.
Linux GTK/native chooser, physical Android/Termux, live Agent authentication,
provider inference, installed service removal, signed distribution and production
release jobs are NOT_CHECKED. No live/provider/platform support is upgraded.

CONNECTION-LINK-REMOVAL consumer and connected CONNECTION-LINK-RETIREMENT source/
delivery implementation are handled as one candidate, not unilateral goal closure.
Existing live tasks remain pending. The coordinator owns independent approval,
canonical ledger reconciliation, integration and any authorized publication.
