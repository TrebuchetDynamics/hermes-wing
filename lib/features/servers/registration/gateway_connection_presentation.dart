class GatewayConnectionPresentation {
  const GatewayConnectionPresentation();

  String? validateBaseUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the Gormes gateway base URL.';
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return 'Enter a valid Gormes gateway URL.';
    }
    if (!{'http', 'https', 'ws', 'wss'}.contains(uri.scheme)) {
      return 'Use http, https, ws, or wss.';
    }
    return null;
  }

  String? validateAddressAndPort({
    required String address,
    required String port,
    String scheme = 'http',
  }) {
    final parsed = parseAddressPort(
      address: address,
      port: port,
      scheme: scheme,
    );
    return parsed.error;
  }

  GatewayConnectionAddressPort parseAddressPort({
    required String address,
    required String port,
    String scheme = 'http',
  }) {
    final rawAddress = address.trim();
    final rawPort = port.trim();
    if (rawAddress.isEmpty) {
      return const GatewayConnectionAddressPort.error(
        'Enter the Gormes gateway address.',
      );
    }

    final defaultScheme = _supportedInputScheme(scheme) ?? 'http';
    final parseInput = _addressLooksLikeUri(rawAddress)
        ? rawAddress
        : '$defaultScheme://$rawAddress';
    final uri = Uri.tryParse(parseInput);
    if (uri == null || uri.host.isEmpty) {
      return const GatewayConnectionAddressPort.error(
        'Enter a valid Gormes gateway address.',
      );
    }
    if (!{'http', 'https', 'ws', 'wss'}.contains(uri.scheme)) {
      return const GatewayConnectionAddressPort.error(
        'Use http, https, ws, or wss.',
      );
    }

    final detectedPort = uri.hasPort ? uri.port : null;
    final selectedPort = detectedPort ?? _parsePort(rawPort);
    if (selectedPort == null) {
      return const GatewayConnectionAddressPort.error(
        'Enter a valid gateway port.',
      );
    }

    final baseUri = Uri(
      scheme: _httpSchemeFor(uri.scheme),
      host: uri.host,
      port: selectedPort,
    );
    return GatewayConnectionAddressPort(
      address: uri.host,
      port: '$selectedPort',
      baseUrl: baseUri.toString(),
      detectedPortFromAddress: detectedPort != null,
    );
  }

  GatewayConnectionAddressPort splitBaseUrl(String baseUrl) {
    final parsed = parseAddressPort(address: baseUrl, port: '');
    if (parsed.hasError) return parsed;
    return parsed;
  }

  GatewayConnectionRequest connectRequest({
    required String baseUrl,
    required String token,
    String? webSocketUrl,
  }) {
    final trimmedToken = token.trim();
    final trimmedWebSocketUrl = webSocketUrl?.trim();
    return GatewayConnectionRequest(
      baseUrl: baseUrl.trim(),
      token: trimmedToken.isEmpty ? null : trimmedToken,
      webSocketUrl: trimmedWebSocketUrl == null || trimmedWebSocketUrl.isEmpty
          ? null
          : trimmedWebSocketUrl,
    );
  }

  GatewayConnectionRequest connectRequestFromParts({
    required String address,
    required String port,
    required String token,
    String scheme = 'http',
    String? webSocketUrl,
  }) {
    final parsed = parseAddressPort(
      address: address,
      port: port,
      scheme: scheme,
    );
    if (parsed.hasError) {
      throw ArgumentError(parsed.error);
    }
    return connectRequest(
      baseUrl: parsed.baseUrl!,
      token: token,
      webSocketUrl: webSocketUrl,
    );
  }
}

class GatewayConnectionAddressPort {
  const GatewayConnectionAddressPort({
    required this.address,
    required this.port,
    required this.baseUrl,
    this.detectedPortFromAddress = false,
  }) : error = null;

  const GatewayConnectionAddressPort.error(this.error)
    : address = null,
      port = null,
      baseUrl = null,
      detectedPortFromAddress = false;

  final String? address;
  final String? port;
  final String? baseUrl;
  final String? error;
  final bool detectedPortFromAddress;

  bool get hasError => error != null;
}

class GatewayConnectionRequest {
  const GatewayConnectionRequest({
    required this.baseUrl,
    this.token,
    this.webSocketUrl,
  });

  final String baseUrl;
  final String? token;
  final String? webSocketUrl;
}

bool _addressLooksLikeUri(String value) =>
    RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value);

int? _parsePort(String value) {
  if (value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0 || parsed > 65535) return null;
  return parsed;
}

String _httpSchemeFor(String scheme) => switch (scheme) {
  'ws' => 'http',
  'wss' => 'https',
  _ => scheme,
};

String? _supportedInputScheme(String scheme) {
  final normalized = scheme.trim().toLowerCase();
  return {'http', 'https', 'ws', 'wss'}.contains(normalized)
      ? normalized
      : null;
}
