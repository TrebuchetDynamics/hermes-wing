part of '../hermes_api_channel.dart';

extension _SessionsExtension on HermesApiChannel {
  Future<void> _disconnect() async {
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

  Future<void> _selectSession(String sessionId) async {
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

  Future<void> _createSession({String? title}) async {
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

  Future<void> _renameSession({
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

  Future<void> _deleteSession(String sessionId) async {
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

  Future<void> _forkSession(String sessionId, {String? title}) async {
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
}
