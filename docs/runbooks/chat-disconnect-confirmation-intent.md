# Chat Disconnect confirmation intent

Status: implemented and verified; pending independent same-card review.
Linux-host deterministic widget and static checks passed. Native desktop,
browser, live Agent/provider, physical-platform, distribution and full-gate
qualification remain NOT_CHECKED. This is not integrated daily-use acceptance.

## Behavior

Disconnect confirmation belongs to the Chat owner that opened it. Before any
voice pause, queued-follow-up clearing, local approval clearing, directory
selection clearing or channel disconnect, Wing requires the screen to remain
mounted, the channel and directory instances to match, and the existing Chat
composer owner generation to remain unchanged. Returning to an earlier owner
does not renew its old consent. Obsolete confirmation closes without effects;
the user can open a new confirmation for the current connection.

Current confirmation still disconnects without deleting saved gateways. Cancel
is inert. Directory/contact display-label changes and informational channel
metadata alone do not invalidate consent. No remote authority is inferred from
labels and no new Agent state, transport, capability or automatic retry is added.

## Source boundary

- Desktop `hermes-disconnect-button` and compact More → Disconnect both use
  [the real Chat screen](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart)
  and the same
  [confirmation caller](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart).
- The caller captures the existing composer owner generation and directory before
  awaiting the modal. Its only `_disconnect` invocation receives that captured
  directory rather than rereading a potentially replaced provider.
- Existing Chat notification observation records channel, connected/disconnected
  status, endpoint, contact, selected profile, active session and unsettled
  restoration changes. Profile/session changes matter because Disconnect clears
  local conversation queues as well as disconnecting transport. This repair does
  not add a second owner registry or modify observation/lifecycle behavior.
- [Directory teardown](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart)
  owns remembered-selection clearing and active-channel disconnect. It and the
  channel implementation are unchanged. Admission occurs before teardown, not
  by trying to undo destructive work afterward.

No imports, dependencies, entrypoints, part declarations, localization or
packaging changes. The existing `part of '../hermes_chat_screen.dart'` delivery
boundary is unchanged, and its parent already imports HermesGatewayDirectory.
Upstream reference clones are read-only. No Desktop-specific disconnect behavior
or new runtime contract is asserted. Reauthorization, Connect cleartext consent,
saved-endpoint Reconnect and approval dismissal remain outside this task.

## Regression evidence

[The public-widget target](../../test/features/hermes_chat/screens/hermes_chat_disconnect_confirmation_owner_test.dart)
mounts HermesChatScreen and uses only visible hit-tested Disconnect/menu/modal
controls. Test-local channel notifications, directory notifications and Riverpod
provider changes are the deterministic asynchronous owner transitions. No private
callbacks, modal bypass or fake approval settlement is used.

At widths 1280 and 390, the target covers current confirm/cancel; channel/contact/
endpoint replacement and change-and-return; disconnect/reconnect, profile and
session roundtrips; directory provider replacement; Chat disposal while the root
modal remains; and informational metadata and display-label controls. Additional
active-work cases queue a follow-up with the visible composer Send action, emit
an approval through the channel stream, then change and return the contact before
confirmation. Stale consent preserves both visible queues and the draft.

Operation assertions require zero stale directory calls, disconnects, selection
clears, endpoint saves/deletes/clears, sends, session creation/selection/mutations,
profile selection and approval responses. Draft comparison is taken after owner
notifications, so legitimate owner-transition draft restoration is not attributed
to the late confirmation. Existing connection-loss queue reset is not overridden.
Directory instance resurrection is not tested: ChangeNotifierProvider disposes
replaced instances, so reusing a disposed instance would fabricate a contract.
Notification-silent reconnection epochs are not claimed as tested or identifiable
by the current Chat generation.

The identical final target against captured pre-edit production produced 8 passes
and 24 failures (exit 1), including erroneous directory calls and disposed-ref
exceptions. The repaired target contains 32 passing cases. The target plus the
three named neighboring regressions produced 130 passes (exit 0), including the
saved-gateway/no-auto-resume positive control.

```sh
# Widget commands run inside .task-evidence/t_eb5811e7/project.
flutter test --concurrency=1 --reporter expanded \
  test/features/hermes_chat/screens/hermes_chat_disconnect_confirmation_owner_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart \
  test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart \
  test/features/hermes_chat/screens/hermes_chat_reconnect_read_owner_test.dart
# Static checks run at the canonical repository root.
dart format --output=none --set-exit-if-changed \
  lib/features/hermes_chat/screens/state/hermes_chat_connection.dart \
  test/features/hermes_chat/screens/hermes_chat_disconnect_confirmation_owner_test.dart
flutter analyze
git diff --check -- \
  lib/features/hermes_chat/screens/state/hermes_chat_connection.dart \
  test/features/hermes_chat/screens/hermes_chat_disconnect_confirmation_owner_test.dart \
  docs/runbooks/chat-disconnect-confirmation-intent.md
```

Task-owned copied lib/test/assets/manifests and offline dependencies isolate test
build output from retained root flutter_tester processes. Earlier harness
failures (double directory disposal, active-animation settling, compact Send
rebuild timing) and the fixed unused import are retained in evidence, not counted
as product RED. Final baseline replay uses the same final oracle as repaired
execution. Source hashes, logs, exact commands and baseline-relative task patch
are under `.task-evidence/t_eb5811e7/`.

The local agent-branch snapshot includes inherited full-file bytes from the dirty
connection file. The baseline-relative patch, not the snapshot's HEAD-relative
diff, isolates this task's change. Independent native same-card review determines
final approval. See [client ownership](../adr/client.md#transport-qualification)
and [the daily-use matrix](../plans/2026-10-03-desktop-daily-workflow.md#acceptance-matrix).
