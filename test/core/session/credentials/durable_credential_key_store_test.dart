import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/session/durable_credential_key_store.dart';

import '../support/durable_key_store_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    clearDurableKeysMockHandler();
  });

  tearDown(clearDurableKeysMockHandler);

  test('derives stable key aliases without raw identities', () {
    final alias = DurableCredentialKeyAlias.forGatewayInstall(
      gatewayId: 'gateway-public-id',
      appInstallIdentity: 'navi-install-abc',
    );
    final same = DurableCredentialKeyAlias.forGatewayInstall(
      gatewayId: ' gateway-public-id ',
      appInstallIdentity: ' navi-install-abc ',
    );

    expect(alias.value, same.value);
    expect(alias.value, startsWith('navivox_durable_'));
    expect(alias.value, isNot(contains('gateway-public-id')));
    expect(alias.value, isNot(contains('navi-install-abc')));
  });

  test('rejects blank alias identity fields', () {
    expect(
      () => DurableCredentialKeyAlias.forGatewayInstall(
        gatewayId: ' ',
        appInstallIdentity: 'navi-install-abc',
      ),
      throwsArgumentError,
    );
    expect(
      () => DurableCredentialKeyAlias.forGatewayInstall(
        gatewayId: 'gateway-public-id',
        appInstallIdentity: ' ',
      ),
      throwsArgumentError,
    );
  });

  test('availability returns false when native adapter is absent', () async {
    final store = MethodChannelDurableCredentialKeyStore(
      channel: durableKeysTestChannel,
    );

    expect(await store.isAvailable(), isFalse);
  });

  test('creates ES256 key pair and returns public JWK only', () async {
    setDurableKeysMockHandler((call) async {
      calls.add(call);
      expect(call.method, 'createEs256KeyPair');
      expect(call.arguments, {'alias': durableTestAlias});
      return {
        'kty': 'EC',
        'crv': 'P-256',
        'x': 'public-x',
        'y': 'public-y',
        'alg': 'ES256',
        'kid': 'kid-1',
      };
    });
    final store = MethodChannelDurableCredentialKeyStore(
      channel: durableKeysTestChannel,
    );

    final jwk = await store.createEs256KeyPair(
      alias: const DurableCredentialKeyAlias.native(durableTestAlias),
    );

    expect(jwk.toJson(), {
      'kty': 'EC',
      'crv': 'P-256',
      'x': 'public-x',
      'y': 'public-y',
      'alg': 'ES256',
      'kid': 'kid-1',
    });
    expect(jwk.toJson().keys, isNot(contains('d')));
    expect(calls.single.method, 'createEs256KeyPair');
  });

  test('signs canonical bytes and deletes local key alias', () async {
    final signature = Uint8List.fromList([9, 8, 7]);
    setDurableKeysMockHandler((call) async {
      calls.add(call);
      if (call.method == 'signEs256') {
        expect(call.arguments['alias'], durableTestAlias);
        expect(
          call.arguments['canonicalPayload'],
          Uint8List.fromList([1, 2, 3]),
        );
        return signature;
      }
      if (call.method == 'deleteKey') {
        expect(call.arguments, {'alias': durableTestAlias});
        return null;
      }
      fail('Unexpected method ${call.method}');
    });
    final store = MethodChannelDurableCredentialKeyStore(
      channel: durableKeysTestChannel,
    );
    const alias = DurableCredentialKeyAlias.native(durableTestAlias);

    final result = await store.sign(
      alias: alias,
      canonicalPayload: Uint8List.fromList([1, 2, 3]),
    );
    await store.deleteKey(alias: alias);

    expect(result, signature);
    expect(calls.map((call) => call.method), ['signEs256', 'deleteKey']);
  });
}
