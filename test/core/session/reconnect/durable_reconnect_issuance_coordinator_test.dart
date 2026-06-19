import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/client/navivox_gateway_client.dart';
import 'package:navivox/core/gateway/client/navivox_gateway_config.dart';
import 'package:navivox/core/session/credentials/durable_credential_store.dart';
import 'package:navivox/core/session/identity/app_install_identity_service.dart';
import 'package:navivox/core/session/readiness/reconnect_readiness.dart';
import 'package:navivox/core/session/reconnect/durable_reconnect_issuance_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryStore implements DurableCredentialStore {
  final Map<String, GatewayCredentialMetadata> _saved = {};
  final Map<String, String> _secrets = {};
  int saveCalls = 0;

  @override
  Future<bool> containsCredential({required String gatewayId}) async =>
      _saved.containsKey(gatewayId);

  @override
  Future<GatewayCredentialMetadata?> metadata({required String gatewayId}) async =>
      _saved[gatewayId];

  @override
  Future<void> saveCredential({
    required GatewayCredentialMetadata metadata,
    required String secret,
  }) async {
    saveCalls++;
    _saved[metadata.gatewayId] = metadata;
    _secrets[metadata.gatewayId] = secret;
  }

  @override
  Future<String?> loadSecret({required String gatewayId}) async =>
      _secrets[gatewayId];

  @override
  Future<void> deleteCredential({required String gatewayId}) async {
    _saved.remove(gatewayId);
    _secrets.remove(gatewayId);
  }
}

NavivoxGatewayClient _client(Future<String> Function() onPost) {
  return NavivoxGatewayClient(
    config: NavivoxGatewayConfig.fromBaseUrl(
      'http://127.0.0.1:8765',
      token: 'nvbx_test_token',
    ),
    post: (uri, headers, body) => onPost(),
  );
}

String _usableCredential() => jsonEncode({
  'object': 'gormes.navivox.device_credential',
  'credential_id': 'navivoxcred_1',
  'secret': 'nvbxdc_secret',
  'auth_method': 'device_bearer',
  'interim': true,
  'scopes': ['navivox'],
  'gateway_id': 'gw_1',
  'app_install_id': 'install-1',
});

const _available = ReconnectReadiness(
  kind: ReconnectReadinessKind.available,
  message: 'Reconnect support is available but not saved yet.',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('issues, stores, and reports saved when the store persists', () async {
    final store = _InMemoryStore();
    final coordinator = DurableReconnectIssuanceCoordinator(
      appInstallIdentity: AppInstallIdentityService(),
      credentialStore: store,
    );

    final readiness = await coordinator.persist(
      client: _client(() async => _usableCredential()),
      gatewayId: 'gw_1',
      currentReadiness: _available,
    );

    expect(readiness.kind, ReconnectReadinessKind.saved);
    expect(store.saveCalls, 1);
    expect(await store.containsCredential(gatewayId: 'gw_1'), isTrue);
    final saved = await store.metadata(gatewayId: 'gw_1');
    expect(saved?.credentialLabel, 'navivoxcred_1');
    expect(saved?.appInstallIdentity, isNotEmpty);
  });

  test('stays session-only with the default no-op store', () async {
    final coordinator = DurableReconnectIssuanceCoordinator(
      appInstallIdentity: AppInstallIdentityService(),
      credentialStore: const EmptyDurableCredentialStore(),
    );

    final readiness = await coordinator.persist(
      client: _client(() async => _usableCredential()),
      gatewayId: 'gw_1',
      currentReadiness: _available,
    );

    expect(readiness.kind, ReconnectReadinessKind.available);
    expect(readiness.message, 'Connected for this session; reconnect not saved.');
  });

  test('retries once then stays session-only on transient failure', () async {
    var calls = 0;
    final coordinator = DurableReconnectIssuanceCoordinator(
      appInstallIdentity: AppInstallIdentityService(),
      credentialStore: _InMemoryStore(),
    );

    final readiness = await coordinator.persist(
      client: _client(() async {
        calls++;
        throw StateError('transient');
      }),
      gatewayId: 'gw_1',
      currentReadiness: _available,
    );

    expect(calls, 2, reason: 'one bounded retry after the first failure');
    expect(readiness.kind, ReconnectReadinessKind.available);
    expect(readiness.message, 'Connected for this session; reconnect not saved.');
  });

  test('does not issue when reconnect is not advertised as available', () async {
    var calls = 0;
    final coordinator = DurableReconnectIssuanceCoordinator(
      appInstallIdentity: AppInstallIdentityService(),
      credentialStore: _InMemoryStore(),
    );

    final readiness = await coordinator.persist(
      client: _client(() async {
        calls++;
        return _usableCredential();
      }),
      gatewayId: 'gw_1',
      currentReadiness: const ReconnectReadiness(
        kind: ReconnectReadinessKind.unsupported,
        message: 'Reconnect cannot be saved for this gateway yet.',
      ),
    );

    expect(calls, 0);
    expect(readiness.kind, ReconnectReadinessKind.unsupported);
  });

  test('does not issue without an authenticated gateway identity', () async {
    var calls = 0;
    final coordinator = DurableReconnectIssuanceCoordinator(
      appInstallIdentity: AppInstallIdentityService(),
      credentialStore: _InMemoryStore(),
    );

    final readiness = await coordinator.persist(
      client: _client(() async {
        calls++;
        return _usableCredential();
      }),
      gatewayId: '',
      currentReadiness: _available,
    );

    expect(calls, 0);
    expect(readiness.kind, ReconnectReadinessKind.available);
  });
}
