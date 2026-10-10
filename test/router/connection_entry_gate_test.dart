import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/widgets/connection_entry_gate.dart';
import '../features/hermes_chat/support/fake_hermes_channel.dart';
import '../features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../features/hermes_chat/support/fake_hermes_gateway_directory.dart';

void main() {
  for (final saved in [false, true]) {
    testWidgets('startup waits for secure ownership; saved=$saved', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final read = Completer<List<HermesEndpointConfig>>();
      final store = FakeHermesEndpointStore(onLoadProfiles: () => read.future);
      final channel = FakeHermesChannel.disconnected();
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesChannelProvider.overrideWith((_) => channel),
            hermesGatewayDirectoryProvider.overrideWith((_) => directory),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ConnectionEntryGate(
              child: Scaffold(body: Text('Saved owner shell')),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saved owner shell'), findsNothing);
      expect(find.byKey(const ValueKey('hermes-welcome')), findsNothing);
      read.complete(
        saved
            ? [
                HermesEndpointConfig(
                  baseUrl: 'https://example.invalid',
                  id: 'synthetic-owner',
                ),
              ]
            : [],
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-welcome')),
        saved ? findsNothing : findsOneWidget,
      );
      expect(
        find.text('Saved owner shell'),
        saved ? findsOneWidget : findsNothing,
      );
      expect(store.saveCalls, isEmpty);
      expect(store.clearCalls, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('unreadable secure store stays explicit and retryable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var reject = true;
    final store = FakeHermesEndpointStore(
      onLoadProfiles: () async {
        if (reject) throw StateError('private-storage-detail');
        return [];
      },
    );
    final channel = FakeHermesChannel.disconnected();
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({}),
      activeChannel: channel,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesChannelProvider.overrideWith((_) => channel),
          hermesGatewayDirectoryProvider.overrideWith((_) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ConnectionEntryGate(child: Text('Saved owner shell')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('private-storage-detail'), findsNothing);
    expect(find.byKey(const ValueKey('hermes-welcome')), findsNothing);
    reject = false;
    await tester.tap(find.text('Saved connections could not be read. Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hermes-welcome')), findsOneWidget);
    expect(store.saveCalls, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
