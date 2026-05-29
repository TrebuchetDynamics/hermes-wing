import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/widgets/transcript/transcript_surface.dart';

void main() {
  testWidgets(
    'tool-call tile shows nothing extra when there are no artifacts',
    (tester) async {
      final message = NavivoxChatMessage(
        id: 'm-1',
        author: NavivoxMessageAuthor.assistant,
        kind: NavivoxMessageKind.toolCall,
        createdAt: DateTime(2026, 5, 7, 10),
        toolCall: const NavivoxToolCall(
          name: 'shell.run',
          status: 'completed',
          summary: 'ls -la',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptSurface(messages: [message], onSend: (_) {}),
          ),
        ),
      );

      expect(find.text('shell.run'), findsOneWidget);
      expect(find.text('completed'), findsOneWidget);
      expect(find.text('ls -la'), findsOneWidget);
      expect(find.byIcon(Icons.attachment), findsNothing);
    },
  );

  testWidgets(
    'tool-call tile lists each artifact with kind + title + summary',
    (tester) async {
      final message = NavivoxChatMessage(
        id: 'm-2',
        author: NavivoxMessageAuthor.assistant,
        kind: NavivoxMessageKind.toolCall,
        createdAt: DateTime(2026, 5, 7, 10),
        toolCall: const NavivoxToolCall(
          name: 'shell.run',
          status: 'completed',
          summary: 'ran git diff',
          approval: NavivoxToolApproval(
            id: 'approval-shell',
            status: 'approval_required',
            prompt: 'Approve shell.run?',
            risk: 'Writes files',
          ),
          artifacts: [
            NavivoxToolArtifact(
              id: 'a-1',
              kind: 'file',
              title: 'diff.patch',
              summary: '14 lines changed',
            ),
            NavivoxToolArtifact(
              id: 'a-2',
              kind: 'image',
              title: 'screenshot.png',
              ref: 'artifacts/a-2',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptSurface(messages: [message], onSend: (_) {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.attachment), findsNWidgets(2));
      expect(find.text('diff.patch'), findsOneWidget);
      expect(find.text('14 lines changed'), findsOneWidget);
      expect(find.text('screenshot.png'), findsOneWidget);
      expect(find.text('artifacts/a-2'), findsOneWidget);
      expect(find.text('image'), findsOneWidget);
      expect(find.text('file'), findsOneWidget);
      expect(find.text('Approval required'), findsOneWidget);
      expect(find.text('Approve shell.run?'), findsOneWidget);
      expect(find.text('Writes files'), findsOneWidget);
    },
  );

  testWidgets('safety and approval messages render as first-class cards', (
    tester,
  ) async {
    final messages = [
      NavivoxChatMessage(
        id: 'safe-1',
        author: NavivoxMessageAuthor.system,
        kind: NavivoxMessageKind.safetyWarning,
        createdAt: DateTime(2026, 5, 7, 10),
        safetyNotice: const NavivoxSafetyNotice(
          id: 'safe-1',
          severity: 'high',
          message: 'Shell command wants to modify files',
          risk: 'Writes may change the workspace',
        ),
      ),
      NavivoxChatMessage(
        id: 'approval-1',
        author: NavivoxMessageAuthor.system,
        kind: NavivoxMessageKind.approvalRequest,
        createdAt: DateTime(2026, 5, 7, 10, 1),
        safetyNotice: const NavivoxSafetyNotice(
          id: 'approval-1',
          approvalId: 'approval-1',
          toolCallId: 'call-shell',
          message: 'Approve shell.run?',
          risk: 'Command can edit files',
        ),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(messages: messages, onSend: (_) {}),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('safety-warning-card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('approval-required-card')),
      findsOneWidget,
    );
    expect(find.text('Safety warning'), findsOneWidget);
    expect(find.text('Approval required'), findsOneWidget);
    expect(find.text('high'), findsOneWidget);
    expect(find.text('Shell command wants to modify files'), findsOneWidget);
    expect(find.text('Writes may change the workspace'), findsOneWidget);
    expect(find.text('Approve shell.run?'), findsOneWidget);
    expect(find.text('Command can edit files'), findsOneWidget);
  });
}
