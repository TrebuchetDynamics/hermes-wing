import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('settings manage gateways without rendering credentials', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'a',
          label: 'Alpha',
          baseUrl: 'https://a',
          apiKey: 'sentinel-api-key',
        ),
        HermesEndpointConfig(
          id: 'b',
          label: 'Beta',
          baseUrl: 'https://b',
          apiKey: 'b-secret',
        ),
      ],
    );
    final loader = FakeGatewaySummaryLoader({
      'a': gatewaySummary(['a1']),
      'b': gatewaySummary(['b1']),
    });
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: loader,
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-connect-another-gateway')),
      findsOneWidget,
    );
    expect(find.text('Hermes Agent dashboard'), findsNothing);
    // ROADMAP 5.1 reintroduced Appearance as the theme picker; the legacy
    // dashboard rows above must still stay gone.
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-open-hermes')), findsNothing);
    final voiceLink = find.byKey(const ValueKey('settings-voice-link'));
    await tester.scrollUntilVisible(voiceLink, 300);
    expect(
      find.byKey(const ValueKey('voice-continuous-enabled')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('voice-speak-replies-enabled')),
      findsOneWidget,
    );
    expect(voiceLink, findsOneWidget);
    expect(
      find.text('Credentials stay in secure storage; values hidden'),
      findsOneWidget,
    );
    expect(find.textContaining('sentinel-api-key'), findsNothing);

    var gatewayMenu = find.byKey(const ValueKey('settings-gateway-menu-a'));
    await Scrollable.ensureVisible(tester.element(gatewayMenu), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(gatewayMenu);
    await tester.pumpAndSettle();
    expect(find.text('Manage agents'), findsOneWidget);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-gateway-rename-field')),
      'Work',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    gatewayMenu = find.byKey(const ValueKey('settings-gateway-menu-a'));
    await Scrollable.ensureVisible(tester.element(gatewayMenu), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(gatewayMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reconnect'));
    await tester.pumpAndSettle();
    expect(loader.calls.where((id) => id == 'a'), hasLength(2));
    expect(loader.calls.where((id) => id == 'b'), hasLength(1));

    gatewayMenu = find.byKey(const ValueKey('settings-gateway-menu-a'));
    await Scrollable.ensureVisible(tester.element(gatewayMenu), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(gatewayMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-gateway-remove-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('settings-gateway-remove-confirm')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);

    final diagnostics = find.byKey(const ValueKey('settings-diagnostics-link'));
    await tester.scrollUntilVisible(diagnostics, 300);
    expect(diagnostics, findsOneWidget);
  });

  testWidgets(
    'settings rotates an inactive gateway connection without revealing credentials',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final store = FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(
            id: 'a',
            label: 'Alpha',
            baseUrl: 'https://old.example',
            apiKey: 'old-sentinel-secret',
          ),
        ],
      );
      final loader = FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      });
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: loader,
        activeChannel: channel,
      );
      await directory.refresh();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('settings-gateway-menu-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update connection'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('settings-gateway-base-url-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('settings-gateway-api-key-field')),
        findsOneWidget,
      );
      expect(find.textContaining('old-sentinel-secret'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('settings-gateway-api-key-field')),
            )
            .controller
            ?.text,
        isEmpty,
      );

      await tester.enterText(
        find.byKey(const ValueKey('settings-gateway-base-url-field')),
        'ftp://invalid.example',
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-gateway-connection-save')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Enter an HTTP or HTTPS gateway origin.'),
        findsOneWidget,
      );
      expect(store.saveCalls, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('settings-gateway-base-url-field')),
        'https://new.example/private?secret=value',
      );
      await tester.enterText(
        find.byKey(const ValueKey('settings-gateway-api-key-field')),
        'rotated-sentinel-secret',
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-gateway-connection-save')),
      );
      await tester.pumpAndSettle();

      expect(store.saveCalls.single.id, 'a');
      expect(store.saveCalls.single.baseUrl, 'https://new.example');
      expect(store.saveCalls.single.apiKey, 'rotated-sentinel-secret');
      expect(directory.gateways.single.baseUrl, 'https://new.example');
      expect(find.textContaining('rotated-sentinel-secret'), findsNothing);
      expect(find.textContaining('old-sentinel-secret'), findsNothing);
      expect(loader.calls, ['a', 'a']);
    },
  );

  testWidgets('gateway connection editor fits a phone at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(id: 'a', baseUrl: 'https://a.example'),
      ],
    );
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-gateway-menu-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update connection'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Update gateway connection'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-gateway-base-url-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-gateway-connection-save')),
      findsOneWidget,
    );
  });

  testWidgets('settings overview fits a narrow phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);
  });
}
