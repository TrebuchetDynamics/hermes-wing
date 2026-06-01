import '../../../../core/protocol/navivox_endpoint_uri.dart';
import '../../../../core/protocol/navivox_json.dart';
import '../../models/connection_gateway.dart';

class GatewayConnectionPresentation {
  const GatewayConnectionPresentation();

  String? validateBaseUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the Gormes gateway base URL.';
    return _validateEndpointUriText(
      trimmed,
      invalidMessage: 'Enter a valid Gormes gateway URL.',
    );
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

    final input = _GatewayAddressPortInput(
      rawAddress: rawAddress,
      defaultScheme: _supportedInputScheme(scheme) ?? 'http',
    );
    final uriError = _validateEndpointUriText(
      input.uriText,
      invalidMessage: 'Enter a valid Gormes gateway address.',
    );
    if (uriError != null) {
      return GatewayConnectionAddressPort.error(uriError);
    }
    final uri = Uri.parse(input.uriText);

    final detectedPort = uri.hasPort ? uri.port : null;
    final selectedPort = detectedPort ?? _parsePort(rawPort);
    if (selectedPort == null) {
      return const GatewayConnectionAddressPort.error(
        'Enter a valid gateway port.',
      );
    }

    final endpointUri = _endpointUriWithSelectedPort(
      uri: uri,
      selectedPort: selectedPort,
      detectedPortFromAddress: detectedPort != null,
    );
    final baseUrl = navivoxHttpBaseUrlFromEndpointUri(endpointUri);
    return GatewayConnectionAddressPort(
      address: uri.host,
      port: '$selectedPort',
      baseUrl: baseUrl,
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

class _GatewayAddressPortInput {
  const _GatewayAddressPortInput({
    required this.rawAddress,
    required this.defaultScheme,
  });

  final String rawAddress;
  final String defaultScheme;

  String get uriText {
    if (_addressLooksLikeUri(rawAddress)) return rawAddress;
    return '$defaultScheme://${_authorityAddress(rawAddress)}';
  }
}

bool _addressLooksLikeUri(String value) =>
    RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value);

String _authorityAddress(String value) {
  if (_looksLikeBareIpv6Address(value)) return '[$value]';
  return value;
}

Uri _endpointUriWithSelectedPort({
  required Uri uri,
  required int selectedPort,
  required bool detectedPortFromAddress,
}) {
  if (detectedPortFromAddress) return uri;
  return Uri.parse('${uri.scheme}://${_authorityHost(uri.host)}:$selectedPort');
}

String _authorityHost(String host) {
  if (host.contains(':')) return '[$host]';
  return host;
}

bool _looksLikeBareIpv6Address(String value) {
  if (value.startsWith('[') || value.endsWith(']')) return false;
  return ':'.allMatches(value).length > 1;
}

int? _parsePort(String value) {
  if (value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || !_isValidPort(parsed)) return null;
  return parsed;
}

String? _validateEndpointUriText(
  String text, {
  required String invalidMessage,
}) {
  final validation = _GatewayEndpointUriValidation.tryParse(text);
  if (!validation.isWellFormed) return invalidMessage;
  if (!validation.hasSupportedScheme) return 'Use http, https, ws, or wss.';
  if (validation.hasClientOnlyFragment) return invalidMessage;
  if (!validation.hasValidPort) return invalidMessage;
  return null;
}

class _GatewayEndpointUriValidation {
  const _GatewayEndpointUriValidation._({
    required this.uri,
    required this.containsWhitespace,
  });

  factory _GatewayEndpointUriValidation.tryParse(String text) {
    return _GatewayEndpointUriValidation._(
      uri: Uri.tryParse(text),
      containsWhitespace: _containsWhitespace(text),
    );
  }

  final Uri? uri;
  final bool containsWhitespace;

  bool get isWellFormed =>
      !containsWhitespace && uri != null && uri!.host.isNotEmpty;

  bool get hasSupportedScheme =>
      uri != null && navivoxIsEndpointScheme(uri!.scheme);

  bool get hasClientOnlyFragment => uri?.hasFragment ?? false;

  bool get hasValidPort =>
      uri == null || !uri!.hasPort || _isValidPort(uri!.port);
}

bool _containsWhitespace(String value) => RegExp(r'\s').hasMatch(value);

bool _isValidPort(int port) => port > 0 && port <= 65535;

String? _supportedInputScheme(String scheme) {
  final normalized = scheme.trim().toLowerCase();
  return navivoxIsEndpointScheme(normalized) ? normalized : null;
}
