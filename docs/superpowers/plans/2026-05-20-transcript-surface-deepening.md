# Transcript Surface Deepening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the current chat adapter to `TranscriptSurface` and deepen it into one public module with private/internal behavior files, without changing UI behavior or adding a chat package.

**Architecture:** The public seam is `TranscriptSurface`. It keeps the existing callback shape and `NavivoxChatMessage` input for this slice, while internal `part` files hold transcript bubble rendering, message body rendering, composer behavior, and message actions. `ChatScreen` continues to own channel calls, routing, active Profile contact orchestration, and Local command handling.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Flutter widget tests, existing `NavivoxChatMessage` protocol models.

---

## Accepted Scope

- Rename `SimpleChatAdapter` to `TranscriptSurface`.
- Keep the current callbacks; use **Operator intent** as product language only in this slice.
- Keep `NavivoxChatMessage` directly as the Transcript surface input model.
- Move internal behavior into `part` files so internal classes can stay private to the transcript library.
- Preserve existing behavior and visuals.
- Do not add `flyerhq/flutter_chat_ui`, `v_chat_bubbles`, or any other chat UI package.
- Do not refactor Local command handling out of `ChatScreen` in this slice.

## File Structure

Create:

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart`
  - Public module and only import target for callers.
  - Defines `TranscriptSurface` and `_TranscriptSurfaceState`.
  - Includes imports and `part` declarations.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_bubble.dart`
  - Private bubble row, tail painter, typing indicator.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_message_bodies.dart`
  - Private text/tool/safety/approval/voice body renderers.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_composer.dart`
  - Private input bar, emoji row, attach sheet, voice unavailable sheet.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_message_actions.dart`
  - Private message action sheet and message action text extraction.

Modify:

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/screens/chat_screen.dart`
  - Import `transcript_surface.dart`.
  - Instantiate `TranscriptSurface`.

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/composer_actions_test.dart`
- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/message_actions_test.dart`
- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/chat_voice_button_test.dart`
- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/tool_artifacts_render_test.dart`
  - Import `transcript_surface.dart`.
  - Instantiate `TranscriptSurface`.

Delete after all imports move:

- `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/simple_chat_adapter.dart`

---

## Task 1: Establish the new public Transcript surface seam

**Files:**
- Create: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart`
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/composer_actions_test.dart`

- [ ] **Step 1: Write the failing public-seam test change**

Replace the import and widget names in `composer_actions_test.dart` only:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/widgets/transcript_surface.dart';

void main() {
  testWidgets('composer attachment button opens Telegram-style upload sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Attach'));
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Upload file'), findsOneWidget);
    expect(find.text('Photo or video'), findsOneWidget);
    expect(find.text('Workspace file'), findsOneWidget);
  });

  testWidgets('composer emoji picker inserts emoji before sending', (
    tester,
  ) async {
    final sent = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: sent.add,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'hello',
    );
    await tester.tap(find.byTooltip('Emoji'));
    await tester.pumpAndSettle();

    expect(find.text('😀'), findsOneWidget);
    expect(find.text('👍'), findsOneWidget);

    await tester.tap(find.text('😀'));
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(sent, ['hello😀']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/composer_actions_test.dart
```

Expected: FAIL because `package:navivox/features/chat/widgets/transcript_surface.dart` does not exist or `TranscriptSurface` is undefined.

- [ ] **Step 3: Create minimal public module by copying and renaming the old adapter**

Create `transcript_surface.dart` with the current contents of `simple_chat_adapter.dart`, then make these exact top-level renames:

```dart
class TranscriptSurface extends StatefulWidget {
  const TranscriptSurface({
    required this.messages,
    required this.onSend,
    this.voiceCaptureService,
    this.onVoice,
    this.voiceCaptureTimeout = const Duration(seconds: 30),
    this.voiceUnavailableReason,
    this.textToSpeechService,
    this.assistantTypingLabel,
    this.forwardTargets = const [],
    this.onForward,
    super.key,
  });

  final List<NavivoxChatMessage> messages;
  final ValueChanged<String> onSend;
  final VoiceCaptureService? voiceCaptureService;
  final ValueChanged<VoiceCapture>? onVoice;
  final Duration voiceCaptureTimeout;
  final String? voiceUnavailableReason;
  final TextToSpeechService? textToSpeechService;
  final String? assistantTypingLabel;
  final List<NavivoxProfileContact> forwardTargets;
  final void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward;

  @override
  State<TranscriptSurface> createState() => _TranscriptSurfaceState();
}

class _TranscriptSurfaceState extends State<TranscriptSurface> {
```

Do not change any behavior inside the renamed state class in this task.

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/composer_actions_test.dart
```

Expected: PASS. Both composer tests pass.

- [ ] **Step 5: Commit this slice if the repository ownership is clear**

If `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app` is still untracked under the parent repository, do not commit a partial Navivox project. Record the blocker instead of staging only a few files.

If the Navivox project has been made trackable as a complete repo or submodule, run:

```bash
cd /home/xel/git/sages-openclaw
 git add workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart \
   workspace-mineru/navivox-app/app/test/features/chat/composer_actions_test.dart
 git commit -m "refactor(navivox): introduce transcript surface seam"
```

---

## Task 2: Move production and widget tests to the new public seam

**Files:**
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/screens/chat_screen.dart`
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/message_actions_test.dart`
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/chat_voice_button_test.dart`
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/tool_artifacts_render_test.dart`

- [ ] **Step 1: Write failing references to the new public seam**

In `chat_screen.dart`, replace:

```dart
import '../widgets/simple_chat_adapter.dart';
```

with:

```dart
import '../widgets/transcript_surface.dart';
```

and replace:

```dart
SimpleChatAdapter(
```

with:

```dart
TranscriptSurface(
```

In each listed chat widget test, replace the old import:

```dart
import 'package:navivox/features/chat/widgets/simple_chat_adapter.dart';
```

with:

```dart
import 'package:navivox/features/chat/widgets/transcript_surface.dart';
```

Then replace every `SimpleChatAdapter(` call with `TranscriptSurface(`.

- [ ] **Step 2: Run focused tests to verify references compile against the new seam**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test \
  test/features/chat/composer_actions_test.dart \
  test/features/chat/message_actions_test.dart \
  test/features/chat/chat_voice_button_test.dart \
  test/features/chat/tool_artifacts_render_test.dart \
  test/features/chat/typing_indicator_test.dart
```

Expected before Task 1 implementation: FAIL because `TranscriptSurface` is missing. Expected after Task 1 implementation: PASS.

- [ ] **Step 3: Remove remaining old public-seam references**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
rg "SimpleChatAdapter|simple_chat_adapter" lib test
```

Expected before cleanup: only references in `simple_chat_adapter.dart` itself. If any caller still imports or instantiates the old name, update that caller to `TranscriptSurface`.

- [ ] **Step 4: Run focused tests again**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test \
  test/features/chat/composer_actions_test.dart \
  test/features/chat/message_actions_test.dart \
  test/features/chat/chat_voice_button_test.dart \
  test/features/chat/tool_artifacts_render_test.dart \
  test/features/chat/typing_indicator_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit this slice if the repository ownership is clear**

If the Navivox project has been made trackable as a complete repo or submodule, run:

```bash
cd /home/xel/git/sages-openclaw
 git add workspace-mineru/navivox-app/app/lib/features/chat/screens/chat_screen.dart \
   workspace-mineru/navivox-app/app/test/features/chat/message_actions_test.dart \
   workspace-mineru/navivox-app/app/test/features/chat/chat_voice_button_test.dart \
   workspace-mineru/navivox-app/app/test/features/chat/tool_artifacts_render_test.dart
 git commit -m "refactor(navivox): use transcript surface in chat"
```

---

## Task 3: Extract transcript message actions into a private part file

**Files:**
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart`
- Create: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_message_actions.dart`
- Test: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/message_actions_test.dart`

- [ ] **Step 1: Confirm green behavior before refactor**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/message_actions_test.dart
```

Expected: PASS. This is the green state that permits a pure refactor.

- [ ] **Step 2: Add the part declaration**

Near the imports in `transcript_surface.dart`, add:

```dart
part 'src/transcript_message_actions.dart';
```

- [ ] **Step 3: Move message-action implementation into the part file**

Move these declarations from `transcript_surface.dart` into `src/transcript_message_actions.dart`:

```dart
part of '../transcript_surface.dart';

Future<void> _showTranscriptMessageActions({
  required BuildContext context,
  required NavivoxChatMessage message,
  required List<NavivoxProfileContact> forwardTargets,
  required void Function(NavivoxChatMessage message, NavivoxProfileContact target)?
  onForward,
  required TextToSpeechService? textToSpeechService,
}) {
  final text = _messageActionText(message);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            'Message actions',
            style: Theme.of(sheetContext).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(text),
            ),
          if (text.isNotEmpty) ...[
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy text'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            if (textToSpeechService != null)
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Read aloud'),
                onTap: () async {
                  await textToSpeechService.speak(text);
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(content: Text('Reading aloud')),
                  );
                },
              ),
          ],
          if (forwardTargets.isNotEmpty && onForward != null) ...[
            const Divider(),
            const ListTile(
              leading: Icon(Icons.forward),
              title: Text('Forward to'),
            ),
            for (final target in forwardTargets)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(target.displayName),
                subtitle: Text(target.serverLabel),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onForward(message, target);
                },
              ),
          ],
          if (text.isNotEmpty && textToSpeechService == null)
            const ListTile(
              enabled: false,
              leading: Icon(Icons.volume_off),
              title: Text('Read aloud unavailable'),
              subtitle: Text('Device TTS is not connected.'),
            ),
        ],
      ),
    ),
  );
}

String _messageActionText(NavivoxChatMessage message) {
  return switch (message.kind) {
    NavivoxMessageKind.text => message.text ?? '',
    NavivoxMessageKind.voice => message.voice?.transcript ?? '',
    NavivoxMessageKind.toolCall => [
      message.toolCall?.name,
      message.toolCall?.status,
      message.toolCall?.summary,
    ].whereType<String>().where((part) => part.isNotEmpty).join('\n'),
    NavivoxMessageKind.safetyWarning || NavivoxMessageKind.approvalRequest => [
      message.safetyNotice?.message,
      message.safetyNotice?.risk,
    ].whereType<String>().where((part) => part.isNotEmpty).join('\n'),
  };
}
```

In `_TelegramBubble`, replace the old `_showMessageActions(context)` call with:

```dart
_showTranscriptMessageActions(
  context: context,
  message: message,
  forwardTargets: forwardTargets,
  onForward: onForward,
  textToSpeechService: textToSpeechService,
)
```

- [ ] **Step 4: Run message-action tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/message_actions_test.dart
```

Expected: PASS.

- [ ] **Step 5: Format changed Dart files**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib/features/chat/widgets/transcript_surface.dart lib/features/chat/widgets/src/transcript_message_actions.dart
```

Expected: `Formatted` output or `Changed 0 files`.

---

## Task 4: Extract composer behavior into a private part file

**Files:**
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart`
- Create: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_composer.dart`
- Test: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/composer_actions_test.dart`
- Test: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/chat_voice_button_test.dart`

- [ ] **Step 1: Confirm green behavior before refactor**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/composer_actions_test.dart test/features/chat/chat_voice_button_test.dart
```

Expected: PASS. This is the green state that permits a pure refactor.

- [ ] **Step 2: Add the part declaration**

Near the imports in `transcript_surface.dart`, add:

```dart
part 'src/transcript_composer.dart';
```

- [ ] **Step 3: Move `_InputBar` and `_InputBarState` into the part file**

Create `src/transcript_composer.dart`:

```dart
part of '../transcript_surface.dart';
```

Move the full existing `_InputBar` and `_InputBarState` declarations from `transcript_surface.dart` into this file without changing their constructor, fields, methods, or widget tree.

- [ ] **Step 4: Run composer and voice-button tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/composer_actions_test.dart test/features/chat/chat_voice_button_test.dart
```

Expected: PASS.

- [ ] **Step 5: Format changed Dart files**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib/features/chat/widgets/transcript_surface.dart lib/features/chat/widgets/src/transcript_composer.dart
```

Expected: `Formatted` output or `Changed 0 files`.

---

## Task 5: Extract message body rendering into a private part file

**Files:**
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart`
- Create: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_message_bodies.dart`
- Test: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/tool_artifacts_render_test.dart`
- Test: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/chat_voice_button_test.dart`

- [ ] **Step 1: Confirm green behavior before refactor**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/tool_artifacts_render_test.dart test/features/chat/chat_voice_button_test.dart
```

Expected: PASS. This is the green state that permits a pure refactor.

- [ ] **Step 2: Add the part declaration**

Near the imports in `transcript_surface.dart`, add:

```dart
part 'src/transcript_message_bodies.dart';
```

- [ ] **Step 3: Move body renderers into the part file**

Create `src/transcript_message_bodies.dart`:

```dart
part of '../transcript_surface.dart';
```

Move the complete current declarations from `transcript_surface.dart` into this file without changing behavior:

- `class _MessageBody extends StatelessWidget`
- `class _ToolCallBody extends StatelessWidget`
- `class _SafetyNoticeBody extends StatelessWidget`
- `class _VoiceBody extends StatelessWidget`

Copy each declaration from its `class` line through its final closing brace. Do not rewrite the widget trees while moving them.

- [ ] **Step 4: Run tool and voice rendering tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/tool_artifacts_render_test.dart test/features/chat/chat_voice_button_test.dart
```

Expected: PASS.

- [ ] **Step 5: Format changed Dart files**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib/features/chat/widgets/transcript_surface.dart lib/features/chat/widgets/src/transcript_message_bodies.dart
```

Expected: `Formatted` output or `Changed 0 files`.

---

## Task 6: Extract bubble, tail, and typing rendering into a private part file

**Files:**
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart`
- Create: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_bubble.dart`
- Test: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/typing_indicator_test.dart`
- Test: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/message_actions_test.dart`

- [ ] **Step 1: Confirm green behavior before refactor**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/typing_indicator_test.dart test/features/chat/message_actions_test.dart
```

Expected: PASS. This is the green state that permits a pure refactor.

- [ ] **Step 2: Add the part declaration**

Near the imports in `transcript_surface.dart`, add:

```dart
part 'src/transcript_bubble.dart';
```

- [ ] **Step 3: Move bubble declarations into the part file**

Create `src/transcript_bubble.dart`:

```dart
part of '../transcript_surface.dart';
```

Move the complete current declarations from `transcript_surface.dart` into this file without changing behavior:

- `class _TypingIndicator extends StatelessWidget`
- `class _TelegramBubble extends StatelessWidget`
- `class _BubbleTailPainter extends CustomPainter`

Copy each declaration from its `class` line through its final closing brace. Do not rewrite the widget trees while moving them.

- [ ] **Step 4: Run typing and action tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/typing_indicator_test.dart test/features/chat/message_actions_test.dart
```

Expected: PASS.

- [ ] **Step 5: Format changed Dart files**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib/features/chat/widgets/transcript_surface.dart lib/features/chat/widgets/src/transcript_bubble.dart
```

Expected: `Formatted` output or `Changed 0 files`.

---

## Task 7: Remove the old adapter file and run full Navivox validation

**Files:**
- Delete: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/simple_chat_adapter.dart`
- Modify: imports only if `rg` finds remaining old references.

- [ ] **Step 1: Verify no callers use the old seam**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
rg "SimpleChatAdapter|simple_chat_adapter" lib test
```

Expected: only the old file itself appears. If any caller appears, change that caller to `TranscriptSurface` and `transcript_surface.dart`, then rerun the command.

- [ ] **Step 2: Delete the old file**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
trash lib/features/chat/widgets/simple_chat_adapter.dart
```

If `trash` is not available, move the file to a timestamped backup outside `lib`:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
mkdir -p ../_backups
mv lib/features/chat/widgets/simple_chat_adapter.dart ../_backups/simple_chat_adapter.dart.$(date +%Y%m%dT%H%M%S%z)
```

- [ ] **Step 3: Verify old references are gone**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
rg "SimpleChatAdapter|simple_chat_adapter" lib test
```

Expected: no output and exit code 1 from `rg` because no matches exist.

- [ ] **Step 4: Run focused chat test suite**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test \
  test/features/chat/composer_actions_test.dart \
  test/features/chat/message_actions_test.dart \
  test/features/chat/chat_voice_button_test.dart \
  test/features/chat/tool_artifacts_render_test.dart \
  test/features/chat/typing_indicator_test.dart \
  test/features/chat/chat_active_agent_test.dart \
  test/features/chat/chat_forward_message_test.dart \
  test/features/chat/approval_banner_test.dart \
  test/features/chat/approval_banner_risk_test.dart \
  test/features/chat/profile_contact_list_test.dart
```

Expected: PASS.

- [ ] **Step 5: Run full app tests**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test
```

Expected: PASS. If unrelated tests fail, capture the first failing test name and stderr line in the final report and do not claim a full green suite.

- [ ] **Step 6: Run formatting and diff checks**

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
dart format lib test
cd /home/xel/git/sages-openclaw
git diff --check -- workspace-mineru/navivox-app
```

Expected: Dart formatter completes; `git diff --check` exits 0.

- [ ] **Step 7: Commit and push if the repository ownership is clear**

If the Navivox project has been made trackable as a complete repo or submodule, run:

```bash
cd /home/xel/git/sages-openclaw
 git add workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart \
   workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_bubble.dart \
   workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_message_bodies.dart \
   workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_composer.dart \
   workspace-mineru/navivox-app/app/lib/features/chat/widgets/src/transcript_message_actions.dart \
   workspace-mineru/navivox-app/app/lib/features/chat/screens/chat_screen.dart \
   workspace-mineru/navivox-app/app/test/features/chat/composer_actions_test.dart \
   workspace-mineru/navivox-app/app/test/features/chat/message_actions_test.dart \
   workspace-mineru/navivox-app/app/test/features/chat/chat_voice_button_test.dart \
   workspace-mineru/navivox-app/app/test/features/chat/tool_artifacts_render_test.dart \
   workspace-mineru/navivox-app/app/lib/features/chat/widgets/simple_chat_adapter.dart
 git commit -m "refactor(navivox): deepen transcript surface internals"
 git push origin docs/normalize-bin-gormes-to-gormes
```

If the project is still untracked, do not run the commit commands. Report the exact `git status --short -- workspace-mineru/navivox-app` output.

---

## Self-Review

### Spec coverage

- Rename to `TranscriptSurface`: Task 1 and Task 2.
- One public module with private/internal submodules: Tasks 3 through 6 use Dart `part` files.
- Existing callbacks, no formal Operator intent type: Task 1 preserves constructor shape.
- Keep `NavivoxChatMessage`: Task 1 preserves `messages: List<NavivoxChatMessage>`.
- No visual redesign: every extraction task says move existing implementations without behavior change.
- No new package: no task edits `pubspec.yaml`.
- Local commands stay in `ChatScreen`: no task edits `_handleLocalCommand` or related methods.
- Tests target public seam: test tasks import and instantiate `TranscriptSurface` only.

### Placeholder scan

No task uses placeholder code as implementation. Where existing bodies are moved, the plan names the exact declarations and requires moving their complete current implementations without stubs.

### Type consistency

The public widget is named `TranscriptSurface` in every import, constructor, and call site. The input model remains `NavivoxChatMessage`. The internal files are `part of '../transcript_surface.dart';` so private classes remain in one library.
