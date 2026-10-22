part of '../hermes_api_channel.dart';

extension _ServeReadsExtension on HermesApiChannel {
  Future<void> _connectServeReads(
    String baseUrl,
    String credential, {
    bool Function()? canAccept,
    String profile = 'default',
    String? storedSession,
    bool transient = false,
    bool deferSessionSelection = false,
    void Function(bool Function() isCurrent)? onAcquire,
    bool uncertain = false,
    bool remoteGateway = false,
    Future<void> Function(HermesWebRecovery)? persistRecovery,
  }) async {
    if (!(canAccept?.call() ?? true)) return;
    final generation = _connectionGeneration + 1;
    final recovery = _serveRecoveryGeneration;
    onAcquire?.call(
      () =>
          generation == _connectionGeneration &&
          recovery == _serveRecoveryGeneration,
    );
    final disconnected = _disconnect();
    await disconnected;
    if (generation != _connectionGeneration ||
        recovery != _serveRecoveryGeneration ||
        !(canAccept?.call() ?? true)) {
      return;
    }
    _serveTransient = transient;
    _serveRemoteGateway = remoteGateway;
    _serveCanAccept = transient ? canAccept : null;
    _persistForwardedRecovery = transient ? persistRecovery : null;
    _setState(
      const HermesChannelState(
        status: HermesConnectionStatus.connecting,
        isServeReadOnly: true,
      ),
    );
    HermesWebReadClient? reader;
    bool ownsAcquisition() =>
        generation == _connectionGeneration &&
        recovery == _serveRecoveryGeneration;
    bool current() =>
        ownsAcquisition() &&
        identical(_serveReader, reader) &&
        (canAccept?.call() ?? true);
    try {
      if (generation != _connectionGeneration || !_serveOwnerIsCurrent) return;
      reader = remoteGateway
          ? HermesWebReadClient.forRemoteGateway(
              origin: Uri.parse(baseUrl),
              credential: credential,
              profile: profile,
            )
          : HermesWebReadClient.forLocalReads(
              origin: Uri.parse(baseUrl),
              credential: credential,
              profile: profile,
            );
      _serveReader = reader;
      _serveCredential = credential;
      final profiles = await reader.profiles();
      if (!current()) return;
      if (!profiles.any((p) => p.id == profile)) {
        throw const HermesWebReadException(HermesWebFailureKind.identity);
      }
      final page = await reader.sessions();
      if (!current()) return;
      final session = deferSessionSelection
          ? null
          : storedSession ?? page.sessions.firstOrNull?.id;
      final history = session == null ? null : await reader.history(session);
      if (!current()) return;
      _setState(
        HermesChannelState(
          status: HermesConnectionStatus.connected,
          isServeReadOnly: true,
          connectedBaseUrl: baseUrl,
          connectedWithApiKey: true,
          profiles: profiles,
          selectedProfileId: profile,
          hasUnreconciledRun: uncertain,
          sessions: [
            ..._serveSessions(page),
            if (session != null && !page.sessions.any((s) => s.id == session))
              HermesSession(id: session, source: ''),
          ],
          sessionsNextOffset: page.sessions.length,
          hasMoreSessions: page.sessions.length < page.total,
          activeSessionId: session,
          messages: session == null || history == null
              ? const {}
              : {session: _serveTurns(history, session)},
          messageHistoryNextOffsets: session == null || history == null
              ? const {}
              : {session: history.returned},
          sessionsWithEarlierMessages:
              session != null && history?.returned == 500
              ? {session}
              : const {},
        ),
      );
    } catch (error) {
      if (!current()) return;
      _setState(
        HermesChannelState(
          status: HermesConnectionStatus.error,
          isServeReadOnly: true,
          connectedBaseUrl: reader == null ? null : baseUrl,
          errorMessage: remoteGateway
              ? 'Remote gateway connection failed.'
              : 'Local serve read connection failed.',
          connectionFailureKind: _serveFailure(error),
        ),
      );
    } finally {
      // A replacement intent owns cleanup even while its secure-store clear
      // is pending; stale reads must not invalidate its reserved generation.
      if (ownsAcquisition() && !(canAccept?.call() ?? true)) {
        await _disconnect();
      }
      if (ownsAcquisition() &&
          identical(_serveReader, reader) &&
          !_state.isConnected) {
        reader?.disconnect();
        _serveReader = null;
      }
    }
  }

  Future<void> _selectServeProfile(
    String profile, {
    bool deferSessionSelection = false,
  }) async {
    final previous = _serveReader!;
    if (!_state.isConnected ||
        !_serveOwnerIsCurrent ||
        !_state.profiles.any((p) => p.id == profile)) {
      throw const HermesWebReadException(HermesWebFailureKind.identity);
    }
    final generation = _connectionGeneration;
    final selection = _beginProfileSelection(profile);
    _retireServeChat();
    _setState(_state.copyWith(clearServeChat: true, hasUnreconciledRun: false));
    final reader = previous.forProfile(profile);
    bool current() =>
        generation == _connectionGeneration &&
        selection == _profileSelectionGeneration &&
        identical(_serveReader, previous) &&
        _serveOwnerIsCurrent;
    try {
      final profiles = await reader.profiles();
      if (!current()) return;
      if (!profiles.any((p) => p.id == profile)) {
        throw const HermesWebReadException(HermesWebFailureKind.identity);
      }
      final page = await reader.sessions();
      if (!current()) return;
      final session = deferSessionSelection
          ? null
          : page.sessions.firstOrNull?.id;
      final history = session == null ? null : await reader.history(session);
      if (!current()) return;
      previous.disconnect();
      _serveReader = reader;
      _sessionSelectionGeneration++;
      _setState(
        _state.copyWith(
          profiles: profiles,
          selectedProfileId: profile,
          sessions: _serveSessions(page),
          sessionsNextOffset: page.sessions.length,
          hasMoreSessions: page.sessions.length < page.total,
          activeSessionId: session,
          clearActiveSessionId: session == null,
          messages: session == null || history == null
              ? const {}
              : {session: _serveTurns(history, session)},
          messageHistoryNextOffsets: session == null || history == null
              ? const {}
              : {session: history.returned},
          sessionsWithEarlierMessages:
              session != null && history?.returned == 500
              ? {session}
              : const {},
        ),
      );
    } finally {
      if (!identical(_serveReader, reader)) reader.disconnect();
      _finishProfileSelection(selection);
    }
  }

  Future<void> _selectServeSession(
    String session, {
    bool Function()? canAccept,
  }) async {
    final reader = _serveReader!;
    if (!_state.isConnected ||
        !_serveOwnerIsCurrent ||
        _state.isSelectingProfile ||
        !(canAccept?.call() ?? true)) {
      return;
    }
    if (!_state.sessions.any((s) => s.id == session)) {
      throw const HermesSessionRestorationUnsupported();
    }
    final selection = ++_sessionSelectionGeneration;
    _retireServeChat();
    _setState(_state.copyWith(clearServeChat: true, hasUnreconciledRun: false));
    final history = await reader.history(session);
    if (!identical(_serveReader, reader) ||
        !_serveOwnerIsCurrent ||
        selection != _sessionSelectionGeneration ||
        _state.isSelectingProfile ||
        !(canAccept?.call() ?? true)) {
      return;
    }
    _setState(
      _state.copyWith(
        activeSessionId: session,
        messages: {..._state.messages, session: _serveTurns(history, session)},
        messageHistoryNextOffsets: {
          ..._state.messageHistoryNextOffsets,
          session: history.returned,
        },
        sessionsWithEarlierMessages: {
          ..._state.sessionsWithEarlierMessages.where((s) => s != session),
          if (history.returned == 500) session,
        },
      ),
    );
  }

  Future<void> _loadMoreServeSessions() async {
    final reader = _serveReader!;
    if (!_serveOwnerIsCurrent ||
        !_state.hasMoreSessions ||
        _state.isLoadingMoreSessions ||
        _state.isSelectingProfile) {
      return;
    }
    final offset = _state.sessionsNextOffset;
    _setState(_state.copyWith(isLoadingMoreSessions: true));
    try {
      final page = await reader.sessions(offset: offset);
      if (!identical(_serveReader, reader) ||
          _state.isSelectingProfile ||
          !_serveOwnerIsCurrent) {
        return;
      }
      final existing = _state.sessions.map((s) => s.id).toSet();
      _setState(
        _state.copyWith(
          sessions: [
            ..._state.sessions,
            ..._serveSessions(page).where((s) => !existing.contains(s.id)),
          ],
          sessionsNextOffset: offset + page.sessions.length,
          hasMoreSessions:
              page.sessions.isNotEmpty &&
              offset + page.sessions.length < page.total,
        ),
      );
    } catch (_) {
      if (identical(_serveReader, reader) &&
          _serveOwnerIsCurrent &&
          !_state.isSelectingProfile) {
        rethrow;
      }
    } finally {
      if (identical(_serveReader, reader)) {
        _setState(_state.copyWith(isLoadingMoreSessions: false));
      }
    }
  }

  Future<void> _loadEarlierServeMessages() async {
    final reader = _serveReader!;
    final session = _state.activeSessionId;
    if (!_serveOwnerIsCurrent ||
        session == null ||
        !_state.hasEarlierActiveMessages ||
        _state.isLoadingEarlierActiveMessages ||
        _state.isSelectingProfile) {
      return;
    }
    final selection = _sessionSelectionGeneration;
    final offset = _state.messageHistoryNextOffsets[session]!;
    _setState(_state.copyWith(sessionsLoadingEarlierMessages: {session}));
    try {
      final page = await reader.history(session, offset: offset);
      if (!identical(_serveReader, reader) ||
          !_serveOwnerIsCurrent ||
          selection != _sessionSelectionGeneration ||
          _state.isSelectingProfile) {
        return;
      }
      final existing = _state.messages[session] ?? const <HermesChatTurn>[];
      final ids = existing.map((t) => t.id).toSet();
      _setState(
        _state.copyWith(
          messages: {
            ..._state.messages,
            session: [
              ..._serveTurns(page, session).where((t) => !ids.contains(t.id)),
              ...existing,
            ],
          },
          messageHistoryNextOffsets: {
            ..._state.messageHistoryNextOffsets,
            session: offset + page.returned,
          },
          sessionsWithEarlierMessages: {
            ..._state.sessionsWithEarlierMessages.where((s) => s != session),
            if (page.returned == 500) session,
          },
        ),
      );
    } catch (_) {
      if (identical(_serveReader, reader) &&
          _serveOwnerIsCurrent &&
          selection == _sessionSelectionGeneration &&
          !_state.isSelectingProfile) {
        rethrow;
      }
    } finally {
      if (identical(_serveReader, reader)) {
        _setState(_state.copyWith(sessionsLoadingEarlierMessages: const {}));
      }
    }
  }
}

List<HermesSession> _serveSessions(HermesWebSessionPage page) =>
    List.unmodifiable(
      page.sessions.map(
        (s) => HermesSession(
          id: s.id,
          source: s.source ?? '',
          title: s.title,
          model: s.model,
          messageCount: s.messageCount,
          preview: s.preview,
          startedAt: s.startedAt?.toIso8601String(),
          endedAt: s.endedAt?.toIso8601String(),
        ),
      ),
    );

List<HermesChatTurn> _serveTurns(
  HermesWebHistoryPage page,
  String session,
) => List.unmodifiable(
  page.messages.map(
    (m) => HermesChatTurn(
      id: '${m.id}',
      sessionId: session,
      author: switch (m.role) {
        'user' => HermesTurnAuthor.user,
        'system' => HermesTurnAuthor.system,
        _ => HermesTurnAuthor.assistant,
      },
      createdAt:
          m.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      text: m.role == 'tool' ? '' : m.content ?? '',
      kind: m.role == 'tool' ? HermesTurnKind.toolCall : HermesTurnKind.text,
      toolCall: m.role == 'tool'
          ? HermesToolCall(name: m.toolName ?? 'unknown', status: 'completed')
          : null,
    ),
  ),
);

HermesConnectionFailureKind _serveFailure(Object error) =>
    error is HermesWebReadException
    ? switch (error.kind) {
        HermesWebFailureKind.authentication =>
          HermesConnectionFailureKind.authentication,
        HermesWebFailureKind.identity =>
          HermesConnectionFailureKind.invalidEndpoint,
        HermesWebFailureKind.timeout => HermesConnectionFailureKind.timeout,
        HermesWebFailureKind.network => HermesConnectionFailureKind.network,
        _ => HermesConnectionFailureKind.incompatibleResponse,
      }
    : error is FormatException
    ? HermesConnectionFailureKind.invalidEndpoint
    : HermesConnectionFailureKind.unknown;
