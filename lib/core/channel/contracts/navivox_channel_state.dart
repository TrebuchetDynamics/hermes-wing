import '../../gateway/navivox_gateway_protocol.dart';
import '../../protocol/navivox_event.dart';
import '../../protocol/navivox_voice_run.dart';
import '../../session/readiness/reconnect_readiness.dart';
import 'navivox_gateway_summary.dart';
import 'navivox_profile_contact.dart';

class NavivoxChannelState {
  const NavivoxChannelState({
    this.servers = const [],
    this.activeServerId,
    this.messages = const {},
    this.voiceRuns = const {},
    this.activeVoiceRunId,
    this.runRecordInspectionAvailable = false,
    this.agents = const [],
    this.selectedAgentId,
    this.profileContacts = const [],
    this.selectedProfileContactKey,
    this.profileRouting = const NavivoxProfileRoutingReport(),
    this.profileRoutingSelections =
        const <String, NavivoxProfileRoutingSelection>{},
    this.configSchema,
    this.configValues = const {},
    this.configDiff,
    this.reconnectReadiness = ReconnectReadiness.unknown,
  });

  final List<NavivoxServer> servers;
  final String? activeServerId;
  final Map<String, NavivoxChatMessage> messages;
  final Map<String, NavivoxVoiceRun> voiceRuns;
  final String? activeVoiceRunId;
  final bool runRecordInspectionAvailable;
  final List<NavivoxAgent> agents;
  final String? selectedAgentId;
  final List<NavivoxProfileContact> profileContacts;
  final String? selectedProfileContactKey;
  final NavivoxProfileRoutingReport profileRouting;
  final Map<String, NavivoxProfileRoutingSelection> profileRoutingSelections;
  final Map<String, Object?>? configSchema;
  final Map<String, Object?> configValues;
  final Map<String, Object?>? configDiff;

  /// Operator-visible durable-reconnect readiness for the active gateway,
  /// derived from the gateway capability document on connect.
  final ReconnectReadiness reconnectReadiness;

  List<NavivoxChatMessage> get messagesList => messages.values.toList();
  List<NavivoxVoiceRun> get voiceRunsList => voiceRuns.values.toList();

  /// The run currently in flight, or null when nothing is being captured,
  /// staged, submitted, or awaited. A terminal (completed/cancelled/failed)
  /// run is never "active" — this guards on [NavivoxVoiceRun.isTerminal]
  /// directly so it stays honest for every channel, even ones that do not
  /// clear [activeVoiceRunId] on terminal transitions.
  NavivoxVoiceRun? get activeVoiceRun {
    final id = activeVoiceRunId;
    if (id == null) return null;
    final run = voiceRuns[id];
    if (run == null || run.isTerminal) return null;
    return run;
  }

  /// The most recent run regardless of status, for history and run-record
  /// evidence. Prefers the tracked [activeVoiceRunId], else the last-inserted
  /// run.
  NavivoxVoiceRun? get latestVoiceRun {
    final id = activeVoiceRunId;
    if (id != null) {
      final run = voiceRuns[id];
      if (run != null) return run;
    }
    if (voiceRuns.isEmpty) return null;
    return voiceRuns.values.last;
  }

  bool get hasServers => servers.isNotEmpty;
  NavivoxServer? get activeServer =>
      servers.where((server) => server.id == activeServerId).firstOrNull;
  NavivoxProfileContact? get activeProfileContact => profileContacts
      .where((contact) => contact.key == selectedProfileContactKey)
      .firstOrNull;
  NavivoxProfileRoute? get activeProfileRoute {
    final profileId = activeProfileContact?.profileId;
    if (profileId == null) return null;
    return profileRouting.profiles
        .where((route) => route.profileId == profileId)
        .firstOrNull;
  }

  NavivoxProfileRoutingSelection? get activeProfileRoutingSelection =>
      profileRoutingSelectionFor(activeProfileContact);

  /// Resolves the effective routing selection for any profile contact, not just
  /// the active one. Voice turns may submit to a profile the operator has since
  /// switched away from, so they need the run profile's routing rather than the
  /// active profile's.
  NavivoxProfileRoutingSelection? profileRoutingSelectionFor(
    NavivoxProfileContact? contact,
  ) {
    if (contact == null) return null;
    final route = profileRouting.profiles
        .where((route) => route.profileId == contact.profileId)
        .firstOrNull;
    if (route == null) return null;
    final selected = profileRoutingSelections[contact.key];
    return NavivoxProfileRoutingSelection(
      workspace: _routingChoice(route.workspaces, selected?.workspace),
      provider: _routingChoice(route.providers, selected?.provider),
      channel: _routingChoice(route.channels, selected?.channel),
    );
  }

  NavivoxChannelState withActiveProfileRouting({
    String? workspace,
    String? provider,
    String? channel,
  }) {
    final contact = activeProfileContact;
    if (contact == null) return this;
    final selections = Map<String, NavivoxProfileRoutingSelection>.from(
      profileRoutingSelections,
    );
    selections[contact.key] = NavivoxProfileRoutingSelection(
      workspace: workspace,
      provider: provider,
      channel: channel,
    );
    return copyWith(profileRoutingSelections: selections);
  }

  NavivoxChannelState copyWith({
    List<NavivoxServer>? servers,
    String? activeServerId,
    bool clearActiveServerId = false,
    Map<String, NavivoxChatMessage>? messages,
    Map<String, NavivoxVoiceRun>? voiceRuns,
    String? activeVoiceRunId,
    bool clearActiveVoiceRunId = false,
    bool? runRecordInspectionAvailable,
    List<NavivoxAgent>? agents,
    String? selectedAgentId,
    bool clearSelectedAgentId = false,
    List<NavivoxProfileContact>? profileContacts,
    String? selectedProfileContactKey,
    bool clearSelectedProfileContactKey = false,
    NavivoxProfileRoutingReport? profileRouting,
    Map<String, NavivoxProfileRoutingSelection>? profileRoutingSelections,
    Map<String, Object?>? configSchema,
    bool clearConfigSchema = false,
    Map<String, Object?>? configValues,
    Map<String, Object?>? configDiff,
    bool clearConfigDiff = false,
    ReconnectReadiness? reconnectReadiness,
  }) {
    assert(
      !clearActiveServerId || activeServerId == null,
      'copyWith cannot set and clear activeServerId at the same time.',
    );
    assert(
      !clearActiveVoiceRunId || activeVoiceRunId == null,
      'copyWith cannot set and clear activeVoiceRunId at the same time.',
    );
    assert(
      !clearSelectedAgentId || selectedAgentId == null,
      'copyWith cannot set and clear selectedAgentId at the same time.',
    );
    assert(
      !clearSelectedProfileContactKey || selectedProfileContactKey == null,
      'copyWith cannot set and clear selectedProfileContactKey at the same time.',
    );
    assert(
      !clearConfigSchema || configSchema == null,
      'copyWith cannot set and clear configSchema at the same time.',
    );
    assert(
      !clearConfigDiff || configDiff == null,
      'copyWith cannot set and clear configDiff at the same time.',
    );
    return NavivoxChannelState(
      servers: servers ?? this.servers,
      activeServerId: clearActiveServerId
          ? null
          : activeServerId ?? this.activeServerId,
      messages: messages ?? this.messages,
      voiceRuns: voiceRuns ?? this.voiceRuns,
      activeVoiceRunId: clearActiveVoiceRunId
          ? null
          : activeVoiceRunId ?? this.activeVoiceRunId,
      runRecordInspectionAvailable:
          runRecordInspectionAvailable ?? this.runRecordInspectionAvailable,
      agents: agents ?? this.agents,
      selectedAgentId: clearSelectedAgentId
          ? null
          : selectedAgentId ?? this.selectedAgentId,
      profileContacts: profileContacts ?? this.profileContacts,
      selectedProfileContactKey: clearSelectedProfileContactKey
          ? null
          : selectedProfileContactKey ?? this.selectedProfileContactKey,
      profileRouting: profileRouting ?? this.profileRouting,
      profileRoutingSelections:
          profileRoutingSelections ?? this.profileRoutingSelections,
      configSchema: clearConfigSchema
          ? null
          : configSchema ?? this.configSchema,
      configValues: configValues ?? this.configValues,
      configDiff: clearConfigDiff ? null : configDiff ?? this.configDiff,
      reconnectReadiness: reconnectReadiness ?? this.reconnectReadiness,
    );
  }
}

String? _routingChoice(List<String> allowed, String? selected) {
  final candidate = selected?.trim();
  if (candidate != null &&
      candidate.isNotEmpty &&
      allowed.contains(candidate)) {
    return candidate;
  }
  return allowed.firstOrNull;
}
