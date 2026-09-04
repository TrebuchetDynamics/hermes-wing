import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

/// The approval review sheet renders agent-controlled text — a tool prompt,
/// a risk note, and a tool call id — behind redaction and length bounds. It
/// had almost no coverage, so a change to the shared redaction it calls could
/// have broken it silently.
Widget _app(FakeHermesChannel channel) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(channel)],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HermesChatScreen(),
  ),
);

Future<void> _openReview(
  WidgetTester tester,
  FakeHermesChannel channel,
  HermesApprovalRequest request,
) async {
  await tester.pumpWidget(_app(channel));
  await tester.pumpAndSettle();
  channel.emitApprovalRequest(request);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Review'));
  await tester.pumpAndSettle();
  // Prove the sheet actually opened, so the redaction assertions below can
  // never pass vacuously.
  expect(find.text('Review Hermes approval'), findsOneWidget);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a secret in a tool prompt is redacted in the review sheet', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await _openReview(
      tester,
      channel,
      const HermesApprovalRequest(
        id: 'approval-1',
        toolCallId: 'tool-1',
        prompt: 'curl -H "Authorization: Bearer supersecrettokenvalue" host',
        runId: 'run-1',
      ),
    );

    expect(find.textContaining('supersecrettokenvalue'), findsNothing);
    expect(find.textContaining('[redacted]'), findsWidgets);
  });

  testWidgets('a local path in a risk note is redacted in the review sheet', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await _openReview(
      tester,
      channel,
      const HermesApprovalRequest(
        id: 'approval-1',
        toolCallId: 'tool-1',
        prompt: 'Run the deploy script?',
        risk: 'writes to /home/operator/.hermes/config.yaml',
        runId: 'run-1',
      ),
    );

    expect(find.textContaining('/home/operator'), findsNothing);
  });

  testWidgets('current choices hide unsupported approval decisions', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await _openReview(
      tester,
      channel,
      const HermesApprovalRequest(
        id: '',
        toolCallId: '',
        prompt: 'Run the reviewed command?',
        command: 'bash -c safe-command',
        choices: {HermesApprovalDecision.once, HermesApprovalDecision.deny},
        runId: 'run-1',
      ),
    );

    expect(find.textContaining('Command: bash -c safe-command'), findsWidgets);
    expect(
      find.byKey(const ValueKey('hermes-approval-sheet-session')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('hermes-approval-sheet-always')),
      findsNothing,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('hermes-approval-sheet-once')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a current run-id-only approval can be answered', (tester) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await _openReview(
      tester,
      channel,
      const HermesApprovalRequest(
        id: '   ',
        toolCallId: 'tool-1',
        prompt: 'Run the deploy script?',
        runId: 'run-1',
      ),
    );

    final approve = find.byKey(const ValueKey('hermes-approval-sheet-once'));
    expect(approve, findsOneWidget);
    expect(tester.widget<FilledButton>(approve).onPressed, isNotNull);

    await tester.tap(approve);
    await tester.pumpAndSettle();

    expect(channel.respondToApprovalCalls, [
      {
        'approvalId': '',
        'decision': HermesApprovalDecision.once,
        'runId': 'run-1',
      },
    ]);
  });
}
