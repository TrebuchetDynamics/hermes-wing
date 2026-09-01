/// Parses and validates the Hermes Wing connect pairing payload carried by an
/// Android intent (`wing://connect?...` deep link, or shared text that
/// contains one). Only a small allowlisted shape is accepted: an HTTPS (or
/// explicitly confirmed cleartext) Hermes origin plus a one-time pairing
/// code. Nothing else survives parsing, and no bearer credential is ever
/// carried in this payload — the code below is exchanged for one later, only
/// after operator review.
class HermesEnrollmentPayload {
  const HermesEnrollmentPayload({
    required this.origin,
    required this.code,
    this.brokerOrigin,
    this.wingLinkOrigin,
    this.wingLinkHostFingerprint,
    this.protocolGeneration = 1,
  });

  /// Normalized Hermes API origin: scheme + host + optional port only. No
  /// path, query, fragment, or userinfo ever survives parsing.
  final Uri origin;

  /// Optional same-host, short-lived Wing CLI broker that exchanges [code]
  /// for the existing Hermes API key without changing Hermes Agent.
  final Uri? brokerOrigin;

  /// Optional same-host Wing Link management origin. Its independent control
  /// token is returned only by the reviewed one-time exchange.
  final Uri? wingLinkOrigin;

  /// SHA-256 fingerprint of the persistent Wing Link Ed25519 host key.
  final String? wingLinkHostFingerprint;

  /// Wing Link protocol generation declared by the pairing broker.
  final int protocolGeneration;

  /// The one-time pairing code exchanged for a bearer token after operator
  /// review. This is never a bearer token itself.
  final String code;

  static const _maxCodeLength = 128;
  static const _maxExplicitHandoffLength = 4096;
  static const _connectScheme = 'wing';
  static const _connectHost = 'connect';
  static const _connectPrefix = 'wing://connect?';
  static final _hostFingerprintPattern = RegExp(r'^sha256/[A-Za-z0-9_-]{43}$');
  static final _handoffEdgeCharacters = RegExp(
    r'''^[<>()\[\]'\"]+|[<>()\[\]'\"]+$''',
  );

  /// Extracts one standalone connect URI from an explicit share or paste, then
  /// applies the same strict validation as [parse].
  factory HermesEnrollmentPayload.parseExplicitHandoff(
    String value, {
    bool cleartextOriginConfirmed = false,
  }) {
    if (value.length > _maxExplicitHandoffLength) {
      throw const FormatException('connect handoff is too long');
    }
    final candidates = value
        .split(RegExp(r'\s+'))
        .map((token) => token.replaceAll(_handoffEdgeCharacters, ''))
        .where((token) => token.startsWith(_connectPrefix))
        .toList(growable: false);
    if (candidates.length != 1) {
      throw const FormatException(
        'connect handoff must contain exactly one pairing link',
      );
    }
    return HermesEnrollmentPayload.parse(
      candidates.single,
      cleartextOriginConfirmed: cleartextOriginConfirmed,
    );
  }

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

    final brokerOrigin = _parseBrokerOrigin(
      uri.queryParameters['broker'],
      hermesOrigin: origin,
      cleartextOriginConfirmed: cleartextOriginConfirmed,
    );
    final wingLinkOrigin = _parseWingLinkOrigin(
      uri.queryParameters['control'],
      hermesOrigin: origin,
      cleartextOriginConfirmed: cleartextOriginConfirmed,
    );
    final rawGeneration = uri.queryParameters['protocol_generation'];
    final protocolGeneration = rawGeneration == null
        ? 1
        : int.tryParse(rawGeneration);
    if (protocolGeneration != 1 && protocolGeneration != 2) {
      throw const FormatException('connect payload protocol is unsupported');
    }
    final fingerprint = (uri.queryParameters['host_fingerprint'] ?? '').trim();
    if (fingerprint.isNotEmpty &&
        !_hostFingerprintPattern.hasMatch(fingerprint)) {
      throw const FormatException(
        'connect payload host fingerprint is invalid',
      );
    }
    if (protocolGeneration == 2 &&
        wingLinkOrigin != null &&
        wingLinkOrigin.scheme == 'https' &&
        !_cleartextExemptHosts.contains(wingLinkOrigin.host.toLowerCase()) &&
        fingerprint.isEmpty) {
      throw const FormatException(
        'connect payload is missing a host fingerprint',
      );
    }

    final code = (uri.queryParameters['code'] ?? '').trim();
    if (code.isEmpty) {
      throw const FormatException('connect payload is missing a code');
    }
    if (code.length > _maxCodeLength) {
      throw const FormatException('connect payload code is too long');
    }

    return HermesEnrollmentPayload(
      origin: origin,
      code: code,
      brokerOrigin: brokerOrigin,
      wingLinkOrigin: wingLinkOrigin,
      wingLinkHostFingerprint: fingerprint.isEmpty ? null : fingerprint,
      protocolGeneration: protocolGeneration!,
    );
  }

  static Uri? _parseWingLinkOrigin(
    String? rawOrigin, {
    required Uri hermesOrigin,
    required bool cleartextOriginConfirmed,
  }) => _parseSameHostOrigin(
    rawOrigin,
    field: 'control',
    hermesOrigin: hermesOrigin,
    cleartextOriginConfirmed: cleartextOriginConfirmed,
  );

  static Uri? _parseBrokerOrigin(
    String? rawBroker, {
    required Uri hermesOrigin,
    required bool cleartextOriginConfirmed,
  }) => _parseSameHostOrigin(
    rawBroker,
    field: 'broker',
    hermesOrigin: hermesOrigin,
    cleartextOriginConfirmed: cleartextOriginConfirmed,
  );

  static Uri? _parseSameHostOrigin(
    String? rawOrigin, {
    required String field,
    required Uri hermesOrigin,
    required bool cleartextOriginConfirmed,
  }) {
    final value = rawOrigin?.trim() ?? '';
    if (value.isEmpty) return null;
    final parsed = Uri.parse(value);
    if (parsed.path.isNotEmpty && parsed.path != '/' ||
        parsed.query.isNotEmpty ||
        parsed.fragment.isNotEmpty) {
      throw FormatException(
        'connect payload $field must be an origin without path, query, or fragment',
      );
    }
    final origin = _parseOrigin(
      value,
      cleartextOriginConfirmed: cleartextOriginConfirmed,
    );
    if (origin.host.toLowerCase() != hermesOrigin.host.toLowerCase()) {
      throw FormatException(
        'connect payload $field must use the Hermes endpoint host',
      );
    }
    return origin;
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
