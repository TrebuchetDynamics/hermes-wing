import '../../gateway/client/navivox_gateway_config.dart';
import 'pairing_descriptor_endpoints.dart';
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
    _validatePairingDescriptorEnvelope(uri, descriptor: value);
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
    final endpoints = PairingDescriptorEndpoints.fromWireFields(
      webSocketUrl: fields.required('websocket_url'),
      explicitBaseUrl: fields.optional('base_url'),
      descriptor: value,
    );
    return NavivoxPairingDescriptor(
      baseUri: endpoints.baseUri,
      webSocketUri: endpoints.webSocketUri,
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

void _validatePairingDescriptorEnvelope(Uri uri, {required String descriptor}) {
  if (uri.scheme != 'navivox' || uri.host != 'connect') {
    throw FormatException('Expected navivox://connect descriptor', descriptor);
  }
  if (uri.path.isNotEmpty || uri.hasFragment) {
    throw FormatException(
      'Pairing descriptor must not include path or fragment state',
      descriptor,
    );
  }
}
