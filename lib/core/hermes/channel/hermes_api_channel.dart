import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../protocol/navivox_json.dart';
import '../../protocol/voice/models/navivox_voice_run.dart';
import '../client/hermes_api_client.dart';
import '../client/hermes_api_config.dart';
import '../models/hermes_chat_turn.dart';
import '../models/hermes_health.dart';
import '../models/hermes_job.dart';
import '../policy/hermes_transport_policy.dart';
import '../sse/hermes_sse_event_decoder.dart';
import 'hermes_channel.dart';

/// [HermesChannel] backed by [HermesApiClient] against a live Hermes Agent
/// API server. See docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md.
class HermesApiChannel extends ChangeNotifier implements HermesChannel {
  HermesApiChannel({
    HermesApiClient Function(HermesApiConfig config)? clientBuilder,
    String Function()? sessionIdFactory,
    Uuid? uuid,
  }) : _clientBuilder =
           clientBuilder ?? ((config) => HermesApiClient(config: config)),
       _uuid = uuid ?? const Uuid(),
       _sessionIdFactory =
           sessionIdFactory ??
           (() =>
               'navi-${DateTime.now().microsecondsSinceEpoch}-${(uuid ?? const Uuid()).v4()}');

  final HermesApiClient Function(HermesApiConfig) _clientBuilder;
  final String Function() _sessionIdFactory;
  final Uuid _uuid;

  HermesApiClient? _client;
  HermesChannelState _state = const HermesChannelState();
  StreamSubscription<HermesStreamEvent>? _activeStream;
  Completer<void>? _activeStreamCompleter;
  String? _activeRunId;
  bool _activeTurnStopped = false;
  int _streamGeneration = 0;
  int _connectionGeneration = 0;
  final _approvalController =
      StreamController<NavivoxApprovalRequest>.broadcast();
  final _deletingSessionIds = <String>{};

  @override
  HermesChannelState get state => _state;

  @override
  Stream<NavivoxApprovalRequest> get approvalRequests =>
      _approvalController.stream;

  @override
  void dispose() {
    _client = null;
    _connectionGeneration += 1;
    _streamGeneration += 1;
    _deletingSessionIds.clear();
    unawaited(_activeStream?.cancel());
    _activeStream = null;
    _activeRunId = null;
    final completer = _activeStreamCompleter;
    _activeStreamCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _approvalController.close();
    super.dispose();
  }

  void _setState(HermesChannelState next) {
    _state = next;
    notifyListeners();
  }

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    final generation = _connectionGeneration + 1;
    _connectionGeneration = generation;
    _streamGeneration += 1;
    _deletingSessionIds.clear();
    unawaited(_activeStream?.cancel());
    _activeStream = null;
    _activeRunId = null;
    _client = null;
    final activeCompleter = _activeStreamCompleter;
    _activeStreamCompleter = null;
    if (activeCompleter != null && !activeCompleter.isCompleted) {
      activeCompleter.complete();
    }
    _setState(
      const HermesChannelState(status: HermesConnectionStatus.connecting),
    );
    HermesApiClient? client;
    try {
      client = _clientBuilder(
        HermesApiConfig.fromBaseUrl(baseUrl, apiKey: apiKey),
      );
      _client = client;
      await client.health();
      if (!_isCurrentConnection(generation, client)) return;
      final capabilities = await client.capabilities();
      final detailedHealth = await _optionalHealth(
        capabilities.advertisesEndpoint(
          'health_detailed',
          'GET',
          '/health/detailed',
        ),
        client.healthDetailed,
      );
      final models = await _optionalCatalogList(
        capabilities.advertisesEndpoint('models', 'GET', '/v1/models'),
        client.listModels,
      );
      final skills = await _optionalCatalogList(
        capabilities.advertisesEndpoint('skills', 'GET', '/v1/skills'),
        client.listSkills,
      );
      final enabledToolsets = await _optionalCatalogList(
        capabilities.advertisesEndpoint('toolsets', 'GET', '/v1/toolsets'),
        client.listEnabledToolsets,
      );
      final jobs = await _optionalJobs(
        capabilities.advertisesEndpoint('jobs', 'GET', '/api/jobs'),
        client.listJobs,
      );
      if (!_isCurrentConnection(generation, client)) return;
      var sessions = await client.listSessions();
      if (!_isCurrentConnection(generation, client)) return;
      String? activeId;
      List<HermesChatTurn>? messages;
      if (sessions.isEmpty) {
        if (capabilities.advertisesEndpoint(
          'session_create',
          'POST',
          '/api/sessions',
        )) {
          final created = await client.createSession(id: _sessionIdFactory());
          sessions = [created];
          activeId = created.id;
        }
      } else {
        activeId = sessions.first.id;
      }
      if (activeId != null) {
        messages = await _fetchTurns(client, activeId);
      }
      if (!_isCurrentConnection(generation, client)) return;
      _setState(
        _state.copyWith(
          status: HermesConnectionStatus.connected,
          capabilities: capabilities,
          detailedHealth: detailedHealth,
          models: models,
          skills: skills,
          enabledToolsets: enabledToolsets,
          jobs: jobs,
          sessions: sessions,
          activeSessionId: activeId,
          clearActiveSessionId: activeId == null,
          messages: activeId == null || messages == null
              ? _state.messages
              : {...(_state.messages), activeId: messages},
        ),
      );
    } catch (error) {
      if (generation != _connectionGeneration ||
          (client != null && !identical(_client, client))) {
        return;
      }
      _setState(
        _state.copyWith(
          status: HermesConnectionStatus.error,
          errorMessage: _safeHermesError(error),
        ),
      );
    }
  }

  bool _isCurrentConnection(int generation, HermesApiClient client) {
    return generation == _connectionGeneration && identical(_client, client);
  }

  bool _isConnectedClient(HermesApiClient client) {
    return identical(_client, client) &&
        _state.status == HermesConnectionStatus.connected;
  }

  Future<HermesHealthStatus?> _optionalHealth(
    bool advertised,
    Future<HermesHealthStatus> Function() load,
  ) async {
    if (!advertised) return null;
    try {
      return await load();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _optionalCatalogList(
    bool advertised,
    Future<List<String>> Function() load,
  ) async {
    if (!advertised) return const [];
    try {
      return await load();
    } catch (_) {
      return const [];
    }
  }

  Future<List<HermesJob>> _optionalJobs(
    bool advertised,
    Future<List<HermesJob>> Function() load,
  ) async {
    if (!advertised) return const [];
    try {
      return await load();
    } catch (_) {
      return const [];
    }
  }

  Future<List<HermesChatTurn>> _fetchTurns(
    HermesApiClient client,
    String sessionId,
  ) async {
    final history = await client.sessionMessages(sessionId);
    return [
      for (final message in history)
        HermesChatTurn(
          id: message.id,
          sessionId: sessionId,
          author: switch (message.role) {
            'user' => HermesTurnAuthor.user,
            'assistant' => HermesTurnAuthor.assistant,
            _ => HermesTurnAuthor.system,
          },
          createdAt: DateTime.now(),
          text: message.content,
        ),
    ];
  }

  @override
  Future<void> disconnect() async {
    _client = null;
    _connectionGeneration += 1;
    _streamGeneration += 1;
    _deletingSessionIds.clear();
    unawaited(_activeStream?.cancel());
    _activeStream = null;
    _activeRunId = null;
    final completer = _activeStreamCompleter;
    _activeStreamCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _setState(const HermesChannelState());
  }

  @override
  Future<void> selectSession(String sessionId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    _requireKnownSession(sessionId);
    _finishActiveTurnLocally();
    final turns = await _fetchTurns(client, sessionId);
    if (!_isConnectedClient(client)) return;
    _setState(
      _state.copyWith(
        activeSessionId: sessionId,
        messages: {..._state.messages, sessionId: turns},
      ),
    );
  }

  @override
  Future<void> createSession({String? title}) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    _requireAdvertisedEndpoint(
      'session_create',
      'POST',
      '/api/sessions',
      'create sessions',
    );
    final created = await client.createSession(
      id: _sessionIdFactory(),
      title: title,
    );
    if (!_isConnectedClient(client)) return;
    final turns = await _fetchTurns(client, created.id);
    if (!_isConnectedClient(client)) return;
    _finishActiveTurnLocally();
    _setState(
      _state.copyWith(
        sessions: [..._state.sessions, created],
        activeSessionId: created.id,
        messages: {..._state.messages, created.id: turns},
      ),
    );
  }

  @override
  Future<void> renameSession({
    required String sessionId,
    required String title,
  }) async {
    final client = _client;
    final trimmed = title.trim();
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Session title cannot be empty.',
      );
    }
    _requireAdvertisedEndpoint(
      'session_update',
      'PATCH',
      '/api/sessions/{session_id}',
      'rename sessions',
    );
    _requireKnownSession(sessionId);
    final updated = await client.updateSessionTitle(sessionId, title: trimmed);
    if (!_isConnectedClient(client)) return;
    _setState(
      _state.copyWith(
        sessions: [
          for (final session in _state.sessions)
            if (session.id == updated.id) updated else session,
        ],
      ),
    );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    _requireAdvertisedEndpoint(
      'session_delete',
      'DELETE',
      '/api/sessions/{session_id}',
      'delete sessions',
    );
    _requireKnownSession(sessionId);
    if (!_deletingSessionIds.add(sessionId)) {
      throw StateError('Hermes session delete is already in progress.');
    }
    final wasActive = _state.activeSessionId == sessionId;
    if (wasActive) {
      _finishActiveTurnLocally();
    }
    try {
      await client.deleteSession(sessionId);
      if (!_isConnectedClient(client)) return;
      final remaining = [
        for (final session in _state.sessions)
          if (session.id != sessionId) session,
      ];
      final nextActiveId = wasActive
          ? remaining.firstOrNull?.id
          : _state.activeSessionId;
      final messages = Map<String, List<HermesChatTurn>>.from(_state.messages)
        ..remove(sessionId);
      if (wasActive &&
          nextActiveId != null &&
          !messages.containsKey(nextActiveId)) {
        try {
          messages[nextActiveId] = await _fetchTurns(client, nextActiveId);
        } catch (_) {
          messages[nextActiveId] = const [];
        }
      }
      _setState(
        _state.copyWith(
          sessions: remaining,
          activeSessionId: nextActiveId,
          clearActiveSessionId: nextActiveId == null,
          messages: messages,
        ),
      );
    } finally {
      _deletingSessionIds.remove(sessionId);
    }
  }

  @override
  Future<void> forkSession(String sessionId, {String? title}) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    _requireAdvertisedEndpoint(
      'session_fork',
      'POST',
      '/api/sessions/{session_id}/fork',
      'fork sessions',
    );
    _requireKnownSession(sessionId);
    final fork = await client.forkSession(
      sessionId,
      id: _sessionIdFactory(),
      title: title,
    );
    if (!_isConnectedClient(client)) return;
    final turns = await _fetchTurns(client, fork.id);
    if (!_isConnectedClient(client)) return;
    _finishActiveTurnLocally();
    _setState(
      _state.copyWith(
        sessions: [..._state.sessions, fork],
        activeSessionId: fork.id,
        messages: {..._state.messages, fork.id: turns},
      ),
    );
  }

  void _requireAdvertisedEndpoint(
    String name,
    String method,
    String path,
    String action,
  ) {
    final capabilities = _state.capabilities;
    if (capabilities != null &&
        !capabilities.advertisesEndpoint(name, method, path)) {
      throw StateError('Hermes did not advertise support to $action.');
    }
  }

  void _requireKnownSession(String sessionId) {
    if (!_state.sessions.any((session) => session.id == sessionId)) {
      throw StateError('Hermes session is not in the current session list.');
    }
  }

  @override
  Future<void> sendText(String text) async {
    final message = text.trim();
    if (message.isEmpty) {
      throw ArgumentError.value(
        text,
        'text',
        'Hermes message cannot be blank.',
      );
    }
    final client = _client;
    final sessionId = _state.activeSessionId;
    if (client == null || sessionId == null) {
      throw StateError('Hermes channel is not connected to a session.');
    }
    final activeCompleter = _activeStreamCompleter;
    if ((activeCompleter != null && !activeCompleter.isCompleted) ||
        _state.activeMessages.lastOrNull?.status ==
            HermesTurnStatus.streaming) {
      throw StateError('Hermes turn is already streaming.');
    }
    final capabilities = _state.capabilities;
    if (capabilities != null &&
        !HermesTransportPolicy(capabilities).supportsAnyChatTransport) {
      throw StateError(
        'Hermes did not advertise a supported chat transport for this endpoint.',
      );
    }

    final turns = List<HermesChatTurn>.from(_state.activeMessages);
    final preSendTurnCount = turns.length;
    final now = DateTime.now();
    turns.add(
      HermesChatTurn(
        id: 'local-user-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.user,
        createdAt: now,
        text: message,
      ),
    );
    var assistantTurn = HermesChatTurn(
      id: 'local-assistant-${turns.length}',
      sessionId: sessionId,
      author: HermesTurnAuthor.assistant,
      createdAt: now,
      status: HermesTurnStatus.streaming,
    );
    turns.add(assistantTurn);
    var assistantIndex = turns.length - 1;
    _setTurns(sessionId, turns, clearErrorMessage: true);

    final useRunTransport =
        capabilities != null &&
        HermesTransportPolicy(capabilities).supportsRunsTransport;

    final submissionGeneration = _streamGeneration;
    Stream<HermesStreamEvent>? events;
    String? runId;
    try {
      if (useRunTransport) {
        final run = await client.startRun(
          sessionId: sessionId,
          message: message,
        );
        runId = run.id;
      } else {
        events = client.streamSessionChat(sessionId, message: message);
      }
    } catch (error) {
      if (!identical(_client, client) ||
          _state.status != HermesConnectionStatus.connected ||
          _state.activeSessionId != sessionId ||
          _streamGeneration != submissionGeneration) {
        return;
      }
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      _setTurns(sessionId, turns, errorMessage: _safeHermesError(error));
      rethrow;
    }

    if (!identical(_client, client) ||
        _state.status != HermesConnectionStatus.connected ||
        _state.activeSessionId != sessionId ||
        _streamGeneration != submissionGeneration) {
      return;
    }

    try {
      events ??= client.runEvents(runId!);
    } catch (error) {
      if (!identical(_client, client) ||
          _state.status != HermesConnectionStatus.connected ||
          _state.activeSessionId != sessionId ||
          _streamGeneration != submissionGeneration) {
        return;
      }
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      final message =
          'Hermes run event stream failed to open: ${_safeHermesError(error)}';
      _setTurns(sessionId, turns, errorMessage: message);
      throw StateError(message);
    }
    _activeRunId = runId;
    final toolTurnIndexByCallId = <String, int>{};
    final completer = Completer<void>();
    final streamGeneration = _streamGeneration + 1;
    _streamGeneration = streamGeneration;
    _activeStreamCompleter = completer;
    _activeTurnStopped = false;
    var streamFailed = false;
    var streamEndedBeforeTerminal = false;
    var terminalRunEventReceived = false;
    _activeStream = events.listen(
      (event) {
        if (streamGeneration != _streamGeneration || terminalRunEventReceived) {
          return;
        }
        if (event.isDone) {
          terminalRunEventReceived = true;
          if (!completer.isCompleted) completer.complete();
          return;
        }
        final delta = _streamDelta(event);
        if (delta != null && delta.isNotEmpty) {
          assistantTurn = assistantTurn.appendDelta(delta);
          turns[assistantIndex] = assistantTurn;
          _setTurns(sessionId, List.of(turns));
          return;
        }
        if (_isToolEvent(event.name)) {
          _applyToolEvent(
            sessionId: sessionId,
            event: event,
            turns: turns,
            toolTurnIndexByCallId: toolTurnIndexByCallId,
            insertBefore: assistantIndex,
          );
          assistantIndex = turns.length - 1;
          _setTurns(sessionId, List.of(turns));
          return;
        }
        if (event.name == 'approval.request') {
          final request = _approvalRequestFromEvent(event);
          if (request.id.isEmpty) {
            terminalRunEventReceived = true;
            streamFailed = true;
            assistantTurn = assistantTurn.copyWith(
              status: HermesTurnStatus.failed,
            );
            turns[assistantIndex] = assistantTurn;
            _setTurns(
              sessionId,
              List.of(turns),
              errorMessage:
                  'Hermes approval request was missing an approval id.',
            );
            if (!completer.isCompleted) completer.complete();
            return;
          }
          _approvalController.add(request);
          return;
        }
        if (_isStreamErrorEvent(event.name)) {
          terminalRunEventReceived = true;
          streamFailed = true;
          assistantTurn = assistantTurn.copyWith(
            status: HermesTurnStatus.failed,
          );
          turns[assistantIndex] = assistantTurn;
          _setTurns(
            sessionId,
            List.of(turns),
            errorMessage: _streamErrorMessage(event),
          );
          if (!completer.isCompleted) completer.complete();
          return;
        }
        if (_isSuccessfulTerminalRunEvent(event.name)) {
          terminalRunEventReceived = true;
          if (!completer.isCompleted) completer.complete();
          return;
        }
        if (_isFailedTerminalRunEvent(event.name)) {
          terminalRunEventReceived = true;
          streamFailed = true;
          assistantTurn = assistantTurn.copyWith(
            status: HermesTurnStatus.failed,
          );
          turns[assistantIndex] = assistantTurn;
          _setTurns(
            sessionId,
            List.of(turns),
            errorMessage: _isCancelledTerminalRunEvent(event.name)
                ? 'Hermes run was cancelled.'
                : 'Hermes run failed.',
          );
          if (!completer.isCompleted) completer.complete();
        }
      },
      onError: (Object error) {
        if (streamGeneration != _streamGeneration || terminalRunEventReceived) {
          return;
        }
        streamFailed = true;
        streamEndedBeforeTerminal = true;
        assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
        turns[assistantIndex] = assistantTurn;
        _setTurns(
          sessionId,
          List.of(turns),
          errorMessage: _safeHermesError(error),
        );
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (streamGeneration != _streamGeneration) return;
        if (!terminalRunEventReceived) {
          streamFailed = true;
          streamEndedBeforeTerminal = true;
          assistantTurn = assistantTurn.copyWith(
            status: HermesTurnStatus.failed,
          );
          turns[assistantIndex] = assistantTurn;
          _setTurns(
            sessionId,
            List.of(turns),
            errorMessage: 'Hermes stream closed before a terminal event.',
          );
        }
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    await completer.future;
    if (streamGeneration != _streamGeneration) {
      return;
    }
    if (terminalRunEventReceived) {
      unawaited(_activeStream?.cancel() ?? Future<void>.value());
    }
    final stoppedLocally = _activeTurnStopped;
    if (identical(_activeStreamCompleter, completer)) {
      _activeStreamCompleter = null;
      _activeTurnStopped = false;
    }
    _activeStream = null;
    _activeRunId = null;
    if (!identical(_client, client) ||
        _state.status != HermesConnectionStatus.connected ||
        _state.activeSessionId != sessionId) {
      return;
    }
    if (assistantTurn.status == HermesTurnStatus.streaming) {
      assistantTurn = stoppedLocally
          ? assistantTurn.copyWith(
              status: HermesTurnStatus.failed,
              text: assistantTurn.text.isEmpty
                  ? 'Stopped.'
                  : assistantTurn.text,
            )
          : assistantTurn.copyWith(status: HermesTurnStatus.completed);
      turns[assistantIndex] = assistantTurn;
      _setTurns(sessionId, List.of(turns));
    }

    if (streamFailed && streamEndedBeforeTerminal && !stoppedLocally) {
      try {
        final serverTurns = await _fetchTurns(client, sessionId);
        if (_serverHistoryHasAssistantReplyForCurrentTurn(
          serverTurns,
          message,
          preSendTurnCount,
        )) {
          _setTurns(sessionId, serverTurns, clearErrorMessage: true);
          return;
        }
      } catch (_) {
        // Keep the local failed partial transcript; recovery is best-effort.
      }
    }

    if (!streamFailed && !stoppedLocally) {
      try {
        final serverTurns = await _fetchTurns(client, sessionId);
        if (!_serverHistoryDropsStreamedAssistant(
          serverTurns,
          assistantTurn,
          message,
          preSendTurnCount,
        )) {
          _setTurns(sessionId, serverTurns);
        }
      } catch (_) {
        // Keep the locally streamed transcript; reconciliation is best-effort.
      }
    }
  }

  String? _streamDelta(HermesStreamEvent event) {
    if (!_isDeltaEvent(event.name)) return null;
    return _rawStreamText(event.payload['delta']) ??
        _rawStreamText(event.payload['content']) ??
        _rawStreamText(event.payload['text']);
  }

  String? _rawStreamText(Object? value) {
    if (value is String) return value.isEmpty ? null : value;
    return navivoxOptionalStringFromJson(value);
  }

  bool _isDeltaEvent(String name) {
    return name == 'message' ||
        name == 'message.delta' ||
        name == 'assistant.delta';
  }

  bool _serverHistoryDropsStreamedAssistant(
    List<HermesChatTurn> serverTurns,
    HermesChatTurn localAssistantTurn,
    String sentMessage,
    int preSendTurnCount,
  ) {
    if (localAssistantTurn.text.trim().isEmpty) return false;
    return !_serverHistoryHasAssistantReplyForCurrentTurn(
      serverTurns,
      sentMessage,
      preSendTurnCount,
    );
  }

  bool _serverHistoryHasAssistantReplyForCurrentTurn(
    List<HermesChatTurn> serverTurns,
    String sentMessage,
    int preSendTurnCount,
  ) {
    final normalizedMessage = sentMessage.trim();
    if (normalizedMessage.isNotEmpty) {
      for (var index = serverTurns.length - 1; index >= 0; index--) {
        final turn = serverTurns[index];
        if (turn.author != HermesTurnAuthor.user ||
            turn.text.trim() != normalizedMessage ||
            index < preSendTurnCount) {
          continue;
        }
        return _hasAssistantReplyAfter(serverTurns, index);
      }
    }
    if (serverTurns.length <= preSendTurnCount) return false;
    return _hasAssistantReplyAfter(serverTurns, preSendTurnCount - 1);
  }

  bool _hasAssistantReplyAfter(List<HermesChatTurn> serverTurns, int index) {
    for (final candidate in serverTurns.skip(index + 1)) {
      if (candidate.author == HermesTurnAuthor.user) return false;
      if (candidate.author == HermesTurnAuthor.assistant &&
          candidate.text.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _isStreamErrorEvent(String name) {
    return name == 'error' ||
        name == 'stream.error' ||
        name == 'run.error' ||
        name == 'assistant.error' ||
        name == 'message.error';
  }

  String _streamErrorMessage(HermesStreamEvent event) {
    final detail = _streamErrorDetail(event.payload);
    if (detail == null || detail.trim().isEmpty) {
      return 'Hermes stream reported an error.';
    }
    return 'Hermes stream reported an error: ${_safeHermesError(detail)}';
  }

  String? _streamErrorDetail(Map<String, Object?> payload) {
    final topLevel =
        navivoxOptionalStringFromJson(payload['message']) ??
        navivoxOptionalStringFromJson(payload['detail']);
    if (topLevel != null) return topLevel;
    final nested = navivoxMapFromJson(payload['error']);
    if (nested.isNotEmpty) {
      final code = navivoxOptionalStringFromJson(nested['code']);
      final message =
          navivoxOptionalStringFromJson(nested['message']) ??
          navivoxOptionalStringFromJson(nested['detail']);
      if (code != null && message != null) return '$code: $message';
      return message ?? code;
    }
    return navivoxOptionalStringFromJson(payload['error']);
  }

  bool _isSuccessfulTerminalRunEvent(String name) {
    return name == 'run.completed' ||
        name == 'assistant.completed' ||
        name == 'message.completed';
  }

  bool _isFailedTerminalRunEvent(String name) {
    return name == 'run.failed' ||
        name == 'assistant.failed' ||
        name == 'message.failed' ||
        _isCancelledTerminalRunEvent(name);
  }

  bool _isCancelledTerminalRunEvent(String name) {
    return name == 'run.cancelled' ||
        name == 'assistant.cancelled' ||
        name == 'message.cancelled';
  }

  bool _isToolEvent(String name) {
    return name == 'tool.started' ||
        name == 'tool.progress' ||
        name == 'tool.completed' ||
        name == 'tool.failed';
  }

  /// Tracks tool progress by a `${runId}:${eventCallId}` call id when Hermes
  /// supplies one, falling back to `${runId}:${toolName}` for older events: the
  /// first event for a call id inserts a new turn just before the assistant
  /// reply; later events for the same call id update that turn in place instead
  /// of duplicating it.
  void _applyToolEvent({
    required String sessionId,
    required HermesStreamEvent event,
    required List<HermesChatTurn> turns,
    required Map<String, int> toolTurnIndexByCallId,
    required int insertBefore,
  }) {
    final toolName =
        navivoxOptionalStringFromJson(event.payload['tool']) ??
        navivoxOptionalStringFromJson(event.payload['tool_name']) ??
        'tool';
    final status = switch (event.name) {
      'tool.completed' => 'completed',
      'tool.failed' => 'failed',
      _ => 'running',
    };
    final preview = navivoxOptionalStringFromJson(event.payload['preview']);
    final result =
        navivoxOptionalStringFromJson(event.payload['result_text']) ??
        navivoxOptionalStringFromJson(event.payload['output']) ??
        navivoxOptionalStringFromJson(event.payload['result']);
    final eventCallId =
        navivoxOptionalStringFromJson(event.payload['tool_call_id']) ??
        navivoxOptionalStringFromJson(event.payload['call_id']) ??
        navivoxOptionalStringFromJson(event.payload['id']);
    final callId = eventCallId == null || eventCallId.trim().isEmpty
        ? '$_activeRunId:$toolName'
        : '$_activeRunId:${eventCallId.trim()}';

    final existingIndex = toolTurnIndexByCallId[callId];
    if (existingIndex != null) {
      final existing = turns[existingIndex];
      turns[existingIndex] = existing.copyWith(
        toolCall: existing.toolCall!.copyWith(
          status: status,
          preview: preview,
          result: result,
        ),
      );
      return;
    }
    final turn = HermesChatTurn(
      id: 'tool-$callId',
      sessionId: sessionId,
      author: HermesTurnAuthor.system,
      createdAt: DateTime.now(),
      kind: HermesTurnKind.toolCall,
      toolCall: HermesToolCall(
        name: toolName,
        status: status,
        preview: preview,
        result: result,
      ),
    );
    turns.insert(insertBefore, turn);
    toolTurnIndexByCallId[callId] = insertBefore;
  }

  NavivoxApprovalRequest _approvalRequestFromEvent(HermesStreamEvent event) {
    return NavivoxApprovalRequest(
      id:
          navivoxOptionalStringFromJson(event.payload['approval_id']) ??
          navivoxOptionalStringFromJson(event.payload['approvalId']) ??
          navivoxOptionalStringFromJson(event.payload['id']) ??
          '',
      toolCallId:
          navivoxOptionalStringFromJson(event.payload['tool_call_id']) ??
          navivoxOptionalStringFromJson(event.payload['toolCallId']) ??
          '',
      prompt:
          navivoxOptionalStringFromJson(event.payload['prompt']) ??
          'Approval requested',
      risk: navivoxOptionalStringFromJson(event.payload['risk']),
    );
  }

  void _setTurns(
    String sessionId,
    List<HermesChatTurn> turns, {
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    _setState(
      _state.copyWith(
        messages: {..._state.messages, sessionId: turns},
        errorMessage: errorMessage,
        clearErrorMessage: clearErrorMessage,
      ),
    );
  }

  @override
  void cancelActiveTurn() {
    _finishActiveTurnLocally();
  }

  @override
  void stopActiveTurn() {
    final client = _client;
    final runId = _activeRunId;
    _finishActiveTurnLocally();
    final capabilities = _state.capabilities;
    final canStopRun = capabilities == null
        ? true
        : HermesTransportPolicy(capabilities).supportsRunStop;
    if (client != null && runId != null && canStopRun) {
      unawaited(client.stopRun(runId).catchError((_) {}));
    }
  }

  void _finishActiveTurnLocally() {
    _activeTurnStopped = true;
    _streamGeneration += 1;
    _markActiveStreamingTurnStopped();
    unawaited(_activeStream?.cancel() ?? Future<void>.value());
    _activeStream = null;
    _activeRunId = null;
    final completer = _activeStreamCompleter;
    _activeStreamCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _markActiveStreamingTurnStopped() {
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
    _setTurns(sessionId, turns);
  }

  @override
  Future<void> respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
  }) async {
    final client = _client;
    final runId = _activeRunId;
    if (client == null || runId == null) {
      const message =
          'Could not answer approval: active run is no longer available.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
    final trimmedApprovalId = approvalId.trim();
    if (trimmedApprovalId.isEmpty) {
      const message = 'Could not answer approval: approval id is missing.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
    final capabilities = _state.capabilities;
    if (capabilities != null &&
        !HermesTransportPolicy(capabilities).supportsRunApprovalResponse) {
      const message =
          'Could not answer approval: Hermes did not advertise approval responses for this run.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
    try {
      await client.respondApproval(
        runId: runId,
        approvalId: trimmedApprovalId,
        decision: decision.name,
      );
    } catch (error) {
      if (!identical(_client, client) || _activeRunId != runId) return;
      _setState(
        _state.copyWith(
          errorMessage: 'Could not answer approval: ${_safeHermesError(error)}',
        ),
      );
      rethrow;
    }
  }

  @override
  String startVoiceRun() {
    final id = 'voice-${_uuid.v4()}';
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
    if (run == null || run.isTerminal || transcript == null) {
      return;
    }
    final trimmedTranscript = transcript.trim();
    if (trimmedTranscript.isEmpty) {
      _updateVoiceRun(run.markFailed('Hermes voice transcript was empty.'));
      return;
    }
    final submittedSessionId = _state.activeSessionId;
    final capabilities = _state.capabilities;
    if (submittedSessionId == null) {
      _updateVoiceRun(
        run.markFailed('Hermes channel is not connected to a session.'),
      );
      return;
    }
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
      run.markSubmitted(requestId: voiceRunId, sessionId: submittedSessionId),
    );
    sendText(trimmedTranscript)
        .then((_) {
          final current = _state.voiceRuns[voiceRunId];
          if (current == null || current.isTerminal) return;
          if (current.sessionId != submittedSessionId ||
              _state.activeSessionId != submittedSessionId) {
            _updateVoiceRun(
              current.markFailed(
                'Hermes session changed before voice turn completed.',
              ),
            );
            return;
          }
          final assistantTurns =
              (_state.messages[submittedSessionId] ?? const []).where(
                (turn) => turn.author == HermesTurnAuthor.assistant,
              );
          final assistantReply = assistantTurns.lastOrNull;
          if (assistantReply == null ||
              assistantReply.status == HermesTurnStatus.failed ||
              assistantReply.text.trim().isEmpty) {
            _updateVoiceRun(
              current.markFailed('Hermes voice turn did not complete.'),
            );
            return;
          }
          _updateVoiceRun(current.markCompleted());
        })
        .catchError((Object error) {
          final current = _state.voiceRuns[voiceRunId];
          if (current != null && !current.isTerminal) {
            _updateVoiceRun(current.markFailed(_safeHermesError(error)));
          }
        });
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

String _safeHermesError(Object error) {
  var text = error.toString();
  text = text.replaceAllMapped(
    RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Bearer [redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(r'Basic\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Basic [redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'((?:Cookie|Set-Cookie|X-API-Key|X-Auth-Token)\s*[:=]\s*)[^\n\r,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(r'([a-z][a-z0-9+.-]*://)([^/\s@]+@)', caseSensitive: false),
    (match) => '${match[1]}[redacted]@',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'(api[-_ ]?key|token|secret|password|passwd|pwd|credential|credentials|auth)(\s*(?:=|:)\s*)[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}${match[2]}[redacted]',
  );
  text = text
      .replaceAll(
        RegExp(r'sk-[a-z0-9_-]{12,}', caseSensitive: false),
        'sk-[redacted]',
      )
      .replaceAll(
        RegExp(r'gh[pousr]_[a-z0-9_]{20,}', caseSensitive: false),
        'ghp_[redacted]',
      )
      .replaceAll(
        RegExp(r'xox[abprs]-[a-z0-9-]{20,}', caseSensitive: false),
        'xox-[redacted]',
      )
      .replaceAll(
        RegExp(
          r'eyJ[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}',
          caseSensitive: false,
        ),
        '[redacted-jwt]',
      )
      .replaceAll(
        RegExp(r'secret[-_a-z0-9.]*', caseSensitive: false),
        '[redacted]',
      );
  if (text.length <= 240) return text;
  return '${text.substring(0, 240).trimRight()}…';
}
