# Chat reply-completion focus ownership

## Delivered behavior

A completed active reply may refocus the desktop composer only while the Chat
owner that scheduled that callback remains current. The caller captures the
existing composer-owner generation and checks it, plus channel-provider identity,
when the post-frame callback runs. Observed owner loss permanently invalidates
that callback, even if the original owner returns before the frame.

The existing generation covers channel identity, connection status, connected
origin, selected profile, selected session, contact, and unsettled restoration.
Channel notifications, provider adoption, and directory notifications update it
synchronously. No additional listener, owner object, runtime module, dependency,
or disposal hook was added.

Same-owner completion still focuses the composer. Unrelated inventory/directory
notifications do not invalidate that owner. Background replies and Android-platform
widget completions do not focus it. Existing unmount and non-current modal-route
checks remain in force. Initial-entry focus and deliberate session Open focus
are unchanged; see [session settlement](chat-session-settlement.md).

This is a Wing presentation fence, not a change to Agent completion detection,
transport, send admission, session selection, or authority. Server-owned state,
transcripts and existing drafts remain unchanged by the callback.

## Regression evidence

The public widget regression is
[test/features/hermes_chat/screens/hermes_chat_completion_focus_owner_test.dart](../../test/features/hermes_chat/screens/hermes_chat_completion_focus_owner_test.dart).
It mounts the real screen with advertised streaming capabilities, initializes
both session drafts, settles initial focus, starts a new streaming reply, and
notifies completion before an ownership transition and the next frame. It never
invokes a private screen callback. State-provider replacement and notifying
channel/directory fixtures exercise synchronous admission; they are not live
transport or full directory-activation qualification. Session transitions use the
public channel selection contract rather than a rail Open action, whose separate
intentional focus is unchanged.

The matrix covers session, profile, origin, connection, contact, restoration and
provider replacement, with loss/return cases for each. Replacement profile/origin
states carry an initialized selected session/history. A disconnect clears channel
state. The test verifies the current session/profile/history, session/provider
replacement drafts, retained outside focus, and zero sends, creates, connections,
disconnections or approval responses. Controls cover current-owner success,
unrelated notifications, background completion, Android-platform widgets, modal
suppression and unmount. No operation-added listeners exist to clean up.

Final identical test oracle on baseline source: exit 1, 8 passes and 12 relevant
obsolete-focus failures. Final repaired source: exit 0, 20 passes. The first
fixture attempt timed out because it tried to settle an animated streaming view;
that log is not RED evidence. The final fixture settles before starting a new
streaming turn and resets the platform override inside each test.

Executed on Linux with Flutter 3.44.2 / Dart 3.12.2:

```sh
flutter test --reporter expanded \
  test/features/hermes_chat/screens/hermes_chat_completion_focus_owner_test.dart \
  test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart \
  test/features/hermes_chat/screens/hermes_chat_session_settlement_owner_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart \
  test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart
flutter analyze
dart format --output=none --set-exit-if-changed \
  lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart \
  test/features/hermes_chat/screens/hermes_chat_completion_focus_owner_test.dart
git diff --check
```

The five suites passed 212 tests; analysis reported no issues; formatting and
whitespace checks passed. Flutter tests and analysis ran in the isolated project
under `.task-evidence/t_64756dfb/project`. Its complete current Flutter source,
integration tests, assets, tools and manifests are hash-checked against the
workspace; read-only reference repositories are not in that source closure.
Task-local logs, command exits, hashes, closure proof and baseline-relative patch
are in `.task-evidence/t_64756dfb/`. The patch, not the inherited full Git diff,
defines task attribution.

## Evidence ceilings

Implementation is completed and independently approved in same-card review run 245.
The [independent review](../../.task-evidence/t_64756dfb/independent-review.md)
records 212 focused widget passes, clean analysis, formatting and whitespace checks.
Native desktop
build/interaction/package, compiled browser, live Agent/provider, Android/device,
physical accessibility, the full canonical suite and full parity are NOT_CHECKED.
Android-platform widgets do not qualify a physical Android keyboard. This scoped
widget/caller repair does not resolve separate native build prerequisites or
approve the parked approval-resource work.
