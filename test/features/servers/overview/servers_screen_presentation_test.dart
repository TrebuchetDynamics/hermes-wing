import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/session/readiness/reconnect_readiness.dart';
import 'package:navivox/features/servers/overview/servers_screen_presentation.dart';

import '../../shared/fixtures/profile_contact_fixtures.dart';

const _servers = [
  NavivoxServer(id: 'zulu', name: 'Zulu Gateway', status: 'offline'),
  NavivoxServer(id: 'alpha', name: 'Alpha Gateway', status: 'online'),
];

final _contacts = [
  supportTriageProfile(serverId: 'zulu', serverLabel: 'Zulu Gateway'),
  mineruBuilderProfile(
    serverId: 'alpha',
    serverLabel: 'Alpha Gateway',
    latestPreview: 'Ready',
    activeTurnState: 'streaming',
  ),
  personalProfile(
    serverId: 'alpha',
    serverLabel: 'Alpha Gateway',
    health: NavivoxProfileHealth.warning,
    latestPreview: 'Workspace warning',
    workspaceRootCount: 1,
    workspaceRootsOk: false,
  ),
];

void main() {
  test('sorts gateways and groups Profile contacts with gateway copy', () {
    final presentation = ServersScreenPresentation.fromState(
      NavivoxChannelState(
        servers: _servers,
        activeServerId: 'alpha',
        profileContacts: _contacts,
        selectedProfileContactKey: 'alpha::mineru',
      ),
    );

    expect(presentation.hasGateways, isTrue);
    expect(presentation.gateways.map((gateway) => gateway.server.id), [
      'alpha',
      'zulu',
    ]);

    final active = presentation.gateways.first;
    expect(active.active, isTrue);
    expect(active.statusSubtitle, 'Active session gateway · online');
    expect(active.gatewayStatus.title, 'Gateway status');
    expect(active.gatewayStatus.headline, 'Active session connected');
    expect(active.gatewayStatus.sessionLine, 'Session: active in this app');
    expect(active.gatewayStatus.reportedStatusLine, 'Reported status: Online');
    expect(
      active.gatewayStatus.profileContactsLine,
      'Profile contacts: 2 profiles · 1 warning · 1 active turn',
    );
    expect(
      active.gatewayStatus.deferredMetadataMessage,
      contains('Base URL, auth, exposure, stream health, credentials'),
    );
    expect(active.profileContacts.map((profile) => profile.contact.profileId), [
      'mineru',
      'personal',
    ]);
    expect(active.activeProfileContact?.profileId, 'mineru');
    expect(active.activeProfileLabel, 'Mineru Builder · mineru');
    expect(active.countLabels, ['2 profiles', '1 warning', '1 active turn']);
    expect(active.profileContacts.first.compactHealthLabel, 'online');
    expect(active.profileContacts.last.compactHealthLabel, 'warning');

    final registered = presentation.gateways.last;
    expect(registered.active, isFalse);
    expect(registered.statusSubtitle, 'Registered gateway · offline');
    expect(registered.gatewayStatus.headline, 'Registered gateway offline');
    expect(registered.gatewayStatus.sessionLine, 'Session: not active');
    expect(
      registered.gatewayStatus.reportedStatusLine,
      'Reported status: Offline',
    );
    expect(
      registered.gatewayStatus.profileContactsLine,
      'Profile contacts: 1 profile · 1 auth',
    );
    expect(registered.activeProfileContact, isNull);
    expect(registered.activeProfileLabel, isNull);
    expect(registered.countLabels, ['1 profile', '1 auth']);
    expect(registered.profileContacts.single.compactHealthLabel, 'auth');
  });

  test('owns manage gateway sheet and disconnect copy', () {
    final presentation = ServersScreenPresentation.fromState(
      NavivoxChannelState(
        servers: _servers,
        activeServerId: 'alpha',
        profileContacts: _contacts,
        selectedProfileContactKey: 'alpha::mineru',
      ),
    );

    final active = presentation.gateways.first;
    expect(active.manageTitle, 'Manage gateway');
    expect(active.serverIdTitle, 'Server ID');
    expect(active.activeProfileTitle, 'Active profile contact');
    expect(active.profilesSectionTitle, 'Profiles on this gateway');
    expect(
      active.emptyProfilesLabel,
      'No profiles reported by this gateway yet.',
    );
    expect(active.showDisconnectAction, isTrue);
    expect(active.disconnectActionTitle, 'Disconnect current session');
    expect(
      active.disconnectActionSubtitle,
      'Close the active Gormes gateway connection for this app session.',
    );
    expect(active.disconnectDialogTitle, 'Disconnect Alpha Gateway?');
    expect(
      active.disconnectDialogBody,
      'Navivox will close the active gateway session. Stored app settings stay on this device.',
    );
    expect(active.disconnectCancelLabel, 'Cancel');
    expect(active.disconnectConfirmLabel, 'Disconnect');
    expect(active.disconnectedMessage, 'Disconnected Alpha Gateway');
    expect(
      active.disconnectFailedMessage('network down'),
      'Disconnect failed: network down',
    );

    final registered = presentation.gateways.last;
    expect(registered.showDisconnectAction, isFalse);
  });

  test('reports empty gateway state', () {
    final presentation = ServersScreenPresentation.fromState(
      const NavivoxChannelState(),
    );

    expect(presentation.hasGateways, isFalse);
    expect(presentation.gateways, isEmpty);
  });

  test('surfaces reconnect readiness only for the active gateway', () {
    final presentation = ServersScreenPresentation.fromState(
      NavivoxChannelState(
        servers: _servers,
        activeServerId: 'alpha',
        profileContacts: _contacts,
        selectedProfileContactKey: 'alpha::mineru',
        reconnectReadiness: const ReconnectReadiness(
          kind: ReconnectReadinessKind.available,
          message: 'Reconnect support is available but not saved yet.',
        ),
      ),
    );

    final active = presentation.gateways.firstWhere(
      (g) => g.server.id == 'alpha',
    );
    expect(active.showReconnectStatus, isTrue);
    expect(active.reconnectStatusTitle, 'Reconnect readiness');
    expect(
      active.reconnectStatusMessage,
      'Reconnect support is available but not saved yet.',
    );

    // The inactive, registered gateway has no live capability document, so it
    // must not present a reconnect readiness state.
    final registered = presentation.gateways.firstWhere(
      (g) => g.server.id == 'zulu',
    );
    expect(registered.showReconnectStatus, isFalse);
  });

  test('exposes a blocked reconnect recovery message for the active gateway', () {
    final presentation = ServersScreenPresentation.fromState(
      NavivoxChannelState(
        servers: _servers,
        activeServerId: 'alpha',
        profileContacts: _contacts,
        selectedProfileContactKey: 'alpha::mineru',
        reconnectReadiness: const ReconnectReadiness(
          kind: ReconnectReadinessKind.blocked,
          message: 'Reconnect cannot be saved on this connection.',
          recoveryMessage:
              'Durable reconnect is advertised with unsupported effective security.',
        ),
      ),
    );

    final active = presentation.gateways.firstWhere(
      (g) => g.server.id == 'alpha',
    );
    expect(active.showReconnectStatus, isTrue);
    expect(
      active.reconnectRecoveryMessage,
      'Durable reconnect is advertised with unsupported effective security.',
    );
  });
}
