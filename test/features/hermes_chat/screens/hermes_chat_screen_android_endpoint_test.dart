import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

void main() {
  testWidgets('first launch opens the agent directory, not server setup', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(
            FakeHermesChannel.disconnected(),
          ),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profiles'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gateway-contacts-empty')),
      findsOneWidget,
    );
    expect(find.text('Add gateway or profile'), findsOneWidget);
    expect(find.text('Connect to your Hermes VPS'), findsNothing);
    expect(find.byKey(const ValueKey('hermes-base-url-field')), findsNothing);
  });

  testWidgets('manual setup announces saved gateway loading', (tester) async {
    final loading = Completer<List<HermesEndpointConfig>>();
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(onLoadProfiles: () => loading.future);
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(initiallyEditingConnection: true),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-endpoints-loading')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Loading saved Hermes gateways'),
      findsOneWidget,
    );

    loading.complete(const []);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hermes-endpoints-loading')),
      findsNothing,
    );
  });

  testWidgets('saved gateway storage failure stays retryable', (tester) async {
    var attempts = 0;
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore(
      onLoadProfiles: () async {
        attempts += 1;
        if (attempts == 1) throw StateError('private storage failure');
        return const [
          HermesEndpointConfig(
            id: 'lab',
            label: 'Lab gateway',
            baseUrl: 'https://example.invalid',
          ),
        ];
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(initiallyEditingConnection: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved gateways unavailable'), findsOneWidget);
    expect(find.textContaining('private storage failure'), findsNothing);
    expect(find.byKey(const ValueKey('hermes-base-url-field')), findsOneWidget);

    final retry = find.byKey(const ValueKey('hermes-endpoints-retry'));
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    final loadsBeforeRetry = store.loadProfilesCalls;
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(store.loadProfilesCalls, loadsBeforeRetry + 1);
    expect(
      find.byKey(const ValueKey('hermes-endpoint-profile-lab')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-endpoints-load-error')),
      findsNothing,
    );
  });

  testWidgets('manual endpoint fields opt out of autofill and IME learning', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);

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

    for (final key in [
      'hermes-base-url-field',
      'hermes-api-key-field',
      'hermes-profile-label-field',
    ]) {
      final field = tester.widget<TextField>(find.byKey(ValueKey(key)));
      expect(field.enableIMEPersonalizedLearning, isFalse, reason: key);
      expect(field.autofillHints, isEmpty, reason: key);
    }
  });

  testWidgets('manual setup can open on an existing chat screen', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore();

    Widget app({required bool editingConnection}) => ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HermesChatScreen(initiallyEditingConnection: editingConnection),
      ),
    );

    await tester.pumpWidget(app(editingConnection: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hermes-base-url-field')), findsNothing);

    await tester.pumpWidget(app(editingConnection: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-base-url-field')), findsOneWidget);
  });
}
