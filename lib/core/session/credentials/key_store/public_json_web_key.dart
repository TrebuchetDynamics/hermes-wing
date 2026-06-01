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
