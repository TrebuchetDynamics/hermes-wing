import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/profile_contacts/profile_contact_presentation.dart';

import '../shared/fixtures/profile_contact_fixtures.dart';

void main() {
  test('centralizes Profile contact screen and add-sheet copy', () {
    const presentation = ProfileContactsScreenPresentation();

    expect(presentation.title, 'Navivox');
    expect(presentation.searchHint, 'Search Profiles');
    expect(presentation.searchTooltip, 'Search profiles');
    expect(presentation.closeSearchTooltip, 'Close search');
    expect(presentation.manageGatewaysTooltip, 'Manage gateways');
    expect(presentation.profileListMenuTooltip, 'Open profile list menu');
    expect(presentation.noProfilesMessage, 'No profiles loaded');
    expect(presentation.noVisibleChatsMessage, 'No chats found');
    expect(presentation.addProfileTooltip, 'Add profile');
    expect(presentation.allServersLabel, 'All');
    expect(
      presentation.menuRows.map((row) => '${row.kind.name}:${row.title}'),
      [
        'manageGateways:Manage gateways',
        'manageProfiles:Manage profiles',
        'openMemory:Memory',
        'openConfig:Config',
        'openSettings:Settings',
      ],
    );
    expect(
      presentation.addProfileRows.map(
        (row) => '${row.kind.name}:${row.title}:${row.subtitle}',
      ),
      [
        'newProfile:New profile:Server-validated profile creation is next.',
        'addServer:Add server:Import connect-info from Gormes.',
      ],
    );
  });

  test(
    'summarizes an online profile contact for list, details, and search',
    () {
      final contact = mineruBuilderProfile(
        serverLabel: 'Local Gormes',
        latestPreview: 'Goncho memory active',
        latestAt: DateTime(2026, 5, 23, 10, 15),
        activeTurnState: 'streaming',
      );

      final summary = ProfileContactPresentation(contact);

      expect(summary.healthLabel, 'online');
      expect(summary.compactHealthLabel, 'online');
      expect(summary.workspaceLabel, '2 roots');
      expect(summary.voiceLabel, 'mic available');
      expect(summary.channelsLabel, 'local/web chat, voice');
      expect(summary.memoryLabel, 'Goncho available');
      expect(summary.gonchoStatusLabel, 'available');
      expect(summary.latestLabel, 'typing…');
      expect(summary.chatListPreviewLabel, 'typing… · online · 2 roots');
      expect(summary.avatarInitial, 'M');
      expect(summary.avatarColorIndex, 13);
      expect(summary.avatarSemanticLabel, 'Mineru Builder profile avatar');
      expect(
        summary.searchTerms,
        containsAll(<String>[
          'Mineru Builder',
          'mineru',
          'local',
          'Local Gormes',
          'Goncho memory active',
          'online',
          '2 roots',
          'mic available',
          'typing…',
        ]),
      );
      expect(summary.detailsTitle, 'Profile details');
      expect(summary.detailsSubtitle, 'Mineru Builder\nmineru');
      expect(summary.diagnosticsTitle, 'Profile diagnostics');
      expect(summary.diagnosticLines, [
        'Health: online',
        'Workspace: 2 roots',
        'Voice: mic available',
        'Latest: typing…',
        'Server: Local Gormes',
      ]);
      expect(summary.identityLines, [
        'Display name: Mineru Builder',
        'Profile path: mineru',
        'System prompt: not reported by API',
      ]);
      expect(summary.channelLines, [
        'Local/web chat: enabled',
        'Voice channel: mic available',
        'Telegram: not reported by API',
        'Discord: not reported by API',
        'WhatsApp: not reported by API',
      ]);
      expect(summary.memoryLines, [
        'Provider: Goncho',
        'Goncho status: available',
      ]);
      expect(summary.skillsLines, ['Skills: not reported by API']);
      expect(summary.configLines, [
        'Server: Local Gormes',
        'Profile ID: mineru',
        'Config: profile scoped',
        'Secrets: redacted',
      ]);
      expect(summary.logStatusLines, [
        'Status: online',
        'Latest: typing…',
        'Active turn: streaming',
      ]);
      expect(
        summary.detailSections.map(
          (section) =>
              '${section.kind.name}:${section.title}:${section.lines.first}',
        ),
        [
          'identity:Identity / system prompt:Display name: Mineru Builder',
          'channels:Connected channels:Local/web chat: enabled',
          'memory:Memory settings:Provider: Goncho',
          'skills:Skills list:Skills: not reported by API',
          'config:Config/environment summary:Server: Local Gormes',
          'logs:Logs/status:Status: online',
        ],
      );
      expect(
        summary.detailActions.map(
          (action) => '${action.kind.name}:${action.title}:${action.subtitle}',
        ),
        [
          'openChat:Open chat:Use this profile for the next turn.',
          'openMemory:Open memory:Inspect memory scoped to this profile.',
          'editProfile:Edit profile:Open profile-scoped config editor.',
        ],
      );
      expect(summary.agentFallbackSummaryLines, [
        'mineru',
        'Status: online',
        'Channels: local/web chat, voice',
        'Memory: Goncho available',
        'Skills: profile skills pending API',
        'Config: profile scoped',
        'Latest: Goncho memory active',
      ]);
    },
  );

  test('keeps list voice hints profile-reported, not full readiness', () {
    const contact = NavivoxProfileContact(
      serverId: 'lab',
      profileId: 'mineru',
      displayName: 'Mineru Builder',
      serverLabel: 'Lab Gateway',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Ready',
      micAvailable: true,
    );

    final summary = ProfileContactPresentation(contact);

    expect(summary.voiceLabel, 'mic available');
    expect(summary.channelsLabel, 'local/web chat, voice');
    expect(summary.searchTerms, contains('mic available'));
    expect(summary.searchTerms.join(' '), isNot(contains('trust')));
    expect(summary.searchTerms.join(' '), isNot(contains('device STT')));
    expect(summary.searchTerms.join(' '), isNot(contains('continuous voice')));
  });

  test('formats contact list timestamps like Telegram chat rows', () {
    final now = DateTime.now();

    expect(
      ProfileContactPresentation(
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'today',
          displayName: 'Today',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
          latestAt: DateTime(now.year, now.month, now.day, 9, 7),
        ),
      ).latestTimeLabel,
      '09:07',
    );
    expect(
      ProfileContactPresentation(
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'older',
          displayName: 'Older',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
          latestAt: DateTime(now.year, 1, 2, 9, 7),
        ),
      ).latestTimeLabel,
      'Jan 2',
    );
    expect(
      ProfileContactPresentation(
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'last-year',
          displayName: 'Last Year',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
          latestAt: DateTime(now.year - 1, 12, 31, 9, 7),
        ),
      ).latestTimeLabel,
      '12/31/${now.year - 1}',
    );
  });

  test('summarizes auth and workspace problems with Goncho wording', () {
    const contact = NavivoxProfileContact(
      serverId: 'office',
      profileId: 'support',
      displayName: 'Support Triage',
      serverLabel: 'Office',
      health: NavivoxProfileHealth.needsAuth,
      latestPreview: '',
      workspaceRootCount: 0,
      workspaceRootsOk: false,
      attentionBadges: ['auth'],
      micAvailable: false,
    );

    final summary = ProfileContactPresentation(contact);

    expect(summary.healthLabel, 'auth required');
    expect(summary.compactHealthLabel, 'auth');
    expect(summary.workspaceLabel, 'workspace issue');
    expect(summary.voiceLabel, 'mic unavailable');
    expect(summary.channelsLabel, 'local/web chat');
    expect(summary.memoryLabel, 'Goncho needs workspace attention');
    expect(summary.gonchoStatusLabel, 'needs workspace attention');
    expect(summary.latestLabel, 'no recent activity');
    expect(summary.chatListPreviewLabel, '⚠ Workspace issue · auth required');
    expect(summary.avatarInitial, 'S');
    expect(summary.avatarColorIndex, 17);
    expect(summary.avatarSemanticLabel, 'Support Triage profile avatar');
    expect(summary.searchTerms, containsAll(<String>['auth', 'auth required']));
    expect(summary.diagnosticLines, [
      'Health: auth required',
      'Workspace: workspace issue',
      'Voice: mic unavailable',
      'Latest: no recent activity',
      'Server: Office',
    ]);
    expect(summary.memoryLines, [
      'Provider: Goncho',
      'Goncho status: needs workspace attention',
    ]);
    expect(summary.agentFallbackSummaryLines, [
      'support',
      'Status: auth required',
      'Channels: local/web chat',
      'Memory: Goncho needs workspace attention',
      'Skills: profile skills pending API',
      'Config: profile scoped',
    ]);
  });

  test('uses profile id as avatar fallback when display name is blank', () {
    const contact = NavivoxProfileContact(
      serverId: 'local',
      profileId: 'mineru',
      displayName: '   ',
      serverLabel: 'Local Gormes',
      health: NavivoxProfileHealth.online,
      latestPreview: '',
    );

    final summary = ProfileContactPresentation(contact);

    expect(summary.avatarInitial, 'M');
    expect(summary.avatarSemanticLabel, 'mineru profile avatar');
  });

  test(
    'describes config scope from the selected gateway and profile contact',
    () {
      const server = NavivoxServer(
        id: 'local',
        name: 'Local Gormes',
        status: 'online',
      );
      const contact = NavivoxProfileContact(
        serverId: 'local',
        profileId: 'mineru',
        displayName: 'Mineru Builder',
        serverLabel: 'local',
        health: NavivoxProfileHealth.online,
        latestPreview: '',
      );

      final scope = ProfileContactScopePresentation(
        activeServer: server,
        activeServerId: 'local',
        activeProfile: contact,
      );

      expect(scope.serverLabel, 'Local Gormes');
      expect(scope.profileLabel, 'Mineru Builder');
      expect(scope.profileId, 'mineru');
    },
  );
}
