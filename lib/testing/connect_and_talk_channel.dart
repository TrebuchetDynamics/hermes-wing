import '../core/channel/gateway_navivox_channel.dart';
import '../core/channel/navivox_channel.dart';
import '../core/protocol/navivox_event.dart';
import '../core/protocol/navivox_profile_contact_key.dart';
import '../core/protocol/navivox_voice_run.dart';

class ConnectAndTalkChannel extends GatewayNavivoxChannel {
  NavivoxChannelState _state = const NavivoxChannelState();
  String? connectedBaseUrl;
  String? connectedToken;
  String? connectedWebSocketUrl;
  final List<String> sentTexts = [];
  final List<String> sentVoiceTranscripts = [];
  int _voiceRunCounter = 0;

  @override
  NavivoxChannelState get state => _state;

  @override
  Future<void> connect({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
  }) async {
    connectedBaseUrl = baseUrl;
    connectedToken = token;
    connectedWebSocketUrl = webSocketUrl;
    const server = NavivoxServer(
      id: 'navivox-gateway',
      name: 'Gormes Gateway',
      status: 'Gateway online - 127.0.0.1:8765',
    );
    const profile = NavivoxProfileContact(
      serverId: 'navivox-gateway',
      profileId: 'default',
      displayName: 'Default profile',
      serverLabel: 'Gormes Gateway',
      health: NavivoxProfileHealth.online,
      latestPreview: 'Gateway online',
      micAvailable: true,
    );
    _state = _state.copyWith(
      servers: [server],
      activeServerId: server.id,
      profileContacts: [profile],
      selectedProfileContactKey: profile.key,
    );
    notifyListeners();
  }

  @override
  void sendText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    sentTexts.add(trimmed);
    final now = DateTime(2026, 5, 16, 9, 41);
    final active = _state.activeProfileContact;
    final messages = Map<String, NavivoxChatMessage>.from(_state.messages);
    messages['user-${sentTexts.length}'] = NavivoxChatMessage(
      id: 'user-${sentTexts.length}',
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.text,
      createdAt: now,
      text: trimmed,
      serverId: active?.serverId,
      profileId: active?.profileId,
    );
    messages['assistant-${sentTexts.length}'] = NavivoxChatMessage(
      id: 'assistant-${sentTexts.length}',
      author: NavivoxMessageAuthor.assistant,
      kind: NavivoxMessageKind.text,
      createdAt: now,
      text: 'hello from gateway',
      serverId: active?.serverId,
      profileId: active?.profileId,
    );
    _state = _state.copyWith(messages: messages);
    notifyListeners();
  }

  @override
  void selectProfileContact({
    required String serverId,
    required String profileId,
  }) {
    _state = _state.copyWith(
      activeServerId: serverId,
      selectedProfileContactKey: navivoxProfileContactKey(
        serverId: serverId,
        profileId: profileId,
      ),
    );
    notifyListeners();
  }

  @override
  void sendVoice({required String transcript}) {
    sendText(transcript);
  }

  @override
  String startVoiceRun() {
    final active = _state.activeProfileContact;
    final id = 'voice-${++_voiceRunCounter}';
    final run = NavivoxVoiceRun.recording(
      id: id,
      serverId: active?.serverId ?? 'navivox-gateway',
      profileId: active?.profileId ?? 'default',
      createdAt: DateTime(2026, 5, 16, 9, 41),
    );
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns)..[id] = run;
    _state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: id);
    notifyListeners();
    return id;
  }

  @override
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
    NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
  }) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.copyWith(
      status: NavivoxVoiceRunStatus.pendingSend,
      transcript: transcript,
      duration: duration,
      confidence: confidence,
      transcriptSource: transcriptSource,
      updatedAt: DateTime(2026, 5, 16, 9, 42),
    );
    _state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
    notifyListeners();
  }

  @override
  void cancelVoiceRun(
    String voiceRunId, {
    String reason = 'cancelled before send',
  }) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns)
      ..[voiceRunId] = run.markCancelled(reason);
    _state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
    notifyListeners();
  }

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns)
      ..[voiceRunId] = run.markFailed(reason);
    _state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
    notifyListeners();
  }

  @override
  void submitVoiceRun(String voiceRunId) {
    final run = _state.voiceRuns[voiceRunId];
    final transcript = run?.transcript?.trim() ?? '';
    if (run == null || transcript.isEmpty) return;
    sentVoiceTranscripts.add(transcript);
    final now = DateTime(2026, 5, 16, 9, 41);
    final active = _state.activeProfileContact;
    final n = sentVoiceTranscripts.length;
    final messages = Map<String, NavivoxChatMessage>.from(_state.messages);
    messages['voice-user-$n'] = NavivoxChatMessage(
      id: 'voice-user-$n',
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.voice,
      createdAt: now,
      text: transcript,
      serverId: active?.serverId,
      profileId: active?.profileId,
      voice: NavivoxVoiceMessage(
        voiceRunId: voiceRunId,
        duration: run.duration ?? Duration.zero,
        transcript: transcript,
        confidence: run.confidence ?? 1,
        status: NavivoxVoiceRunStatus.submitted,
      ),
    );
    messages['voice-assistant-$n'] = NavivoxChatMessage(
      id: 'voice-assistant-$n',
      author: NavivoxMessageAuthor.assistant,
      kind: NavivoxMessageKind.text,
      createdAt: now,
      text: 'voice reply from gateway',
      serverId: active?.serverId,
      profileId: active?.profileId,
    );
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.markSubmitted(requestId: 'voice-request-$voiceRunId');
    _state = _state.copyWith(
      messages: messages,
      voiceRuns: runs,
      activeVoiceRunId: voiceRunId,
    );
    notifyListeners();
  }

  @override
  void cancelActiveTurn() {}

  @override
  void stopActiveTurn() {}
}

class FailingConnectChannel extends GatewayNavivoxChannel {
  @override
  Future<void> connect({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
  }) async {
    throw StateError('connection failed for $token');
  }
}
