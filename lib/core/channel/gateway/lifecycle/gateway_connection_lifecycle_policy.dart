import '../../../gateway/navivox_gateway_protocol.dart';
import '../../../session/readiness/reconnect_readiness.dart';
import '../../contracts/navivox_channel.dart';
import '../client/gateway_capability_policy.dart';
import '../profiles/gateway_profile_contact_policy.dart';

/// Pure state policy for gateway connection lifecycle outcomes.
///
/// Runtime code still owns HTTP/WebSocket effects. This policy centralizes the
/// channel-state consequences of closed capability mode, successful capability
/// loading, and failed saved-session reconnect cleanup.
NavivoxChannelState navivoxClosedCapabilityGatewayState({
  required NavivoxChannelState state,
  required NavivoxGatewayConfig config,
  required String status,
  String? gatewayLabel,
}) {
  final contact = navivoxClosedCapabilityProfileContact(
    status,
    serverLabel: gatewayLabel,
  );
  return state.copyWith(
    servers: [
      NavivoxServer(
        id: contact.serverId,
        name: contact.serverLabel,
        status: '$status - ${config.baseUri.host}:${config.baseUri.port}',
      ),
    ],
    activeServerId: contact.serverId,
    profileContacts: [contact],
    selectedProfileContactKey: contact.key,
    profileRouting: const NavivoxProfileRoutingReport(),
    profileRoutingSelections: const {},
    runRecordInspectionAvailable: false,
    configSchema: const {},
    configValues: const {},
    configDiff: const {},
    reconnectReadiness: ReconnectReadiness.unknown,
  );
}

NavivoxChannelState navivoxConnectedGatewayState({
  required NavivoxChannelState state,
  required NavivoxGatewayConfig config,
  required NavivoxCapabilityDocument capabilities,
  required List<NavivoxProfileContact> contacts,
  required NavivoxProfileRoutingReport profileRouting,
  required Map<String, Object?> configSchema,
  required Map<String, Object?> configValues,
}) {
  return navivoxStateWithProfileContacts(
    state: state,
    contacts: contacts,
    config: config,
  ).copyWith(
    profileRouting: profileRouting,
    runRecordInspectionAvailable: navivoxRunRecordsSupported(capabilities),
    configSchema: configSchema,
    configValues: configValues,
    configDiff: const {},
    reconnectReadiness: ReconnectReadiness.fromCapabilities(capabilities),
  );
}

NavivoxChannelState navivoxFailedSavedSessionReconnectState({
  required NavivoxChannelState state,
}) {
  return state.copyWith(
    servers: const [],
    clearActiveServerId: true,
    profileContacts: const [],
    clearSelectedProfileContactKey: true,
    profileRouting: const NavivoxProfileRoutingReport(),
    profileRoutingSelections: const {},
    runRecordInspectionAvailable: false,
    configSchema: const {},
    configValues: const {},
    configDiff: const {},
    reconnectReadiness: ReconnectReadiness.unknown,
  );
}
