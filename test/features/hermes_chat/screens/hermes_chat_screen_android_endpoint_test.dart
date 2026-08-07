import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    expect(find.text('Agents'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gateway-contacts-empty')),
      findsOneWidget,
    );
    expect(find.text('Add gateway or agent'), findsOneWidget);
    expect(find.text('Connect to your Hermes VPS'), findsNothing);
    expect(find.byKey(const ValueKey('hermes-base-url-field')), findsNothing);
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
