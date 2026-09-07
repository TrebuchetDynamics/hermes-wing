import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/router/app_routes.dart';

import '../features/hermes_chat/support/fake_hermes_channel.dart';
import '../features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../features/hermes_chat/support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('settings detail routes render inside the app shell and return', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(profiles: const []);
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader(const {}),
      activeChannel: channel,
    );
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go(AppRoutes.settings);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final voice = find.byKey(const ValueKey('settings-voice-link'));
    await Scrollable.ensureVisible(tester.element(voice), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(voice);
    await tester.pumpAndSettle();
    expect(find.text('Voice & speech'), findsWidgets);
    final speak = find.byKey(const ValueKey('voice-speak-replies-enabled'));
    await tester.ensureVisible(speak);
    await tester.tap(speak);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(speak).value, isTrue);
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-voice-link')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('voice-speak-replies-enabled')),
      findsNothing,
    );
    await tester.ensureVisible(voice);
    await tester.tap(voice);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(speak).value, isTrue);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    final diagnostics = find.byKey(const ValueKey('settings-diagnostics-link'));
    await Scrollable.ensureVisible(tester.element(diagnostics), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(diagnostics);
    await tester.pumpAndSettle();
    expect(find.text('Diagnostics'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
