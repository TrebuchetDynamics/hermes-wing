# Task 1 Subagent Packet — Transcript Surface Deepening

Use this packet with an Agent/subagent dispatch tool.

Task tool description: `Implement Task 1: Establish the new public Transcript surface seam`

```text
You are implementing Task 1: Establish the new public Transcript surface seam.

## Task Description

**Files:**
- Create: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/lib/features/chat/widgets/transcript_surface.dart`
- Modify: `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app/test/features/chat/composer_actions_test.dart`

- [ ] Step 1: Write the failing public-seam test change.

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

- [ ] Step 2: Run test to verify it fails.

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/composer_actions_test.dart
```

Expected: FAIL because `package:navivox/features/chat/widgets/transcript_surface.dart` does not exist or `TranscriptSurface` is undefined.

- [ ] Step 3: Create minimal public module by copying and renaming the old adapter.

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

- [ ] Step 4: Run test to verify it passes.

Run:

```bash
cd /home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app
flutter test test/features/chat/composer_actions_test.dart
```

Expected: PASS. Both composer tests pass.

- [ ] Step 5: Commit this slice if the repository ownership is clear.

If `/home/xel/git/sages-openclaw/workspace-mineru/navivox-app` is still untracked under the parent repository, do not commit a partial Navivox project. Record the blocker instead of staging only a few files.

## Context

Navivox is the operator-facing Flutter app for talking to trusted local or self-hosted Gormes profiles. The accepted architecture direction is to deepen the **Transcript surface** before any package swap. The Transcript surface owns user turns, assistant turns, tool activity, safety notices, approval prompts, voice transcript bubbles, the composer, and message action sheets for the active Profile contact.

This is a rename-only first slice. Keep `NavivoxChatMessage` as the input model. Keep existing callbacks. Do not introduce a formal Operator intent type yet. Do not add chat packages. Do not refactor Local command handling out of `ChatScreen`.

## Work from

`/home/xel/git/sages-openclaw/workspace-mineru/navivox-app/app`

## Before You Begin

Ask questions if anything is unclear. If the project is still untracked under the parent repository, complete files/tests but report commit as BLOCKED with exact `git status --short -- /home/xel/git/sages-openclaw/workspace-mineru/navivox-app` evidence.

## Report Format

- Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented
- What you tested and exact output summary
- Files changed
- Self-review findings
- Blockers or concerns
```
