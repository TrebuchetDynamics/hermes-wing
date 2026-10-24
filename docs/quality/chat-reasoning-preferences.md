# Local Chat display preferences — reasoning and code isolation

This is bounded offline implementation evidence for the owner's parallel parity
batch, following `CLONE03-LOCAL-NEXT` (`38f89cf9`). It does not close CLONE-03 or
PARITY and does not qualify a platform release.

## Official source

Read-only public source at `14e1e43a23761b369641208e204365cd6cb9399d`:

- [`store/reasoning-disclosure.ts`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/store/reasoning-disclosure.ts): install-local collapsed preference, default false, independent of Agent display configuration.
- [`message-parts.tsx:219`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/components/assistant-ui/thread/message-parts.tsx#L219): explicit user disclosure, live preview latch, completed historical blocks closed, a bounded scrollable automatic preview and following only while the reader stays near its end.
- [`appearance-settings.tsx:1052`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/app/settings/appearance-settings.tsx#L1052) and [`settings-manifest.ts`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/app/settings/settings-manifest.ts): Chat display control and canonical `appearance.reasoning-collapsed` field.
- [`streaming.test.tsx:669`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/components/assistant-ui/thread/streaming.test.tsx#L669): collapsed opt-in suppresses live preview and still permits explicit opening.

## Implemented outcome

Chat display now offers **Collapse thinking by default**, including search and
field-over-page navigation. Its local boolean preserves direction, text scale,
spellcheck, theme and legacy preferences. It never writes Agent configuration.

Without that opt-in, active reasoning has a 160px automatic preview which stays
mounted when the turn settles. Growing content follows only while the preview
reader remains near its end. Explicitly opened reasoning has its full available
height; explicit user open/close outranks preference changes. Completed blocks
which never previewed and replacement session owners start closed. Reduced motion
uses immediate expansion and the existing static progress equivalent.

The preference load has a readiness boundary: a saved collapsed choice is loaded
before an automatic preview can latch. A storage failure keeps current choices
usable. Existing ownership keys continue to fence row state by conversation.

Review also reproduced an inline-code link regression in the first direction
slice. The correction uses Markdown's public `LinkSyntax.createNode` unchanged
and annotates only code AST nodes with the normalized parent href. Ordinary
anchors keep their native renderer; isolated code uses the existing safe scheme
allowlist and launcher, keyboard activation and a disposed tap recognizer. No
source text or bidi control is inserted. Both inline and reference-style links,
unlinked duplicate code and rejected schemes are covered.

Flutter's default selection ordering sorts separate inline widget fragments from
left to right. A small `StaticSelectionContainerDelegate` subclass, enabled only
for **explicit RTL**, uses first-fragment line position and RTL inline order to
preserve copied text across wraps. Auto and explicit LTR keep the prior selection
container path. Narrow paragraph/list/quote/fenced-code copy is compared against
the original Auto output through live direction changes.

## Executed validation

Flutter 3.44.2 / Dart 3.12.2 on Linux, deterministic fake channels only:

- `flutter gen-l10n` and changed Dart formatting passed.
- The new final three targets passed **13 cases**: `hermes_chat_text_direction_test.dart`,
  `hermes_chat_reasoning_preferences_test.dart` and `chat_reasoning_settings_test.dart`.
- The earlier six-target reasoning/direction/transcript run passed **106 cases**
  before the additional bounded-preview and inline-link/copy regressions.
- Review reproduced missing inline-code activation and reversed RTL copy; both
  now have permanent behavioral cases. The long-preview exploratory test
  interacted before the collapse animation completed; finishing the next frame
  fixed the test without altering production viewport behavior.
- The final six-target run passed **120 cases**:
  `flutter test --no-pub --concurrency=1
  test/features/hermes_chat/screens/hermes_chat_text_direction_test.dart
  test/features/hermes_chat/screens/hermes_chat_reasoning_preferences_test.dart
  test/features/settings/chat_reasoning_settings_test.dart
  test/features/settings/chat_text_direction_settings_test.dart
  test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart
  test/features/hermes_chat/presentation/hermes_markdown_block_viewport_test.dart`.
- `flutter analyze --no-pub`: no issues after fixing two style notices.
  Changed Dart formatting and `git diff --check` passed.
- Existing `reasoning-disclosure.spec.mjs` now opts into collapsed presentation
  through the real Settings switch before its keyboard and owner-replacement
  journey. The coordinator runs it against the final integrated web build.

The coordinator owns final integrated analysis, the unchanged whole serial suite,
web build/browser execution and publication. Native GTK/device behavior, paired
Desktop screenshots and physical accessibility/voice remain separate acceptance.

### Expanded summary semantics follow-up

The integrated Chromium journey exposed an expanded live preview whose summary
was exposed as a group rather than an operable button. Two widget regressions
reproduced the missing button flag at 390px/200% text under Linux and Android
platform variants. Flutter 3.44.2's public
`ExpansionTile.internalAddSemanticForOnTap` forwards the button role to its native
ListTile header; enabling it preserves that role with expanded body children.

`flutter test --no-pub --concurrency=1
 test/features/hermes_chat/screens/hermes_chat_reasoning_preferences_test.dart`
passed all **7 cases** after the fix. The new cases assert button/tap semantics,
expanded/collapsed state, Enter/Space operation and retained focus while active
reasoning becomes Thought. `flutter analyze --no-pub`, changed-file formatting
and `git diff --check` passed. The coordinator reruns the original browser
journey on the integrated build; its assertions remain unchanged.
