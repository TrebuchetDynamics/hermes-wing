# Chat session section disclosure

Chat's wide session rail and compact Sessions panel expose independent **Pinned**
and **Chats** buttons over the already-loaded session inventory. Both start
expanded. Pinned appears only when the current search/source filter has pinned
matches; Chats contains the existing date subgroups and unpinned matches.

## Interaction and authority

- Click, Enter or Space toggles a section. Tab and Shift+Tab traverse the buttons
  and expanded rows. A disclosure retains keyboard focus when it closes.
- Each button has a merged semantic label, button role and explicit expanded or
  collapsed state. Chevron direction supplies a non-color visual cue. Closing
  removes rows, row menus, checkboxes and Chats date headings from the widget and
  semantic trees rather than merely moving them offscreen.
- Search and source filtering operate on all loaded sessions, including closed
  sections. Clear restores the filtered inventory, not the disclosure state.
  Existing empty-inventory and no-match messages remain distinct from closed
  groups. An all-pinned inventory leaves Chats with no ordinary rows.
- Select all still targets the existing search/source-filtered, non-streaming
  sessions, including closed sections. Counts and explicit delete confirmation
  retain the existing selected-ID semantics; closing is not deselection.
- Disclosure makes no Agent request or mutation, changes no active session,
  draft, pin preference, streaming ownership or unread state, and dispatches no
  automatic profile/session choice. Re-expanded rows use existing actions.

## Volatile ownership

The two booleans are local presentation state only, shared through the existing
session presentation implementation. They survive same-channel/host/profile
inventory and streaming updates. Channel replacement or a changed connected
origin/profile resets both to expanded, even when sessions reuse identifiers.
Synchronous owner observation invalidates cached disclosure callbacks, including
same-frame owner roundtrips. Disposal also invalidates them.

Closing/reopening the compact modal or recreating the wide rail may reset the
buttons to expanded. No new preference, domain state, API or dependency is added.
Existing query/source/selection ownership and session-action policies are not
expanded by this change.

## Reference and intentional differences

The read-only Desktop reference is
[SidebarRecentSessions.tsx](../../hermes-desktop/src/renderer/src/screens/Layout/SidebarRecentSessions.tsx)
at `2ed89070bc6c9e8231a37bb55df8a7722a3776b8` (Pinned disclosure around lines
791–823; Chats around 899–935). This is checkout evidence, not a latest-release
or running Desktop claim. The reference's `lat` executable was unavailable;
no tooling was installed or reference files changed.

Wing preserves its existing date subgroups underneath expanded Chats as a
temporary product deviation. Compact date-heading spacing is tightened to keep
nearby groups reachable after adding the parent disclosure. Desktop-style
persistent disclosure and Project/path grouping are not implemented. Global
shell composition, transport restoration and native/live daily-use qualification
remain separate work.

## Verification

Production `HermesChatScreen` regressions live in
[hermes_chat_session_disclosure_test.dart](../../test/features/hermes_chat/screens/hermes_chat_session_disclosure_test.dart).
The Linux Flutter widget runner exercises 390px and 1280px widths, actual
Tab/Shift+Tab/Enter/Space input, merged semantics, removal of closed descendants,
search/clear/source filtering, pin/unpin and all-pinned inventory, same-owner
stream/inventory updates, owner replacement/roundtrip/disposal, bulk targeting,
pending/failed selections, drafts, modal/view recreation and 200% text with
reduced motion in 700px-high windows. A 600px-high compact test preserves
reachable date subgroups and keyboard recovery after scrolling.

Commands for this slice:

```sh
flutter gen-l10n
dart format lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart test/features/hermes_chat/screens/hermes_chat_session_disclosure_test.dart
flutter analyze
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_disclosure_test.dart
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart test/features/hermes_chat/screens/hermes_chat_session_id_copy_test.dart
```

The initial two production-screen regressions failed against the unchanged
headings because disclosure semantics were absent. Raw RED/iteration/final logs,
command exits, parsed counts, baseline snapshots and baseline-relative diffs are
kept in the task's profile-local `autogoal/session-disclosure` evidence directory.
The shared fakes and existing neighboring tests remain unchanged.

This verifies presentation in the Linux widget runner only. It does not qualify
physical screen readers, compiled Chromium, native desktop interaction, Android,
live Agent/provider behavior or complete Desktop parity. The existing native/live
workflow gates and paused continuation remain unchanged.
