import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import '../../shared/transcript_surface_test_app.dart';
import '../../shared/transcript_test_fixtures.dart';

void main() {
  testWidgets(
    'tool-call tile shows nothing extra when there are no artifacts',
    (tester) async {
      final message = transcriptToolMessage(
        id: 'm-1',
        createdAt: DateTime(2026, 5, 7, 10),
        toolCall: transcriptToolCall(
          name: 'shell.run',
          status: 'completed',
          summary: 'ls -la',
        ),
      );

      await tester.pumpWidget(
        transcriptSurfaceTestApp(
          messages: [message],
          onSend: transcriptNoopSend,
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
      final message = transcriptToolMessage(
        id: 'm-2',
        createdAt: DateTime(2026, 5, 7, 10),
        toolCall: transcriptToolCall(
          name: 'shell.run',
          status: 'completed',
          summary: 'ran git diff',
          approval: transcriptShellApproval(),
          artifacts: [
            transcriptDiffArtifact(),
            transcriptScreenshotArtifact(ref: 'artifacts/a-2'),
          ],
        ),
      );

      await tester.pumpWidget(
        transcriptSurfaceTestApp(
          messages: [message],
          onSend: transcriptNoopSend,
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
      transcriptNoticeMessage(
        id: 'safe-1',
        kind: NavivoxMessageKind.safetyWarning,
        createdAt: DateTime(2026, 5, 7, 10),
        notice: transcriptSafetyNotice(
          id: 'safe-1',
          severity: 'high',
          message: 'Shell command wants to modify files',
          risk: 'Writes may change the workspace',
        ),
      ),
      transcriptNoticeMessage(
        id: 'approval-1',
        kind: NavivoxMessageKind.approvalRequest,
        createdAt: DateTime(2026, 5, 7, 10, 1),
        notice: transcriptApprovalNotice(
          id: 'approval-1',
          approvalId: 'approval-1',
          toolCallId: 'call-shell',
          message: 'Approve shell.run?',
          risk: 'Command can edit files',
        ),
      ),
    ];

    await tester.pumpWidget(
      transcriptSurfaceTestApp(messages: messages, onSend: transcriptNoopSend),
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
