part of '../hermes_api_channel.dart';

extension _SessionsExtension on HermesApiChannel {
  Future<void> _disconnect() async {
    _client = null;
    _connectionGeneration += 1;
    _sessionSelectionGeneration += 1;
    _invalidateProfileSelection();
    _deletingSessionOperations.clear();
    _forkingSessionOperations.clear();
    _clearActiveRunTracking();
    _setState(const HermesChannelState());
  }

  Future<void> _selectSession(String sessionId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    _requireKnownSession(sessionId);
    final selectionGeneration = ++_sessionSelectionGeneration;
    final connectionGeneration = _connectionGeneration;
    final profileId = _state.selectedProfileId;
    final baseUrl = _state.connectedBaseUrl;
    final capabilities = _state.capabilities;
    bool isCurrentSelection() =>
        selectionGeneration == _sessionSelectionGeneration &&
        _isCurrentConnection(connectionGeneration, client) &&
        _state.selectedProfileId == profileId;
    final detachedRunStillActive = baseUrl != null && capabilities != null
        ? await _recoverDetachedRun(
            client: client,
            capabilities: capabilities,
            baseUrl: baseUrl,
            profileId: profileId,
            sessionId: sessionId,
          )
        : false;
    if (!isCurrentSelection()) return;
    final List<HermesChatTurn> turns;
    try {
      turns = _state.isSessionStreaming(sessionId)
          ? List<HermesChatTurn>.from(_state.messages[sessionId] ?? const [])
          : await _fetchTurns(client, sessionId, profileId: profileId);
    } catch (_) {
      if (!isCurrentSelection()) return;
      rethrow;
    }
    if (!isCurrentSelection()) return;
    _setState(
      _state.copyWith(
        activeSessionId: sessionId,
        hasUnreconciledRun: detachedRunStillActive,
        errorMessage: detachedRunStillActive
            ? 'Hermes run is still active. Reconnect later before retrying.'
            : null,
        clearErrorMessage: !detachedRunStillActive,
        messages: {..._state.messages, sessionId: turns},
      ),
    );
    if (detachedRunStillActive) {
      unawaited(
        _reattachDetachedRun(
          client: client,
          baseUrl: baseUrl,
          profileId: profileId,
          sessionId: sessionId,
        ),
      );
    }
  }

  Future<void> _createSession({String? title}) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    final profileId = _state.selectedProfileId;
    _requireAdvertisedEndpoint(
      'session_create',
      'POST',
      '/api/sessions',
      'create sessions',
    );
    final created = await client.createSession(
      id: _sessionIdFactory(),
      title: title,
      profile: profileId,
    );
    if (!_isConnectedProfile(client, profileId)) return;
    final turns = await _fetchTurns(client, created.id, profileId: profileId);
    if (!_isConnectedProfile(client, profileId)) return;
    _setState(
      _state.copyWith(
        sessions: [..._state.sessions, created],
        activeSessionId: created.id,
        hasUnreconciledRun: _sessionHasDetachedRun(
          sessionId: created.id,
          profileId: profileId,
        ),
        clearErrorMessage: true,
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
    final profileId = _state.selectedProfileId;
    _requireAdvertisedEndpoint(
      'session_update',
      'PATCH',
      '/api/sessions/{session_id}',
      'rename sessions',
    );
    _requireKnownSession(sessionId);
    final updated = await client.updateSessionTitle(
      sessionId,
      title: trimmed,
      profile: profileId,
    );
    if (!_isConnectedProfile(client, profileId)) return;
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
    final profileId = _state.selectedProfileId;
    _requireAdvertisedEndpoint(
      'session_delete',
      'DELETE',
      '/api/sessions/{session_id}',
      'delete sessions',
    );
    _requireKnownSession(sessionId);
    if (_deletingSessionOperations.containsKey(sessionId)) {
      throw StateError('Hermes session delete is already in progress.');
    }
    final operation = Object();
    _deletingSessionOperations[sessionId] = operation;
    _finishSessionTurnLocally(sessionId);
    try {
      await client.deleteSession(sessionId, profile: profileId);
      if (!_isConnectedProfile(client, profileId)) return;
      final remaining = [
        for (final session in _state.sessions)
          if (session.id != sessionId) session,
      ];
      final deletingCurrentSession = _state.activeSessionId == sessionId;
      final nextActiveId = deletingCurrentSession
          ? remaining.firstOrNull?.id
          : _state.activeSessionId;
      final messages = Map<String, List<HermesChatTurn>>.from(_state.messages)
        ..remove(sessionId);
      if (deletingCurrentSession &&
          nextActiveId != null &&
          !messages.containsKey(nextActiveId)) {
        try {
          messages[nextActiveId] = await _fetchTurns(
            client,
            nextActiveId,
            profileId: profileId,
          );
        } catch (_) {
          messages[nextActiveId] = const [];
        }
      }
      if (!_isConnectedProfile(client, profileId)) return;
      _setState(
        _state.copyWith(
          sessions: remaining,
          activeSessionId: nextActiveId,
          clearActiveSessionId: nextActiveId == null,
          hasUnreconciledRun: _sessionHasDetachedRun(
            sessionId: nextActiveId,
            profileId: profileId,
          ),
          messages: messages,
        ),
      );
    } finally {
      if (identical(_deletingSessionOperations[sessionId], operation)) {
        _deletingSessionOperations.remove(sessionId);
      }
    }
  }

  Future<void> _forkSession(String sessionId, {String? title}) async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    final profileId = _state.selectedProfileId;
    _requireAdvertisedEndpoint(
      'session_fork',
      'POST',
      '/api/sessions/{session_id}/fork',
      'fork sessions',
    );
    _requireKnownSession(sessionId);
    if (_state.isSessionStreaming(sessionId)) {
      throw StateError(
        'Hermes cannot branch a session while its reply is active.',
      );
    }
    if (_forkingSessionOperations.containsKey(sessionId)) {
      throw StateError('Hermes session branching is already in progress.');
    }
    final operation = Object();
    _forkingSessionOperations[sessionId] = operation;
    try {
      final inheritedTurns = List<HermesChatTurn>.from(
        _state.messages[sessionId] ?? const [],
      );
      final fork = await client.forkSession(
        sessionId,
        id: _sessionIdFactory(),
        title: title,
        profile: profileId,
      );
      if (!_isConnectedProfile(client, profileId)) return;
      List<HermesChatTurn> turns;
      try {
        turns = await _fetchTurns(client, fork.id, profileId: profileId);
      } catch (_) {
        // The fork mutation is already durable on Hermes. Keep the accepted
        // child visible and inherit the locally loaded source transcript rather
        // than reporting a failure that could prompt a duplicate retry.
        turns = inheritedTurns;
      }
      if (!_isConnectedProfile(client, profileId)) return;
      _setState(
        _state.copyWith(
          sessions: [..._state.sessions, fork],
          activeSessionId: fork.id,
          hasUnreconciledRun: _sessionHasDetachedRun(
            sessionId: fork.id,
            profileId: profileId,
          ),
          clearErrorMessage: true,
          messages: {..._state.messages, fork.id: turns},
        ),
      );
    } finally {
      if (identical(_forkingSessionOperations[sessionId], operation)) {
        _forkingSessionOperations.remove(sessionId);
      }
    }
  }

  void _requireAdvertisedEndpoint(
    String name,
    String method,
    String path,
    String action,
  ) {
    final capabilities = _state.capabilities;
    if (capabilities == null) return;
    final endpoint = capabilities.endpoints[name];
    if (!capabilities.supportsSchema ||
        !capabilities.advertisesEndpoint(name, method, path) ||
        endpoint == null ||
        endpoint.requiredScopes.any(
          (scope) => !capabilities.auth.allows(scope),
        )) {
      throw StateError(
        'Hermes did not advertise authorized support to $action.',
      );
    }
  }

  void _requireKnownSession(String sessionId) {
    if (!_state.sessions.any((session) => session.id == sessionId)) {
      throw StateError('Hermes session is not in the current session list.');
    }
  }
}
