import '../gateway/navivox_gateway_config.dart';
import 'navivox_endpoint_uri.dart';
import 'navivox_json.dart';

class NavivoxPairingDescriptor {
  const NavivoxPairingDescriptor({
    required this.baseUri,
    required this.webSocketUri,
    required this.authMode,
    required this.exposureMode,
    required this.tokenRequired,
    this.token,
    this.serverId,
    this.profileId,
    this.workspaceId,
    this.providerId,
    this.channelIds = const [],
  });

  factory NavivoxPairingDescriptor.parse(String value) {
    final uri = Uri.parse(value.trim());
    if (uri.scheme != 'navivox' || uri.host != 'connect') {
      throw FormatException('Expected navivox://connect descriptor', value);
    }
    final query = uri.queryParameters;
    final tokenRequired = _boolFromPairingParam(query['token_required']);
    final token = _optionalPairingParam(query['rest_token']);
    if (tokenRequired && token == null) {
      throw FormatException('Pairing descriptor requires rest_token', value);
    }
    final webSocketUri = Uri.parse(
      _requiredPairingParam(query, 'websocket_url', value),
    );
    final baseUri = Uri.parse(
      _optionalPairingParam(query['base_url']) ??
          _baseUrlFromWebSocketUri(webSocketUri, value),
    );
    return NavivoxPairingDescriptor(
      baseUri: baseUri,
      webSocketUri: webSocketUri,
      authMode: _optionalPairingParam(query['auth_mode']) ?? '',
      exposureMode: _optionalPairingParam(query['exposure_mode']) ?? '',
      tokenRequired: tokenRequired,
      token: token,
      serverId: _optionalPairingParam(query['server_id']),
      profileId: _optionalPairingParam(query['profile_id']),
      workspaceId: _optionalPairingParam(query['workspace_id']),
      providerId: _optionalPairingParam(query['provider_id']),
      channelIds: _csvPairingParam(query['channel_ids']),
    );
  }

  final Uri baseUri;
  final Uri webSocketUri;
  final String authMode;
  final String exposureMode;
  final bool tokenRequired;
  final String? token;
  final String? serverId;
  final String? profileId;
  final String? workspaceId;
  final String? providerId;
  final List<String> channelIds;

  NavivoxGatewayConfig toGatewayConfig() {
    return NavivoxGatewayConfig(
      baseUri: baseUri,
      token: token,
      webSocketUri: webSocketUri,
    );
  }
}

String _requiredPairingParam(
  Map<String, String> query,
  String name,
  String descriptor,
) {
  final value = _optionalPairingParam(query[name]);
  if (value == null) {
    throw FormatException('Pairing descriptor missing $name', descriptor);
  }
  return value;
}

String? _optionalPairingParam(String? value) {
  return navivoxOptionalStringFromJson(value);
}

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

bool _boolFromPairingParam(String? value) {
  return value?.trim().toLowerCase() == 'true';
}

List<String> _csvPairingParam(String? value) {
  final trimmed = navivoxOptionalStringFromJson(value);
  if (trimmed == null) return const [];
  return navivoxTrimmedStringList(trimmed.split(','));
}
