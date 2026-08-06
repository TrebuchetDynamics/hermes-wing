import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/gateway/screens/gateway_screen.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesCapabilityDocument _capabilities({
  bool detailedHealth = true,
  bool grantGatewayRead = true,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': [if (grantGatewayRead) 'gateway:read'],
  },
  'endpoints': {
    if (detailedHealth)
      'health_detailed': {
        'method': 'GET',
        'path': '/health/detailed',
        'required_scopes': ['gateway:read'],
      },
  },
});

const _initialHealth = HermesHealthStatus(
  status: 'ok',
  platform: 'hermes-agent',
  version: '0.18.0',
  gatewayState: 'running',
  activeAgents: 1,
);

const _richHealth = HermesHealthStatus(
  status: 'degraded',
  platform: 'hermes-agent',
  version: '0.18.1',
  gatewayState: 'draining',
  activeAgents: 2,
  gatewayBusy: true,
  gatewayDrainable: false,
  updatedAt: '2026-07-18T23:10:00.000Z',
  pid: 4321,
  platforms: [
    HermesGatewayPlatformStatus(name: 'discord', status: 'degraded'),
    HermesGatewayPlatformStatus(name: 'telegram', status: 'connected'),
  ],
  readiness: HermesGatewayReadiness(
    status: 'degraded',
    checks: [
      HermesGatewayReadinessCheck(id: 'state_db', status: 'ok'),
      HermesGatewayReadinessCheck(
        id: 'config',
        status: 'degraded',
        detail: 'using defaults',
      ),
      HermesGatewayReadinessCheck(id: 'disk', status: 'ok', usedPercent: 42.5),
      HermesGatewayReadinessCheck(
        id: 'gateway',
        status: 'ok',
        connectedPlatforms: 1,
        configuredPlatforms: 2,
      ),
      HermesGatewayReadinessCheck(
        id: 'background_queues',
        status: 'ok',
        activeApiRuns: 3,
        processCompletions: 4,
        activeDelegations: 5,
      ),
    ],
  ),
);

Widget _testApp(
  FakeHermesChannel channel, {
  double textScale = 1,
  HermesGatewayDirectory? directory,
}) => ProviderScope(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    if (directory != null)
      hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const GatewayScreen(),
  ),
);

void main() {
  testWidgets(
    'shows advertised bounded gateway status without admin controls',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _capabilities(),
        detailedHealth: _initialHealth,
      );
      addTearDown(channel.dispose);

      await tester.pumpWidget(_testApp(channel));
      await tester.pumpAndSettle();

      expect(find.text('Gateway'), findsWidgets);
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('hermes-agent'), findsOneWidget);
      expect(find.text('0.18.0'), findsOneWidget);
      expect(find.text('running'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('Read-only gateway status'), findsOneWidget);
      expect(find.text('Restart'), findsNothing);
      expect(find.text('Configure'), findsNothing);
      expect(find.text('Logs'), findsNothing);
    },
  );

  testWidgets('shows bounded readiness, workload, and platform diagnostics', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      detailedHealth: _richHealth,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Busy'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text('2026-07-18T23:10:00.000Z'), findsOneWidget);
    expect(find.text('4321'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Runtime readiness'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Runtime readiness'), findsOneWidget);
    expect(find.text('State database'), findsOneWidget);
    expect(find.textContaining('using defaults'), findsOneWidget);
    expect(find.textContaining('42.5% used'), findsOneWidget);
    expect(find.textContaining('1 of 2 connected'), findsOneWidget);
    expect(
      find.textContaining('3 API runs · 4 completions · 5 delegations'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Messaging platforms'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Messaging platforms'), findsOneWidget);
    expect(find.text('discord'), findsOneWidget);
    expect(find.text('telegram'), findsOneWidget);
    expect(find.text('private stack'), findsNothing);
    expect(find.text('Restart'), findsNothing);
  });

  testWidgets('refresh reloads detailed health through the channel seam', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      detailedHealth: _initialHealth,
      refreshedDetailedHealth: const HermesHealthStatus(
        status: 'ok',
        platform: 'hermes-agent',
        version: '0.18.1',
        gatewayState: 'running',
        activeAgents: 3,
      ),
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-refresh-button')));
    await tester.pumpAndSettle();

    expect(channel.loadDetailedHealthCalls, 1);
    expect(find.text('0.18.1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('unsupported detailed health fails closed and hides stale data', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(detailedHealth: false),
      detailedHealth: _initialHealth,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('This gateway did not advertise detailed health status.'),
      findsOneWidget,
    );
    expect(find.text('0.18.0'), findsNothing);
    expect(find.byKey(const ValueKey('gateway-refresh-button')), findsNothing);
  });

  testWidgets('detailed health requires the granted gateway read scope', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(grantGatewayRead: false),
      detailedHealth: _initialHealth,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('This gateway did not advertise detailed health status.'),
      findsOneWidget,
    );
    expect(find.text('Healthy'), findsNothing);
    expect(find.byKey(const ValueKey('gateway-refresh-button')), findsNothing);
    expect(channel.loadDetailedHealthCalls, 0);
  });

  testWidgets('health load failure does not expose raw errors or stale data', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      detailedHealth: _initialHealth,
      optionalResourceErrors: const {
        HermesOptionalResource.detailedHealth:
            'private gateway process path and stack trace',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Detailed gateway status could not be loaded from Hermes.'),
      findsOneWidget,
    );
    expect(find.textContaining('private gateway'), findsNothing);
    expect(find.text('0.18.0'), findsNothing);
  });

  testWidgets('gateway picker activates the selected saved gateway', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha',
          baseUrl: 'https://alpha',
        ),
        HermesEndpointConfig(
          id: 'beta',
          label: 'Beta',
          baseUrl: 'https://beta',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
        'beta': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(_testApp(channel, directory: directory));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-status-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(directory.activeContactId?.gatewayId, 'beta');
    expect(channel.connectCalls.last.baseUrl, 'https://beta');
  });

  testWidgets('disconnect keeps the saved gateway available', (tester) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha',
          baseUrl: 'https://alpha',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    await directory.activateGateway('alpha');

    await tester.pumpWidget(_testApp(channel, directory: directory));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-disconnect-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-disconnect-confirm')));
    await tester.pumpAndSettle();

    expect(channel.disconnectCalls, 1);
    expect(directory.activeContactId, isNull);
    expect(directory.gateways.map((gateway) => gateway.id), contains('alpha'));
  });

  testWidgets('retains gateway status at 200% text scale', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      detailedHealth: _richHealth,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Messaging platforms'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Messaging platforms'), findsOneWidget);
  });
}
