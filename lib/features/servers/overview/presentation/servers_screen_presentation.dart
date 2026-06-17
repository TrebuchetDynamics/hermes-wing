import '../../../../core/channel/navivox_channel.dart';
import '../../../../core/session/readiness/reconnect_readiness.dart';
import '../../../../shared/presentation/count_labels.dart';
import '../../../../shared/presentation/profile_health_labels.dart';

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
          final active = server.id == state.activeServerId;
          return ServerGatewayPresentation(
            server: server,
            profileContacts: List.unmodifiable(
              (contactsByServer[server.id] ?? const <NavivoxProfileContact>[])
                  .map(GatewayProfileContactPresentation.new),
            ),
            active: active,
            activeProfileContact: activeProfileContact,
            // Durable reconnect readiness is only meaningful for the gateway
            // whose live capability document is loaded — the active session.
            reconnectReadiness: active
                ? state.reconnectReadiness
                : ReconnectReadiness.unknown,
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
    this.reconnectReadiness = ReconnectReadiness.unknown,
  });

  final NavivoxServer server;
  final List<GatewayProfileContactPresentation> profileContacts;
  final bool active;
  final NavivoxProfileContact? activeProfileContact;
  final ReconnectReadiness reconnectReadiness;

  /// Reconnect readiness is shown only for the active gateway once its
  /// capability document has resolved (i.e. not the pre-connect unknown state).
  bool get showReconnectStatus =>
      active && reconnectReadiness.kind != ReconnectReadinessKind.unknown;

  String get reconnectStatusTitle => 'Reconnect readiness';
  String get reconnectStatusMessage => reconnectReadiness.message;
  String? get reconnectRecoveryMessage => reconnectReadiness.recoveryMessage;

  String get statusSubtitle =>
      '${active ? 'Active session gateway' : 'Registered gateway'} · ${server.status}';

  GatewayStatusPresentation get gatewayStatus => GatewayStatusPresentation(
    rawStatus: server.status,
    active: active,
    countLabels: countLabels,
  );

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
      countLabel(profileContacts.length, 'profile'),
      if (warningCount > 0) countLabel(warningCount, 'warning'),
      if (authCount > 0) countLabel(authCount, 'auth'),
      if (activeTurns > 0) countLabel(activeTurns, 'active turn'),
    ];
  }
}

class GatewayStatusPresentation {
  const GatewayStatusPresentation({
    required this.rawStatus,
    required this.active,
    required this.countLabels,
  });

  final String rawStatus;
  final bool active;
  final List<String> countLabels;

  String get title => 'Gateway status';

  String get headline {
    final status = _normalizedGatewayStatus(rawStatus);
    return switch (status) {
      'online' || 'ready' =>
        active ? 'Active session connected' : 'Registered gateway online',
      'offline' =>
        active
            ? 'Active session gateway offline'
            : 'Registered gateway offline',
      '' =>
        active
            ? 'Active session status unknown'
            : 'Registered gateway status unknown',
      _ =>
        active
            ? 'Active session: ${_formattedGatewayStatus(rawStatus)}'
            : 'Registered gateway: ${_formattedGatewayStatus(rawStatus)}',
    };
  }

  String get sessionLine =>
      active ? 'Session: active in this app' : 'Session: not active';

  String get reportedStatusLine =>
      'Reported status: ${_formattedGatewayStatus(rawStatus)}';

  String get summaryLine => '$sessionLine · $reportedStatusLine';

  String get profileContactsLine => countLabels.isEmpty
      ? 'Profile contacts: none reported yet'
      : 'Profile contacts: ${countLabels.join(' · ')}';

  String get deferredMetadataTitle => 'Connection metadata pending';

  String get deferredMetadataMessage =>
      'Base URL, auth, exposure, stream health, credentials, and local trust are not reported by the current app state yet.';
}

class GatewayProfileContactPresentation {
  const GatewayProfileContactPresentation(this.contact);

  final NavivoxProfileContact contact;

  String get compactHealthLabel => compactProfileHealthLabel(contact.health);
}

String _normalizedGatewayStatus(String status) => status.trim().toLowerCase();

String _formattedGatewayStatus(String status) {
  final words = status
      .trim()
      .split(RegExp(r'[\s_-]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .toList(growable: false);
  if (words.isEmpty) return 'Unknown';
  return words.join(' ');
}
