import '../../../core/channel/navivox_channel.dart';
import '../../profile_contacts/profile_contact_presentation.dart';

class ServersScreenPresentation {
  const ServersScreenPresentation({required this.gateways});

  factory ServersScreenPresentation.fromState(NavivoxChannelState state) {
    final sortedServers = [...state.servers]
      ..sort((a, b) => a.name.compareTo(b.name));
    final contactsByServer = <String, List<NavivoxProfileContact>>{};
    for (final contact in state.profileContacts) {
      contactsByServer.putIfAbsent(contact.serverId, () => []).add(contact);
    }

    return ServersScreenPresentation(
      gateways: List.unmodifiable(
        sortedServers.map((server) {
          final activeProfile = state.activeProfileContact;
          final activeProfileContact =
              activeProfile != null && activeProfile.serverId == server.id
              ? activeProfile
              : null;
          return ServerGatewayPresentation(
            server: server,
            profileContacts: List.unmodifiable(
              (contactsByServer[server.id] ?? const <NavivoxProfileContact>[])
                  .map(GatewayProfileContactPresentation.new),
            ),
            active: server.id == state.activeServerId,
            activeProfileContact: activeProfileContact,
          );
        }),
      ),
    );
  }

  final List<ServerGatewayPresentation> gateways;

  bool get hasGateways => gateways.isNotEmpty;
}

class ServerGatewayPresentation {
  const ServerGatewayPresentation({
    required this.server,
    required this.profileContacts,
    required this.active,
    required this.activeProfileContact,
  });

  final NavivoxServer server;
  final List<GatewayProfileContactPresentation> profileContacts;
  final bool active;
  final NavivoxProfileContact? activeProfileContact;

  String get statusSubtitle =>
      '${active ? 'Active session gateway' : 'Registered gateway'} · ${server.status}';

  String? get activeProfileLabel {
    final profile = activeProfileContact;
    if (profile == null) return null;
    return '${profile.displayName} · ${profile.profileId}';
  }

  String get manageTitle => 'Manage gateway';
  String get serverIdTitle => 'Server ID';
  String get activeProfileTitle => 'Active profile contact';
  String get profilesSectionTitle => 'Profiles on this gateway';
  String get emptyProfilesLabel => 'No profiles reported by this gateway yet.';

  bool get showDisconnectAction => active;
  String get disconnectActionTitle => 'Disconnect current session';
  String get disconnectActionSubtitle =>
      'Close the active Gormes gateway connection for this app session.';
  String get disconnectDialogTitle => 'Disconnect ${server.name}?';
  String get disconnectDialogBody =>
      'Navivox will close the active gateway session. Stored app settings stay on this device.';
  String get disconnectCancelLabel => 'Cancel';
  String get disconnectConfirmLabel => 'Disconnect';
  String get disconnectedMessage => 'Disconnected ${server.name}';
  String disconnectFailedMessage(Object error) => 'Disconnect failed: $error';

  List<String> get countLabels {
    final warningCount = profileContacts
        .where(
          (profile) =>
              !profile.contact.workspaceRootsOk ||
              profile.contact.health == NavivoxProfileHealth.warning,
        )
        .length;
    final authCount = profileContacts
        .where(
          (profile) => profile.contact.health == NavivoxProfileHealth.needsAuth,
        )
        .length;
    final activeTurns = profileContacts
        .where((profile) => profile.contact.activeTurnState != 'idle')
        .length;

    return [
      _plural(profileContacts.length, 'profile'),
      if (warningCount > 0) _plural(warningCount, 'warning'),
      if (authCount > 0) _plural(authCount, 'auth'),
      if (activeTurns > 0) _plural(activeTurns, 'active turn'),
    ];
  }

  static String _plural(int count, String noun) {
    if (count == 1) return '1 $noun';
    return '$count ${noun}s';
  }
}

class GatewayProfileContactPresentation {
  const GatewayProfileContactPresentation(this.contact);

  final NavivoxProfileContact contact;

  String get compactHealthLabel =>
      ProfileContactPresentation(contact).compactHealthLabel;
}
