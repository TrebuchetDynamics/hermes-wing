import '../serialization/navivox_json.dart';

/// URI normalization helpers shared by Navivox pairing and setup flows.
const navivoxEndpointSchemes = {'http', 'https', 'ws', 'wss'};

bool navivoxIsEndpointScheme(String scheme) {
  return navivoxEndpointSchemes.contains(scheme.trim().toLowerCase());
}

String navivoxHttpSchemeFromEndpointScheme(
  String scheme, {
  String? descriptor,
}) {
  return switch (scheme.trim().toLowerCase()) {
    'ws' => 'http',
    'wss' => 'https',
    'http' => 'http',
    'https' => 'https',
    _ => throw FormatException(
      'Navivox endpoint URI must use ws, wss, http, or https',
      descriptor,
    ),
  };
}

String navivoxOriginFromUri(Uri uri) {
  return NavivoxEndpointOrigin.fromUri(uri).format();
}

/// Reconnect-safe endpoint origin value.
///
/// This type makes origin stripping explicit: path/query/fragment are excluded,
/// and callers that accept untrusted endpoint text must validate userinfo before
/// constructing an origin so credentials are not silently discarded.
class NavivoxEndpointOrigin {
  const NavivoxEndpointOrigin({
    required this.scheme,
    required this.host,
    required this.explicitPort,
  });

  factory NavivoxEndpointOrigin.fromUri(Uri uri, {String? schemeOverride}) {
    return NavivoxEndpointOrigin(
      scheme: schemeOverride ?? uri.scheme,
      host: uri.host,
      explicitPort: uri.hasPort ? uri.port : null,
    );
  }

  final String scheme;
  final String host;
  final int? explicitPort;

  String format() {
    final formattedHost = host.contains(':') ? '[$host]' : host;
    final formattedPort = explicitPort == null ? '' : ':$explicitPort';
    return '$scheme://$formattedHost$formattedPort';
  }
}

String navivoxHttpBaseUrlFromEndpointUri(Uri uri, {String? descriptor}) {
  _validateNavivoxEndpointUri(
    uri,
    descriptor: descriptor,
    allowedSchemes: navivoxEndpointSchemes,
    missingHostMessage: 'Navivox endpoint URI must include a host',
    invalidSchemeMessage:
        'Navivox endpoint URI must use ws, wss, http, or https',
    userinfoMessage: 'Navivox endpoint URI must not include userinfo',
  );
  final scheme = navivoxHttpSchemeFromEndpointScheme(
    uri.scheme,
    descriptor: descriptor,
  );
  return NavivoxEndpointOrigin.fromUri(uri, schemeOverride: scheme).format();
}

String? navivoxHttpOriginOrOriginalFromString(String? raw) {
  final value = navivoxOptionalStringFromJson(raw);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return value;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return value;
  return navivoxOriginFromUri(uri);
}

Uri navivoxWebSocketUriFromEndpointString(String raw, {String? descriptor}) {
  final uri = _requiredEndpointUriFromString(raw);
  _validateNavivoxEndpointUri(
    uri,
    descriptor: descriptor,
    allowedSchemes: const {'ws', 'wss'},
    missingHostMessage: 'Navivox websocket URI must include a host',
    invalidSchemeMessage: 'Navivox websocket URI must use ws or wss',
    userinfoMessage: 'Navivox websocket URI must not include userinfo',
  );
  if (uri.hasFragment) {
    throw FormatException(
      'Navivox websocket URI must not include a fragment',
      descriptor,
    );
  }
  return uri;
}

void _validateNavivoxEndpointUri(
  Uri uri, {
  required String? descriptor,
  required Set<String> allowedSchemes,
  required String missingHostMessage,
  required String invalidSchemeMessage,
  required String userinfoMessage,
}) {
  if (uri.host.isEmpty) {
    throw FormatException(missingHostMessage, descriptor);
  }
  if (!allowedSchemes.contains(uri.scheme.toLowerCase())) {
    throw FormatException(invalidSchemeMessage, descriptor);
  }
  if (_navivoxEndpointUriHasUserInfo(uri)) {
    throw FormatException(userinfoMessage, descriptor);
  }
}

bool _navivoxEndpointUriHasUserInfo(Uri uri) => uri.userInfo.isNotEmpty;

String? navivoxWebSocketUrlFromEndpointString(String? raw) {
  final value = navivoxOptionalStringFromJson(raw);
  if (value == null) return null;
  try {
    return navivoxWebSocketUriFromEndpointString(value).toString();
  } on FormatException {
    return null;
  }
}

String? navivoxHttpBaseUrlFromEndpointString(String? raw) {
  final uri = _endpointUriFromString(raw);
  if (uri == null || !navivoxIsEndpointScheme(uri.scheme)) return null;
  try {
    return navivoxHttpBaseUrlFromEndpointUri(uri);
  } on FormatException {
    return null;
  }
}

Uri _requiredEndpointUriFromString(String raw) {
  final value = raw.trim();
  return Uri.parse(value);
}

Uri? _endpointUriFromString(String? raw) {
  final value = navivoxOptionalStringFromJson(raw);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  return uri;
}
