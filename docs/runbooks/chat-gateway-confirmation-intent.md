# Chat contact-departure confirmation intent

Status: implementation verified; independent same-card review pending.
Evidence is Linux-host deterministic Flutter widget execution, not native desktop,
browser, live Agent/provider, full-suite or distribution qualification. Those
remain NOT_CHECKED. This is not integrated daily-use acceptance.

## Behavior

The active-work **Switch chats** dialog opened by **Back to contacts** or system
back belongs to the Chat owner that opened it. Before pausing voice, clearing
follow-ups or pending approvals, or leaving the contact, the caller requires:

- the original screen to remain mounted;
- the original channel and directory provider instances; and
- the original existing composer-owner generation.

Channel, connection, endpoint, contact, profile and session transitions invalidate
that generation. A change followed by a return does not renew old consent.
Stale Switch closes the modal without departure effects. Stay remains inert.
Current Switch still clears local pending work and calls the captured directory's
existing selection-clear/disconnect path. Display labels and informational
metadata do not invalidate consent; legitimate background streaming still raises
the guard and current consent can leave it.

No new Agent capability, shadow state, automatic mutation replay, localization,
import, dependency or lifetime observer is introduced. The boolean dialog itself
is unchanged: admission belongs to its callers after the asynchronous result.

## Source and reachability

[The Chat screen](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart)
contains both departure callers. `_showGatewayContacts` captures the directory
and generation before awaiting consent, then checks ownership before every local
side effect and uses that captured directory. `_openGatewayContact` applies the
same admission before its local effects and activation. The existing
`_syncAttachmentOwner` and directory/channel notification observation remain
unchanged; metadata is not treated as resource identity.

`_openGatewayContact` has one production caller: `GatewayContactsView.onOpen`.
The view is built only when `showingDirectory` is true, which requires
`directory.activeContactId == null`. Therefore its active-contact confirmation
branch is not exposed through contact rows in a stable public screen. The tests
prove rows cannot be hit-tested in the active-work modal flow and prove a row can
invoke activation without that modal when the directory is visible. They do not
fabricate a stale `_openGatewayContact` confirmation or call a hidden callback.
A synchronous directory activation spy counts that invocation; the existing
[gateway-switch target](../../test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart)
exercises actual directory activation and saved-gateway behavior.

The original [Disconnect repair](chat-disconnect-confirmation-intent.md) and
[approval-dismissal repair](chat-approval-dismissal.md) are separate consent
contracts. Their production files and regression targets are unchanged. Retesting
Disconnect does not constitute its independent final review, and changing screen
bytes does not inherit predecessor source-bound qualification.

## Regression and checks

[The new public-widget target](../../test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart)
uses visible hit-tested Back to contacts, Stay and Switch controls, system back,
real HermesChatScreen dialogs, channel/directory notifications and Riverpod
provider replacement. No private callbacks or modal-barrier bypass are used.

At widths 1280 and 390 it covers:

- unchanged Switch and Stay, and system-back departure;
- channel/contact/endpoint change and change-return;
- disconnect/reconnect, profile and session roundtrips;
- directory provider replacement;
- disposal of Chat while the root modal remains visible;
- informational metadata, display-label and background-work positive controls;
- stale consent retaining a visibly queued follow-up, pending approval and draft;
- zero stale directory/activation/disconnect/selection-write calls and zero
  endpoint, message, approval, profile or session mutations.

Draft comparison in owner-transition cases is taken after notifications, so
legitimate draft restoration is not mistaken for a late-dialog effect. Existing
connection-loss queue reset is not changed. Directory-instance resurrection and
notification-silent owner epochs are not claimed. Disposal is a passing safety
control on the baseline too; the authentic RED is wrong-owner departure, not a
claimed disposal exception.

The identical final oracle against the captured pre-edit screen produced 16
passes and 22 failures (exit 1). Repaired execution of the new target plus the
three required neighboring targets produced 247 passes (exit 0).

Commands:

```sh
# Tests run in .task-evidence/t_bf512e72/project with offline dependencies.
flutter test --concurrency=1 --reporter expanded \
  test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart
flutter test --concurrency=1 --reporter expanded \
  test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart \
  test/features/hermes_chat/screens/hermes_chat_disconnect_confirmation_owner_test.dart \
  test/features/hermes_chat/screens/hermes_chat_session_settlement_owner_test.dart
# Static checks run at the canonical repository root.
dart format --output=none --set-exit-if-changed \
  lib/features/hermes_chat/screens/hermes_chat_screen.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart
flutter analyze
git diff --check -- \
  lib/features/hermes_chat/screens/hermes_chat_screen.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart \
  docs/runbooks/chat-gateway-confirmation-intent.md
```

Canonical analysis passes with no issues after two test-local lint corrections;
formatter, scoped whitespace and local-link checks pass. Final RED/GREEN logs,
source fingerprints, protected-file comparison, baseline status and the task-only
baseline-relative production patch are in `.task-evidence/t_bf512e72/`.
The isolated project copies current lib/test/assets/manifests only; it does not
copy credentials, runtime state or upstream clones, and does not reuse retained
root flutter_tester PID 96817. Test compilation exercises the existing screen
entrypoint and parts without manifest changes; packaged runtime is NOT_CHECKED.

The authorized local `agent/wing/t_bf512e72` snapshot includes inherited dirty
full-file screen bytes. The baseline-relative patch isolates this task's two
caller changes; the snapshot's HEAD-relative diff does not. Independent native
same-card review owns final approval. See [client ownership](../adr/client.md#transport-qualification)
and [the daily-use acceptance matrix](../plans/2026-10-03-desktop-daily-workflow.md#acceptance-matrix).
