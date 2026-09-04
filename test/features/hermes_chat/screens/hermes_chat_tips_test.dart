import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

Widget _app(FakeHermesChannel channel) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(channel)],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HermesChatScreen(),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a connected chat shows the voice tip once', (tester) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(_app(channel));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('wing-tip-voice')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wing-tip-voice-dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wing-tip-voice')), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).getStringList(
        'wing.tips.dismissed.v1',
      ),
      contains('voice'),
    );
  });

  testWidgets('the approvals tip rides with the first approval card', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(_app(channel));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('wing-tip-approvals')), findsNothing);

    channel.emitApprovalRequest(
      const HermesApprovalRequest(
        id: 'approval-1',
        toolCallId: 'tool-1',
        prompt: 'Run the deploy script?',
        runId: 'run-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('wing-tip-approvals')), findsOneWidget);

    final dismiss = find.byKey(const ValueKey('wing-tip-approvals-dismiss'));
    await tester.ensureVisible(dismiss);
    await tester.pumpAndSettle();
    await tester.tap(dismiss);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wing-tip-approvals')), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-approval-banner')),
      findsOneWidget,
    );
  });

  testWidgets('the voice tip stays usable at 200% text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('wing-tip-voice')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wing-tip-voice-dismiss')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('wing-tip-voice')), findsNothing);
  });

  testWidgets('the voice tip stays hidden while disconnected', (tester) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);

    await tester.pumpWidget(_app(channel));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('wing-tip-voice')), findsNothing);
  });
}
