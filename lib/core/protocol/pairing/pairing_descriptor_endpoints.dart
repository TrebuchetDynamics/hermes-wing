import '../endpoint/navivox_endpoint_uri.dart';

/// Derived endpoint values from a `navivox://connect` descriptor.
///
/// Keeping endpoint derivation separate from field extraction makes the pairing
/// handoff assumptions explicit: the websocket endpoint is the connection URI,
/// while the HTTP base URI is always an origin, either from an explicit
/// `base_url` or derived from the websocket endpoint.
class PairingDescriptorEndpoints {
  const PairingDescriptorEndpoints({
    required this.baseUri,
    required this.webSocketUri,
  });

  factory PairingDescriptorEndpoints.fromWireFields({
    required String webSocketUrl,
    required String? explicitBaseUrl,
    required String descriptor,
  }) {
    final webSocketUri = navivoxWebSocketUriFromEndpointString(
      webSocketUrl,
      descriptor: descriptor,
    );
    return PairingDescriptorEndpoints(
      baseUri: pairingDescriptorBaseUri(
        explicitBaseUrl: explicitBaseUrl,
        webSocketUri: webSocketUri,
        descriptor: descriptor,
      ),
      webSocketUri: webSocketUri,
    );
  }

  final Uri baseUri;
  final Uri webSocketUri;
}

Uri pairingDescriptorBaseUri({
  required String? explicitBaseUrl,
  required Uri webSocketUri,
  required String descriptor,
}) {
  if (explicitBaseUrl != null) {
    return _httpBaseUriFromPairingParam(explicitBaseUrl, descriptor);
  }
  return Uri.parse(_baseUrlFromWebSocketUri(webSocketUri, descriptor));
}

Uri _httpBaseUriFromPairingParam(String value, String descriptor) {
  final uri = _validatedHttpBaseUri(value, descriptor);
  return Uri.parse(navivoxOriginFromUri(uri));
}

Uri _validatedHttpBaseUri(String value, String descriptor) {
  final uri = Uri.parse(value);
  final scheme = uri.scheme.toLowerCase();
  if ((scheme != 'http' && scheme != 'https') || uri.host.isEmpty) {
    throw FormatException(
      'Pairing descriptor base_url must use http or https',
      descriptor,
    );
  }
  if (uri.hasFragment) {
    throw FormatException(
      'Pairing descriptor base_url must not include a fragment',
      descriptor,
    );
  }
  if (_pairingDescriptorUriHasUserInfo(uri)) {
    throw FormatException(
      'Pairing descriptor base_url must not include userinfo',
      descriptor,
    );
  }
  return uri;
}

bool _pairingDescriptorUriHasUserInfo(Uri uri) => uri.userInfo.isNotEmpty;

String _baseUrlFromWebSocketUri(Uri uri, String descriptor) {
  try {
    return navivoxHttpBaseUrlFromEndpointUri(uri, descriptor: descriptor);
  } on FormatException {
    throw FormatException(
      'Pairing descriptor invalid websocket_url',
      descriptor,
    );
  }
}
