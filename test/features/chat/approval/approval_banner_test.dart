import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/test_navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/chat/approval/approval_banner.dart';

void main() {
  testWidgets(
    'shows the prompt and resolves Allow into respondToApproval(true)',
    (tester) async {
      final channel = TestNavivoxChannel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ApprovalBanner(channel: channel)),
        ),
      );

      expect(find.byType(ApprovalBanner), findsOneWidget);
      expect(find.text('Allow'), findsNothing);

      channel.emitApprovalRequest(
        const NavivoxApprovalRequest(
          id: 'ap-1',
          toolCallId: 'tc-1',
          prompt: 'Allow shell.run to delete /tmp/x?',
          risk: 'medium',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('shell.run'), findsOneWidget);
      expect(find.text('Allow'), findsOneWidget);
      expect(find.text('Deny'), findsOneWidget);

      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(channel.approvalResponses.length, 1);
      expect(channel.approvalResponses.single.approvalId, 'ap-1');
      expect(channel.approvalResponses.single.approved, isTrue);
      // Banner clears after the response is sent.
      expect(find.text('Allow'), findsNothing);
    },
  );

  testWidgets('Deny calls respondToApproval(false)', (tester) async {
    final channel = TestNavivoxChannel();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ApprovalBanner(channel: channel)),
      ),
    );

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'ap-2',
        toolCallId: 'tc-2',
        prompt: 'Allow shell.run?',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deny'));
    await tester.pumpAndSettle();

    expect(channel.approvalResponses.single.approved, isFalse);
  });
}
