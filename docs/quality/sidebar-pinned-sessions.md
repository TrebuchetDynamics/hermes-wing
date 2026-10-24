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
