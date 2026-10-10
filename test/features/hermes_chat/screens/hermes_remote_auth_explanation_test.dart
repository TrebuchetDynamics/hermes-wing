import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../../../../integration_test/support/remote_auth_explanation_native_fixture.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('public Remote auth recovery $width text $scale', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await runRemoteAuthExplanationJourney(tester, capture: (_) async {});
      });
    }
  }
  testWidgets(
    'Remote and VPN explain token support without claiming OAuth detection',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel.disconnected();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesEndpointStoreProvider.overrideWithValue(
              FakeHermesEndpointStore(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HermesChatScreen(initiallyEditingConnection: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final mode in ['remote', 'vpn', 'local']) {
        final key = mode == 'local'
            ? 'hermes-connection-mode-local'
            : 'hermes-remote-transport-$mode';
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        final explanation = find.byKey(
          const ValueKey('hermes-remote-auth-explanation'),
        );
        if (mode == 'local') {
          expect(explanation, findsNothing);
        } else {
          expect(explanation, findsOneWidget);
          final copy = tester.widget<SelectableText>(explanation).data!;
          expect(copy, contains('Hermes Agent endpoint'));
          expect(copy, contains('Wing Link'));
          expect(copy, contains('provider API key'));
          expect(copy, contains('Browser OAuth sign-in is not supported'));
          expect(copy, contains('OAuth-only server cannot currently connect'));
          expect(copy, contains('retry explicitly'));
          expect(copy, isNot(contains('detected')));
          expect(find.bySemanticsLabel(copy), findsOneWidget);
        }
      }
      expect(channel.connectCalls, isEmpty);
      semantics.dispose();
    },
  );
}
