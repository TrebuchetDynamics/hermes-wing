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

  Future<bool> _restoreSession(
    String sessionId, {
    bool Function()? canAccept,
  }) async {
    final client = _requireConnectedClient();
    final profileId = _state.selectedProfileId;
    final profileGuard = _profileRequestGuard(client, profileId);
    clearActiveSession();
    final selectionGeneration = _sessionSelectionGeneration;
    bool owned() => profileGuard() && (canAccept?.call() ?? true);
    bool currentMetadata() =>
        owned() && selectionGeneration == _sessionSelectionGeneration;
    if (!currentMetadata()) return false;
    final capabilities = _state.capabilities;
    final known = _state.sessions.any((session) => session.id == sessionId);
    bool authorized(String name, String path) =>
        capabilities != null &&
        _capabilityEndpointAuthorized(capabilities, name, 'GET', path) &&
        (capabilities.endpoints[name]?.profileScoped != true ||
            capabilities.profileContext.isSupportedQueryContext ||
            client.config.pathProfileId != null);
    if (!authorized(
          'session_messages',
          '/api/sessions/{session_id}/messages',
        ) ||
        (!known && !authorized('session', '/api/sessions/{session_id}'))) {
      throw const HermesSessionRestorationUnsupported();
    }
    if (!known) {
      final session = await client.getSession(sessionId, profile: profileId);
      if (!currentMetadata()) return false;
      _setState(_state.copyWith(sessions: [..._state.sessions, session]));
      // A synchronous listener may explicitly choose a session on admission.
      if (!currentMetadata()) return false;
    }
    final historyGeneration = _sessionSelectionGeneration + 1;
    await _selectSession(sessionId, canAccept: owned);
    return owned() &&
        historyGeneration == _sessionSelectionGeneration &&
        _state.activeSessionId == sessionId;
  }

  Future<void> _selectSession(
    String sessionId, {
    bool Function()? canAccept,
  }) async {
    if (!(canAccept?.call() ?? true)) return;
    _requireStableProfile();
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    _requireKnownSession(sessionId);
    final selectionGeneration = ++_sessionSelectionGeneration;
    final connectionGeneration = _connectionGeneration;
    final profileSelectionGeneration = _profileSelectionGeneration;
    final profileId = _state.selectedProfileId;
    final baseUrl = _state.connectedBaseUrl;
    final capabilities = _state.capabilities;
    bool isCurrentSelection() =>
        selectionGeneration == _sessionSelectionGeneration &&
        profileSelectionGeneration == _profileSelectionGeneration &&
        _isCurrentConnection(connectionGeneration, client) &&
        _state.selectedProfileId == profileId &&
        (canAccept?.call() ?? true);
    final detachedRunStillActive = baseUrl != null && capabilities != null
        ? await _recoverDetachedRun(
            client: client,
            capabilities: capabilities,
            baseUrl: baseUrl,
            profileId: profileId,
            sessionId: sessionId,
            canAccept: isCurrentSelection,
          )
        : false;
    if (!isCurrentSelection()) return;
    final transcriptAtStart = _state.messages[sessionId];
    bool canAcceptHistory() =>
        isCurrentSelection() &&
        identical(_state.messages[sessionId], transcriptAtStart);
    final List<HermesChatTurn> turns;
    try {
      turns = _state.isSessionStreaming(sessionId)
          ? List<HermesChatTurn>.from(_state.messages[sessionId] ?? const [])
          : await _fetchTurns(
              client,
              sessionId,
              profileId: profileId,
              canAccept: canAcceptHistory,
            );
    } catch (_) {
      if (!canAcceptHistory()) return;
      rethrow;
    }
    if (!canAcceptHistory()) return;
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

  Future<void> _loadEarlierMessages() async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    final sessionId = _state.activeSessionId;
    if (sessionId == null ||
        !_state.sessionsWithEarlierMessages.contains(sessionId) ||
        _state.sessionsLoadingEarlierMessages.contains(sessionId)) {
      return;
    }

    final generation = _connectionGeneration;
    final profileSelectionGeneration = _profileSelectionGeneration;
    final profileId = _state.selectedProfileId;
    final offset = _state.messageHistoryNextOffsets[sessionId] ?? 0;
    bool isCurrentRequest() =>
        _isCurrentConnection(generation, client) &&
        _profileSelectionGeneration == profileSelectionGeneration &&
        _state.selectedProfileId == profileId &&
        _state.sessions.any((session) => session.id == sessionId);

    _setState(
      _state.copyWith(
        sessionsLoadingEarlierMessages: {
          ..._state.sessionsLoadingEarlierMessages,
          sessionId,
        },
        clearErrorMessage: true,
      ),
    );
    try {
      _requireHistoryRead(client, _state.capabilities);
      final page = await client.sessionMessagesPage(
        sessionId,
        profile: profileId,
        offset: offset,
      );
      if (!isCurrentRequest()) return;
      if (page.offset != offset || page.order != 'latest') {
        throw StateError('Hermes returned unexpected message pagination.');
      }
      final cacheKey = _recentTurnKey(client, sessionId, profileId: profileId);
      const maxLoadedHistoryMessages = 5000;
      final existingTurns = _state.messages[sessionId] ?? const [];
      final olderTurns = _turnsFromHistory(
        page.messages,
        sessionId: sessionId,
        unmatched: List.of(existingTurns),
        fetchedAt: DateTime.now(),
      );
      final existingTurnIds = {
        for (final turn in existingTurns)
          if (turn.id.isNotEmpty) turn.id,
      };
      final mergedTurns = [
        for (final turn in olderTurns)
          if (turn.id.isEmpty || existingTurnIds.add(turn.id)) turn,
        ...existingTurns,
      ];

      final existingHistory =
          _runHistorySnapshots[cacheKey]?.messages ?? const <HermesMessage>[];
      final existingMessageIds = {
        for (final message in existingHistory)
          if (message.id.isNotEmpty) message.id,
      };
      final mergedHistory = [
        for (final message in page.messages)
          if (message.id.isEmpty || existingMessageIds.add(message.id)) message,
        ...existingHistory,
      ];
      _runHistorySnapshots.remove(cacheKey);
      _runHistorySnapshots[cacheKey] = _HermesRunHistorySnapshot(
        mergedHistory.length <= maxLoadedHistoryMessages
            ? mergedHistory
            : mergedHistory.sublist(
                mergedHistory.length - maxLoadedHistoryMessages,
              ),
      );
      _messageHistoryPagination[cacheKey] = _HermesMessageHistoryPagination(
        nextOffset: page.nextOffset,
        hasMore: page.hasMore && page.nextOffset < maxLoadedHistoryMessages,
      );
      _setState(
        _state.copyWith(
          messages: {..._state.messages, sessionId: mergedTurns},
          sessionsLoadingEarlierMessages: {
            ..._state.sessionsLoadingEarlierMessages,
          }..remove(sessionId),
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      if (!isCurrentRequest()) return;
      _setState(
        _state.copyWith(
          sessionsLoadingEarlierMessages: {
            ..._state.sessionsLoadingEarlierMessages,
          }..remove(sessionId),
          errorMessage: _safeHermesError(error),
        ),
      );
    }
  }

  Future<void> _loadMoreSessions() async {
    final client = _client;
    if (client == null) {
      throw StateError('Hermes channel is not connected.');
    }
    if (!_state.hasMoreSessions || _state.isLoadingMoreSessions) return;

    final generation = _connectionGeneration;
    final profileSelectionGeneration = _profileSelectionGeneration;
    final profileId = _state.selectedProfileId;
    final offset = _state.sessionsNextOffset;
    bool isCurrentRequest() =>
        _isCurrentConnection(generation, client) &&
        _profileSelectionGeneration == profileSelectionGeneration &&
        _state.selectedProfileId == profileId;

    _setState(
      _state.copyWith(isLoadingMoreSessions: true, clearErrorMessage: true),
    );
    try {
      final page = await client.listSessionsPage(
        profile: profileId,
        offset: offset,
      );
      if (!isCurrentRequest()) return;
      if (page.offset != offset) {
        throw StateError('Hermes returned an unexpected session page offset.');
      }
      final knownIds = _state.sessions.map((session) => session.id).toSet();
      final additional = page.sessions
          .where((session) => knownIds.add(session.id))
          .toList(growable: false);
      _setState(
        _state.copyWith(
          sessions: [..._state.sessions, ...additional],
          sessionsNextOffset: page.nextOffset,
          hasMoreSessions: page.hasMore,
          isLoadingMoreSessions: false,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      if (!isCurrentRequest()) return;
      _setState(
        _state.copyWith(
          isLoadingMoreSessions: false,
          errorMessage: _safeHermesError(error),
        ),
      );
    }
  }

  Future<void> _createSession({
    String? title,
    bool Function()? canAccept,
  }) async {
    if (!(canAccept?.call() ?? true)) return;
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
    final requestedId = _sessionIdFactory();
    final previousSessionId = _state.activeSessionId;
    final profileGuard = _profileRequestGuard(client, profileId);
    bool isCurrentContext() => profileGuard() && (canAccept?.call() ?? true);
    // New-chat intent ends the previous send target immediately. Keep the new
    // target unavailable until its initial history is ready for submission.
    clearActiveSession();
    final selectionGeneration = _sessionSelectionGeneration;
    bool isCurrentSelection() =>
        isCurrentContext() &&
        selectionGeneration == _sessionSelectionGeneration;
    // Clearing selection notifies synchronous listeners before the write.
    if (!isCurrentSelection()) return;
    final HermesSession created;
    try {
      created = await client.createSession(
        id: requestedId,
        title: title,
        profile: profileId,
      );
    } catch (_) {
      if (isCurrentSelection() &&
          _state.sessions.any((session) => session.id == previousSessionId)) {
        _setState(_state.copyWith(activeSessionId: previousSessionId));
      }
      rethrow;
    }
    if (!isCurrentContext()) return;
    var turns = const <HermesChatTurn>[];
    String? historyError;
    if (isCurrentSelection()) {
      try {
        turns = await _fetchTurns(
          client,
          created.id,
          profileId: profileId,
          canAccept: isCurrentSelection,
        );
      } catch (error) {
        historyError =
            'Hermes session was created, but its history could not be loaded: '
            '${_safeHermesError(error)}';
      }
    }
    if (!isCurrentContext()) return;
    final selectCreated = isCurrentSelection();
    _setState(
      _state.copyWith(
        sessions: [
          ..._state.sessions,
          if (!_state.sessions.any((session) => session.id == created.id))
            created,
        ],
        activeSessionId: selectCreated ? created.id : null,
        hasUnreconciledRun: selectCreated
            ? _sessionHasDetachedRun(
                sessionId: created.id,
                profileId: profileId,
              )
            : null,
        errorMessage: selectCreated ? historyError : null,
        clearErrorMessage: selectCreated && historyError == null,
        messages: {
          ..._state.messages,
          if (!_state.messages.containsKey(created.id)) created.id: turns,
        },
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
    final isCurrentContext = _profileRequestGuard(client, profileId);
    final operation = Object();
    _renamingSessionOperations[sessionId] = operation;
    try {
      final updated = await client.updateSessionTitle(
        sessionId,
        title: trimmed,
        profile: profileId,
      );
      if (!isCurrentContext() ||
          !identical(_renamingSessionOperations[sessionId], operation)) {
        return;
      }
      _setState(
        _state.copyWith(
          sessions: [
            for (final session in _state.sessions)
              if (session.id == updated.id) updated else session,
          ],
        ),
      );
    } finally {
      if (identical(_renamingSessionOperations[sessionId], operation)) {
        _renamingSessionOperations.remove(sessionId);
      }
    }
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
    final isCurrentContext = _profileRequestGuard(client, profileId);
    if (_deletingSessionOperations.containsKey(sessionId)) {
      throw StateError('Hermes session delete is already in progress.');
    }
    final operation = Object();
    _deletingSessionOperations[sessionId] = operation;
    _finishSessionTurnLocally(sessionId);
    try {
      await client.deleteSession(sessionId, profile: profileId);
      if (!isCurrentContext()) return;
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
      final needsHistory =
          deletingCurrentSession &&
          nextActiveId != null &&
          !messages.containsKey(nextActiveId);
      final selectionGeneration = _sessionSelectionGeneration;
      final profileSelectionGeneration = _profileSelectionGeneration;
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
      if (needsHistory) {
        List<HermesChatTurn> turns;
        try {
          turns = await _fetchTurns(client, nextActiveId, profileId: profileId);
        } catch (_) {
          turns = const [];
        }
        // Deletion is already authoritative; delayed history must not restore
        // a snapshot over a newer selection, mutation, or streamed response.
        if (!_isConnectedProfile(client, profileId) ||
            profileSelectionGeneration != _profileSelectionGeneration ||
            selectionGeneration != _sessionSelectionGeneration ||
            _state.activeSessionId != nextActiveId ||
            !_state.sessions.any((session) => session.id == nextActiveId) ||
            _state.messages.containsKey(nextActiveId)) {
          return;
        }
        _setState(
          _state.copyWith(messages: {..._state.messages, nextActiveId: turns}),
        );
      }
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
    final isCurrentContext = _profileRequestGuard(client, profileId);
    final selectionGeneration = ++_sessionSelectionGeneration;
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
      if (!isCurrentContext()) return;
      List<HermesChatTurn> turns;
      try {
        turns = await _fetchTurns(client, fork.id, profileId: profileId);
      } catch (_) {
        // The fork mutation is already durable on Hermes. Keep the accepted
        // child visible and inherit the locally loaded source transcript rather
        // than reporting a failure that could prompt a duplicate retry.
        turns = inheritedTurns;
      }
      if (!isCurrentContext()) return;
      final selectFork = selectionGeneration == _sessionSelectionGeneration;
      _setState(
        _state.copyWith(
          sessions: [..._state.sessions, fork],
          activeSessionId: selectFork ? fork.id : null,
          hasUnreconciledRun: selectFork
              ? _sessionHasDetachedRun(sessionId: fork.id, profileId: profileId)
              : null,
          clearErrorMessage: selectFork,
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
