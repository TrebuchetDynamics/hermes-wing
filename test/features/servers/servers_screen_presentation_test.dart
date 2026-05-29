import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/servers/overview/servers_screen_presentation.dart';

const _servers = [
  NavivoxServer(id: 'zulu', name: 'Zulu Gateway', status: 'offline'),
  NavivoxServer(id: 'alpha', name: 'Alpha Gateway', status: 'online'),
];

const _contacts = [
  NavivoxProfileContact(
    serverId: 'zulu',
    profileId: 'support',
    displayName: 'Support Triage',
    serverLabel: 'Zulu Gateway',
    health: NavivoxProfileHealth.needsAuth,
    latestPreview: 'Waiting for token',
    attentionBadges: ['auth'],
  ),
  NavivoxProfileContact(
    serverId: 'alpha',
    profileId: 'mineru',
    displayName: 'Mineru Builder',
    serverLabel: 'Alpha Gateway',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
    workspaceRootCount: 2,
    micAvailable: true,
    activeTurnState: 'streaming',
  ),
  NavivoxProfileContact(
    serverId: 'alpha',
    profileId: 'personal',
    displayName: 'Personal',
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
      const NavivoxChannelState(
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
    expect(registered.activeProfileContact, isNull);
    expect(registered.activeProfileLabel, isNull);
    expect(registered.countLabels, ['1 profile', '1 auth']);
    expect(registered.profileContacts.single.compactHealthLabel, 'auth');
  });

  test('owns manage gateway sheet and disconnect copy', () {
    final presentation = ServersScreenPresentation.fromState(
      const NavivoxChannelState(
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
}
