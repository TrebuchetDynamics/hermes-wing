# Official feature-matrix rebuild

## Scope and verdict

This records the earlier rebuild. The [October 18 refresh](official-desktop-parity-refresh-2026-10-18.md) now owns the current matrix snapshot; its source changes do not invalidate or rerun historical Wing receipts.


`PARITY-OFFICIAL-MATRIX` rebuilds the [human matrix](../product/hermes-desktop-feature-matrix.md)
and [JSON](../product/hermes-desktop-feature-matrix.json) from the official
`hermes-agent/apps/desktop` checkout. This is documentation/source mapping only.
No product code, Agent runtime, task status, lease or platform receipt is changed.
No upstream app or test suite was executed. Linux/Android runtime cells remain
`not_run`; there is no blanket parity certification.

## Source identity and method

- Read-only Agent pin: `158fd638da1629c8e62caf9ade1515d162def8ab`.
- Desktop tree: `2038178ee53e13cde6fe297daa2484a868e7d3a3`.
- Wing implementation baseline: `5c6ccdf3ea6b1df22aa3f797977fcc21fd690859`.
- Official source: [pinned Desktop](https://github.com/NousResearch/hermes-agent/tree/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop).
  The isolated Wing worktree does not contain the reference clone; inspection
  used the repository's permanent read-only reference, without copying or updating it.

Read upstream root/Desktop/src guides, README and DESIGN before source tracing.
Fresh row references have line ranges, pinned URLs and SHA-256 fingerprints;
supporting sources carry their own fingerprints and bounded observations. Current
bytes are checked against the committed pin, not just a branch name. Official
test paths are nearest inspection leads, **not passing-test receipts**. Some
assertions were read; others are recorded only as leads for the next operation trace.

The route inventory is reconciled to `src/app/routes.ts` and the contribution
rendering seam. JSON `route_coverage` assigns every built-in route to a feature
group; bundled plugin loading is separately recorded. Grouping does not imply an
exhaustive census of controls, extension behavior or backend capabilities.

The [bounded knowledge study](../analysis/official-desktop-graphify.md#bounded-knowledge-study-and-planning-consequences)
remains a lead, not authority. Bootstrap imports, contribution registration and
pane subscriptions are distinguished from semantically traced request ownership,
lease release, send/input/Stop handlers and replay assertions. Deeper Settings,
native IPC, update rollback, Projects/backend authority, tool rendering, slash
catalog/dispatch and accessibility remain unverified where not traced end to end.

Notable corrections:

- Official first-run offers an existing connection or deliberate local bootstrap;
  Wing's welcome and metadata-only/manual local preparation remain explicit gaps.
- Wing has native SSH forwarding code; the old external-tunnel-only description
  is not current. That code is not proof of official SSH startup/lifecycle parity.
- Official export fetches all session messages and downloads JSON; Wing's
  loaded-only text/Markdown export is not the same operation.
- Messaging pairing is not Wing Link pairing. Retired pairing/trust and Office
  groups are not official feature admissions. Canonical Bots and Starmap are distinct.
- Cloud topology, Nous free tier and provider OAuth are not interchangeable.
- Memory provider configuration is not proof of a memory-entry CRUD browser;
  optional Kanban registration is not proof of board interaction semantics.
- Desktop Stop optimistically settles presentation and requests interruption.
  Wing's authoritative terminal/history reconciliation remains required; local
  stream cleanup or an interrupt acknowledgment cannot establish stopped work.

## Historical mapping preservation

JSON `historical_mappings.rows` retains each prior ID, outcome name, goal, existing
and remaining task IDs, qualification-task IDs, receipt attribution and runtime
result values, where present. Those are **historical associations**, not fresh
feature support or new ownership. Fresh rows explicitly associate relevant legacy
IDs; new feature-group IDs are not new backlog task IDs. TODO/goals remain untouched.

Prior source paths, candidate-flow assignments and feature/status totals are not
transferred. New source and verification candidates are rechecked individually.
The former [next-slice receipt](desktop-next-port-slice.md) retains its historical
checks and totals, but its script/next-slice contract is not current authority.
`scripts/check_desktop_next_port_slice.py` targets the retired checkout/schema;
it is **not** a validator for this rebuilt matrix. Do not revive or repin it merely
to obtain a passing historical mapping count.

## Retained Wing behavior evidence

Existing receipts stay unmodified. Their prior Desktop comparisons remain withdrawn:

- [Entry labels](connection-entry-labels.md), [saved endpoint edit](saved-endpoint-edit.md),
  [global session modal](global-session-modal.md), [session search/resume](session-search-resume-journey.md),
  [fork](session-fork-journey.md), [dictation](chat-direct-dictation.md) and
  [reasoning disclosure](reasoning-disclosure-implementation.md) record bounded Wing behavior,
  not official feature qualification.
- [Approval/attachment fixture](android-approval-attachment-fixture.md) records seven
  Flutter widget passes; Android startup failed before launch and Android assertions
  remained NOT_CHECKED. It does not qualify approval/Stop/resume/attachments on-device.
- The withdrawn matrix recorded `npm run test` results of **3,501 passed, zero failed**
  and later **3,504 passed, zero failed**, both exit **0**. These were shared/changed
  worktree receipts, not fresh tests on the rebuilt official mapping.
- Its syntax pass recorded **58 YAML files** passing Maestro syntax with CLI `2.4.0`.
  It also recorded an unauthorized Android target and native Linux prerequisite
  failure (exit **2**, missing libsecret/GStreamer metadata), not rendered flows.
- Original optional local artifacts remain identified by
  `.task-evidence/parity-flow-matrix/{npm-test-result.json,npm-test.log,flow-inventory.json,syntax-results.json,preflights.json}`
  and `.task-evidence/parity-matrix-refresh/direct-npm-result.json`. Their absence
  from a fresh clone is not fresh failure or permission to invent replacement receipts.

Later [native serve chat](local-serve-production-chat.md),
[restoration](local-serve-restoration.md) and [workspace overlay](chat-workspace-overlay-native.md)
receipts remain bounded to their own builds/targets/fixtures. None fills the new
matrix's target cells automatically.

## Offline validation and update triggers

For this documentation slice:

1. Pin the permanent official checkout with `git -C <reference> rev-parse HEAD`.
2. Parse JSON; check unique IDs and JSON/Markdown row agreement, all built-in
   route mappings, source line ranges, committed-byte SHA-256 and pinned URLs.
3. Verify every Wing source, candidate/launcher path and changed Markdown link.
   Compare retained historical task/result fields with the Wing baseline JSON.
4. Run `flutter test --no-pub test/tooling/`, then `git diff --check`.
   These are host-side offline checks, not native Linux or Android execution.

Revisit mapping when the official pin changes, a traced action/contract changes,
Wing routes or candidate harnesses change, or a named-target receipt is admitted.
Do not advance a runtime cell when only source mappings, test leads or hashes change.

## Pending named-target acceptance

`PARITY-NATIVE-LINUX` and `PARITY-MAESTRO-ANDROID-DEVICE` retain separate execution.
Each row specifies a Linux and Android verification path; unsupported operations
must remain unavailable until exact authoritative contracts exist. A manual path
is not a completed harness or positive coverage. Owned native launchers in JSON
must be used where candidates enforce sandbox/display guards.

Capture actual build/OS/device/display/driver and source/flow identities, explicit
operations, authoritative effects, recovery and redacted logs. Distinguish fixture,
live Agent/provider, native plugins, keyring/keystore, physical audio, IME and
assistive technology. No live authentication, inference, physical Android, native
GTK interaction, distribution/rollback or screen-reader acceptance ran in this task.
