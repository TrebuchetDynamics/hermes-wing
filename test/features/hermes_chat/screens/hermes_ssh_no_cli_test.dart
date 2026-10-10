import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_add_screen.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('Android SSH and Remote entry do not require CLI QR setup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final store = FakeHermesEndpointStore();
    final channel = HermesApiChannel();
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({}),
      activeChannel: channel,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWith((_) => channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((_) => directory),
          hermesVoiceCaptureServiceProvider.overrideWithValue(null),
          hermesTextToSpeechServiceProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesAddScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scanner = find.byKey(const ValueKey('hermes-open-qr-scanner'));
    expect(scanner, findsNothing);
    expect(find.byKey(const ValueKey('hermes-base-url-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-api-key-field')), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('hermes-connection-mode-local')),
    );
    await tester.pumpAndSettle();
    expect(find.text('This phone'), findsOneWidget);
    expect(scanner, findsNothing);
    expect(find.byKey(const ValueKey('hermes-api-key-field')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('platform-local-skip-guide')),
    );
    await tester.tap(find.byKey(const ValueKey('platform-local-skip-guide')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hermes-api-key-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-base-url-field')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('hermes-connection-mode-ssh')),
    );
    await tester.tap(find.byKey(const ValueKey('hermes-connection-mode-ssh')));
    await tester.pumpAndSettle();
    expect(scanner, findsNothing);
    expect(find.byKey(const ValueKey('managed-ssh-host')), findsOneWidget);
    expect(find.byKey(const ValueKey('managed-ssh-password')), findsOneWidget);
    expect(
      find.textContaining('Start a fixed, trusted SSH tunnel outside Wing'),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('hermes-connection-mode-remote')),
    );
    await tester.pumpAndSettle();
    expect(scanner, findsNothing);
    expect(find.byKey(const ValueKey('hermes-base-url-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-api-key-field')), findsOneWidget);
    expect(channel.state.isConnected, isFalse);
    expect(await store.loadProfiles(), isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });
}
