import '../../gateway/navivox_gateway_protocol.dart';
import 'gateway_client_guard.dart';

/// Gateway-facing capability policy for channel features.
///
/// Keeping the endpoint/capability checks in one place prevents channel methods
/// from re-stating the same advertised-endpoint contract before each gateway
/// call.
bool navivoxCapabilityDocumentUsable(NavivoxCapabilityDocument capabilities) {
  return capabilities.object == 'gormes.navivox.capabilities' &&
      capabilities.protocolVersion == navivoxWebSocketProtocol &&
      capabilities.auth.mode.trim().isNotEmpty &&
      capabilities.advertisesEndpoint('GET', '/v1/navivox/capabilities') &&
      capabilities.streams.canonicalEndpoint.trim().isNotEmpty;
}

bool navivoxCapabilityAllows(
  NavivoxCapabilityDocument capabilities,
  String capability,
  String method,
  String path,
) {
  return capabilities.supports(capability) &&
      capabilities.advertisesEndpoint(method, path);
}

NavivoxGatewayClient navivoxRequireGatewayCapability({
  required NavivoxGatewayClient? client,
  required NavivoxCapabilityDocument? capabilities,
  required bool Function(NavivoxCapabilityDocument capabilities) isAvailable,
  required String connectMessage,
  required String unavailableMessage,
}) {
  final connectedClient = navivoxRequireConnectedGatewayClient(
    client: client,
    message: connectMessage,
  );
  if (capabilities == null || !isAvailable(capabilities)) {
    throw StateError(unavailableMessage);
  }
  return connectedClient;
}

bool navivoxProfileContactsAvailable(NavivoxCapabilityDocument capabilities) {
  return navivoxCapabilityAllows(
    capabilities,
    'profile_contacts',
    'GET',
    '/v1/navivox/profile-contacts',
  );
}

bool navivoxProfileRoutingAvailable(NavivoxCapabilityDocument capabilities) {
  return navivoxCapabilityAllows(
    capabilities,
    'profile_routing',
    'GET',
    '/v1/navivox/profile-routing',
  );
}

bool navivoxStreamAvailable(NavivoxCapabilityDocument capabilities) {
  return navivoxCapabilityAllows(
        capabilities,
        'stream_turns',
        'WS',
        '/v1/navivox/stream',
      ) &&
      capabilities.streams.canonicalEndpoint == '/v1/navivox/stream';
}

bool navivoxRunRecordsSupported(NavivoxCapabilityDocument capabilities) {
  return capabilities.voice.runRecordsEndpoint.trim().isNotEmpty;
}

bool navivoxConfigAdminSupported(NavivoxCapabilityDocument capabilities) {
  return navivoxCapabilityAllows(
        capabilities,
        'config_admin',
        'GET',
        '/v1/navivox/config-admin/schema',
      ) &&
      capabilities.advertisesEndpoint('GET', '/v1/navivox/config-admin') &&
      capabilities.advertisesEndpoint(
        'POST',
        '/v1/navivox/config-admin/diff',
      ) &&
      capabilities.advertisesEndpoint(
        'POST',
        '/v1/navivox/config-admin/validate',
      ) &&
      capabilities.advertisesEndpoint('POST', '/v1/navivox/config-admin/apply');
}

bool navivoxProfileSeedAvailable(NavivoxCapabilityDocument capabilities) {
  return navivoxCapabilityAllows(
    capabilities,
    'profile_seed',
    'POST',
    '/v1/navivox/profile-seed',
  );
}

bool navivoxVoiceProfilesAvailable(NavivoxCapabilityDocument capabilities) {
  return navivoxCapabilityAllows(
    capabilities,
    'voice_profiles',
    'GET',
    '/v1/navivox/voice-profiles',
  );
}

bool navivoxVoiceProfileValidationAvailable(
  NavivoxCapabilityDocument capabilities,
) {
  return navivoxCapabilityAllows(
    capabilities,
    'voice_profiles',
    'POST',
    '/v1/navivox/voice-profiles/validate',
  );
}
