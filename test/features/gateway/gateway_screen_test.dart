import 'dart:async';

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
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
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

const _testFingerprint = 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

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

class _DeferredHealthChannel extends FakeHermesChannel {
  _DeferredHealthChannel()
    : super(
        capabilities: _capabilities(),
        basicHealth: _initialHealth,
        detailedHealth: _initialHealth,
        connectedBaseUrl: 'https://initial.example',
      );

  final pending = <Completer<void>>[];

  Future<void> replaceConnection(String baseUrl) async {
    await disconnect();
    await connect(baseUrl: baseUrl);
  }

  @override
  Future<void> loadDetailedHealth() {
    loadDetailedHealthCalls += 1;
    final completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }
}

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

Future<HermesGatewayDirectory> _activeTrustDirectory(
  FakeHermesChannel channel,
) async {
  final directory = directoryFor(
    configs: const [
      HermesEndpointConfig(
        id: 'alpha',
        label: 'Alpha',
        baseUrl: 'https://alpha',
        wingLinkOrigin: 'https://host.example:8654',
        wingLinkToken: 'stored-token',
        wingLinkHostFingerprint: _testFingerprint,
        wingLinkDeviceId: 'cred_phone',
      ),
    ],
    loader: FakeGatewaySummaryLoader({
      'alpha': gatewaySummary(['default']),
    }),
    activeChannel: channel,
  );
  await directory.refresh();
  await directory.activateGateway('alpha');
  return directory;
}

void main() {
  testWidgets('legacy metadata never opens management or erases saved access', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      basicHealth: _initialHealth,
      refreshedDetailedHealth: _initialHealth,
    );
    addTearDown(channel.dispose);
    const config = HermesEndpointConfig(
      id: 'alpha',
      label: 'Alpha',
      baseUrl: 'https://alpha.example',
      apiKey: 'fixture-agent-key',
      wingLinkOrigin: 'https://link.example',
      wingLinkToken: 'fixture-link-token',
      wingLinkPendingCredentialId: 'fixture-pending',
      wingLinkHostFingerprint: _testFingerprint,
      wingLinkDeviceId: 'fixture-device',
    );
    var recoveries = 0;
    final store = FakeHermesEndpointStore(profiles: const [config]);
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
      }),
      activeChannel: channel,
      pendingCredentialRecovery: (_) async {
        recoveries++;
        return false;
      },
    );
    await directory.refresh();
    expect(recoveries, 0);
    await directory.activateGateway('alpha');
    await tester.pumpWidget(_testApp(channel, directory: directory));
    await tester.pumpAndSettle();
    expect(recoveries, 0);
    expect(find.byKey(const ValueKey('gateway-trust-card')), findsNothing);
    expect(find.text('Revoke this device'), findsNothing);
    expect(find.textContaining('wing-link approvals'), findsNothing);
    expect(find.text('Healthy'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gateway-refresh-button')));
    await tester.pumpAndSettle();
    expect(channel.loadDetailedHealthCalls, 1);

    await tester.tap(find.byKey(const ValueKey('gateway-disconnect-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(channel.disconnectCalls, 0);
    await tester.tap(find.byKey(const ValueKey('gateway-disconnect-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-disconnect-confirm')));
    await tester.pumpAndSettle();
    expect(channel.disconnectCalls, 1);
    expect(directory.activeContactId, isNull);
    final connects = channel.connectCalls.length;
    await directory.renameGateway('alpha', 'Renamed');
    await tester.pumpAndSettle();
    expect(channel.connectCalls, hasLength(connects));
    await tester.tap(find.byKey(const ValueKey('gateway-connect-chat-button')));
    await tester.pumpAndSettle();
    expect(channel.connectCalls, hasLength(connects + 1));
    expect(channel.connectCalls.last.baseUrl, config.baseUrl);
    expect(channel.connectCalls.last.apiKey, config.apiKey);
    expect(directory.activeContactId?.gatewayId, 'alpha');
    expect(recoveries, 0);
    final retained = (await store.loadProfiles()).single;
    expect(retained.baseUrl, config.baseUrl);
    expect(retained.apiKey, config.apiKey);
    expect(retained.wingLinkOrigin, config.wingLinkOrigin);
    expect(retained.wingLinkToken, config.wingLinkToken);
    expect(
      retained.wingLinkPendingCredentialId,
      config.wingLinkPendingCredentialId,
    );
    expect(retained.wingLinkHostFingerprint, config.wingLinkHostFingerprint);
    expect(retained.wingLinkDeviceId, config.wingLinkDeviceId);
    expect(store.deleteProfileCalls, isEmpty);
    expect(store.clearCalls, 0);
  });

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

      expect(find.text('Connections'), findsWidgets);
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
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('gateway-body-list')),
        matching: find.byType(Scrollable),
      ),
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
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('gateway-body-list')),
        matching: find.byType(Scrollable),
      ),
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

  testWidgets('stale health failure does not affect a replacement connection', (
    tester,
  ) async {
    final channel = _DeferredHealthChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-refresh-button')));
    await tester.pump();
    expect(channel.loadDetailedHealthCalls, 1);

    await channel.replaceConnection('https://replacement.example');
    await tester.pump();
    channel.pending.single.completeError(StateError('old gateway failed'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('gateway-status-inline-retry')),
      findsNothing,
    );
    expect(find.text('Gateway status unavailable'), findsNothing);
    expect(find.text('0.18.0'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('gateway-refresh-button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('unsupported detailed health falls back to basic health', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(detailedHealth: false),
      basicHealth: _initialHealth,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('0.18.0'), findsOneWidget);
    expect(find.text('Active agents'), findsNothing);
    expect(
      find.text(
        'Connected. Showing basic health because this gateway does not advertise detailed status.',
      ),
      findsOneWidget,
    );
    expect(find.text('Gateway status unavailable'), findsNothing);
    expect(find.byKey(const ValueKey('gateway-refresh-button')), findsNothing);
  });

  testWidgets('detailed health requires the granted gateway read scope', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(grantGatewayRead: false),
      basicHealth: _initialHealth,
      detailedHealth: _richHealth,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('0.18.0'), findsOneWidget);
    expect(find.text('0.18.1'), findsNothing);
    expect(find.byKey(const ValueKey('gateway-refresh-button')), findsNothing);
    expect(channel.loadDetailedHealthCalls, 0);
  });

  testWidgets('detailed health failure falls back without exposing raw errors', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      basicHealth: _initialHealth,
      refreshedDetailedHealth: _richHealth,
      optionalResourceErrors: const {
        HermesOptionalResource.detailedHealth:
            'private gateway process path and stack trace',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Healthy'), findsOneWidget);
    expect(
      find.text(
        'Connected. Basic health is available, but detailed status could not be loaded.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('private gateway'), findsNothing);
    expect(find.text('0.18.0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gateway-status-inline-retry')));
    await tester.pumpAndSettle();
    expect(channel.loadDetailedHealthCalls, 1);
    expect(find.text('0.18.1'), findsOneWidget);
  });

  testWidgets('missing detailed health offers an inline retry action', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      refreshedDetailedHealth: _richHealth,
      optionalResourceErrors: const {
        HermesOptionalResource.detailedHealth: 'private transport failure',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();
    expect(find.text('Gateway status unavailable'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(channel.loadDetailedHealthCalls, 1);
    expect(find.text('0.18.1'), findsOneWidget);
  });

  testWidgets(
    'host inspection does not connect chat until explicitly requested',
    (tester) async {
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
      await tester.tap(find.byKey(const ValueKey('connection-host-beta')));
      await tester.pumpAndSettle();

      expect(directory.managementGatewayId, 'beta');
      expect(directory.activeContactId, isNull);
      expect(channel.connectCalls, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('gateway-connect-chat-button')),
      );
      await tester.pumpAndSettle();
      expect(directory.activeContactId?.gatewayId, 'beta');
      expect(channel.connectCalls.last.baseUrl, 'https://beta');
    },
  );

  testWidgets('renames the active saved gateway', (tester) async {
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
    await tester.tap(find.byKey(const ValueKey('settings-gateway-menu-alpha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-gateway-rename-field')),
      'Work',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(directory.gateways.single.label, 'Work');
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('host disconnect closes its active enrolled profile', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    final directory = directoryFor(
      configs: [
        for (final id in ['default', 'coder'])
          HermesEndpointConfig(
            id: id,
            label: 'Host',
            baseUrl: 'https://host.example/p/$id',
            wingLinkOrigin: 'https://link.example',
            wingLinkDeviceId: 'shared-device',
          ),
      ],
      loader: FakeGatewaySummaryLoader({
        for (final id in ['default', 'coder']) id: gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    addTearDown(channel.dispose);
    await directory.refresh();
    await directory.activateGateway('coder');
    directory.selectManagementGateway('default');
    await tester.pumpWidget(_testApp(channel, directory: directory));
    await tester.pumpAndSettle();
    expect(find.text('Chat connected'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gateway-disconnect-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-disconnect-confirm')));
    await tester.pumpAndSettle();
    expect(channel.disconnectCalls, 1);
    expect(directory.activeContactId, isNull);
    expect(directory.gateways, hasLength(2));
  });

  testWidgets('disconnected chat never loads legacy management', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = await _activeTrustDirectory(channel);
    await directory.showDirectory();
    final connections = channel.connectCalls.length;
    await tester.pumpWidget(_testApp(channel, directory: directory));
    await tester.pumpAndSettle();
    expect(channel.connectCalls, hasLength(connections));
    expect(directory.activeContactId, isNull);
    expect(find.byKey(const ValueKey('gateway-trust-revoke')), findsNothing);
    expect(find.text('Chat disconnected'), findsOneWidget);
  });

  testWidgets('replacing saved config never reloads legacy management', (
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
          wingLinkOrigin: 'https://host.example:8654',
          wingLinkToken: 'token-old',
          wingLinkHostFingerprint: _testFingerprint,
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

    await directory.renameGateway('alpha', 'Renamed');
    await tester.pumpAndSettle();

    expect(directory.configForGateway('alpha')!.label, 'Renamed');
    expect(directory.configForGateway('alpha')!.wingLinkToken, 'token-old');
    expect(channel.connectCalls, hasLength(1));
    expect(channel.disconnectCalls, 0);
    expect(find.byKey(const ValueKey('gateway-trust-card')), findsNothing);
  });

  testWidgets('disconnect preserves the saved gateway for reconnect', (
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
    expect(directory.gateways.single.id, 'alpha');
    expect(directory.configForGateway('alpha'), isNotNull);
  });

  testWidgets(
    'removing a paired host deletes every enrolled profile and no other host',
    (tester) async {
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final store = FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(
            id: 'default-endpoint',
            label: 'Home · default',
            baseUrl: 'https://home.example/p/default',
            wingLinkOrigin: 'https://link.example:8654',
            wingLinkDeviceId: 'home-device',
          ),
          HermesEndpointConfig(
            id: 'coder-endpoint',
            label: 'Home · coder',
            baseUrl: 'https://home.example/p/coder',
            wingLinkOrigin: 'https://link.example:8654',
            wingLinkDeviceId: 'home-device',
          ),
          HermesEndpointConfig(
            id: 'work-endpoint',
            label: 'Work',
            baseUrl: 'https://work.example',
          ),
          HermesEndpointConfig(
            id: 'other-device-endpoint',
            label: 'Other device',
            baseUrl: 'https://other.example/p/default',
            wingLinkOrigin: 'https://link.example:8654',
            wingLinkDeviceId: 'other-device',
          ),
        ],
      );
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({
          'default-endpoint': gatewaySummary(['default']),
          'coder-endpoint': gatewaySummary(['coder']),
          'work-endpoint': gatewaySummary(['default']),
          'other-device-endpoint': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('coder-endpoint');
      directory.selectManagementGateway('default-endpoint');

      await tester.pumpWidget(_testApp(channel, directory: directory));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('settings-gateway-menu-default-endpoint')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(store.deleteProfileCalls, isEmpty);
      expect(directory.activeContactId?.gatewayId, 'coder-endpoint');
      await tester.tap(
        find.byKey(const ValueKey('settings-gateway-remove-confirm')),
      );
      await tester.pumpAndSettle();

      expect(
        store.deleteProfileCalls,
        unorderedEquals(['default-endpoint', 'coder-endpoint']),
      );
      expect(channel.disconnectCalls, 1);
      expect(directory.activeContactId, isNull);
      expect(directory.hosts, hasLength(2));
      expect(
        directory.hosts.map((host) => host.id),
        unorderedEquals(['work-endpoint', 'other-device-endpoint']),
      );
      expect(directory.configForGateway('default-endpoint'), isNull);
      expect(directory.configForGateway('coder-endpoint'), isNull);
      expect(
        directory.configForGateway('work-endpoint')?.baseUrl,
        'https://work.example',
      );
      expect(
        directory.configForGateway('other-device-endpoint')?.wingLinkDeviceId,
        'other-device',
      );
      expect(
        (await store.loadProfiles()).map((config) => config.id),
        unorderedEquals(['work-endpoint', 'other-device-endpoint']),
      );
      expect(find.text('Home'), findsNothing);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Other device'), findsOneWidget);
    },
  );

  testWidgets(
    'refreshing a paired host checks every enrolled profile and no other host',
    (tester) async {
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final loader = FakeGatewaySummaryLoader({
        'default-endpoint': gatewaySummary(['default']),
        'coder-endpoint': gatewaySummary(['coder']),
        'work-endpoint': gatewaySummary(['default']),
        'other-device-endpoint': gatewaySummary(['default']),
      });
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'default-endpoint',
            label: 'Home · default',
            baseUrl: 'https://home.example/p/default',
            wingLinkOrigin: 'https://link.example:8654',
            wingLinkDeviceId: 'home-device',
          ),
          HermesEndpointConfig(
            id: 'coder-endpoint',
            label: 'Home · coder',
            baseUrl: 'https://home.example/p/coder',
            wingLinkOrigin: 'https://link.example:8654',
            wingLinkDeviceId: 'home-device',
          ),
          HermesEndpointConfig(
            id: 'work-endpoint',
            label: 'Work',
            baseUrl: 'https://work.example',
          ),
          HermesEndpointConfig(
            id: 'other-device-endpoint',
            label: 'Other device',
            baseUrl: 'https://other.example/p/default',
            wingLinkOrigin: 'https://link.example:8654',
            wingLinkDeviceId: 'other-device',
          ),
        ],
        loader: loader,
        activeChannel: channel,
      );
      await directory.refresh();

      await tester.pumpWidget(_testApp(channel, directory: directory));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('settings-gateway-menu-default-endpoint')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refresh status'));
      await tester.pumpAndSettle();

      expect(
        loader.calls.where((id) => id == 'default-endpoint'),
        hasLength(2),
      );
      expect(loader.calls.where((id) => id == 'coder-endpoint'), hasLength(2));
      expect(loader.calls.where((id) => id == 'work-endpoint'), hasLength(1));
      expect(
        loader.calls.where((id) => id == 'other-device-endpoint'),
        hasLength(1),
      );
      expect(directory.hosts, hasLength(3));
      expect(
        directory.hosts
            .firstWhere((host) => host.id == 'default-endpoint')
            .profileCount,
        2,
      );
      expect(channel.connectCalls, isEmpty);
    },
  );

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
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('gateway-body-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Messaging platforms'), findsOneWidget);
  });
}
