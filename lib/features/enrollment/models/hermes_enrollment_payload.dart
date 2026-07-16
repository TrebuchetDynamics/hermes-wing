/// Parses and validates the Hermes Wing connect pairing payload carried by an
/// Android intent (`wing://connect?...` deep link, or shared text that
/// contains one). Only a small allowlisted shape is accepted: an HTTPS (or
/// explicitly confirmed cleartext) Hermes origin plus a one-time pairing
/// code. Nothing else survives parsing, and no bearer credential is ever
/// carried in this payload — the code below is exchanged for one later, only
/// after operator review.
class HermesEnrollmentPayload {
  const HermesEnrollmentPayload({required this.origin, required this.code});

  /// Normalized Hermes API origin: scheme + host + optional port only. No
  /// path, query, fragment, or userinfo ever survives parsing.
  final Uri origin;

  /// The one-time pairing code exchanged for a bearer token after operator
  /// review. This is never a bearer token itself.
  final String code;

  static const _maxCodeLength = 128;
  static const _connectScheme = 'wing';
  static const _connectHost = 'connect';

  /// Hosts exempt from the plaintext-origin confirmation requirement below,
  /// matching the loopback/emulator hosts already trusted by the manual
  /// connect form; see `hermesEndpointRequiresCleartextCredentialWarning`.
  static const _cleartextExemptHosts = {
    'localhost',
    '127.0.0.1',
    '::1',
    '10.0.2.2',
  };

  factory HermesEnrollmentPayload.parse(
    String value, {
    bool cleartextOriginConfirmed = false,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('connect payload is blank');
    }
    final uri = Uri.parse(trimmed);
    if (uri.scheme != _connectScheme || uri.host != _connectHost) {
      throw const FormatException('not a Hermes Wing connect payload');
    }
    if (uri.fragment.isNotEmpty) {
      throw const FormatException(
        'connect payload must not include a fragment',
      );
    }
    if (uri.userInfo.isNotEmpty) {
      throw const FormatException('connect payload must not include userinfo');
    }
    if (uri.queryParametersAll.containsKey('token')) {
      throw const FormatException(
        'connect payload must not include a token parameter',
      );
    }

    final origin = _parseOrigin(
      uri.queryParameters['origin'],
      cleartextOriginConfirmed: cleartextOriginConfirmed,
    );

    final code = (uri.queryParameters['code'] ?? '').trim();
    if (code.isEmpty) {
      throw const FormatException('connect payload is missing a code');
    }
    if (code.length > _maxCodeLength) {
      throw const FormatException('connect payload code is too long');
    }

    return HermesEnrollmentPayload(origin: origin, code: code);
  }

  static Uri _parseOrigin(
    String? rawOrigin, {
    required bool cleartextOriginConfirmed,
  }) {
    final trimmed = rawOrigin?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw const FormatException('connect payload is missing an origin');
    }
    final Uri originUri;
    try {
      originUri = Uri.parse(trimmed);
    } on FormatException {
      throw const FormatException('connect payload origin is not a valid URI');
    }
    if (originUri.scheme != 'http' && originUri.scheme != 'https') {
      throw const FormatException(
        'connect payload origin must use http or https',
      );
    }
    if (originUri.host.isEmpty) {
      throw const FormatException('connect payload origin must include a host');
    }
    if (originUri.userInfo.isNotEmpty) {
      throw const FormatException(
        'connect payload origin must not include userinfo',
      );
    }
    if (originUri.fragment.isNotEmpty) {
      throw const FormatException(
        'connect payload origin must not include a fragment',
      );
    }
    final normalized = Uri(
      scheme: originUri.scheme,
      host: originUri.host,
      port: originUri.hasPort ? originUri.port : null,
    );
    if (originUri.scheme == 'http' &&
        !_cleartextExemptHosts.contains(originUri.host.toLowerCase()) &&
        !cleartextOriginConfirmed) {
      throw HermesEnrollmentCleartextOriginRequired(normalized);
    }
    return normalized;
  }
}

/// Thrown when a connect payload's origin uses plaintext HTTP against a
/// non-loopback host. Callers must obtain the same explicit confirmation
/// used for the manual cleartext Hermes connect flow (see
/// `hermesEndpointRequiresCleartextCredentialWarning`) and re-parse with
/// `cleartextOriginConfirmed: true` before treating the payload as valid.
class HermesEnrollmentCleartextOriginRequired extends FormatException {
  HermesEnrollmentCleartextOriginRequired(this.origin)
    : super('connect payload origin uses plaintext HTTP without confirmation');

  /// The normalized (scheme+host+port only) plaintext origin awaiting
  /// confirmation.
  final Uri origin;
}
