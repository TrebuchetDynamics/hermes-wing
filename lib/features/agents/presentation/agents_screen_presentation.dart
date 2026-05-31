import '../../../core/channel/navivox_channel.dart';
import '../../profile_contacts/profile_contact_list_presentation.dart';

class AgentsScreenPresentation {
  const AgentsScreenPresentation({
    required this.agents,
    required this.selectedAgentId,
    required this.profileContacts,
    required this.selectedProfileContactKey,
    required this.profileServerLabel,
  });

  factory AgentsScreenPresentation.fromState(NavivoxChannelState state) {
    final profileList = ProfileContactListPresentation.fromContacts(
      servers: state.servers,
      contacts: state.profileContacts,
      selectedServerId: state.activeServerId,
    );
    final profileContacts = profileList.visibleContacts;

    return AgentsScreenPresentation(
      agents: List.unmodifiable(state.agents),
      selectedAgentId: state.selectedAgentId,
      profileContacts: profileContacts,
      selectedProfileContactKey: state.selectedProfileContactKey,
      profileServerLabel: _profileServerLabel(state, profileContacts),
    );
  }

  final List<NavivoxAgent> agents;
  final String? selectedAgentId;
  final List<NavivoxProfileContact> profileContacts;
  final String? selectedProfileContactKey;
  final String profileServerLabel;

  String get screenTitle => 'Agents';

  String get refreshProfilesTooltip => 'Refresh profiles';

  String get profileFallbackTitle => 'Profiles on $profileServerLabel';

  String get profileFallbackSubtitle =>
      'Loaded from Gormes profile contacts. Select one profile to scope chat, memory, and config.';

  String get emptyProfilesTitle => 'No profiles found on this server';

  String get emptyProfilesSubtitle =>
      'Connect to a Gormes server, refresh profiles, or draft a new profile from a seed.';

  String get refreshProfilesLabel => 'Refresh profiles';

  String get createImportProfileLabel => 'Add profile';

  String get createImportProfileSheetTitle => 'Add a profile';

  String get createImportProfileSheetSubtitle =>
      'Create from a natural-language seed through Gormes, or add another gateway that already has profiles.';

  String get createFromSeedTitle => 'Create from seed';

  String get createFromSeedSubtitle =>
      'Ask Gormes to draft a profile from natural language.';

  String get addGatewayTitle => 'Add gateway';

  String get addGatewaySubtitle =>
      'Register another Gormes gateway and refresh its profile contacts.';

  bool get showAgentList => agents.isNotEmpty;
  bool get showProfileFallback => !showAgentList && profileContacts.isNotEmpty;
  bool get showEmptyProfileState => !showAgentList && profileContacts.isEmpty;

  static String _profileServerLabel(
    NavivoxChannelState state,
    List<NavivoxProfileContact> profileContacts,
  ) {
    final activeServer = state.activeServer;
    if (activeServer != null) return activeServer.name;
    if (profileContacts.isNotEmpty) return profileContacts.first.serverLabel;
    return 'selected server';
  }
}
