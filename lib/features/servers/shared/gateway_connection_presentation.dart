import '../../../core/protocol/navivox_endpoint_uri.dart';
import '../../../core/protocol/navivox_json.dart';
import '../models/connection_gateway.dart';

class GatewayConnectionPresentation {
  const GatewayConnectionPresentation();

  String? validateBaseUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the Gormes gateway base URL.';
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return 'Enter a valid Gormes gateway URL.';
    }
    if (!navivoxIsEndpointScheme(uri.scheme)) {
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
    if (!navivoxIsEndpointScheme(uri.scheme)) {
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

    final baseUri = Uri.parse(
      navivoxHttpBaseUrlFromEndpointUri(uri.replace(port: selectedPort)),
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
    return GatewayConnectionRequest(
      baseUrl: baseUrl.trim(),
      token: navivoxOptionalStringFromJson(token),
      webSocketUrl: navivoxOptionalStringFromJson(webSocketUrl),
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

bool _addressLooksLikeUri(String value) =>
    RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value);

int? _parsePort(String value) {
  if (value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0 || parsed > 65535) return null;
  return parsed;
}

String? _supportedInputScheme(String scheme) {
  final normalized = scheme.trim().toLowerCase();
  return navivoxIsEndpointScheme(normalized) ? normalized : null;
}
