# Profiles mutation intent

## Scope and behavior

Card `t_eb72edbe` repairs existing-profile rename and delete intent in the actual
Profiles screen and editor. Hermes Agent remains the profile authority; this
change does not add native capabilities or expand Wing Link compatibility.

An existing editor, its row callbacks, destructive confirmation and local-approval
retry belong to the management source that opened them. A source change does not
reinterpret the same profile ID or revision on another host. The screen captures
the client, source-owner token, target ID and operation-specific revision. It
checks provider replacements before a widget frame and checks ownership again
before reconciliation, conflict reload and inventory reload.

The sheet uses the existing source notification and owner predicate for existing
profiles as well as Persona. Its mutation generation binds confirmation and
settlement to the editor target, revision, channel and callbacks. Owner loss
clears pending deletion approval and obsolete busy/error state. Obsolete save and
delete actions are unavailable; Cancel remains available. Reopen an editor on the
current source for fresh intent. A same-frame A–B–A roundtrip does not revive the
old editor or approval.

Already-started requests cannot be undone. They use their original client and
exact operation target/revision; they are neither cancelled through an invented
API nor replayed through a replacement client. Obsolete settlements cannot
initiate reconciliation, old-source inventory reload, approval retention, error
feedback or editor navigation. Reconciliation or reads already started while
owned retain their existing contracts; this repair does not add cancellation or
transactional rollback to them.

Same-owner rename/delete still work. Conflict recovery reloads through the same
captured client, preserves the conflict message, and permits an explicit retry.
The server checks the submitted revision; Wing does not silently upgrade a stale
editor revision. Delete approval retry uses the exact original idempotency key,
target and delete action revision. A conflict without pending approval requires
fresh delete confirmation and a new request key.

Create/setup, provider configuration, Persona contracts, directory browsing and
backend APIs are not expanded by this repair.

## Executed regression evidence

All evidence is local deterministic Flutter widget execution, not a live exploit
or native desktop qualification. Fixtures use synthetic callback transports with
no sockets, credentials or personal runtime state.

Before any production edit, the actual `ProfilesScreen` → `ProfileEditorSheet`
regression opened A's editor, switched management to B and submitted Save.
The empty-write assertion failed: B received PATCH `/v1/profiles/coder` with
`name=renamed` and `revision=r-coder`. The production baseline and real RED log
were retained. The same regression is GREEN after the repair.

A second RED after the screen guard demonstrated obsolete delete confirmation
closing the editor despite no submission; the sheet guard repairs that settlement.
A later RED demonstrated a cached callback sending through the old directory
before a replacement-provider frame; direct provider-identity checks repair it.
The local directory-replacement harness explicitly observes its replacement via a
watched test-only provider. Earlier invalidation experiments were harness failures,
not product RED evidence.

The final focused run passed 174 tests, including 35 new mutation-owner cases:

- host change, visible and same-frame A–B–A;
- client factory, channel and directory replacement, including pre-frame callbacks;
- enrollment and read-authority loss;
- cached row/editor callbacks, delete confirmation and pending approval retry;
- delayed rename/delete success, error, conflict and approval after source change;
- disposal with cached actions and pending settlement;
- exact same-owner conflict retry and exact delete-approval idempotency.

The neighboring suite preserves existing create/setup, search/inventory,
profile lifecycle and Persona ownership/client/fidelity behavior.

Commands executed from the repository root:

```bash
flutter test --no-pub --concurrency=1 test/features/profiles/profiles_mutation_owner_test.dart
flutter test --no-pub --concurrency=1 test/features/profiles/profiles_mutation_owner_test.dart --plain-name 'obsolete delete confirmation'
flutter test --no-pub --concurrency=1 test/features/profiles/profiles_mutation_owner_test.dart --plain-name 'before a frame'
# Final focused run: 174 passed, exit 0.
flutter test --no-pub --concurrency=1 test/features/profiles/profiles_mutation_owner_test.dart test/features/profiles/profiles_screen_test.dart test/features/profiles/profiles_search_ownership_test.dart test/features/profiles/profile_editor_sheet_test.dart test/features/profiles/profile_persona_ownership_test.dart test/features/profiles/profile_persona_client_ownership_test.dart test/features/profiles/profile_persona_fidelity_test.dart
dart format --output=none --set-exit-if-changed lib/features/profiles/screens/profiles_screen.dart lib/features/profiles/widgets/profile_editor_sheet.dart test/features/profiles/profiles_mutation_owner_test.dart
flutter analyze --no-pub
```

Final formatting reported zero changed files; analysis reported no issues, exit 0.
Task-relative baselines, RED/GREEN logs and final validation receipts are retained
under `.task-evidence/t_eb72edbe/` in the local workspace. They are not release
artifacts or a replacement for the native Kanban approval lane.

SHA-256 source binding for the final focused test, formatter and analyzer:

| File | SHA-256 |
| --- | --- |
| `lib/features/profiles/screens/profiles_screen.dart` | `6a4dfae6aad03101cfaa4265a7f83e57e6ca8d808cca8852ea5aebbdaaaa77e2` |
| `lib/features/profiles/widgets/profile_editor_sheet.dart` | `6500a45435d0cf6b69b8c5758739c9ce2612745a7962fb21af322d9544512d97` |
| `test/features/profiles/profiles_mutation_owner_test.dart` | `1029453a368a93d132438466223c6c6d5c1ef98f8f2f3e5f2d46857e257541c8` |

## Review and qualification limits

Card `t_eb72edbe` is completed with same-card native review approval in run 119.
The reviewer independently reran all 174 focused tests, analysis and changed-file
formatting successfully. The reviewer also verified six final file fingerprints,
the task-relative diff and eight affected local links. Independent review and
native approval close this bounded repair, not the integrated workflow.

The retained review archive is `.task-evidence/t_eb72edbe-review-evidence.zip`.
Its SHA-256 is `bb56d33b55ae9668142e6c3e2cc8bbe6bdb261e6f12defd6d336b4d6b137eb97`.
This documentation pass inspected the archive and live approval; it reran no tests.

Native desktop interaction, physical local approvals, live backend, compiled
browser, full suite, full integrated workflow/parity, packaged execution, signed
distribution and release remain `NOT_CHECKED`. No upstream, Wing Link API, runtime,
packaging, installation or privileged changes were made.

## Related boundaries

- [API/state and fresh destructive intent](../adr/api-and-state.md)
- [Client owner/generation fences](../adr/client.md)
- [Stable destructive resource identity](../security/threat-model.md)
- [Profiles route](../product/routes.md)
- [Existing profile search](profile-search.md)
- [Persona ownership](persona-ownership.md)
