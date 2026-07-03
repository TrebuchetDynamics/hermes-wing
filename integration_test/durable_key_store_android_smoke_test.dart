import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:navivox/core/session/credentials/durable_credential_key_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.trebuchetdynamics.navivox/durable_keys');

  testWidgets('Android durable key store creates signs and deletes ES256 keys', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;
    final available = await channel.invokeMethod<bool>('isAvailable');
    expect(available, isTrue);

    final alias =
        'navivox_durable_integration_${DateTime.now().microsecondsSinceEpoch}_smoke_suffix_padding';
    try {
      final jwk = await channel.invokeMapMethod<String, String>(
        'createEs256KeyPair',
        {'alias': alias},
      );
      expect(jwk, isNotNull);
      expect(jwk, containsPair('kty', 'EC'));
      expect(jwk, containsPair('crv', 'P-256'));
      expect(jwk, containsPair('alg', 'ES256'));
      expect(jwk!['x'], isNotEmpty);
      expect(jwk['y'], isNotEmpty);
      expect(jwk, isNot(contains('d')));

      final signature = await channel.invokeMethod<Uint8List>('signEs256', {
        'alias': alias,
        'canonicalPayload': Uint8List.fromList([1, 2, 3]),
      });
      expect(signature, isNotNull);
      expect(signature, hasLength(64));
    } finally {
      await channel.invokeMethod<void>('deleteKey', {'alias': alias});
      await channel.invokeMethod<void>('deleteKey', {'alias': alias});
    }
  });

  testWidgets('Android durable key store adapter validates and signs', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;

    const store = MethodChannelDurableCredentialKeyStore();
    expect(await store.isAvailable(), isTrue);

    final alias = DurableCredentialKeyAlias.native(
      'navivox_durable_adapter_${DateTime.now().microsecondsSinceEpoch}_smoke_suffix_padding',
    );
    try {
      final jwk = await store.createEs256KeyPair(alias: alias);
      expect(jwk.kty, 'EC');
      expect(jwk.crv, 'P-256');
      expect(jwk.alg, 'ES256');
      expect(jwk.x, isNotEmpty);
      expect(jwk.y, isNotEmpty);
      expect(jwk.toJson(), isNot(contains('d')));

      final signature = await store.sign(
        alias: alias,
        canonicalPayload: Uint8List.fromList([4, 5, 6]),
      );
      expect(signature, hasLength(64));
    } finally {
      await store.deleteKey(alias: alias);
      await store.deleteKey(alias: alias);
    }
  });

  testWidgets('Android durable key store rejects non-durable aliases', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;

    expect(
      () => channel.invokeMethod<void>('deleteKey', {
        'alias': 'raw-host-or-token',
      }),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'invalid_argument',
        ),
      ),
    );
  });
}
