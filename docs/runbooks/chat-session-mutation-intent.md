# Chat session mutation intent

Chat rename, branch, single delete, and bulk delete confirmations belong to the
connection/profile that opened them. A surviving dialog cannot transfer its intent
to a replacement owner, even when that owner has the same opaque session ID.

## Implemented behavior

The shared session action wrapper snapshots the channel, connected origin,
selected profile and active gateway contact. It observes channel, provider and
directory changes for the lifetime of the dialog and submitted operation. Owner
loss, disconnection, pending profile selection, unsettled restoration, exact
operation authorization loss, or disappearance/ineligibility of an unsubmitted
row invalidates the intent permanently. Returning to the old owner before the
next frame does not revive it.

Admission reuses the existing channel state's operation-specific authorization
policy and requires a currently known session ID. Session reads do not grant a
mutation. Rename retains its nonblank/changed-title rules; branch and delete
retain their non-streaming eligibility rules.

A stale confirmation closes normally but submits no mutation. Reopen the action
in the current owner to provide fresh intent. This repair does not introduce new
copy or a new session-management feature.

Bulk deletion rechecks intent before each request and after each await. Already
submitted work may finish at its original server; owner loss stops subsequent
requests, draft cleanup, contact refresh and stale success/error feedback. Normal
same-owner bulk deletion still reports bounded partial failure and continues after
a failed request. Observers are removed on completion, cancellation and route
disposal, even if the dialog remains on the root navigator after Chat unmounts.

Hermes Agent remains authoritative. There is no offline mutation queue, replay,
new transport contract, Wing Link request, or shadow session store.

Public New Session and session-row Open settlement now have a separate,
caller-only owner fence. Their legitimate active-session transitions are not
mutation-confirmation invalidations; see the
[session settlement runbook](chat-session-settlement.md) for scoped behavior,
production error characterization and deterministic verification.

## Executed regression evidence

On the pre-repair dirty source at HEAD
`ca149a82189c8c9e5abd98b376bfeae1e43f6f3f`, an actual wide Chat widget opened Rename
for profile A, changed the channel to profile B with the same `target` ID, and
confirmed. The expected empty mutation list failed: the recorded rename targeted
profile `b`. This was an executed widget reproduction, not a live Agent exploit.

```sh
flutter test test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart --plain-name 'rename rejects cross-profile same-ID confirmation at 1280.0'
```

RED exit 1 was saved before production changes. After repair:

```sh
flutter test test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart
flutter analyze
flutter test test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart
flutter test test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/screens/hermes_chat_profile_picker_test.dart
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/session/hermes_chat_session_actions.dart lib/features/hermes_chat/screens/hermes_chat_screen.dart test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart
```

Results: 136 new mutation-owner tests passed, 75 gateway-switch tests passed,
57 nearest owner/restoration/profile-picker tests passed; analyzer found no
issues; changed Dart formatting reported zero changes. The new tests exercise
both the 390-wide compact sheet and 1280-wide rail using the real Chat widget,
in-memory provider overrides and a task-local fake. They cover all four stale
confirmations, A→B→A, origin change, disconnect/reconnect, pending selection,
channel replacement/return, row removal/return, missing write operations, revoked
write grants with session reads retained, unmount, same-owner success/Cancel,
nonblank rename, partial bulk failure, and late success/error without replacement
draft cleanup or feedback.

The existing screen presentation generation does not observe every required
selection/authorization transition. A local lifetime observer provides the latch;
a four-line screen disposal hook is necessary to remove it while a root-navigator
dialog outlives Chat. The initial observer iteration reproduced a leftover task
listener at disposal; the final unmount tests assert only the pre-existing inert
directory listener remains.

## Evidence boundary

Receipts, baseline bytes/diffs, fingerprints and the Wing-local journal are stored
under the executing Wing profile's `autogoal/session-mutation-intent/` directory.
These results apply to the deterministic Flutter widget runner on Linux, not a
native desktop interaction or compiled browser journey. Predecessor dirty edits
were preserved and are not attributed to this repair.

NOT_CHECKED: compiled browser, native desktop/device, physical Android, screen
reader, live Agent/provider, full daily-workflow/parity and release acceptance.
No live Agent requests, credentials, network installs, upstream edits, commits,
pushes or deployment were part of this task.

Authority: [API and state](../adr/api-and-state.md) and
[authorization threat model](../security/threat-model.md#authorization).
