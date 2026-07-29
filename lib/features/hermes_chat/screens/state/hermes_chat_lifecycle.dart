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
        await directory.activate(activeContactId);
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

  void _onChannelChanged() {
    final channel = _subscribed;
    if (channel != null) {
      if (channel.state.isConnected) {
        final completedAssistantSignature = _completedAssistantTurnSignature(
          channel.state,
        );
        if (completedAssistantSignature != _completedAssistantSignature) {
          _completedAssistantSignature = completedAssistantSignature;
          if (completedAssistantSignature != null) {
            _refreshActiveGatewayContact();
          }
        }
        final activeSessionId = channel.state.activeSessionId;
        if (_observedSessionId != null &&
            _observedSessionId != activeSessionId) {
          final voiceNotice = _voiceInputController.continuousEnabled
              ? 'Hermes session changed. Continuous voice paused.'
              : _voiceInputController.speaking
              ? 'Hermes session changed. Spoken reply stopped.'
              : _voiceInputController.capturing
              ? 'Hermes session changed. Voice capture stopped.'
              : null;
          _voiceInputController.pause(voiceNotice);
        }
        _observedSessionId = activeSessionId;
        _dropQueuedFollowUpsForMissingSessions(channel.state);
        _scheduleTranscriptScrollToBottom(force: _isTurnActive(channel.state));
        _sendQueuedFollowUpIfIdle(channel);
      } else {
        _queuedFollowUps.clear();
        _queuedFollowUpError = null;
        _approvals.reset();
        _observedSessionId = null;
        _completedAssistantSignature = null;
        _voiceInputController.pause();
      }
    }
    if (mounted) {
      _setState(() {});
      unawaited(_voiceInputController.maybeContinue());
    }
  }
}
