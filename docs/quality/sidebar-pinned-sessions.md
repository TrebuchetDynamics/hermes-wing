# Sidebar pinned sessions

This bounded CLONE-02/HD-SHELL slice exposes local session pins in the expanded
sidebar. It does not qualify the complete Desktop shell or its multi-pane model.

## Reference and behavior

Official source: `NousResearch/hermes-agent@14e1e43a23761b369641208e204365cd6cb9399d`,
[`apps/desktop/src/app/chat/sidebar/index.tsx`, lines 1760–1790](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/app/chat/sidebar/index.tsx#L1760-L1790).
Desktop renders a separate Pinned section and routes pin/unpin through the same
local presentation state used by session rows.

Wing now projects loaded, visible pinned sessions above its existing source groups.
Each session appears once, and its exact ID is retained even when display titles
match or are redacted. Existing Open actions retain their Agent admission gates.
Pin/Unpin is a separate named keyboard-operable action and makes no Agent request.

Chat, the global session picker and the sidebar share one Riverpod-owned
`HermesSessionPinStore`; opening a picker or hiding the sidebar does not create or
dispose another pin owner. Existing preference records and the
`wing.hermes.pinned_sessions.v1` namespace remain unchanged. Pins stay scoped to
an explicit saved gateway/profile identity. Unsaved direct connections use an
opaque SHA-256 digest of the exact endpoint plus the profile; no raw endpoint is
persisted. Ambiguous historical `direct` pin records remain intact and inert;
Wing cannot assign them to a guessed endpoint. A missing direct endpoint has no
pin identity. Hidden or unloaded sessions do not become
visible from pin records, and pinning does not fetch, create, resume or select them.
The Chat session sheet recomputes its pin owner when channel state changes.
A pending choice is rechecked after asynchronous loading and rejected if its
owner, route admission or visible session has changed.

This slice preserves Wing's bounded loaded-session inventory. Desktop's manual
pin ordering, section disclosure, profile tags, Project grouping, full search and
multi-pane/window composition remain separate gaps. The displayed section is
omitted when it contains no loaded visible pin; this is a recorded presentation
adaptation rather than Desktop's empty pinned-section placeholder.

## Validation

The focused regressions exercise saved-pin projection, keyboard pin/unpin,
sidebar/picker synchronization, sidebar and route lifetime, exact contact
isolation, stale-owner/removal rejection and preservation of drafts and Agent
state. The existing pin-store tests retain persistence, bounded write ordering and
disposal checks. The saved-pin projection regression first failed before implementation and passes
with the shared owner and projection.

No live Agent mutation, native picker, physical device, paired Desktop scene or
cross-platform runtime acceptance is established by these widget regressions.

Executed on Linux with Flutter 3.44.2 / Dart 3.12.2:

- `flutter pub get --offline --enforce-lockfile`: passed; no lockfile change.
- `flutter test --no-pub --concurrency=1
  test/shared/widgets/app_shell_pinned_sessions_test.dart
  test/features/hermes_chat/session
  test/features/hermes_chat/screens/hermes_chat_session_disclosure_test.dart`:
  **59 passed**, including the final endpoint/profile and Chat-sheet owner fixes.
- `flutter analyze --no-pub`: no issues (10.3 seconds).
- `dart format` on the nine changed Dart files: no remaining formatting changes.
- `git diff --check`: passed.
- `flutter test --no-pub --concurrency=1
  test/features/hermes_chat/session test/shared/widgets/app_shell*_test.dart`:
  **170 passed**, covering existing shell navigation, focus, scrolling, status,
  grouped recents, picker actions and adaptive large-text journeys.

## Follow-up: stale saved contacts and pending Chat actions

A saved directory contact is now used as a pin namespace only when its configured
base URL and profile still match the connected channel. Otherwise the resolver
uses the current opaque direct owner, or no owner when the endpoint is missing.
This keeps a manual connection whose secure-storage save failed from projecting
pins belonging to the previous saved connection. The directory and saved records
are not mutated to repair presentation identity.

Wide Chat and its compact session picker also bind pin callbacks to the captured
composer owner generation, channel, contact, visible session and mounted view.
The guard runs again after pin-store hydration, so an owner that changes away and
returns cannot revive a queued choice. Closing Chat does not authorize a stale
callback to write to the app-owned shared store. Valid same-owner callbacks retain
their local behavior; no Agent request is added.

The actual manual-connect/save-failure regression and the 390/1280px pending
owner-roundtrip regressions failed before their respective fixes. Final focused
validation passed **83 tests**:

```sh
flutter test --no-pub --concurrency=1 \
  test/shared/widgets/app_shell_pinned_sessions_test.dart \
  test/features/hermes_chat/session \
  test/features/hermes_chat/screens/hermes_chat_session_disclosure_test.dart \
  test/features/hermes_chat/screens/hermes_chat_pin_owner_connection_test.dart \
  test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart \
  test/features/hermes_chat/screens/hermes_chat_pin_intent_owner_test.dart
```

An earlier broader attempt reached 62 passes before the `flutter_tester` process
segfaulted while starting the unchanged remote-retry neighbor. The core identified
SIGSEGV in a stripped Flutter/Dart VM snapshot; available memory and journal reads
did not establish an OOM cause. No detailed Dart/native cause was resolved. That
unchanged neighbor then passed **18/18** in isolation, and the final combined run
above passed all 83 cases without skips. No test gate was weakened or omitted.
Final `flutter analyze --no-pub` passed with no issues (4.2 seconds).
Changed Dart files were formatted and `git diff --check` passed. This remains
Linux widget/tool evidence; integrated and named-platform acceptance stays separate.
