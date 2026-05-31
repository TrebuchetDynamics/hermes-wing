import 'package:intl/intl.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../shared/presentation/profile_contact_labels.dart';
import '../../../shared/presentation/profile_health_labels.dart';

export '../../../shared/presentation/profile_contact_scope_presentation.dart';

const _avatarColorSlots = 18;

class ProfileContactPresentation {
  const ProfileContactPresentation(this.contact);

  final NavivoxProfileContact contact;

  String get healthLabel => profileHealthLabel(contact.health);

  String get compactHealthLabel => compactProfileHealthLabel(contact.health);

  String get workspaceLabel {
    if (!contact.workspaceRootsOk) return 'workspace issue';
    if (contact.workspaceRootCount == 1) return '1 root';
    return '${contact.workspaceRootCount} roots';
  }

  String get voiceLabel {
    if (!contact.micAvailable) return 'mic unavailable';
    return 'mic available';
  }

  String get channelsLabel {
    return contact.micAvailable ? 'local/web chat, voice' : 'local/web chat';
  }

  String get memoryLabel {
    if (!contact.workspaceRootsOk) return 'Goncho needs workspace attention';
    return 'Goncho available';
  }

  String get gonchoStatusLabel {
    if (!contact.workspaceRootsOk) return 'needs workspace attention';
    if (contact.workspaceRootCount > 0) return 'available';
    return 'not reported by API';
  }

  String get latestLabel {
    if (contact.activeTurnState == 'streaming') return 'typing…';
    final preview = contact.latestPreview.trim();
    return preview.isEmpty ? 'no recent activity' : preview;
  }

  String get chatListPreviewLabel {
    final lead = _chatListLeadLabel;
    final segments = <String>[lead];
    final health = healthLabel;
    if (health != lead) segments.add(health);
    if (contact.workspaceRootsOk) {
      segments.add(workspaceLabel);
    } else if (lead != '⚠ Workspace issue') {
      segments.add('⚠ Workspace issue');
    }
    return segments.join(' · ');
  }

  String get _chatListLeadLabel {
    if (contact.activeTurnState == 'streaming') return 'typing…';
    final preview = contact.latestPreview.trim();
    if (preview.isNotEmpty) return preview;
    if (!contact.workspaceRootsOk) return '⚠ Workspace issue';
    return 'Profile ready';
  }

  String get latestTimeLabel {
    final latestAt = contact.latestAt;
    if (latestAt == null) return '';
    final now = DateTime.now();
    final latestDay = DateTime(latestAt.year, latestAt.month, latestAt.day);
    final today = DateTime(now.year, now.month, now.day);
    if (latestDay == today) return DateFormat.Hm().format(latestAt);
    if (latestAt.year == now.year) return DateFormat.MMMd().format(latestAt);
    return DateFormat.yMd().format(latestAt);
  }

  int get attentionCount => contact.attentionBadges.length;

  String get avatarInitial {
    final runes = _avatarLabel.runes;
    if (runes.isEmpty) return '?';
    return String.fromCharCode(runes.first).toUpperCase();
  }

  int get avatarColorIndex =>
      contact.avatarSeed.codeUnits.fold<int>(0, (sum, unit) => sum + unit) %
      _avatarColorSlots;

  String get avatarSemanticLabel => '$_avatarLabel profile avatar';

  String get detailsTitle => 'Profile details';

  String get detailsSubtitle => '${contact.displayName}\n${contact.profileId}';

  String get diagnosticsTitle => 'Profile diagnostics';

  List<String> get diagnosticLines => [
    'Health: $healthLabel',
    'Workspace: $workspaceLabel',
    'Voice: $voiceLabel',
    'Latest: $latestLabel',
    'Server: ${contact.serverLabel}',
  ];

  List<String> get identityLines => [
    'Display name: ${contact.displayName}',
    'Profile path: ${contact.profileId}',
    'System prompt: not reported by API',
  ];

  List<String> get channelLines => [
    'Local/web chat: enabled',
    'Voice channel: $voiceLabel',
    'Telegram: not reported by API',
    'Discord: not reported by API',
    'WhatsApp: not reported by API',
  ];

  List<String> get memoryLines => [
    'Provider: Goncho',
    'Goncho status: $gonchoStatusLabel',
  ];

  List<String> get skillsLines => ['Skills: not reported by API'];

  List<String> get configLines => [
    'Server: ${contact.serverLabel}',
    'Profile ID: ${contact.profileId}',
    'Config: profile scoped',
    'Secrets: redacted',
  ];

  List<String> get logStatusLines => [
    'Status: $healthLabel',
    'Latest: $latestLabel',
    'Active turn: ${contact.activeTurnState}',
  ];

  List<ProfileContactDetailSectionPresentation> get detailSections => [
    ProfileContactDetailSectionPresentation(
      kind: ProfileContactDetailSectionKind.identity,
      title: 'Identity / system prompt',
      lines: identityLines,
    ),
    ProfileContactDetailSectionPresentation(
      kind: ProfileContactDetailSectionKind.channels,
      title: 'Connected channels',
      lines: channelLines,
    ),
    ProfileContactDetailSectionPresentation(
      kind: ProfileContactDetailSectionKind.memory,
      title: 'Memory settings',
      lines: memoryLines,
    ),
    ProfileContactDetailSectionPresentation(
      kind: ProfileContactDetailSectionKind.skills,
      title: 'Skills list',
      lines: skillsLines,
    ),
    ProfileContactDetailSectionPresentation(
      kind: ProfileContactDetailSectionKind.config,
      title: 'Config/environment summary',
      lines: configLines,
    ),
    ProfileContactDetailSectionPresentation(
      kind: ProfileContactDetailSectionKind.logs,
      title: 'Logs/status',
      lines: logStatusLines,
    ),
  ];

  List<ProfileContactDetailActionPresentation> get detailActions => const [
    ProfileContactDetailActionPresentation(
      kind: ProfileContactDetailActionKind.openChat,
      title: 'Open chat',
      subtitle: 'Use this profile for the next turn.',
    ),
    ProfileContactDetailActionPresentation(
      kind: ProfileContactDetailActionKind.openMemory,
      title: 'Open memory',
      subtitle: 'Inspect memory scoped to this profile.',
    ),
    ProfileContactDetailActionPresentation(
      kind: ProfileContactDetailActionKind.editProfile,
      title: 'Edit profile',
      subtitle: 'Open profile-scoped config editor.',
    ),
  ];

  List<String> get agentFallbackSummaryLines {
    final lines = [
      contact.profileId,
      'Status: $healthLabel',
      'Channels: $channelsLabel',
      'Memory: $memoryLabel',
      'Skills: profile skills pending API',
      'Config: profile scoped',
    ];
    final latestPreview = contact.latestPreview.trim();
    if (latestPreview.isNotEmpty) lines.add('Latest: $latestPreview');
    return lines;
  }

  String get _avatarLabel =>
      profileContactIdentityLabel(contact, fallback: 'profile');

  List<String> get searchTerms => [
    contact.displayName,
    contact.profileId,
    contact.serverId,
    contact.serverLabel,
    contact.latestPreview,
    healthLabel,
    compactHealthLabel,
    workspaceLabel,
    voiceLabel,
    latestLabel,
    chatListPreviewLabel,
    contact.activeTurnState,
    ...contact.attentionBadges,
  ];
}

class ProfileContactsScreenPresentation {
  const ProfileContactsScreenPresentation();

  String get title => 'Navivox';

  String get searchHint => 'Search Profiles';

  String get searchTooltip => 'Search profiles';

  String get closeSearchTooltip => 'Close search';

  String get manageGatewaysTooltip => 'Manage gateways';

  String get profileListMenuTooltip => 'Open profile list menu';

  String get noProfilesMessage => 'No profiles loaded';

  String get noVisibleChatsMessage => 'No chats found';

  String get addProfileTooltip => 'Add profile';

  String get allServersLabel => 'All';

  List<ProfileContactsMenuRowPresentation> get menuRows => const [
    ProfileContactsMenuRowPresentation(
      kind: ProfileContactsMenuActionKind.manageGateways,
      title: 'Manage gateways',
    ),
    ProfileContactsMenuRowPresentation(
      kind: ProfileContactsMenuActionKind.manageProfiles,
      title: 'Manage profiles',
    ),
    ProfileContactsMenuRowPresentation(
      kind: ProfileContactsMenuActionKind.openMemory,
      title: 'Memory',
    ),
    ProfileContactsMenuRowPresentation(
      kind: ProfileContactsMenuActionKind.openConfig,
      title: 'Config',
    ),
    ProfileContactsMenuRowPresentation(
      kind: ProfileContactsMenuActionKind.openSettings,
      title: 'Settings',
    ),
  ];

  List<ProfileContactsAddRowPresentation> get addProfileRows => const [
    ProfileContactsAddRowPresentation(
      kind: ProfileContactsAddRowKind.newProfile,
      title: 'New profile',
      subtitle: 'Server-validated profile creation is next.',
    ),
    ProfileContactsAddRowPresentation(
      kind: ProfileContactsAddRowKind.addServer,
      title: 'Add server',
      subtitle: 'Import connect-info from Gormes.',
    ),
  ];
}

enum ProfileContactsMenuActionKind {
  manageGateways,
  manageProfiles,
  openMemory,
  openConfig,
  openSettings,
}

class ProfileContactsMenuRowPresentation {
  const ProfileContactsMenuRowPresentation({
    required this.kind,
    required this.title,
  });

  final ProfileContactsMenuActionKind kind;
  final String title;
}

enum ProfileContactsAddRowKind { newProfile, addServer }

class ProfileContactsAddRowPresentation {
  const ProfileContactsAddRowPresentation({
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  final ProfileContactsAddRowKind kind;
  final String title;
  final String subtitle;
}

enum ProfileContactDetailSectionKind {
  identity,
  channels,
  memory,
  skills,
  config,
  logs,
}

class ProfileContactDetailSectionPresentation {
  const ProfileContactDetailSectionPresentation({
    required this.kind,
    required this.title,
    required this.lines,
  });

  final ProfileContactDetailSectionKind kind;
  final String title;
  final List<String> lines;
}

enum ProfileContactDetailActionKind { openChat, openMemory, editProfile }

class ProfileContactDetailActionPresentation {
  const ProfileContactDetailActionPresentation({
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  final ProfileContactDetailActionKind kind;
  final String title;
  final String subtitle;
}
