import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';

class TestNavivoxChannel extends ChangeNotifier implements NavivoxChannel {
  TestNavivoxChannel({
    NavivoxChannelState initial = const NavivoxChannelState(),
  }) : _state = initial;

  NavivoxChannelState _state;
  final StreamController<NavivoxApprovalRequest> _approvals =
      StreamController<NavivoxApprovalRequest>.broadcast();
  int _messageCounter = 0;

  final List<String> sentTexts = [];
  final List<({String text, String? serverId, String? profileId})>
  sentTextCalls = [];
  final List<String> sentVoiceTranscripts = [];
  int cancelRequests = 0;
  int stopRequests = 0;
  final List<({String approvalId, bool approved})> approvalResponses = [];
  final List<({String field, Object? value})> configSetCalls = [];
  final List<({String name, String secret})> configSecretSetCalls = [];
  String? lastSelectedAgentId;
  ({String serverId, String profileId})? selectedProfileScope;
  int agentListRequests = 0;

  @override
  NavivoxChannelState get state => _state;

  set state(NavivoxChannelState next) {
    _state = next;
    notifyListeners();
  }

  void seedAgents(List<NavivoxAgent> agents, {String? selectedAgentId}) {
    state = _state.copyWith(
      agents: agents,
      selectedAgentId: selectedAgentId ?? _state.selectedAgentId,
    );
  }

  void seedServers(List<NavivoxServer> servers, {String? activeServerId}) {
    state = _state.copyWith(
      servers: servers,
      activeServerId: activeServerId ?? _state.activeServerId,
    );
  }

  void seedProfileContacts(
    List<NavivoxProfileContact> contacts, {
    String? selectedKey,
  }) {
    state = _state.copyWith(
      profileContacts: contacts,
      selectedProfileContactKey:
          selectedKey ?? _state.selectedProfileContactKey,
    );
  }

  void seedMessages(List<NavivoxChatMessage> messages) {
    final map = <String, NavivoxChatMessage>{};
    for (final m in messages) {
      map[m.id] = m;
    }
    state = _state.copyWith(messages: map);
  }

  void emitApprovalRequest(NavivoxApprovalRequest request) {
    _approvals.add(request);
  }

  void emitConfigSchema(Map<String, Object?> schema) {
    state = _state.copyWith(configSchema: schema);
  }

  void emitConfigValues(Map<String, Object?> values) {
    state = _state.copyWith(configValues: values);
  }

  void emitConfigDiff(Map<String, Object?> diff) {
    state = _state.copyWith(configDiff: diff);
  }

  @override
  Stream<NavivoxApprovalRequest> get approvalRequests => _approvals.stream;

  @override
  Future<void> connect({required String baseUrl, String? token}) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void sendText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    sentTexts.add(trimmed);
    final active = _state.activeProfileContact;
    sentTextCalls.add((
      text: trimmed,
      serverId: active?.serverId,
      profileId: active?.profileId,
    ));
    final messages = Map<String, NavivoxChatMessage>.from(_state.messages);
    messages['test-user-${++_messageCounter}'] = NavivoxChatMessage(
      id: 'test-user-$_messageCounter',
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.text,
      createdAt: DateTime.utc(2026, 5, 16, 12, 0, _messageCounter),
      text: trimmed,
    );
    state = _state.copyWith(messages: messages);
  }

  @override
  void sendVoice({required String transcript}) {
    sentVoiceTranscripts.add(transcript);
  }

  @override
  String startVoiceRun() {
    final active = _state.activeProfileContact;
    final id = 'test-voice-${++_messageCounter}';
    final run = NavivoxVoiceRun.recording(
      id: id,
      serverId: active?.serverId ?? 'navivox-gateway',
      profileId: active?.profileId ?? 'default',
      createdAt: DateTime.utc(2026, 5, 16, 12, 0, _messageCounter),
    );
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[id] = run;
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: id);
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
      transcriptSource: transcriptSource,
      transcript: transcript,
      duration: duration,
      confidence: confidence,
      updatedAt: DateTime.utc(2026, 5, 16, 12, 1),
    );
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
  }

  @override
  void cancelVoiceRun(
    String voiceRunId, {
    String reason = 'cancelled before send',
  }) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.markCancelled(reason);
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
  }

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null) return;
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.markFailed(reason);
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
  }

  @override
  void submitVoiceRun(String voiceRunId) {
    final run = _state.voiceRuns[voiceRunId];
    final transcript = run?.transcript?.trim() ?? '';
    if (run == null || transcript.isEmpty) return;
    sentVoiceTranscripts.add(transcript);
    final runs = Map<String, NavivoxVoiceRun>.from(_state.voiceRuns);
    runs[voiceRunId] = run.markSubmitted(requestId: 'test-request-$voiceRunId');
    state = _state.copyWith(voiceRuns: runs, activeVoiceRunId: voiceRunId);
  }

  @override
  void cancelActiveTurn() {
    cancelRequests += 1;
  }

  @override
  void stopActiveTurn() {
    stopRequests += 1;
  }

  @override
  void respondToApproval({required String approvalId, required bool approved}) {
    approvalResponses.add((approvalId: approvalId, approved: approved));
  }

  @override
  void requestAgentList() => agentListRequests += 1;

  @override
  void selectAgent(String agentId) {
    lastSelectedAgentId = agentId;
    state = _state.copyWith(selectedAgentId: agentId);
  }

  @override
  void selectProfileContact({
    required String serverId,
    required String profileId,
  }) {
    selectedProfileScope = (serverId: serverId, profileId: profileId);
    state = _state.copyWith(
      activeServerId: serverId,
      selectedProfileContactKey: '$serverId::$profileId',
    );
  }

  @override
  void sendConfigSet({required String field, required Object? value}) {
    configSetCalls.add((field: field, value: value));
  }

  @override
  void sendConfigSecretSet({required String name, required String secret}) {
    configSecretSetCalls.add((name: name, secret: secret));
  }

  @override
  void dispose() {
    _approvals.close();
    super.dispose();
  }
}
