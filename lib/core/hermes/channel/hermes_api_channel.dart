import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../protocol/wing_json.dart';
import '../../protocol/voice/models/wing_voice_run.dart';
import '../client/hermes_api_client.dart';
import '../client/hermes_api_config.dart';
import '../models/hermes_capabilities.dart';
import '../models/hermes_chat_turn.dart';
import '../models/hermes_health.dart';
import '../models/hermes_job.dart';
import '../models/hermes_run.dart';
import '../models/hermes_runtime_model.dart';
import '../models/hermes_session.dart';
import '../models/hermes_skill.dart';
import '../models/hermes_toolset.dart';
import '../policy/hermes_transport_policy.dart';
import '../reconciliation/hermes_text_reconciliation.dart';
import '../../../shared/async/fire_and_forget.dart';
import '../../../shared/security/wing_redaction.dart';
import '../setup/hermes_endpoint_store.dart';
import '../shared/hermes_api_http.dart';
import '../sse/hermes_sse_event_decoder.dart';
import 'approvals/hermes_approval_responder.dart';
import 'hermes_channel.dart';
import 'hermes_detached_run_store.dart';

part 'api_channel/hermes_api_channel_connection.dart';
part 'api_channel/hermes_api_channel_sessions.dart';
part 'api_channel/hermes_api_channel_profiles.dart';
part 'api_channel/hermes_api_channel_providers.dart';
part 'api_channel/hermes_api_channel_messaging.dart';
part 'api_channel/hermes_api_channel_voice.dart';
part 'api_channel/hermes_api_channel_errors.dart';

/// [HermesChannel] backed by [HermesApiClient] against a live Hermes Agent
/// API server. See docs/adr/client.md.
class HermesApiChannel extends ChangeNotifier
    implements HermesChannel, HermesAudioChannel {
  HermesApiChannel({
    HermesApiClient Function(HermesApiConfig config)? clientBuilder,
    String Function()? sessionIdFactory,
    Uuid? uuid,
    HermesDetachedRunStore? detachedRunStore,
    this.streamIdleTimeout = const Duration(minutes: 5),
    this.runStatusReconcileInterval = const Duration(seconds: 3),
  }) : _clientBuilder =
           clientBuilder ?? ((config) => HermesApiClient(config: config)),
       _uuid = uuid ?? const Uuid(),
       // Named public injection cannot use a private initializing formal.
       // ignore: prefer_initializing_formals
       _detachedRunStore = detachedRunStore,
       _sessionIdFactory =
           sessionIdFactory ??
           (() =>
               'navi-${DateTime.now().microsecondsSinceEpoch}-${(uuid ?? const Uuid()).v4()}');

  final HermesApiClient Function(HermesApiConfig) _clientBuilder;
  final String Function() _sessionIdFactory;
  final Uuid _uuid;
  final HermesDetachedRunStore? _detachedRunStore;
  final Duration streamIdleTimeout;
  final Duration runStatusReconcileInterval;

  static final _detachedRunOperationTails = <Object, Future<void>>{};

  HermesApiClient? _client;
  HermesChannelState _state = const HermesChannelState();
  final _activeStreams = <String, StreamSubscription<HermesStreamEvent>>{};
  final _activeStreamCompleters = <String, Completer<void>>{};
  final _activeRunIds = <String, String>{};
  final HermesApprovalResponder _approvalResponder = HermesApprovalResponder();
  final _sessionStreamGenerations = <String, int>{};
  final _pendingRunSubmissionGenerations = <String, int>{};
  final _explicitlyStoppedStreamGenerations = <int>{};
  final _detachedRuns = <String, HermesDetachedRunLease>{};
  final _confirmedDetachedRunKeys = <String>{};
  final _recentTurns = <String, List<HermesChatTurn>>{};
  final _runHistorySnapshots = <String, _HermesRunHistorySnapshot>{};
  final _messageHistoryPagination = <String, _HermesMessageHistoryPagination>{};
  Future<void>? _detachedRunsLoadFuture;
  bool _detachedRunsLoadFailed = false;
  int _nextStreamGeneration = 0;
  int _connectionGeneration = 0;
  final _voiceOwners = <String, (int, String?, String?)>{};
  final _voiceReplyTurns = <String, HermesChatTurn>{};
  int _sessionSelectionGeneration = 0;
  int _profileSelectionGeneration = 0;
  int _jobsRequestGeneration = 0;
  int _toolsRequestGeneration = 0;
  int _healthRequestGeneration = 0;
  int _providersRequestGeneration = 0;
  int _modelsRequestGeneration = 0;
  int _modelOptionsRequestGeneration = 0;
  String? _pendingProfileSelectionId;
  final _approvalController =
      StreamController<HermesApprovalRequest>.broadcast();
  final _deletingSessionOperations = <String, Object>{};
  final _forkingSessionOperations = <String, Object>{};

  @override
  HermesChannelState get state => _state;

  @override
  Stream<HermesApprovalRequest> get approvalRequests =>
      _approvalController.stream;

  @override
  void dispose() {
    _client = null;
    _connectionGeneration += 1;
    _sessionSelectionGeneration += 1;
    _invalidateProfileSelection();
    _deletingSessionOperations.clear();
    _forkingSessionOperations.clear();
    _clearActiveRunTracking();
    _detachedRuns.clear();
    _runHistorySnapshots.clear();
    _messageHistoryPagination.clear();
    _approvalController.close();
    super.dispose();
  }

  String _recentTurnKey(
    HermesApiClient client,
    String sessionId, {
    String? profileId,
  }) {
    // _recentTurns is never cleared on connect(), so the discriminator must
    // change across connections, not across credentials: a new connection
    // (even reusing the same credential) must never reconcile against the
    // previous connection's cached turns. _connectionGeneration increments on
    // every connect()/disconnect() and is stable within a connection.
    final profile = profileId ?? _state.selectedProfileId ?? 'default';
    return '${client.config.baseUri}|$_connectionGeneration|$profile|$sessionId';
  }

  void _setState(HermesChannelState next) {
    if (next.activeSessionId != _state.activeSessionId ||
        next.selectedProfileId != _state.selectedProfileId ||
        next.status != _state.status) {
      _voiceOwners.clear();
      _voiceReplyTurns.clear();
    }
    final client = _client;
    if (client != null) {
      final profileId = next.selectedProfileId ?? 'default';
      final offsets = <String, int>{};
      final hasEarlier = <String>{};
      for (final session in next.sessions) {
        final pagination =
            _messageHistoryPagination[_recentTurnKey(
              client,
              session.id,
              profileId: profileId,
            )];
        if (pagination == null) continue;
        offsets[session.id] = pagination.nextOffset;
        if (pagination.hasMore) hasEarlier.add(session.id);
      }
      next = next.copyWith(
        messageHistoryNextOffsets: offsets,
        sessionsWithEarlierMessages: hasEarlier,
      );
    }
    _state = next;
    notifyListeners();
  }

  String? _requestProfileForEndpoint(String endpointName) {
    final endpoint = _state.capabilities?.endpoints[endpointName];
    if (endpoint?.profileScoped != true) return null;
    if (_state.capabilities?.profileContext.isSupportedQueryContext == true) {
      return _requireSelectedProfile('send a profile-scoped request');
    }
    return null;
  }

  int _beginProfileSelection(String profileId) {
    _profileSelectionGeneration += 1;
    _pendingProfileSelectionId = profileId;
    return _profileSelectionGeneration;
  }

  bool _isCurrentProfileSelection(
    int selectionGeneration,
    int connectionGeneration,
    HermesApiClient client,
  ) =>
      selectionGeneration == _profileSelectionGeneration &&
      _isCurrentConnection(connectionGeneration, client);

  void _finishProfileSelection(int selectionGeneration) {
    if (selectionGeneration == _profileSelectionGeneration) {
      _pendingProfileSelectionId = null;
    }
  }

  void _invalidateProfileSelection() {
    _profileSelectionGeneration += 1;
    _pendingProfileSelectionId = null;
  }

  void _clearActiveRunTracking() {
    for (final stream in _activeStreams.values) {
      unawaited(stream.cancel());
    }
    for (final completer in _activeStreamCompleters.values) {
      if (!completer.isCompleted) completer.complete();
    }
    _activeStreams.clear();
    _activeStreamCompleters.clear();
    _activeRunIds.clear();
    _approvalResponder.clear();
    _sessionStreamGenerations.clear();
  }

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) =>
      _connect(baseUrl: baseUrl, apiKey: apiKey);

  @override
  Future<void> disconnect() => _disconnect();

  @override
  void clearActiveSession() =>
      _setState(_state.copyWith(clearActiveSessionId: true));

  @override
  Future<void> selectSession(String sessionId) => _selectSession(sessionId);

  @override
  Future<void> loadEarlierMessages() => _loadEarlierMessages();

  @override
  Future<void> loadMoreSessions() => _loadMoreSessions();

  @override
  Future<void> createSession({String? title}) => _createSession(title: title);

  @override
  Future<void> renameSession({
    required String sessionId,
    required String title,
  }) => _renameSession(sessionId: sessionId, title: title);

  @override
  Future<void> deleteSession(String sessionId) => _deleteSession(sessionId);

  @override
  Future<void> forkSession(String sessionId, {String? title}) =>
      _forkSession(sessionId, title: title);

  @override
  Future<void> selectProfile(
    String profileId, {
    bool allowDiscovered = false,
  }) => _selectProfile(profileId, allowDiscovered: allowDiscovered);

  @override
  Future<void> createProfile({required String name, String? cloneFrom}) =>
      _createProfile(name: name, cloneFrom: cloneFrom);

  @override
  Future<void> renameProfile({
    required String profileId,
    required String name,
    required String revision,
  }) => _renameProfile(profileId: profileId, name: name, revision: revision);

  @override
  Future<void> deleteProfile({
    required String profileId,
    required String revision,
  }) => _deleteProfile(profileId: profileId, revision: revision);

  @override
  Future<HermesProfileSoul> readProfileSoul(String profileId) =>
      _readProfileSoul(profileId);

  @override
  Future<void> writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  }) => _writeProfileSoul(profileId: profileId, soul: soul, revision: revision);

  @override
  Future<void> loadDetailedHealth() => _reloadDetailedHealth();

  @override
  Future<void> loadJobs() => _reloadJobs();

  @override
  Future<void> reconcileActiveSession() async {
    final sessionId = _state.activeSessionId;
    if (_state.status != HermesConnectionStatus.connected ||
        sessionId == null ||
        _state.isSessionStreaming(sessionId)) {
      return;
    }
    await _selectSession(sessionId);
  }

  @override
  Future<void> loadToolInventory() => _reloadToolInventory();

  @override
  Future<void> loadProviders() => _loadProviders();

  @override
  Future<void> setProviderCredential({
    required String slug,
    required String envVar,
    required String value,
  }) => _setProviderCredential(slug: slug, envVar: envVar, value: value);

  @override
  Future<void> removeProviderCredential({
    required String slug,
    required String envVar,
  }) => _removeProviderCredential(slug: slug, envVar: envVar);

  @override
  Future<HermesCredentialProbe> validateProviderCredential({
    required String slug,
  }) => _validateProviderCredential(slug: slug);

  @override
  Future<void> loadModels() => _loadModels();

  @override
  Future<void> loadModelOptions({bool refresh = false}) =>
      _loadModelOptions(refresh: refresh);

  @override
  Future<void> lockSessionModel({
    required String sessionId,
    required String provider,
    required String model,
  }) =>
      _lockSessionModel(sessionId: sessionId, provider: provider, model: model);

  @override
  Future<void> refreshModels() => _refreshModels();

  @override
  Future<void> assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
  }) => _assignModel(
    scope: scope,
    task: task,
    provider: provider,
    model: model,
    revision: revision,
  );

  @override
  Future<String> transcribePcm16(Uint8List pcm16) {
    _requireAudioEndpoint('audio_transcribe', 'POST', '/api/audio/transcribe');
    return _requireConnectedClient().transcribePcm16(
      pcm16,
      profile: _state.selectedProfileId,
    );
  }

  @override
  Future<Uint8List> synthesizeSpeech(String text) {
    _requireAudioEndpoint('audio_speak', 'POST', '/api/audio/speak');
    return _requireConnectedClient().synthesizeSpeech(
      text,
      profile: _state.selectedProfileId,
    );
  }

  void _requireAudioEndpoint(String name, String method, String path) {
    final capabilities = _state.capabilities;
    final policy = capabilities == null
        ? null
        : HermesTransportPolicy(capabilities);
    final authorized = switch ((name, method, path)) {
      ('audio_speak', 'POST', '/api/audio/speak') =>
        policy?.supportsSpeechSynthesis ?? false,
      ('audio_transcribe', 'POST', '/api/audio/transcribe') =>
        policy?.supportsSpeechTranscription ?? false,
      _ => false,
    };
    if (!authorized) {
      throw StateError('Hermes did not advertise its audio API.');
    }
  }

  @override
  Future<void> sendText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
  }) => _sendText(
    text,
    imageDataUrl: imageDataUrl,
    textAttachment: textAttachment,
    attachmentName: attachmentName,
  );

  @override
  bool get canSteerActiveTurn {
    final sessionId = _state.activeSessionId;
    return sessionId != null &&
        _state.canSteerRuns &&
        _activeRunIds.containsKey(sessionId);
  }

  @override
  void cancelActiveTurn() => _cancelActiveTurn();

  @override
  void stopActiveTurn() => fireAndForget(_stopActiveTurn(), 'stop active turn');

  @override
  HermesTurnInterruptionTarget? get activeTurnInterruptionTarget {
    final session = _state.activeSessionId;
    final generation = _sessionStreamGenerations[session];
    if (session == null ||
        generation == null ||
        !_state.isSessionStreaming(session)) {
      return null;
    }
    return HermesTurnInterruptionTarget(
      owner: this,
      connectionGeneration: _connectionGeneration,
      profileId: _state.selectedProfileId,
      sessionId: session,
      streamGeneration: generation,
      runId: _activeRunIds[session],
    );
  }

  @override
  Future<bool> stopTurn(HermesTurnInterruptionTarget target) async {
    if (!target.matches(activeTurnInterruptionTarget)) return false;
    final capabilities = _state.capabilities;
    final canConfirm =
        target.runId != null &&
        capabilities != null &&
        HermesTransportPolicy(capabilities).supportsRunStop;
    await _stopActiveTurn();
    return canConfirm;
  }

  @override
  Future<void> steerActiveTurn(String text) async {
    final client = _requireConnectedClient();
    if (!_state.canSteerRuns) {
      throw StateError('Hermes did not advertise run steering.');
    }
    final sessionId = _state.activeSessionId;
    if (sessionId == null) {
      throw StateError('Hermes has no active session to steer.');
    }
    final runId = _activeRunIds[sessionId];
    if (runId == null) {
      throw StateError('The active Hermes turn cannot accept steer input.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Steer input cannot be blank.');
    }
    await client.steerRun(
      runId,
      text: trimmed,
      profile: _requestProfileForEndpoint('run_steer'),
    );
  }

  @override
  Future<void> respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
    String? runId,
    HermesApprovalRequest? origin,
  }) => _respondToApproval(
    approvalId: approvalId,
    decision: decision,
    runId: runId,
    origin: origin,
  );

  Future<void> _respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
    String? runId,
    HermesApprovalRequest? origin,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    if (origin != null &&
        (origin.id.trim() != approvalId.trim() ||
            origin.runId != runId ||
            origin.connectionGeneration != _connectionGeneration ||
            origin.profileSelectionGeneration != _profileSelectionGeneration ||
            origin.profileId != _state.selectedProfileId ||
            _activeRunIds[origin.sessionId] != runId)) {
      throw StateError(
        'This approval no longer belongs to the active Hermes context.',
      );
    }
    final generation = _connectionGeneration;
    final profileGeneration = _profileSelectionGeneration;
    await _approvalResponder.respond(
      client: client,
      state: _state,
      approvalId: approvalId,
      decision: decision,
      activeRunIds: _activeRunIds.values,
      runId: runId,
      selectedProfileId: origin == null
          ? _state.selectedProfileId
          : origin.profileId,
      safeError: _safeHermesError,
      reportError: (message) {
        if (_isCurrentConnection(generation, client) &&
            profileGeneration == _profileSelectionGeneration) {
          _setState(_state.copyWith(errorMessage: message));
        }
      },
    );
  }

  @override
  String startVoiceRun() => _startVoiceRun();

  @override
  String? voiceReplyTurnId(String voiceRunId) {
    final expected = _voiceReplyTurns[voiceRunId];
    if (expected == null) return null;
    return _state.activeMessages.any(
          (turn) =>
              turn.id == expected.id && turn.createdAt == expected.createdAt,
        )
        ? expected.id
        : null;
  }

  @override
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
  }) => _stageVoiceRunTranscript(
    voiceRunId: voiceRunId,
    transcript: transcript,
    duration: duration,
    confidence: confidence,
  );

  @override
  void submitVoiceRun(String voiceRunId) => _submitVoiceRun(voiceRunId);

  @override
  void cancelVoiceRun(String voiceRunId, {String reason = 'cancelled'}) =>
      _cancelVoiceRun(voiceRunId, reason: reason);

  @override
  void failVoiceRun(String voiceRunId, {required String reason}) =>
      _failVoiceRun(voiceRunId, reason: reason);
}

class _HermesMessageHistoryPagination {
  const _HermesMessageHistoryPagination({
    required this.nextOffset,
    required this.hasMore,
  });

  final int nextOffset;
  final bool hasMore;
}

class _HermesRunHistorySnapshot {
  _HermesRunHistorySnapshot(List<HermesMessage> messages)
    : messages = List.unmodifiable(messages);

  final List<HermesMessage> messages;

  bool get isPlain =>
      messages.every((message) => message.isPlainRunHistoryMessage);
}
