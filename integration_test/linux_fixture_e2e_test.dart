import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../test/features/hermes_chat/support/fake_hermes_channel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Linux native app boots, creates a session, and sends a turn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            const EmptyHermesEndpointStore(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final priorSessionId = channel.state.activeSessionId;
    await tester.tap(find.byKey(const ValueKey('hermes-new-session')));
    await tester.pumpAndSettle();
    expect(channel.state.activeSessionId, isNot(priorSessionId));

    const message = 'linux native e2e';
    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      message,
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(
      channel.state.activeMessages.any((turn) => turn.text == 'echo: $message'),
      isTrue,
    );
    expect(find.text('echo: $message'), findsOneWidget);
  });
}
