import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';

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
        child: const MaterialApp(home: SettingsScreen()),
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
    expect(find.text('Appearance'), findsNothing);
    expect(find.byKey(const ValueKey('settings-open-hermes')), findsNothing);
    expect(
      find.byKey(const ValueKey('voice-continuous-enabled')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('voice-speak-replies-enabled')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('settings-voice-link')), findsOneWidget);
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
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);
  });
}
