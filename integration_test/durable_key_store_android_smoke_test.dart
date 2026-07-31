import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.trebuchetdynamics.hermes.wing/durable_keys',
  );

  testWidgets('Android durable key store creates signs and deletes ES256 keys', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;
    final available = await channel.invokeMethod<bool>('isAvailable');
    expect(available, isTrue);

    final alias =
        'wing_durable_integration_${DateTime.now().microsecondsSinceEpoch}_smoke_suffix_padding';
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

  testWidgets('Android durable key store rejects invalid aliases', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;

    await expectLater(
      channel.invokeMethod<void>('createEs256KeyPair', {'alias': 'too_short'}),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'invalid_argument',
        ),
      ),
    );
  });
}
