import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/providers/hermes_directory_lifetime.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

class FailingStore extends FakeHermesEndpointStore {
  FailingStore()
    : super(
        initial: const HermesEndpointConfig(
          id: 'saved-owner',
          baseUrl: 'https://first.example.invalid',
        ),
      );
  int attempts = 0;
  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
  }) async {
    attempts++;
    throw StateError('synthetic secure storage unavailable');
  }
}

void main() {
  testWidgets(
    'manual connect with save failure cannot project stale saved pins',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'wing.hermes.pinned_sessions.v1': [
          jsonEncode(['saved-owner', 'default', 'sess_1']),
        ],
      });
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel();
      final store = FailingStore();
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({
          'saved-owner': const GatewaySummary(
            profiles: [],
            sessionsByProfile: {},
            unscopedSessions: [HermesSession(id: 'sess_1', source: 'fake')],
          ),
        }),
        activeChannel: channel,
      );
      await directory.start();
      await directory.activate(
        const GatewayContactId(gatewayId: 'saved-owner', profileId: 'default'),
      );
      final lifetime = HermesDirectoryLifetime()..attach(directory);
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((_) => directory),
          hermesDirectoryLifetimeProvider.overrideWithValue(lifetime),
        ],
      );
      addTearDown(() {
        container.dispose();
        lifetime.dispose();
        channel.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppShell(
              location: '/hermes',
              child: HermesChatScreen(initiallyEditingConnection: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pinned = find.byKey(const ValueKey('shell-pinned-sessions'));
      expect(pinned, findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('hermes-base-url-field')),
        'https://second.example.invalid',
      );
      final connect = find.byKey(const ValueKey('hermes-connect-button'));
      await tester.ensureVisible(connect);
      await tester.tap(connect);
      await tester.pumpAndSettle();
      expect(store.attempts, 1);
      expect(channel.state.isConnected, isTrue);
      expect(channel.state.connectedBaseUrl, 'https://second.example.invalid');
      expect(
        directory.activeContactId,
        const GatewayContactId(gatewayId: 'saved-owner', profileId: 'default'),
      );
      expect(
        find.byKey(const ValueKey('hermes-connection-save-error')),
        findsOneWidget,
      );
      expect(pinned, findsNothing);
    },
  );
}
