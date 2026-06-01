import 'package:flutter/services.dart';

import '../key_store/durable_credential_key_alias.dart';
import '../key_store/durable_credential_key_store.dart';
import '../key_store/public_json_web_key.dart';

class MethodChannelDurableCredentialKeyStore
    implements DurableCredentialKeyStore {
  const MethodChannelDurableCredentialKeyStore({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const _channelName = 'com.trebuchetdynamics.navivox/durable_keys';

  final MethodChannel _channel;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<PublicJsonWebKey> createEs256KeyPair({
    required DurableCredentialKeyAlias alias,
  }) async {
    final result = await _channel.invokeMethod<Object?>('createEs256KeyPair', {
      'alias': alias.value,
    });
    if (result is! Map) {
      throw const FormatException(
        'Native key store did not return a public JWK.',
      );
    }
    return PublicJsonWebKey.fromJson(result);
  }

  @override
  Future<Uint8List> sign({
    required DurableCredentialKeyAlias alias,
    required Uint8List canonicalPayload,
  }) async {
    final result = await _channel.invokeMethod<Uint8List>('signEs256', {
      'alias': alias.value,
      'canonicalPayload': canonicalPayload,
    });
    if (result == null || result.isEmpty) {
      throw const FormatException(
        'Native key store did not return a signature.',
      );
    }
    return result;
  }

  @override
  Future<void> deleteKey({required DurableCredentialKeyAlias alias}) async {
    await _channel.invokeMethod<void>('deleteKey', {'alias': alias.value});
  }
}
