import 'package:navivox/core/channel/navivox_channel.dart';

/// Shared gateway + Profile contact fixtures used by feature tests.
const localGormesServer = NavivoxServer(
  id: 'local',
  name: 'Local Gormes',
  status: 'online',
);

const officeServer = NavivoxServer(
  id: 'office',
  name: 'Office',
  status: 'offline',
);

const officeGatewayServer = NavivoxServer(
  id: 'office',
  name: 'Office Gateway',
  status: 'offline',
);

const remoteGormesServer = NavivoxServer(
  id: 'remote',
  name: 'Remote Gormes',
  status: 'offline',
);

NavivoxProfileContact mineruBuilderProfile({
  String serverId = 'local',
  String serverLabel = 'local',
  NavivoxProfileHealth health = NavivoxProfileHealth.online,
  String latestPreview = 'Ready to work on mineru',
  DateTime? latestAt,
  int workspaceRootCount = 2,
  bool workspaceRootsOk = true,
  int workspaceRootsWarning = 0,
  int workspaceRootsError = 0,
  bool micAvailable = true,
  String activeTurnState = 'idle',
}) {
  return NavivoxProfileContact(
    serverId: serverId,
    profileId: 'mineru',
    displayName: 'Mineru Builder',
    serverLabel: serverLabel,
    health: health,
    latestPreview: latestPreview,
    latestAt: latestAt,
    workspaceRootCount: workspaceRootCount,
    workspaceRootsOk: workspaceRootsOk,
    workspaceRootsWarning: workspaceRootsWarning,
    workspaceRootsError: workspaceRootsError,
    micAvailable: micAvailable,
    activeTurnState: activeTurnState,
  );
}

NavivoxProfileContact supportTriageProfile({
  String serverId = 'office',
  String serverLabel = 'office',
  NavivoxProfileHealth health = NavivoxProfileHealth.needsAuth,
  String latestPreview = 'Waiting for token',
  DateTime? latestAt,
  int workspaceRootCount = 1,
  bool micAvailable = false,
}) {
  return NavivoxProfileContact(
    serverId: serverId,
    profileId: 'support',
    displayName: 'Support Triage',
    serverLabel: serverLabel,
    health: health,
    latestPreview: latestPreview,
    latestAt: latestAt,
    workspaceRootCount: workspaceRootCount,
    attentionBadges: const ['auth'],
    micAvailable: micAvailable,
  );
}

NavivoxProfileContact personalProfile({
  String serverId = 'local',
  String serverLabel = 'local',
  NavivoxProfileHealth health = NavivoxProfileHealth.offline,
  String latestPreview = 'Gateway unavailable',
  DateTime? latestAt,
  int workspaceRootCount = 0,
  bool workspaceRootsOk = true,
  bool micAvailable = false,
}) {
  return NavivoxProfileContact(
    serverId: serverId,
    profileId: 'personal',
    displayName: 'Personal',
    serverLabel: serverLabel,
    health: health,
    latestPreview: latestPreview,
    latestAt: latestAt,
    workspaceRootCount: workspaceRootCount,
    workspaceRootsOk: workspaceRootsOk,
    attentionBadges: const ['offline'],
    micAvailable: micAvailable,
  );
}

NavivoxProfileContact linkReviewerProfile() {
  return const NavivoxProfileContact(
    serverId: 'local',
    profileId: 'link',
    displayName: 'Link Reviewer',
    serverLabel: 'local',
    health: NavivoxProfileHealth.warning,
    latestPreview: 'Reviewing',
  );
}

NavivoxProfileContact sidonPlannerProfile() {
  return const NavivoxProfileContact(
    serverId: 'remote',
    profileId: 'sidon',
    displayName: 'Sidon Planner',
    serverLabel: 'remote',
    health: NavivoxProfileHealth.offline,
    latestPreview: 'Away',
  );
}

List<NavivoxServer> localOfficeServers({NavivoxServer office = officeServer}) {
  return [localGormesServer, office];
}

List<NavivoxProfileContact> sortedProfileListContacts() {
  return [
    supportTriageProfile(latestAt: DateTime(2026, 5, 16, 9, 22)),
    mineruBuilderProfile(latestAt: DateTime(2026, 5, 16, 9, 41)),
    personalProfile(latestAt: DateTime(2026, 5, 15, 18)),
  ];
}
