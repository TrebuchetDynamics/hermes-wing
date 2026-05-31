import '../../gateway/navivox_gateway_protocol.dart';
import '../contracts/navivox_channel.dart';

/// Gateway profile-contact fallback and server-list policy.
///
/// Keeping fallback contacts and status derivation together ensures capability
/// failures, empty profile snapshots, and live contact updates use the same
/// server/profile defaults.
NavivoxProfileContact navivoxClosedCapabilityProfileContact(String status) {
  return NavivoxProfileContact(
    serverId: 'navivox-gateway',
    profileId: 'default',
    displayName: 'Default profile',
    serverLabel: 'Gormes Gateway',
    health: NavivoxProfileHealth.warning,
    latestPreview: status,
    latestPreviewKind: 'status',
    workspaceRootCount: 0,
    workspaceRootsOk: false,
    micAvailable: false,
    voiceCapability: const NavivoxVoiceCapability(
      disabledReason: 'Navivox capabilities unavailable',
      isReported: true,
    ),
  );
}

NavivoxProfileContact navivoxFallbackProfileContact() {
  return const NavivoxProfileContact(
    serverId: 'navivox-gateway',
    profileId: 'default',
    displayName: 'Default profile',
    serverLabel: 'Gormes Gateway',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Gateway online',
    latestPreviewKind: 'status',
    workspaceRootCount: 1,
    workspaceRootsOk: true,
    micAvailable: true,
  );
}

List<NavivoxServer> navivoxServersFromProfileContacts(
  List<NavivoxProfileContact> contacts,
  NavivoxGatewayConfig config,
) {
  final servers = <String, NavivoxServer>{};
  for (final contact in contacts) {
    servers.putIfAbsent(
      contact.serverId,
      () => NavivoxServer(
        id: contact.serverId,
        name: contact.serverLabel,
        status: _serverStatus(contact, config),
      ),
    );
  }
  return servers.values.toList(growable: false);
}

List<NavivoxServer> navivoxUpsertProfileServer(
  List<NavivoxServer> servers,
  NavivoxProfileContact contact,
) {
  final index = servers.indexWhere((server) => server.id == contact.serverId);
  if (index >= 0) return servers;
  return [
    ...servers,
    NavivoxServer(
      id: contact.serverId,
      name: contact.serverLabel,
      status: _profileHealthStatus(contact),
    ),
  ];
}

String _serverStatus(
  NavivoxProfileContact contact,
  NavivoxGatewayConfig config,
) {
  if (contact.serverId == 'navivox-gateway') {
    return 'Gateway online - ${config.baseUri.host}:${config.baseUri.port}';
  }
  return _profileHealthStatus(contact);
}

String _profileHealthStatus(NavivoxProfileContact contact) {
  return switch (contact.health) {
    NavivoxProfileHealth.online => 'Gateway online',
    NavivoxProfileHealth.offline => 'Gateway offline',
    NavivoxProfileHealth.needsAuth => 'Provider auth required',
    NavivoxProfileHealth.warning => 'Profile warning',
  };
}
