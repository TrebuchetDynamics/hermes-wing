import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/test_navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/chat/widgets/approval_banner.dart';

void main() {
  testWidgets('high-risk approvals show a warning icon + "High risk" label', (
    tester,
  ) async {
    final channel = TestNavivoxChannel();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ApprovalBanner(channel: channel)),
      ),
    );

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'ap-h',
        toolCallId: 'tc-h',
        prompt: 'shell.run rm -rf /?',
        risk: 'high',
      ),
    );
    await tester.pump();
    await tester.pump();

    final badge = find.byKey(const ValueKey('approval-risk-badge'));
    expect(badge, findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.byIcon(Icons.warning)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: badge, matching: find.text('High risk')),
      findsOneWidget,
    );
  });

  testWidgets('medium-risk approvals show a "Medium risk" label', (
    tester,
  ) async {
    final channel = TestNavivoxChannel();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ApprovalBanner(channel: channel)),
      ),
    );

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'ap-m',
        toolCallId: 'tc-m',
        prompt: 'shell.run mv x y?',
        risk: 'medium',
      ),
    );
    await tester.pump();
    await tester.pump();

    final badge = find.byKey(const ValueKey('approval-risk-badge'));
    expect(badge, findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('Medium risk')),
      findsOneWidget,
    );
  });

  testWidgets('approvals without a risk field omit the risk badge entirely', (
    tester,
  ) async {
    final channel = TestNavivoxChannel();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ApprovalBanner(channel: channel)),
      ),
    );

    channel.emitApprovalRequest(
      const NavivoxApprovalRequest(
        id: 'ap-n',
        toolCallId: 'tc-n',
        prompt: 'shell.run ls?',
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('approval-risk-badge')), findsNothing);
  });
}
