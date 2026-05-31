import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../../protocol/navivox_json.dart';

class DurableCredentialKeyAlias {
  const DurableCredentialKeyAlias.native(this.value);

  factory DurableCredentialKeyAlias.forGatewayInstall({
    required String gatewayId,
    required String appInstallIdentity,
  }) {
    final gateway = gatewayId.trim();
    final install = appInstallIdentity.trim();
    if (gateway.isEmpty || install.isEmpty) {
      throw ArgumentError(
        'Gateway identity and app install identity are required.',
      );
    }
    final digest = sha256.convert(utf8.encode('$gateway\u0000$install'));
    return DurableCredentialKeyAlias.native('navivox_durable_$digest');
  }

  final String value;

  @override
  String toString() => value;
}

class PublicJsonWebKey {
  const PublicJsonWebKey({
    required this.kty,
    required this.crv,
    required this.x,
    required this.y,
    required this.alg,
    this.kid,
  });

  factory PublicJsonWebKey.fromJson(Map<Object?, Object?> json) {
    return PublicJsonWebKey(
      kty: _requiredString(json, 'kty'),
      crv: _requiredString(json, 'crv'),
      x: _requiredString(json, 'x'),
      y: _requiredString(json, 'y'),
      alg: _requiredString(json, 'alg'),
      kid: _optionalString(json, 'kid'),
    );
  }

  final String kty;
  final String crv;
  final String x;
  final String y;
  final String alg;
  final String? kid;

  Map<String, Object?> toJson() => {
    'kty': kty,
    'crv': crv,
    'x': x,
    'y': y,
    'alg': alg,
    if (kid != null) 'kid': kid,
  };

  static String _requiredString(Map<Object?, Object?> json, String key) {
    final value = navivoxOptionalLiteralStringFromJson(json[key]);
    if (value == null) {
      throw FormatException('Missing public JWK field: $key');
    }
    return value;
  }

  static String? _optionalString(Map<Object?, Object?> json, String key) {
    return navivoxOptionalLiteralStringFromJson(json[key]);
  }
}

abstract interface class DurableCredentialKeyStore {
  Future<bool> isAvailable();

  Future<PublicJsonWebKey> createEs256KeyPair({
    required DurableCredentialKeyAlias alias,
  });

  Future<Uint8List> sign({
    required DurableCredentialKeyAlias alias,
    required Uint8List canonicalPayload,
  });

  Future<void> deleteKey({required DurableCredentialKeyAlias alias});
}

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
