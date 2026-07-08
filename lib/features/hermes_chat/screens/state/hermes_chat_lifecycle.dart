part of '../hermes_chat_screen.dart';

extension _HermesChatScreenLifecycle on _HermesChatScreenState {
  Future<void> _reconnectAfterResumeIfRecoverable() async {
    if (_reconnectingOnResume || !mounted) return;
    final channel = ref.read(hermesChannelProvider);
    final state = channel.state;
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
        controller.position.maxScrollExtent - controller.position.pixels < 160;
    if (!force && !wasNearBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<List<HermesEndpointConfig>> _loadEndpointProfiles() async {
    final profiles = await ref.read(hermesEndpointStoreProvider).loadProfiles();
    if (!mounted || profiles.isEmpty) return profiles;
    final currentBaseUrl = hermesPublicEndpointBaseUrl(_baseUrlController.text);
    if (currentBaseUrl == 'http://127.0.0.1:8642' &&
        _apiKeyController.text.isEmpty) {
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
        final activeSessionId = channel.state.activeSessionId;
        if (_approvalSessionId != null &&
            _approvalSessionId != activeSessionId) {
          _pendingApprovals.clear();
          _answeringApprovalId = null;
        }
        _approvalSessionId = activeSessionId;
        _dropQueuedFollowUpsForMissingSessions(channel.state);
        _scheduleTranscriptScrollToBottom(force: _isTurnActive(channel.state));
        _sendQueuedFollowUpIfIdle(channel);
      } else {
        _queuedFollowUps.clear();
        _queuedFollowUpError = null;
        _pendingApprovals.clear();
        _answeringApprovalId = null;
        _approvalSessionId = null;
        _continuousVoiceEnabled = false;
        _voiceError = null;
        _stopSpeaking();
      }
    }
    if (mounted) _setState(() {});
  }
}
