import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
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

const _testFingerprint = 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
const _changedFingerprint =
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';

const _initialHealth = HermesHealthStatus(
  status: 'ok',
  platform: 'hermes-agent',
  version: '0.18.0',
  gatewayState: 'running',
  activeAgents: 1,
);

WingLinkClient _trustClient({
  void Function()? onDelete,
  Object? getError,
  Object? deleteError,
  String reportedFingerprint = _testFingerprint,
}) => WingLinkClient(
  origin: Uri.parse('https://host.example:8654'),
  token: 'test-token',
  hostFingerprint: _testFingerprint,
  get: (uri, headers) async {
    if (getError != null) throw getError;
    return jsonEncode(
      uri.path == '/meta'
          ? {
              'protocol_generation': 2,
              'minimum_protocol_generation': 1,
              'supported_protocol_generations': [1, 2],
              'version': '1.2.3',
              'host_fingerprint': reportedFingerprint,
              'capabilities': ['device.self.read'],
            }
          : {
              'device_id': 'cred_phone',
              'name': 'Pixel',
              'scopes': ['health.read', 'profile.read'],
              'created_at': '2026-01-01T00:00:00Z',
              'legacy': false,
            },
    );
  },
  delete: (uri, headers) async {
    if (deleteError != null) throw deleteError;
    onDelete?.call();
    return '';
  },
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
  GatewayWingLinkClientBuilder? wingLinkClientBuilder,
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
    home: GatewayScreen(wingLinkClientBuilder: wingLinkClientBuilder),
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
    await tester.tap(find.byKey(const ValueKey('gateway-rename-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('gateway-rename-field')),
      'Work',
    );
    await tester.tap(find.byKey(const ValueKey('gateway-rename-save')));
    await tester.pumpAndSettle();

    expect(directory.gateways.single.label, 'Work');
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('trust reloads when the active gateway config is replaced', (
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
    var trustLoads = 0;

    await tester.pumpWidget(
      _testApp(
        channel,
        directory: directory,
        wingLinkClientBuilder: (_) {
          trustLoads++;
          return _trustClient();
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(trustLoads, 1);

    await directory.renameGateway('alpha', 'Renamed');
    await tester.pumpAndSettle();

    expect(trustLoads, 2);
  });

  testWidgets('disconnect forgets the saved gateway', (tester) async {
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
    expect(directory.gateways, isEmpty);
  });

  testWidgets('shows changed identity, upgrade, and expired states at 100%', (
    tester,
  ) async {
    final cases = <({Object? error, String fingerprint, String message})>[
      (
        error: null,
        fingerprint: _changedFingerprint,
        message: 'host fingerprint changed',
      ),
      (
        error: const WingLinkUpgradeRequired(),
        fingerprint: _testFingerprint,
        message: 'outside the supported compatibility window',
      ),
      (
        error: Exception('Wing Link HTTP 401'),
        fingerprint: _testFingerprint,
        message: 'expired or revoked',
      ),
    ];
    for (final testCase in cases) {
      final channel = FakeHermesChannel(
        capabilities: _capabilities(),
        basicHealth: _initialHealth,
      );
      final directory = await _activeTrustDirectory(channel);
      await tester.pumpWidget(
        _testApp(
          channel,
          directory: directory,
          wingLinkClientBuilder: (_) => _trustClient(
            getError: testCase.error,
            reportedFingerprint: testCase.fingerprint,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(testCase.message, findRichText: true),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      channel.dispose();
    }
  });

  testWidgets('shows host approval pending without request identifiers', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      basicHealth: _initialHealth,
    );
    addTearDown(channel.dispose);
    final directory = await _activeTrustDirectory(channel);
    await tester.pumpWidget(
      _testApp(
        channel,
        directory: directory,
        wingLinkClientBuilder: (_) => _trustClient(
          deleteError: const WingLinkApprovalRequired(
            approvalId: 'appr_test',
            operationId: 'op_test',
            idempotencyKey: 'retry-test',
            expiresAt: 2000000000,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('gateway-body-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-trust-revoke')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('gateway-trust-revoke-confirm')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('gateway-trust-approval-pending')),
      findsOneWidget,
    );
    expect(find.textContaining('appr_test'), findsNothing);
    expect(find.textContaining('op_test'), findsNothing);
  });

  testWidgets('shows pinned trust and confirms self-revocation at 200% scale', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      basicHealth: _initialHealth,
      detailedHealth: _initialHealth,
    );
    addTearDown(channel.dispose);
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
    var revoked = false;

    await tester.pumpWidget(
      _testApp(
        channel,
        directory: directory,
        textScale: 2,
        wingLinkClientBuilder: (_) =>
            _trustClient(onDelete: () => revoked = true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('gateway-body-list')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    expect(find.text(_testFingerprint), findsOneWidget);
    expect(find.textContaining('Pixel'), findsOneWidget);
    expect(find.textContaining('health.read'), findsOneWidget);
    expect(find.textContaining('wing-link approvals list'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('gateway-body-list')),
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gateway-trust-revoke')));
    await tester.pumpAndSettle();
    expect(revoked, isFalse);
    await tester.tap(
      find.byKey(const ValueKey('gateway-trust-revoke-confirm')),
    );
    await tester.pumpAndSettle();
    expect(revoked, isTrue);
    expect(find.byKey(const ValueKey('gateway-trust-revoked')), findsOneWidget);
    expect(tester.takeException(), isNull);
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
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('gateway-body-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Messaging platforms'), findsOneWidget);
  });
}
