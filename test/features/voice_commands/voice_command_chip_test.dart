import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice_commands/models/voice_command.dart';
import 'package:wing/features/voice_commands/widgets/voice_command_chip.dart';

void main() {
  const result = VoiceRouteResult(
    command: VoiceCommandId.newSession,
    args: {},
    tier: VoiceCommandTier.confirm,
    transcript: 'start a new conversation',
  );

  Widget harness({
    required VoidCallback onConfirm,
    required VoidCallback onDecline,
    Duration? autoDeclineAfter,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: VoiceCommandChip(
          result: result,
          onConfirm: onConfirm,
          onDecline: onDecline,
          autoDeclineAfter: autoDeclineAfter,
        ),
      ),
    );
  }

  testWidgets('renders the describe() text', (tester) async {
    await tester.pumpWidget(harness(onConfirm: () {}, onDecline: () {}));

    expect(find.text('Start a new session?'), findsOneWidget);
  });

  testWidgets('Confirm fires onConfirm exactly once', (tester) async {
    var confirmCount = 0;
    await tester.pumpWidget(
      harness(onConfirm: () => confirmCount++, onDecline: () {}),
    );

    await tester.tap(find.byKey(const ValueKey('voice-command-chip-confirm')));
    await tester.pump();

    expect(confirmCount, 1);
  });

  testWidgets("'Not now' fires onDecline", (tester) async {
    var declineCount = 0;
    await tester.pumpWidget(
      harness(onConfirm: () {}, onDecline: () => declineCount++),
    );

    await tester.tap(find.byKey(const ValueKey('voice-command-chip-decline')));
    await tester.pump();

    expect(declineCount, 1);
  });

  testWidgets('autoDeclineAfter fires onDecline once the duration elapses', (
    tester,
  ) async {
    var declineCount = 0;
    await tester.pumpWidget(
      harness(
        onConfirm: () {},
        onDecline: () => declineCount++,
        autoDeclineAfter: const Duration(seconds: 5),
      ),
    );

    expect(declineCount, 0);
    await tester.pump(const Duration(seconds: 5));

    expect(declineCount, 1);
  });

  testWidgets('a sticky chip (null autoDeclineAfter) never auto-declines', (
    tester,
  ) async {
    var declineCount = 0;
    await tester.pumpWidget(
      harness(onConfirm: () {}, onDecline: () => declineCount++),
    );

    await tester.pump(const Duration(seconds: 30));

    expect(declineCount, 0);
  });

  testWidgets('the timer is cancelled on dispose (no pending-timer failure)', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        onConfirm: () {},
        onDecline: () {},
        autoDeclineAfter: const Duration(seconds: 5),
      ),
    );

    await tester.pumpWidget(const SizedBox());
    // If dispose() failed to cancel the timer, flutter_test would flag a
    // pending timer at test teardown.
  });
}
