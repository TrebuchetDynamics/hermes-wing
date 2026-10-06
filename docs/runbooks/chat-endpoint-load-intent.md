# Saved endpoint loading and connection-form intent

Status: implemented; Linux-host deterministic widget/static evidence. Native,
browser, live Agent, physical Android, packaged delivery and full parity are
NOT_CHECKED. Card `t_323250d0` is completed and independently approved in
same-card review run 272. The review lane is not native application execution.

## Contract

A delayed saved-gateway read must not overwrite newer manual connection-form
intent. Editing a label, changing an origin and returning to its initial value,
or explicitly choosing a preset claims the form. Retrying a failed read does
not release that claim. Loading still exposes the saved rows, and deliberately
selecting one fills the form without connecting or persisting anything.

An untouched form retains the existing autofill rule: an empty or default local
origin with an empty credential may receive the first saved endpoint. Focus,
selection/caret changes and credential visibility alone do not claim the form.
The initial origin comes from `WING_HERMES_BASE_URL`, which is empty without a
build define; the local preset is `http://127.0.0.1:8642`.

The form tracks text changes and explicit `applyProfile`/`clear` actions with a
one-way pristine-state fence. Even a same-value preset claims intent. Controller
listeners belong to the form and are disposed with its controllers. This fence
is read only by saved-endpoint autofill. The normalized, trimmed connect attempt
staleness rule is unchanged; cosmetic origin edits do not newly invalidate a
connect result.

There is no new network request, persistence operation, credential acquisition,
channel state, protocol field or shadow Agent state. See the
[client architecture](../adr/client.md) and accepted
[daily-use workflow](../plans/2026-10-03-desktop-daily-workflow.md).

## Executed characterization

`test/features/hermes_chat/screens/hermes_chat_endpoint_load_intent_test.dart`
mounts the real `HermesChatScreen(initiallyEditingConnection: true)`. A delayed
`FakeHermesEndpointStore.loadProfiles` completer controls read settlement. The
channel and gateway directory are deterministic existing fakes. The directory
has its own empty store, so it cannot consume the manual-form read or perform
background discovery. Public TextFields and hit-tested controls are the oracle;
no private callback or disabled-control bypass is used.

Both 1280×900 and 390×844 surfaces run with the Linux platform test variant:

- Label-only edit at the actual empty default origin and empty credential.
- Origin edit away and back to that default.
- Developer shortcuts expanded publicly, then local preset chosen twice.
- Untouched autofill followed by deliberate selection of a different saved row
  after a manual edit.
- Load error/retry with and without an earlier edit; error detail stays hidden.
- Unmount before the read settles.

All cases assert zero connects, disconnects, sends, session create/select/
rename/delete/fork, profile selection and endpoint save/saveAll/delete/clear.
Saved rows remain available after settlement. Safe `.invalid` origins and empty
credentials are used. Three added form unit controls cover edit-and-return,
same-value actions, and caret/masking non-intent.

The final identical widget oracle on captured pre-repair production returned
exit 1: eight actual overwrite failures and six passing controls. Label intent
expected `Manual label` but received `Saved gateway`; preset intent expected an
empty label but also received `Saved gateway`. Repaired production returned
exit 0: all 14 cases passed. Early harness attempts (wrong initial-origin
assumption, animation settling and platform cleanup) are not defect evidence.
The final RED has no timeout or foundation-invariant failures.

## Validation

Executed in the byte-identical isolated Flutter closure at
`.task-evidence/t_323250d0/project`, avoiding root build output and the retained
orphan tester. No process was killed. The closure includes all current
`lib`, `test`, `integration_test`, `assets`, and `tools`, plus `pubspec.yaml`,
`pubspec.lock`, `analysis_options.yaml`, and `l10n.yaml`. Flutter imports remain
within the existing app boundary; no module, dependency or packaging change
was added. Closure hashes and baseline-relative patches are task-local receipts,
not packaged execution evidence.

```sh
flutter test --concurrency=1 --reporter=expanded \
  test/features/hermes_chat/screens/hermes_chat_endpoint_load_intent_test.dart \
  test/features/hermes_chat/screens/hermes_chat_screen_android_endpoint_test.dart \
  test/features/hermes_chat/controllers/hermes_connection_form_test.dart \
  test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart
flutter analyze
```

Result: 124 tests passed, exit 0; analyzer reported no issues, exit 0. Changed
Dart files passed `dart format --output=none --set-exit-if-changed`; repository
`git diff --check` and changed-document local-link validation passed. Android
endpoint widgets are deterministic checks, not physical Android qualification.

## Scope and handoff

Only the form controller, saved-load guard, nearest controller tests, new widget
characterization and this runbook were changed. Inherited dirty edits, including
completion-focus/reconnect changes in the lifecycle extension, remain intact.
No upstream, Agent, Wing Link, backend, routing or platform implementation was
changed. The [connection-authority rules](../../CONTEXT.md) remain unchanged.

The card contains conflicting snapshot instructions: acceptance requests a local
agent-branch commit, while its final execution paragraph explicitly prohibits
commits. No commit, stage or branch mutation was performed. A baseline-relative
patch and scoped fingerprints are prepared for independent native same-card
review. Snapshot authorization is an administrative question, not a gate on
implementation or review entry. No native/live/full-suite qualification is
claimed or consumed by this local slice.
