import 'dart:convert';

/// Deliberately contains no remote response, URI, or credential in diagnostics.
class GatewayAuthException implements Exception {
  const GatewayAuthException(this.reason);
  final String reason;
  @override
  String toString() => 'GatewayAuthException: $reason';
}

Uri validateGatewayOrigin(Uri value, {bool allowLoopbackHttpForTests = false}) {
  final loopbackTest =
      allowLoopbackHttpForTests &&
      value.scheme == 'http' &&
      value.host == '127.0.0.1';
  if ((!loopbackTest && value.scheme != 'https') ||
      !value.hasAuthority ||
      value.host.isEmpty ||
      value.userInfo.isNotEmpty ||
      (value.path.isNotEmpty && value.path != '/') ||
      value.hasQuery ||
      value.hasFragment ||
      value.port < 1 ||
      value.port > 65535 ||
      value.toString().contains('\\')) {
    throw const GatewayAuthException('invalid_origin');
  }
  return Uri.parse(value.origin);
}

class GatewayAuthProvider {
  const GatewayAuthProvider({
    required this.name,
    required this.displayName,
    required this.supportsPassword,
  });
  final String name;
  final String displayName;
  final bool supportsPassword;
}

/// Tokens are origin-scoped secrets, not endpoint form values. Never log them.
class GatewayTokenSet {
  GatewayTokenSet._({
    required this.origin,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.provider,
    required this.userId,
  });
  final Uri origin;
  final String accessToken;
  final String refreshToken;

  /// Unix epoch seconds, as supplied by Hermes (zero means unknown expiry).
  final double expiresAt;
  final String provider;
  final String userId;

  factory GatewayTokenSet.fromJson(Uri origin, Map<String, dynamic> body) {
    final expiry = body['expires_at'];
    if (body['token_type'] != 'Bearer' ||
        expiry is! num ||
        !expiry.isFinite ||
        expiry < 0 ||
        expiry > 253402300799) {
      throw const GatewayAuthException('invalid_token_response');
    }
    return GatewayTokenSet._(
      origin: origin,
      accessToken: boundedAuthString(body['access_token'], 16384),
      refreshToken: boundedAuthString(
        body['refresh_token'],
        16384,
        allowEmpty: true,
      ),
      expiresAt: expiry.toDouble(),
      provider: boundedAuthString(body['provider'], 128),
      userId: boundedAuthString(body['user_id'], 1024),
    );
  }

  bool needsRefresh({
    DateTime? now,
    Duration skew = const Duration(seconds: 60),
  }) =>
      expiresAt == 0 ||
      (now ?? DateTime.now()).millisecondsSinceEpoch / 1000 >=
          expiresAt - skew.inSeconds;

  /// Only for the secure store, never ordinary preferences or diagnostics.
  Map<String, Object> toSecureJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'token_type': 'Bearer',
    'expires_at': expiresAt,
    'provider': provider,
    'user_id': userId,
  };

  @override
  String toString() => 'GatewayTokenSet(<redacted>)';
}

String boundedAuthString(Object? value, int max, {bool allowEmpty = false}) {
  if (value is! String ||
      (!allowEmpty && value.isEmpty) ||
      utf8.encode(value).length > max ||
      value.runes.any((r) => r < 32 || r == 127)) {
    throw const GatewayAuthException('invalid_response');
  }
  return value;
}
