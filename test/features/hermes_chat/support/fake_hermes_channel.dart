import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/hermes/models/hermes_job.dart';
import 'package:wing/core/hermes/models/hermes_run.dart';
import 'package:wing/core/hermes/models/hermes_runtime_model.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/models/hermes_skill.dart';
import 'package:wing/core/hermes/models/hermes_toolset.dart';
import 'package:wing/core/hermes/policy/hermes_transport_policy.dart';
import 'package:wing/core/protocol/voice/models/wing_voice_run.dart';

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
    HermesHealthStatus? basicHealth,
    HermesHealthStatus? detailedHealth,
    List<String> models = const [],
    List<HermesRuntimeModel> runtimeModels = const [],
    List<String> skills = const [],
    List<HermesSkill> skillDetails = const [],
    List<HermesToolset> toolsets = const [],
    List<String> enabledToolsets = const [],
    List<HermesJob> jobs = const [],
    Map<HermesOptionalResource, String> optionalResourceErrors = const {},
    List<HermesSession>? sessions,
    List<HermesProfile> profiles = const [],
    String? selectedProfileId,
    List<HermesProvider> providers = const [],
    this.modelInventory,
    this.validateProviderResult = const HermesCredentialProbe(
      ok: true,
      detail: 'Credential accepted.',
    ),
    this.profileSoul = const HermesProfileSoul(soul: '', revision: 'rev-1'),
    this.refreshedDetailedHealth,
    this.loadDetailedHealthFails = false,
    this.refreshedJobs,
    this.loadJobsFails = false,
    String connectedBaseUrl = 'http://fake-hermes:8642',
    bool connectedWithApiKey = true,
    bool hasUnreconciledRun = false,
    this.createSessionFails = false,
    this.selectSessionFails = false,
    this.selectSessionFailureMessage = 'select failed',
    this.deleteSessionFailureIds = const {},
    this.approvalResponsesFail = false,
    this.approvalResponseGate,
    this.connectGate,
    this.sendTextGate,
    this.createProfileFails = false,
    this.renameProfileFails = false,
    this.deleteProfileFails = false,
    this.writeProfileSoulFails = false,
    this.profileMutationFailureMessage = 'Hermes API returned HTTP 412',
  }) : connectCapabilities = capabilities,
       connectBasicHealth = basicHealth,
       _state = status == HermesConnectionStatus.connected
           ? HermesChannelState(
               status: status,
               capabilities: capabilities,
               basicHealth: basicHealth,
               detailedHealth: detailedHealth,
               models: models,
               runtimeModels: runtimeModels,
               skills: skills,
               skillDetails: skillDetails,
               toolsets: toolsets,
               enabledToolsets: enabledToolsets,
               jobs: jobs,
               optionalResourceErrors: optionalResourceErrors,
               errorMessage: errorMessage,
               connectedBaseUrl: connectedBaseUrl,
               connectedWithApiKey: connectedWithApiKey,
               hasUnreconciledRun: hasUnreconciledRun,
               sessions:
                   sessions ?? [HermesSession(id: sessionId, source: 'fake')],
               profiles: profiles,
               selectedProfileId: selectedProfileId,
               providers: providers,
               modelInventory: modelInventory,
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

  factory FakeHermesChannel.disconnected({
    Set<String> deleteSessionFailureIds = const {},
  }) => FakeHermesChannel(
    status: HermesConnectionStatus.disconnected,
    deleteSessionFailureIds: deleteSessionFailureIds,
  );

  final HermesCapabilityDocument? connectCapabilities;
  final HermesHealthStatus? connectBasicHealth;
  final List<FakeHermesConnectCall> connectCalls = [];
  int disconnectCalls = 0;
  final List<String> sentVoiceTranscripts = [];
  final List<String?> sentImageDataUrls = [];
  final List<String?> sentTextAttachments = [];
  final List<String?> createSessionCalls = [];
  final List<String> selectSessionCalls = [];
  final List<Map<String, String>> renameSessionCalls = [];
  final List<String> deleteSessionCalls = [];
  final List<String> forkSessionCalls = [];
  final List<String> selectProfileCalls = [];
  final List<bool> selectProfileAllowDiscoveredCalls = [];
  final List<Map<String, String?>> createProfileCalls = [];
  final List<Map<String, String>> renameProfileCalls = [];
  final List<Map<String, String>> deleteProfileCalls = [];
  final List<String> readProfileSoulCalls = [];
  final List<Map<String, String>> writeProfileSoulCalls = [];
  final HermesProfileSoul profileSoul;

  /// Provider/model seam call recording. [setProviderCredentialCalls] records
  /// the raw `value` it was given (the transport seam), but the fake never
  /// exposes that value through observable [state] — only presence.
  int loadDetailedHealthCalls = 0;
  final HermesHealthStatus? refreshedDetailedHealth;
  final bool loadDetailedHealthFails;
  int loadJobsCalls = 0;
  final List<HermesJob>? refreshedJobs;
  final bool loadJobsFails;
  int loadProvidersCalls = 0;
  final List<Map<String, String>> setProviderCredentialCalls = [];
  final List<Map<String, String>> removeProviderCredentialCalls = [];
  final List<String> validateProviderCredentialCalls = [];
  int loadModelsCalls = 0;
  int refreshModelsCalls = 0;
  final List<Map<String, String?>> assignModelCalls = [];
  final HermesModelInventory? modelInventory;
  final HermesCredentialProbe validateProviderResult;
  final List<Map<String, Object?>> respondToApprovalCalls = [];
  final bool createSessionFails;
  bool selectSessionFails;
  String selectSessionFailureMessage;
  final Set<String> deleteSessionFailureIds;
  final bool approvalResponsesFail;
  final Future<void> Function()? approvalResponseGate;
  final Future<void> Function()? connectGate;
  final Future<void> Function()? sendTextGate;

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

  void replaceSessions(
    List<HermesSession> sessions, {
    required String? activeSessionId,
  }) {
    _setState(
      _state.copyWith(
        sessions: sessions,
        activeSessionId: activeSessionId,
        clearActiveSessionId: activeSessionId == null,
        messages: {
          for (final session in sessions)
            session.id: _state.messages[session.id] ?? const <HermesChatTurn>[],
        },
      ),
    );
  }

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    connectCalls.add(FakeHermesConnectCall(baseUrl: baseUrl, apiKey: apiKey));
    final gate = connectGate;
    if (gate != null) {
      _setState(
        const HermesChannelState(status: HermesConnectionStatus.connecting),
      );
      await gate();
    }
    const sessionId = 'sess_1';
    _setState(
      HermesChannelState(
        status: HermesConnectionStatus.connected,
        capabilities: connectCapabilities,
        basicHealth: connectBasicHealth,
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
    disconnectCalls++;
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
    if (deleteSessionFailureIds.contains(sessionId)) {
      throw StateError('private transport failure');
    }
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
  Future<void> selectProfile(
    String profileId, {
    bool allowDiscovered = false,
  }) async {
    selectProfileCalls.add(profileId);
    selectProfileAllowDiscoveredCalls.add(allowDiscovered);
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
  Future<void> loadDetailedHealth() async {
    loadDetailedHealthCalls += 1;
    if (loadDetailedHealthFails) {
      throw StateError('detailed health refresh failed');
    }
    final replacement = refreshedDetailedHealth;
    if (replacement == null) return;
    final errors = Map<HermesOptionalResource, String>.from(
      _state.optionalResourceErrors,
    )..remove(HermesOptionalResource.detailedHealth);
    _setState(
      _state.copyWith(
        detailedHealth: replacement,
        optionalResourceErrors: errors,
      ),
    );
  }

  @override
  Future<void> loadJobs() async {
    loadJobsCalls += 1;
    if (loadJobsFails) throw StateError('jobs refresh failed');
    final replacement = refreshedJobs;
    if (replacement == null) return;
    final errors = Map<HermesOptionalResource, String>.from(
      _state.optionalResourceErrors,
    )..remove(HermesOptionalResource.jobs);
    _setState(
      _state.copyWith(jobs: replacement, optionalResourceErrors: errors),
    );
  }

  @override
  Future<void> loadProviders() async {
    loadProvidersCalls += 1;
  }

  @override
  Future<void> setProviderCredential({
    required String slug,
    required String envVar,
    required String value,
  }) async {
    setProviderCredentialCalls.add({
      'slug': slug,
      'envVar': envVar,
      'value': value,
    });
    // Reconcile presence only — the raw value never lands in observable state.
    _setState(
      _state.copyWith(
        providers: [
          for (final provider in _state.providers)
            if (provider.slug == slug)
              HermesProvider(
                slug: provider.slug,
                label: provider.label,
                authType: provider.authType,
                envVars: provider.envVars,
                configured: true,
                keyHint: _maskHint(value),
              )
            else
              provider,
        ],
      ),
    );
  }

  @override
  Future<void> removeProviderCredential({
    required String slug,
    required String envVar,
  }) async {
    removeProviderCredentialCalls.add({'slug': slug, 'envVar': envVar});
    _setState(
      _state.copyWith(
        providers: [
          for (final provider in _state.providers)
            if (provider.slug == slug)
              HermesProvider(
                slug: provider.slug,
                label: provider.label,
                authType: provider.authType,
                envVars: provider.envVars,
              )
            else
              provider,
        ],
      ),
    );
  }

  @override
  Future<HermesCredentialProbe> validateProviderCredential({
    required String slug,
  }) async {
    validateProviderCredentialCalls.add(slug);
    return validateProviderResult;
  }

  @override
  Future<void> loadModels() async {
    loadModelsCalls += 1;
  }

  @override
  Future<void> refreshModels() async {
    refreshModelsCalls += 1;
  }

  @override
  Future<void> assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
  }) async {
    assignModelCalls.add({
      'scope': scope,
      'task': task,
      'provider': provider,
      'model': model,
      'revision': revision,
    });
    final current = _state.modelInventory ?? const HermesModelInventory();
    _setState(
      _state.copyWith(
        modelInventory: current.withAssignment(
          HermesModelAssignment(
            activeProvider: provider,
            activeModel: model,
            auxiliary: current.assignment.auxiliary,
            revision: '$revision-next',
          ),
        ),
      ),
    );
  }

  /// Masked last-4-only hint mirroring the server contract; never the full
  /// value.
  static String _maskHint(String value) {
    if (value.length >= 8) return '····${value.substring(value.length - 4)}';
    return '····';
  }

  @override
  Future<void> sendText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
  }) async {
    sentImageDataUrls.add(imageDataUrl);
    sentTextAttachments.add(textAttachment);
    final attachment = imageDataUrl != null || textAttachment != null
        ? HermesTurnAttachment(
            name:
                attachmentName ??
                (textAttachment != null ? 'attachment.txt' : 'attachment'),
            kind: imageDataUrl != null
                ? HermesAttachmentKind.image
                : HermesAttachmentKind.file,
          )
        : null;
    final gate = sendTextGate;
    if (gate == null) {
      _appendExchange(text, attachment: attachment);
      return;
    }
    beginStreamingTurn(text, attachment: attachment);
    await gate();
    completeStreamingTurn(text: 'Echo: $text');
  }

  void emitApprovalRequest(HermesApprovalRequest request) {
    _approvalController.add(request);
  }

  void setCapabilities(HermesCapabilityDocument capabilities) {
    _setState(_state.copyWith(capabilities: capabilities));
  }

  /// Test-only helper: leaves an assistant turn `streaming` (as a real
  /// in-flight run would) so widget tests can exercise the stop control.
  void beginStreamingTurn(String userText, {HermesTurnAttachment? attachment}) {
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
        attachment: attachment,
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

  void completeStreamingTurn({
    String text = 'done',
    HermesRunUsage? usage,
    String? sessionId,
  }) {
    final targetSessionId = sessionId ?? _state.activeSessionId;
    if (targetSessionId == null) return;
    final turns = List<HermesChatTurn>.from(
      _state.messages[targetSessionId] ?? const [],
    );
    final index = turns.lastIndexWhere(
      (turn) => turn.status == HermesTurnStatus.streaming,
    );
    if (index == -1) return;
    final turn = turns[index];
    turns[index] = turn.copyWith(
      text: text,
      status: HermesTurnStatus.completed,
      usage: usage,
    );
    _setState(
      _state.copyWith(messages: {..._state.messages, targetSessionId: turns}),
    );
  }

  void addReasoningTurn(String text) {
    final sessionId = _state.activeSessionId;
    if (sessionId == null) return;
    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final assistantIndex = turns.lastIndexWhere(
      (turn) => turn.status == HermesTurnStatus.streaming,
    );
    turns.insert(
      assistantIndex < 0 ? turns.length : assistantIndex,
      HermesChatTurn(
        id: 'reasoning-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.system,
        createdAt: DateTime.now(),
        kind: HermesTurnKind.reasoning,
        text: text,
      ),
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

  void _appendExchange(String text, {HermesTurnAttachment? attachment}) {
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
        attachment: attachment,
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
    final run = WingVoiceRun.recording(
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

  void _updateVoiceRun(WingVoiceRun run) {
    _setState(_state.copyWith(voiceRuns: {..._state.voiceRuns, run.id: run}));
  }
}
