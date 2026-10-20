part of '../hermes_api_channel.dart';

extension _BotChatSelection on HermesApiChannel {
  Future<bool> _openBotChat({
    required bool background,
    bool Function()? canAccept,
  }) {
    if (!(canAccept?.call() ?? true)) return Future.value(false);
    final source = _serveReader;
    final profile = _state.selectedProfileId;
    if (source == null || profile == null || !_state.isConnected) {
      throw UnsupportedError(
        'Canonical Bot Chat needs the qualified native contract.',
      );
    }
    if (background && _state.activeSession?.title != 'Bot Chat') {
      return Future.value(false);
    }
    bool settled() =>
        !_state.isSelectingProfile &&
        !_qualifyingServeChat &&
        !_state.hasUnreconciledRun &&
        !_serveSubmissionPending &&
        _serveStopPending == null &&
        _pendingApprovals.isEmpty &&
        (_serveLifecycle == null || _serveLifecycle!.canSubmit);
    if (!settled()) {
      throw UnsupportedError('Reconcile the current conversation first.');
    }
    final owner = (
      _connectionGeneration,
      _profileSelectionGeneration,
      _sessionSelectionGeneration,
      background,
    );
    if (_botChatOwner == owner && _botChatFlight != null) {
      return _botChatFlight!;
    }
    final sourceLifecycle = _serveLifecycle;
    var invalid = false;
    bool current() =>
        !invalid &&
        identical(source, _serveReader) &&
        identical(sourceLifecycle, _serveLifecycle) &&
        _serveOwnerIsCurrent &&
        _state.isConnected &&
        _state.selectedProfileId == profile &&
        settled() &&
        owner ==
            (
              _connectionGeneration,
              _profileSelectionGeneration,
              _sessionSelectionGeneration,
              background,
            ) &&
        (canAccept?.call() ?? true);
    final candidate = source.forProfile(profile);
    // An intervening turn or same-frame owner roundtrip permanently expires
    // this opening; becoming idle again is not renewed navigation intent.
    void observeSource() {
      if (!current()) {
        invalid = true;
        candidate.disconnect();
      }
    }

    final known = _state.sessions.any((s) => s.title == 'Bot Chat');
    var adopted = false;
    addListener(observeSource);
    final work = (() async {
      try {
        final next = await candidate.prepareBotChat(
          knownCanonical: known,
          allowCreate: !background,
          idempotencyKey: _uuid.v4(),
          canAccept: current,
        );
        if (next == null || !current()) return false;
        final session = next.storedSessionId!;
        if (background && session != _state.activeSessionId) return false;
        candidate.adoptPreparedBotChat();
        removeListener(observeSource);
        _retireServeChat();
        source.disconnect();
        _serveReader = candidate;
        _serveLifecycle = next;
        adopted = true;
        _sessionSelectionGeneration++;
        final qualification = _serveQualification;
        bool owns() =>
            identical(candidate, _serveReader) &&
            identical(next, _serveLifecycle) &&
            qualification == _serveQualification &&
            _serveOwnerIsCurrent &&
            !_state.isSelectingProfile &&
            _state.activeSessionId == session;
        // Metadata below is verified by native registry/detail reads. It is
        // never consulted as a canonical ID pin or offered as ordinary recents.
        _setState(
          _state.copyWith(
            sessions: [
              ..._state.sessions.where(
                (s) => s.id != session && !(s.hidden && s.title == 'Bot Chat'),
              ),
              HermesSession(
                id: session,
                source: '',
                title: 'Bot Chat',
                hidden: true,
              ),
            ],
            // The retired reader cannot settle its pending loading flags.
            isLoadingMoreSessions: false,
            sessionsLoadingEarlierMessages: const {},
            messageHistoryNextOffsets: {..._state.messageHistoryNextOffsets}
              ..remove(session),
            sessionsWithEarlierMessages: {..._state.sessionsWithEarlierMessages}
              ..remove(session),
            activeSessionId: session,
            clearServeChat: true,
            hasUnreconciledRun: true,
            messages: {..._state.messages, session: next.turns},
            clearErrorMessage: true,
          ),
        );
        if (!owns()) return false;
        var persisted = false;
        void sync() {
          if (persisted && owns()) _syncServeChat(next);
        }

        _serveChanges = next.changes.listen((_) => sync(), onDone: sync);
        try {
          await _persistServeRecovery(next);
        } catch (_) {
          if (owns()) {
            _retireServeChat();
            _setState(
              _state.copyWith(
                clearServeChat: true,
                hasUnreconciledRun: true,
                errorMessage:
                    'Bot Chat history loaded, but recovery storage failed. Reconcile explicitly before sending.',
              ),
            );
          }
          rethrow;
        }
        persisted = true;
        sync();
        return owns();
      } catch (error) {
        if (!adopted && !current()) return false;
        if (error is HermesWebReadException &&
            error.kind == HermesWebFailureKind.rpc &&
            error.rpcCode == -32601) {
          throw UnsupportedError(
            'Agent canonical Bot Chat operations are unavailable.',
          );
        }
        rethrow;
      } finally {
        removeListener(observeSource);
        if (!adopted) candidate.disconnect();
      }
    })();
    _botChatOwner = owner;
    late final Future<bool> flight;
    flight = work.whenComplete(() {
      if (identical(_botChatFlight, flight)) {
        _botChatFlight = null;
        _botChatOwner = null;
      }
    });
    return _botChatFlight = flight;
  }
}
