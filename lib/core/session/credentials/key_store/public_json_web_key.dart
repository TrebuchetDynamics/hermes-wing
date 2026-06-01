import '../../../protocol/navivox_json.dart';

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
    final fields = PublicJsonWebKeyFields.fromJson(json);
    return PublicJsonWebKey(
      kty: fields.kty,
      crv: fields.crv,
      x: fields.x,
      y: fields.y,
      alg: fields.alg,
      kid: fields.kid,
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
}

/// Validated public ES256 key material returned by the native key store.
///
/// This makes the durable reconnect key contract explicit: Navivox accepts only
/// a public P-256 EC JWK and rejects any private material before the value can
/// cross from the platform adapter into reconnect setup.
class PublicJsonWebKeyFields {
  const PublicJsonWebKeyFields({
    required this.kty,
    required this.crv,
    required this.x,
    required this.y,
    required this.alg,
    this.kid,
  });

  factory PublicJsonWebKeyFields.fromJson(Map<Object?, Object?> json) {
    if (navivoxOptionalLiteralStringFromJson(json['d']) != null) {
      throw const FormatException(
        'Public JWK must not include private key material.',
      );
    }

    final fields = PublicJsonWebKeyFields(
      kty: _requiredString(json, 'kty'),
      crv: _requiredString(json, 'crv'),
      x: _requiredString(json, 'x'),
      y: _requiredString(json, 'y'),
      alg: _requiredString(json, 'alg'),
      kid: _optionalString(json, 'kid'),
    );
    fields._validateEs256PublicKey();
    return fields;
  }

  final String kty;
  final String crv;
  final String x;
  final String y;
  final String alg;
  final String? kid;

  void _validateEs256PublicKey() {
    if (kty != 'EC') {
      throw const FormatException('Public JWK kty must be EC for ES256.');
    }
    if (crv != 'P-256') {
      throw const FormatException('Public JWK crv must be P-256 for ES256.');
    }
    if (alg != 'ES256') {
      throw const FormatException('Public JWK alg must be ES256.');
    }
  }

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
