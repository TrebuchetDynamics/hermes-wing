import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/core/hermes/models/hermes_capabilities.dart';
import 'package:navivox/core/hermes/models/hermes_chat_turn.dart';
import 'package:navivox/core/hermes/models/hermes_health.dart';
import 'package:navivox/core/hermes/models/hermes_job.dart';
import 'package:navivox/core/hermes/models/hermes_session.dart';
import 'package:navivox/core/hermes/policy/hermes_transport_policy.dart';
import 'package:navivox/core/protocol/voice/models/navivox_voice_run.dart';

class FakeHermesConnectCall {
  const FakeHermesConnectCall({required this.baseUrl, this.apiKey});

  final String baseUrl;
  final String? apiKey;
}

/// Lightweight [HermesChannel] test double: an in-memory session with no real
/// HTTP/SSE transport, used by controller and widget tests. `sendText` and
/// voice-run submission both append a user turn plus an immediate, completed
/// assistant echo turn so transcript/continuous-voice behavior is testable
/// without a real streaming server.
class FakeHermesChannel extends ChangeNotifier implements HermesChannel {
  FakeHermesChannel({
    HermesConnectionStatus status = HermesConnectionStatus.connected,
    String sessionId = 'sess_1',
    String? errorMessage,
    HermesCapabilityDocument? capabilities,
    String? activeSessionId,
    HermesHealthStatus? detailedHealth,
    List<String> models = const [],
    List<String> skills = const [],
    List<String> enabledToolsets = const [],
    List<HermesJob> jobs = const [],
    List<HermesSession>? sessions,
    List<HermesProfile> profiles = const [],
    String? selectedProfileId,
    this.profileSoul = const HermesProfileSoul(soul: '', revision: 'rev-1'),
    String connectedBaseUrl = 'http://fake-hermes:8642',
    bool connectedWithApiKey = true,
    this.createSessionFails = false,
    this.selectSessionFails = false,
    this.selectSessionFailureMessage = 'select failed',
    this.approvalResponsesFail = false,
    this.approvalResponseGate,
    this.createProfileFails = false,
    this.renameProfileFails = false,
    this.deleteProfileFails = false,
    this.writeProfileSoulFails = false,
    this.profileMutationFailureMessage = 'Hermes API returned HTTP 412',
  }) : _state = status == HermesConnectionStatus.connected
           ? HermesChannelState(
               status: status,
               capabilities: capabilities,
               detailedHealth: detailedHealth,
               models: models,
               skills: skills,
               enabledToolsets: enabledToolsets,
               jobs: jobs,
               errorMessage: errorMessage,
               connectedBaseUrl: connectedBaseUrl,
               connectedWithApiKey: connectedWithApiKey,
               sessions:
                   sessions ?? [HermesSession(id: sessionId, source: 'fake')],
               profiles: profiles,
               selectedProfileId: selectedProfileId,
               activeSessionId:
                   activeSessionId ??
                   ((sessions != null && sessions.isEmpty) ? null : sessionId),
               messages: {
                 for (final session
                     in sessions ??
                         [HermesSession(id: sessionId, source: 'fake')])
                   session.id: const <HermesChatTurn>[],
               },
             )
           : HermesChannelState(status: status, errorMessage: errorMessage);

  factory FakeHermesChannel.disconnected() =>
      FakeHermesChannel(status: HermesConnectionStatus.disconnected);

  final List<FakeHermesConnectCall> connectCalls = [];
  final List<String> sentVoiceTranscripts = [];
  final List<String?> createSessionCalls = [];
  final List<String> selectSessionCalls = [];
  final List<Map<String, String>> renameSessionCalls = [];
  final List<String> deleteSessionCalls = [];
  final List<String> forkSessionCalls = [];
  final List<String> selectProfileCalls = [];
  final List<Map<String, String?>> createProfileCalls = [];
  final List<Map<String, String>> renameProfileCalls = [];
  final List<Map<String, String>> deleteProfileCalls = [];
  final List<String> readProfileSoulCalls = [];
  final List<Map<String, String>> writeProfileSoulCalls = [];
  final HermesProfileSoul profileSoul;
  final List<Map<String, Object?>> respondToApprovalCalls = [];
  final bool createSessionFails;
  bool selectSessionFails;
  String selectSessionFailureMessage;
  final bool approvalResponsesFail;
  final Future<void> Function()? approvalResponseGate;

  /// Profile-mutation failure injection. When set, the corresponding mutation
  /// records its call, refreshes nothing successfully, and throws a
  /// [StateError] carrying [profileMutationFailureMessage] (default contains
  /// `HTTP 412`, which the UI maps to a revision-conflict message).
  final bool createProfileFails;
  final bool renameProfileFails;
  final bool deleteProfileFails;
  final bool writeProfileSoulFails;
  final String profileMutationFailureMessage;
  int stopActiveTurnCalls = 0;
  final _approvalController =
      StreamController<HermesApprovalRequest>.broadcast();

  HermesChannelState _state;

  @override
  HermesChannelState get state => _state;

  @override
  Stream<HermesApprovalRequest> get approvalRequests =>
      _approvalController.stream;

  @override
  void dispose() {
    _approvalController.close();
    super.dispose();
  }

  void _setState(HermesChannelState next) {
    _state = next;
    notifyListeners();
  }

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    connectCalls.add(FakeHermesConnectCall(baseUrl: baseUrl, apiKey: apiKey));
    const sessionId = 'sess_1';
    _setState(
      HermesChannelState(
        status: HermesConnectionStatus.connected,
        sessions: [const HermesSession(id: sessionId, source: 'fake')],
        activeSessionId: sessionId,
        connectedBaseUrl: baseUrl,
        connectedWithApiKey: apiKey?.trim().isNotEmpty ?? false,
        messages: const {sessionId: []},
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    _setState(const HermesChannelState());
  }

  @override
  Future<void> selectSession(String sessionId) async {
    selectSessionCalls.add(sessionId);
    if (selectSessionFails) {
      throw StateError(selectSessionFailureMessage);
    }
    _setState(_state.copyWith(activeSessionId: sessionId));
  }

  @override
  Future<void> createSession({String? title}) async {
    createSessionCalls.add(title);
    if (createSessionFails) {
      throw StateError('create failed');
    }
    final sessionId = 'sess_${_state.sessions.length + 1}';
    final session = HermesSession(id: sessionId, source: 'fake', title: title);
    _setState(
      _state.copyWith(
        sessions: [..._state.sessions, session],
        activeSessionId: sessionId,
        messages: {..._state.messages, sessionId: const <HermesChatTurn>[]},
      ),
    );
  }

  @override
  Future<void> renameSession({
    required String sessionId,
    required String title,
  }) async {
    renameSessionCalls.add({'sessionId': sessionId, 'title': title});
    _setState(
      _state.copyWith(
        sessions: [
          for (final session in _state.sessions)
            if (session.id == sessionId)
              HermesSession(
                id: session.id,
                source: session.source,
                title: title,
              )
            else
              session,
        ],
      ),
    );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    deleteSessionCalls.add(sessionId);
    final remaining = [
      for (final session in _state.sessions)
        if (session.id != sessionId) session,
    ];
    final nextActive = _state.activeSessionId == sessionId
        ? remaining.firstOrNull?.id
        : _state.activeSessionId;
    final messages = Map<String, List<HermesChatTurn>>.from(_state.messages)
      ..remove(sessionId);
    _setState(
      _state.copyWith(
        sessions: remaining,
        activeSessionId: nextActive,
        clearActiveSessionId: nextActive == null,
        messages: messages,
      ),
    );
  }

  @override
  Future<void> forkSession(String sessionId, {String? title}) async {
    forkSessionCalls.add(sessionId);
    final forkId = 'fork-${_state.sessions.length}';
    final fork = HermesSession(
      id: forkId,
      source: 'fake',
      title: title ?? 'Forked session',
      parentSessionId: sessionId,
    );
    _setState(
      _state.copyWith(
        sessions: [..._state.sessions, fork],
        activeSessionId: forkId,
        messages: {
          ..._state.messages,
          forkId: _state.messages[sessionId] ?? const [],
        },
      ),
    );
  }

  @override
  Future<void> selectProfile(String profileId) async {
    selectProfileCalls.add(profileId);
    _setState(_state.copyWith(selectedProfileId: profileId));
  }

  @override
  Future<void> createProfile({required String name, String? cloneFrom}) async {
    createProfileCalls.add({'name': name, 'cloneFrom': cloneFrom});
    if (createProfileFails) {
      throw StateError(profileMutationFailureMessage);
    }
    final id = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    _setState(
      _state.copyWith(
        profiles: [
          ..._state.profiles,
          HermesProfile(id: id, displayName: name.trim(), revision: 'rev-new'),
        ],
      ),
    );
  }

  @override
  Future<void> renameProfile({
    required String profileId,
    required String name,
    required String revision,
  }) async {
    renameProfileCalls.add({
      'profileId': profileId,
      'name': name,
      'revision': revision,
    });
    if (renameProfileFails) {
      throw StateError(profileMutationFailureMessage);
    }
    _setState(
      _state.copyWith(
        profiles: [
          for (final profile in _state.profiles)
            if (profile.id == profileId)
              HermesProfile(
                id: profile.id,
                displayName: name.trim(),
                revision: 'rev-next',
                description: profile.description,
                model: profile.model,
                skillsCount: profile.skillsCount,
                gatewayRunning: profile.gatewayRunning,
              )
            else
              profile,
        ],
      ),
    );
  }

  @override
  Future<void> deleteProfile({
    required String profileId,
    required String revision,
  }) async {
    deleteProfileCalls.add({'profileId': profileId, 'revision': revision});
    if (deleteProfileFails) {
      throw StateError(profileMutationFailureMessage);
    }
    _setState(
      _state.copyWith(
        profiles: [
          for (final profile in _state.profiles)
            if (profile.id != profileId) profile,
        ],
      ),
    );
  }

  @override
  Future<HermesProfileSoul> readProfileSoul(String profileId) async {
    readProfileSoulCalls.add(profileId);
    return profileSoul;
  }

  @override
  Future<void> writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  }) async {
    writeProfileSoulCalls.add({
      'profileId': profileId,
      'soul': soul,
      'revision': revision,
    });
    if (writeProfileSoulFails) {
      throw StateError(profileMutationFailureMessage);
    }
  }

  @override
  Future<void> sendText(String text) async {
    _appendExchange(text);
  }

  void emitApprovalRequest(HermesApprovalRequest request) {
    _approvalController.add(request);
  }

  void setCapabilities(HermesCapabilityDocument capabilities) {
    _setState(_state.copyWith(capabilities: capabilities));
  }

  /// Test-only helper: leaves an assistant turn `streaming` (as a real
  /// in-flight run would) so widget tests can exercise the stop control.
  void beginStreamingTurn(String userText) {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final now = DateTime.now();
    turns.add(
      HermesChatTurn(
        id: 'user-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.user,
        createdAt: now,
        text: userText,
      ),
    );
    turns.add(
      HermesChatTurn(
        id: 'assistant-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.assistant,
        createdAt: now,
        status: HermesTurnStatus.streaming,
      ),
    );
    _setState(
      _state.copyWith(messages: {..._state.messages, sessionId: turns}),
    );
  }

  void completeStreamingTurn({String text = 'done'}) {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final index = turns.lastIndexWhere(
      (turn) => turn.status == HermesTurnStatus.streaming,
    );
    if (index == -1) return;
    final turn = turns[index];
    turns[index] = turn.copyWith(
      text: text,
      status: HermesTurnStatus.completed,
    );
    _setState(
      _state.copyWith(messages: {..._state.messages, sessionId: turns}),
    );
  }

  void addToolCallTurn(HermesToolCall toolCall) {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    turns.add(
      HermesChatTurn(
        id: 'tool-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.system,
        createdAt: DateTime.now(),
        kind: HermesTurnKind.toolCall,
        toolCall: toolCall,
      ),
    );
    _setState(
      _state.copyWith(messages: {..._state.messages, sessionId: turns}),
    );
  }

  void addFailedExchange(
    String text, {
    String errorMessage = 'SocketException: stream dropped',
  }) {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final now = DateTime.now();
    turns.add(
      HermesChatTurn(
        id: 'user-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.user,
        createdAt: now,
        text: text,
      ),
    );
    turns.add(
      HermesChatTurn(
        id: 'assistant-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.assistant,
        createdAt: now,
        status: HermesTurnStatus.failed,
      ),
    );
    _setState(
      _state.copyWith(
        messages: {..._state.messages, sessionId: turns},
        errorMessage: errorMessage,
      ),
    );
  }

  void _appendExchange(String text) {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final now = DateTime.now();
    turns.add(
      HermesChatTurn(
        id: 'user-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.user,
        createdAt: now,
        text: text,
      ),
    );
    turns.add(
      HermesChatTurn(
        id: 'assistant-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.assistant,
        createdAt: now,
        text: 'echo: $text',
      ),
    );
    _setState(
      _state.copyWith(
        messages: {..._state.messages, sessionId: turns},
        clearErrorMessage: true,
      ),
    );
  }

  @override
  void cancelActiveTurn() {}

  @override
  void stopActiveTurn() {
    stopActiveTurnCalls += 1;
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final index = turns.lastIndexWhere(
      (turn) => turn.status == HermesTurnStatus.streaming,
    );
    if (index == -1) return;
    final turn = turns[index];
    turns[index] = turn.copyWith(
      status: HermesTurnStatus.failed,
      text: turn.text.isEmpty ? 'Stopped.' : turn.text,
    );
    _setState(
      _state.copyWith(messages: {..._state.messages, sessionId: turns}),
    );
  }

  @override
  Future<void> respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
  }) async {
    respondToApprovalCalls.add({
      'approvalId': approvalId,
      'decision': decision,
    });
    await approvalResponseGate?.call();
    if (!approvalResponsesFail) return;
    _setState(
      _state.copyWith(errorMessage: 'Could not answer approval: fake failure'),
    );
    throw StateError('fake approval failure');
  }

  @override
  String startVoiceRun() {
    final id = 'voice-${_state.voiceRuns.length}';
    final run = NavivoxVoiceRun.recording(
      id: id,
      serverId: 'hermes',
      profileId: _state.activeSessionId ?? '',
      createdAt: DateTime.now(),
    );
    _setState(
      _state.copyWith(
        voiceRuns: {..._state.voiceRuns, id: run},
        activeVoiceRunId: id,
      ),
    );
    return id;
  }

  @override
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
  }) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null || run.isTerminal) return;
    _updateVoiceRun(
      run.withDeviceTranscript(
        transcript: transcript,
        duration: duration,
        confidence: confidence,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  void submitVoiceRun(String voiceRunId) {
    final run = _state.voiceRuns[voiceRunId];
    final transcript = run?.transcript;
    if (run == null ||
        run.isTerminal ||
        transcript == null ||
        transcript.isEmpty) {
      return;
    }
    final capabilities = _state.capabilities;
    if (capabilities != null &&
        !HermesTransportPolicy(capabilities).supportsAnyChatTransport) {
      _updateVoiceRun(
        run.markFailed(
          'Hermes did not advertise a supported chat transport for this endpoint.',
        ),
      );
      return;
    }
    _updateVoiceRun(
      run.markSubmitted(
        requestId: voiceRunId,
        sessionId: _state.activeSessionId,
      ),
    );
    sentVoiceTranscripts.add(transcript);
    _appendExchange(transcript);
    _updateVoiceRun(_state.voiceRuns[voiceRunId]!.markCompleted());
  }

  @override
  void cancelVoiceRun(String voiceRunId, {String reason = 'cancelled'}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null || run.isTerminal) return;
    _updateVoiceRun(run.markCancelled(reason));
  }

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null || run.isTerminal) return;
    _updateVoiceRun(run.markFailed(reason));
  }

  void _updateVoiceRun(NavivoxVoiceRun run) {
    _setState(_state.copyWith(voiceRuns: {..._state.voiceRuns, run.id: run}));
  }
}
