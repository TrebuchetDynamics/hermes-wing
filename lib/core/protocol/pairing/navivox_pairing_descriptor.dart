import '../../gateway/client/navivox_gateway_config.dart';
import '../endpoint/navivox_endpoint_uri.dart';
import 'pairing_descriptor_query_fields.dart';

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
    final fields = PairingDescriptorQueryFields(
      descriptor: value,
      queryParametersAll: uri.queryParametersAll,
      rawQuery: uri.query,
    );
    final tokenRequired = fields.boolean('token_required');
    final token = fields.optional('rest_token');
    if (tokenRequired && token == null) {
      throw FormatException('Pairing descriptor requires rest_token', value);
    }
    final webSocketUri = navivoxWebSocketUriFromEndpointString(
      fields.required('websocket_url'),
      descriptor: value,
    );
    final baseUri = _baseUriFromPairingParams(
      explicitBaseUrl: fields.optional('base_url'),
      webSocketUri: webSocketUri,
      descriptor: value,
    );
    return NavivoxPairingDescriptor(
      baseUri: baseUri,
      webSocketUri: webSocketUri,
      authMode: fields.optional('auth_mode') ?? '',
      exposureMode: fields.optional('exposure_mode') ?? '',
      tokenRequired: tokenRequired,
      token: token,
      serverId: fields.optional('server_id'),
      profileId: fields.optional('profile_id'),
      workspaceId: fields.optional('workspace_id'),
      providerId: fields.optional('provider_id'),
      channelIds: fields.csv('channel_ids'),
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

Uri _baseUriFromPairingParams({
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
  return uri;
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
