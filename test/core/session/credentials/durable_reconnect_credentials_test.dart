import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/session/durable_reconnect_credentials.dart';

void main() {
  test('gateway credential metadata is non-secret and scoped', () {
    final metadata = GatewayCredentialMetadata(
      gatewayId: 'gw_123',
      appInstallIdentity: 'navi-install-abc',
      credentialLabel: 'Navivox Android',
      createdAt: DateTime.utc(2026),
    );

    expect(metadata.isUsableMetadata, isTrue);
    expect(metadata.gatewayId, 'gw_123');
    expect(metadata.appInstallIdentity, 'navi-install-abc');
  });

  test('gateway credential metadata requires non-blank identity fields', () {
    final missingGateway = GatewayCredentialMetadata(
      gatewayId: ' ',
      appInstallIdentity: 'navi-install-abc',
      credentialLabel: 'Navivox Android',
      createdAt: DateTime.utc(2026),
    );
    final missingInstall = GatewayCredentialMetadata(
      gatewayId: 'gw_123',
      appInstallIdentity: '',
      credentialLabel: 'Navivox Android',
      createdAt: DateTime.utc(2026),
    );
    final missingLabel = GatewayCredentialMetadata(
      gatewayId: 'gw_123',
      appInstallIdentity: 'navi-install-abc',
      credentialLabel: '\t',
      createdAt: DateTime.utc(2026),
    );

    expect(missingGateway.isUsableMetadata, isFalse);
    expect(missingInstall.isUsableMetadata, isFalse);
    expect(missingLabel.isUsableMetadata, isFalse);
  });

  test(
    'empty durable credential store never enables reconnect material',
    () async {
      const store = EmptyDurableCredentialStore();

      expect(await store.containsCredential(gatewayId: 'gw_123'), isFalse);
      expect(await store.metadata(gatewayId: 'gw_123'), isNull);
      await store.deleteCredential(gatewayId: 'gw_123');
    },
  );
}
