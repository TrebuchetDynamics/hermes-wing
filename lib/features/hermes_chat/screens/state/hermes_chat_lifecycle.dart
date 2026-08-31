part of '../hermes_chat_screen.dart';

extension _HermesChatScreenLifecycle on _HermesChatScreenState {
  Future<void> _reconnectAfterResumeIfRecoverable() async {
    if (_reconnectingOnResume || !mounted) return;
    final channel = ref.read(hermesChannelProvider);
    final state = channel.state;
    final directory = ref.read(hermesGatewayDirectoryProvider);
    final activeContactId = directory.activeContactId;
    if (activeContactId != null &&
        state.isConnected &&
        state.hasStreamingSessions) {
      return;
    }
    if (activeContactId != null && state.isConnected) {
      _reconnectingOnResume = true;
      try {
        await directory.activate(
          activeContactId,
          preferredSessionId: state.activeSessionId,
        );
      } finally {
        _reconnectingOnResume = false;
      }
      return;
    }
    final recoverable =
        state.status == HermesConnectionStatus.error ||
        (state.isConnected &&
            state.errorMessage != null &&
            !_isTurnActive(state));
    if (!recoverable) return;
    final saved = await ref.read(hermesEndpointStoreProvider).load();
    if (!mounted || saved == null && state.connectedBaseUrl == null) return;
    _reconnectingOnResume = true;
    try {
      await _reconnect(channel);
    } finally {
      _reconnectingOnResume = false;
    }
  }

  void _scheduleTranscriptScrollToBottom({bool force = false}) {
    if (!mounted) return;
    final controller = _transcriptScrollController;
    final wasNearBottom =
        !controller.hasClients ||
        controller.position.pixels - controller.position.minScrollExtent < 160;
    if (!force && !wasNearBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.animateTo(
        controller.position.minScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<List<HermesEndpointConfig>> _loadEndpointProfiles() async {
    final profiles = await ref.read(hermesEndpointStoreProvider).loadProfiles();
    if (!mounted || profiles.isEmpty) return profiles;
    final currentBaseUrl = hermesPublicEndpointBaseUrl(
      _connectionForm.baseUrl.text,
    );
    if ((currentBaseUrl.isEmpty || currentBaseUrl == 'http://127.0.0.1:8642') &&
        _connectionForm.apiKey.text.isEmpty) {
      _selectEndpointProfile(profiles.first);
    }
    return profiles;
  }

  void _refreshEndpointProfiles() {
    if (!mounted) return;
    _setState(() {
      _endpointProfilesFuture = _loadEndpointProfiles();
    });
  }

  void _scheduleDesktopComposerFocus() {
    if (!_usesDesktopKeyboardShortcuts) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_composerFocusNode.canRequestFocus) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      _composerFocusNode.requestFocus();
    });
  }

  void _scheduleInitialDesktopComposerFocus(bool canSendTurns) {
    if (_initialComposerFocusScheduled ||
        !canSendTurns ||
        !_usesDesktopKeyboardShortcuts) {
      return;
    }
    _initialComposerFocusScheduled = true;
    _scheduleDesktopComposerFocus();
  }

  void _syncUnreadCompletedSessions(
    HermesChannelState state,
    HermesChannelChange change,
  ) {
    final knownSessionIds = state.sessions.map((session) => session.id).toSet();
    for (final sessionId in change.completedReplySessionIds) {
      if (sessionId != state.activeSessionId &&
          knownSessionIds.contains(sessionId)) {
        _unreadCompletedSessionIds
          ..remove(sessionId)
          ..add(sessionId);
      }
    }
    _unreadCompletedSessionIds
      ..remove(state.activeSessionId)
      ..removeWhere((sessionId) => !knownSessionIds.contains(sessionId));
    while (_unreadCompletedSessionIds.length > _maxUnreadCompletedSessions) {
      _unreadCompletedSessionIds.remove(_unreadCompletedSessionIds.first);
    }
  }

  void _onChannelChanged() {
    final channel = _subscribed;
    if (channel != null) {
      if (channel.state.isConnected) {
        final change = _observation.observe(channel.state);
        _syncUnreadCompletedSessions(channel.state, change);
        _syncComposerDraft(channel.state);
        if (change.completedReplyArrived) {
          _refreshActiveGatewayContact();
          if (_completionSoundEnabled) {
            fireAndForget(
              SystemSound.play(SystemSoundType.alert),
              'completion sound playback',
            );
          }
        }
        if (change.activeReplyCompleted) {
          _scheduleDesktopComposerFocus();
        }
        if (change.activeSessionChanged) {
          _stagedAttachment = null;
          _failedDirectTurn = null;
          _attachmentError = null;
          final strings = AppLocalizations.of(context);
          final voiceNotice = _voiceInputController.continuousEnabled
              ? strings.chatVoiceSessionChangedContinuous
              : _voiceInputController.speaking
              ? strings.chatVoiceSessionChangedSpeaking
              : _voiceInputController.capturing
              ? strings.chatVoiceSessionChangedCapturing
              : null;
          _voiceInputController.pause(voiceNotice);
        }
        _dropQueuedFollowUpsForMissingSessions(channel.state);
        _scheduleTranscriptScrollToBottom(
          force: change.activeSessionChanged || change.activeUserTurnArrived,
        );
        _sendQueuedFollowUpIfIdle(channel);
      } else {
        _stagedAttachment = null;
        _failedDirectTurn = null;
        _attachmentError = null;
        _followUps.reset();
        _approvals.reset();
        _unreadCompletedSessionIds.clear();
        _observation.reset();
        _voiceInputController.pause();
      }
    }
    if (mounted) {
      _setState(() {});
      unawaited(_voiceInputController.maybeContinue());
    }
  }
}
