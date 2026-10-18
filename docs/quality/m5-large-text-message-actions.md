# M5 large-text message-action evidence

Task: `DOC-M5-LARGE-TEXT-EVIDENCE`. **Source/receipt attribution only; partial
keyboard oracle, not an end-to-end 200% copy journey or Android qualification.**
Start with the [M5 exit criteria](../../ROADMAP.md#m5--safely-take-away-output-with-native-accessible-interaction)
and the [offline Android fixture follow-up](2026-10-03-android-qualification-discovery.md#offline-fixture-follow-up--doc-m5-android-fixture).

## Pin and scope

`git rev-parse HEAD` returned `f2b8f69e5d5a85ee16fba61e6fee1d5aeac5b003` before
this documentation change. The local native execution slot records this task as
running in its assigned isolated workspace and `DOC-M5-ANDROID-FIXTURE` as closed;
its integration `7593940f047e3ee051a5ba24d7005293ab758cc5` is an ancestor of that
baseline. This verifies the offline dependency, not its pending live acceptance
or a global absence of other workers/continuations. No lease or job was changed.
Only Wing source, tests and retained sanitized evidence were inspected. No test,
build, install, browser/device journey, Agent call or upstream edit ran here.

## One attributable 200% journey

The existing [export test](../../test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart)
`390px 200% sheet is scrollable, semantic and keyboard operable` (lines 528–565)
provides this bounded deterministic oracle:

1. Set the widget viewport to 390 × 844 logical pixels and enable semantics.
   Mount production `HermesChatScreen` with one synthetic loaded turn, a fake
   channel and `Saver` (`supported = true`). The helper at lines 60–87 injects
   `TextScaler.linear(2)`; this is Flutter text scaling, not Android system font
   settings or browser whole-render zoom.
2. Open **More actions → Copy transcript** by `tester.tap` (helper, lines 89–101).
   This reaches the real compact production entry at
   [screen lines 1691–1753](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart#L1691).
   It does not prove keyboard traversal into that entry.
3. Call `ensureVisible` on `hermes-save-transcript-markdown`, then assert the
   **Save as Markdown** semantics label. Send up to twelve Tab presses and
   inspect `FocusManager.instance.primaryFocus` for the keyed `ListTile`.
4. Send Enter; assert exactly one fake saver write in Markdown format and no
   Flutter exception. This proves in-sheet keyboard focus/activation after
   programmatic scrolling, not visible focus-ring contrast, keyboard-only
   scrolling, real filesystem persistence or clipboard readback.

Production [screen lines 1323–1419](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart#L1323)
compose a scroll-controlled bottom sheet with `SafeArea` and
`SingleChildScrollView`. **Copy as text** and **Copy as Markdown** are unconditional
sheet actions; **Save as text/Markdown** require `saver.supported`. The compact
menu and wide toolbar both open this sheet. The export path (lines 1422–1474) snapshots
loaded turns at explicit Save and fences saving/feedback by the captured owner;
the copy path (lines 1476–1525) calls `Clipboard.setData`. The 200% test does not
activate either Copy tile. Separate default-scale cases at test lines 125–188
compare mocked clipboard output and fake saved bytes for 250 Unicode turns;
they must not be combined into a 200% keyboard-copy receipt.

## Per-message actions are a separate, incomplete oracle

The required [message-action test](../../test/features/hermes_chat/screens/hermes_chat_message_actions_a11y_test.dart)
(lines 17–63) mounts a completed synthetic assistant turn at default text scale.
It checks that a bubble `GestureDetector` owns `onLongPress` and exposes
`SemanticsAction.longPress`. It never invokes that semantic action, opens the
sheet, traverses focus, presses Copy or checks clipboard output. Its title
“reachable without a pointer” is not evidence of a completed keyboard journey.

Production [timeline lines 1195–1245](../../lib/features/hermes_chat/presentation/hermes_chat_timeline.dart#L1195)
wire that gesture to Reply/Copy/read-aloud tiles in a bottom sheet; Copy is gated
on a non-streaming, nonempty message (lines 977–978). Copy dispatch calls
`Clipboard.setData` (lines 1291–1305). A separate desktop-enabled inline Copy
button exists at lines 1104–1119, and secondary-click menus at lines 1247–1287;
neither establishes compact keyboard access or 200% focus from this test.
The [production layout](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart#L1577)
wires timeline transcript-copy callbacks to `_copyTranscript` and enables desktop
controls via `_usesDesktopKeyboardShortcuts` (lines 1577–1583); those callbacks
copy directly, not through the Save sheet.

## Retained evidence: do not splice different outcomes

| Retained evidence | What it supports | What it does not support |
| --- | --- | --- |
| [Android discovery and fixture follow-up](2026-10-03-android-qualification-discovery.md#offline-fixture-follow-up--doc-m5-android-fixture) | Historical 17 Android deterministic tests, including long-press semantics; later Linux-hosted 58-test fixture/export run and syntax checks. | Discovery transcript flow failed before clipboard receipts; follow-up ran no Android flow. Neither proves a 200% message Copy journey. |
| [Export runbook](../runbooks/chat-transcript-export.md#browser-baseline-verification-parent-card) | Historical compact 390px/200% widget keyboard activation and separate Chromium download/clipboard equality receipts. | Not a fresh run against this pin. Current [browser export test](../../playwright/tests/regression/transcript-export.spec.mjs) uses 390/1280px, Enter on Save and clicks on Copy; it does not set 200% text/zoom or traverse from the entry by Tab. |
| [Transcript accessibility summary](chat-transcript-accessibility.md#acceptance-evidence) and [sanitized JSON receipt](chat-transcript-accessibility-receipt.json) | Historical widget and Chromium 200% disclosure/approval/recovery focus evidence. JSON `browser[].focus_checks` names only the tool group and **Approve once**. | No Copy/Save focus or output receipt. Its baseline is `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`; the recorded timeline hash `3e5dd9d58b17ead2217067bd74683178269c8b2178b6fe07e2db7a1d6c092df7` differs from the current source. Do not repin or reuse it as current message-action qualification. |

Current source SHA-256 anchors (not new runtime receipts):

| Path | SHA-256 |
| --- | --- |
| `test/features/hermes_chat/screens/hermes_chat_message_actions_a11y_test.dart` | `bb65c742e69b6af1270a75b29facce991942aa71b3e3c46beab839d416d9a98c` |
| `test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart` | `237033a9b17f40ddc08f44460c119c2cc6c20b2cd503685fdee317ff3a926a17` |
| `lib/features/hermes_chat/screens/hermes_chat_screen.dart` | `9564576637d12f76adaa71ebe3e1a680b23a32caaeb2e7ecaceb442c58161bee` |
| `lib/features/hermes_chat/presentation/hermes_chat_timeline.dart` | `74ccb0470d5259123a06c7035faaffd6bcd564c0bfeb8c7fc45df30bc9c6b44d` |

## Remaining proof slice and platform ceiling

**Missing deterministic oracle:** one 200%-text journey that enters message or
transcript actions without pointer input, asserts actual focus on Copy, activates
it and verifies the exact clipboard write. For the per-message path, also invoke
the published semantics action and check the resulting sheet rather than only
its presence. The existing Save test can support in-sheet activation only;
entry traversal, keyboard-only visibility and focus restoration remain unproven
by that case. No new test or implementation is added in this docs-only task.

Android native file export remains unsupported: the
[IO saver](../../lib/features/hermes_chat/export/hermes_transcript_export_io.dart#L8)
selects Linux only, otherwise the unsupported saver. Injecting `Saver.supported`
above cannot qualify Android Save/share. Existing Android Copy still requires
actual clipboard readback on a named owned target. TalkBack focus/actions, native
keyboard/CJK IME, Android system 200% text and physical-device acceptance remain
pending live work, not failures of this offline attribution or waived M5 exits.
There is no new platform, Desktop parity or M5 completion claim.

Revisit this attribution when the compact entry, message gesture/menu, sheet
focus/layout, copy/export dispatch, platform saver gate or cited tests/receipts
change. Re-run the relevant oracle in a separately scoped implementation or
qualification task; source inspection alone does not renew historical results.
