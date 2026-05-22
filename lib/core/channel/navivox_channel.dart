import 'package:flutter/foundation.dart';

import '../protocol/navivox_event.dart';
import '../protocol/navivox_memory.dart';
import '../protocol/navivox_voice_run.dart';

/// A pending approval request issued by the server while a tool call is mid-
/// flight. The user resolves it via [NavivoxChannel.respondToApproval].
class NavivoxApprovalRequest {
  const NavivoxApprovalRequest({
    required this.id,
    required this.toolCallId,
    required this.prompt,
    this.risk,
  });

  final String id;
  final String toolCallId;
  final String prompt;
  final String? risk;
}

class NavivoxServer {
  const NavivoxServer({
    required this.id,
    required this.name,
    required this.status,
  });

  final String id;
  final String name;
  final String status;
}

class NavivoxAgent {
  const NavivoxAgent({
    required this.id,
    required this.name,
    required this.status,
  });

  final String id;
  final String name;
  final String status;
}

enum NavivoxProfileHealth { online, offline, needsAuth, warning }

class NavivoxVoiceCapability {
  const NavivoxVoiceCapability({
    this.deviceStt = 'unavailable',
    this.serverStt = 'unavailable',
    this.serverTts = 'unavailable',
    this.disabledReason = '',
    this.recoveryAction = '',
    this.isReported = false,
  });

  final String deviceStt;
  final String serverStt;
  final String serverTts;
  final String disabledReason;
  final String recoveryAction;
  final bool isReported;

  bool get enabled => disabledReason.trim().isEmpty && !blocksDeviceCapture;

  bool get blocksDeviceCapture =>
      deviceStt.trim().toLowerCase() == 'unavailable' &&
      (isReported || recoveryAction.trim().isNotEmpty);
}

class NavivoxProfileContact {
  const NavivoxProfileContact({
    required this.serverId,
    required this.profileId,
    required this.displayName,
    required this.serverLabel,
    required this.health,
    required this.latestPreview,
    this.latestPreviewKind = 'status',
    this.latestAt,
    this.workspaceRootCount = 0,
    this.workspaceRootsOk = true,
    this.workspaceRootsWarning = 0,
    this.workspaceRootsError = 0,
    this.attentionBadges = const [],
    this.micAvailable = false,
    this.voiceCapability = const NavivoxVoiceCapability(),
    this.activeTurnState = 'idle',
    String? avatarSeed,
  }) : avatarSeed = avatarSeed ?? '$serverId:$profileId';

  final String serverId;
  final String profileId;
  final String displayName;
  final String serverLabel;
  final NavivoxProfileHealth health;
  final String latestPreview;
  final String latestPreviewKind;
  final DateTime? latestAt;
  final int workspaceRootCount;
  final bool workspaceRootsOk;
  final int workspaceRootsWarning;
  final int workspaceRootsError;
  final List<String> attentionBadges;
  final bool micAvailable;
  final NavivoxVoiceCapability voiceCapability;
  final String activeTurnState;
  final String avatarSeed;

  String get key => '$serverId::$profileId';
}

class NavivoxChannelState {
  const NavivoxChannelState({
    this.servers = const [],
    this.activeServerId,
    this.messages = const {},
    this.voiceRuns = const {},
    this.activeVoiceRunId,
    this.agents = const [],
    this.selectedAgentId,
    this.profileContacts = const [],
    this.selectedProfileContactKey,
    this.configSchema,
    this.configValues = const {},
    this.configDiff,
  });

  final List<NavivoxServer> servers;
  final String? activeServerId;
  final Map<String, NavivoxChatMessage> messages;
  final Map<String, NavivoxVoiceRun> voiceRuns;
  final String? activeVoiceRunId;
  final List<NavivoxAgent> agents;
  final String? selectedAgentId;
  final List<NavivoxProfileContact> profileContacts;
  final String? selectedProfileContactKey;
  final Map<String, Object?>? configSchema;
  final Map<String, Object?> configValues;
  final Map<String, Object?>? configDiff;

  List<NavivoxChatMessage> get messagesList => messages.values.toList();
  List<NavivoxVoiceRun> get voiceRunsList => voiceRuns.values.toList();
  NavivoxVoiceRun? get activeVoiceRun {
    final explicitId = activeVoiceRunId;
    if (explicitId != null) return voiceRuns[explicitId];
    if (voiceRuns.isEmpty) return null;
    return voiceRuns.values.last;
  }

  bool get hasServers => servers.isNotEmpty;
  NavivoxServer? get activeServer =>
      servers.where((server) => server.id == activeServerId).firstOrNull;
  NavivoxProfileContact? get activeProfileContact => profileContacts
      .where((contact) => contact.key == selectedProfileContactKey)
      .firstOrNull;

  NavivoxChannelState copyWith({
    List<NavivoxServer>? servers,
    String? activeServerId,
    Map<String, NavivoxChatMessage>? messages,
    Map<String, NavivoxVoiceRun>? voiceRuns,
    String? activeVoiceRunId,
    List<NavivoxAgent>? agents,
    String? selectedAgentId,
    List<NavivoxProfileContact>? profileContacts,
    String? selectedProfileContactKey,
    Map<String, Object?>? configSchema,
    Map<String, Object?>? configValues,
    Map<String, Object?>? configDiff,
  }) {
    return NavivoxChannelState(
      servers: servers ?? this.servers,
      activeServerId: activeServerId ?? this.activeServerId,
      messages: messages ?? this.messages,
      voiceRuns: voiceRuns ?? this.voiceRuns,
      activeVoiceRunId: activeVoiceRunId ?? this.activeVoiceRunId,
      agents: agents ?? this.agents,
      selectedAgentId: selectedAgentId ?? this.selectedAgentId,
      profileContacts: profileContacts ?? this.profileContacts,
      selectedProfileContactKey:
          selectedProfileContactKey ?? this.selectedProfileContactKey,
      configSchema: configSchema ?? this.configSchema,
      configValues: configValues ?? this.configValues,
      configDiff: configDiff ?? this.configDiff,
    );
  }
}

abstract interface class NavivoxChannel implements Listenable {
  NavivoxChannelState get state;
  Stream<NavivoxApprovalRequest> get approvalRequests;
  Future<void> connect({required String baseUrl, String? token});
  Future<void> disconnect();
  void sendText(String text);
  void sendVoice({required String transcript});
  String startVoiceRun();
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
    NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
  });
  void cancelVoiceRun(String voiceRunId, {String reason});
  void failVoiceRun(String voiceRunId, {required String reason});
  void submitVoiceRun(String voiceRunId);
  void cancelActiveTurn();
  void stopActiveTurn();
  void respondToApproval({required String approvalId, required bool approved});
  void requestAgentList();
  Future<NavivoxMemoryOverview> memoryOverview({
    String? serverId,
    String? profileId,
  });
  Future<NavivoxMemorySearchResult> memorySearch({
    String? serverId,
    String? profileId,
    String query,
    NavivoxMemoryType type,
    int limit,
    String? pageToken,
  });
  Future<NavivoxMemoryDetail> memoryDetail({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
  });
  Future<NavivoxMemoryActionResult> memoryAction({
    String? serverId,
    String? profileId,
    required String id,
    required NavivoxMemoryType type,
    required NavivoxMemoryActionType action,
    String? correction,
  });
  void selectAgent(String agentId);
  void selectProfileContact({
    required String serverId,
    required String profileId,
  });
  void sendConfigSet({required String field, required Object? value});
  void sendConfigSecretSet({required String name, required String secret});
}
