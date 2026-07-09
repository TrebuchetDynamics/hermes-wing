part of '../hermes_chat_screen.dart';

extension _HermesChatScreenMessageFlow on _HermesChatScreenState {
  void _enqueueApprovalRequest(HermesApprovalRequest request) {
    final requestKey = _approvalRequestKey(request);
    final duplicate = _pendingApprovals.any(
      (pending) => _approvalRequestKey(pending) == requestKey,
    );
    if (duplicate || _answeringApprovalId == request.id.trim()) return;
    _approvalSessionId = _subscribed?.state.activeSessionId;
    _pendingApprovals.addLast(request);
  }

  String _approvalRequestKey(HermesApprovalRequest request) {
    final id = request.id.trim();
    if (id.isNotEmpty) return 'id:$id';
    final toolCallId = request.toolCallId.trim();
    if (toolCallId.isNotEmpty) {
      return 'tool:$toolCallId';
    }
    return 'prompt:${request.prompt}';
  }

  void _sendComposerText(HermesChannel channel) {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    if (_isTurnActive(channel.state)) {
      if (_queuedFollowUps.length >= _maxQueuedFollowUps) {
        _setState(() {
          _queuedFollowUpError =
              'Queued follow-ups are full ($_maxQueuedFollowUps). Wait for Hermes to finish before adding more.';
        });
        return;
      }
      _composerController.clear();
      _setState(() {
        _queuedFollowUpError = null;
        _queuedFollowUps.addLast(
          _QueuedFollowUp(text, channel.state.activeSessionId),
        );
      });
      return;
    }
    _composerController.clear();
    if (_queuedFollowUpError != null) {
      _setState(() => _queuedFollowUpError = null);
    }
    _sendText(channel, text);
  }

  bool _isTurnActive(HermesChannelState state) =>
      state.activeMessages.isNotEmpty &&
      state.activeMessages.last.status == HermesTurnStatus.streaming;

  bool _canSendTurns(HermesChannelState state) {
    if (state.activeSessionId == null) return false;
    final capabilities = state.capabilities;
    if (capabilities == null) return true;
    return HermesTransportPolicy(capabilities).supportsAnyChatTransport;
  }

  bool _canRespondToApprovals(HermesChannelState state) {
    final capabilities = state.capabilities;
    if (capabilities == null) return true;
    return HermesTransportPolicy(capabilities).supportsRunApprovalResponse;
  }

  bool _canCreateSession(HermesChannelState state) =>
      state.capabilities?.advertisesEndpoint(
        'session_create',
        'POST',
        '/api/sessions',
      ) ??
      false;

  void _sendQueuedFollowUpIfIdle(HermesChannel channel) {
    if (!_canSendQueuedFollowUp(channel.state)) return;
    final queued = _queuedFollowUps.removeFirst();
    _queuedFollowUpError = null;
    _sendText(
      channel,
      queued.text,
      requeueOnFailure: true,
      requeueSessionId: queued.sessionId,
    );
  }

  void _dropQueuedFollowUpsForMissingSessions(HermesChannelState state) {
    final sessionIds = state.sessions.map((session) => session.id).toSet();
    _queuedFollowUps.removeWhere(
      (queued) =>
          queued.sessionId != null && !sessionIds.contains(queued.sessionId),
    );
  }

  bool _canSendQueuedFollowUp(HermesChannelState state) {
    if (_queuedFollowUps.isEmpty ||
        _isTurnActive(state) ||
        !_canSendTurns(state)) {
      return false;
    }
    return _queuedFollowUps.first.sessionId == state.activeSessionId;
  }

  bool _canOpenQueuedFollowUpSession(HermesChannelState state) {
    if (_queuedFollowUps.isEmpty) return false;
    final sessionId = _queuedFollowUps.first.sessionId;
    if (sessionId == null || sessionId == state.activeSessionId) return false;
    return state.sessions.any((session) => session.id == sessionId);
  }

  Future<void> _openQueuedFollowUpSession(
    BuildContext context,
    HermesChannel channel,
  ) async {
    if (!_canOpenQueuedFollowUpSession(channel.state)) return;
    final sessionId = _queuedFollowUps.first.sessionId;
    if (sessionId == null) return;
    try {
      await channel.selectSession(sessionId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open queued follow-up session: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  void _retryLastFailedTurn(HermesChannel channel) {
    if (!_canSendTurns(channel.state)) return;
    final text = _retryableFailedUserText(channel.state);
    if (text == null) return;
    _sendText(channel, text);
  }

  void _sendText(
    HermesChannel channel,
    String text, {
    bool requeueOnFailure = false,
    String? requeueSessionId,
  }) {
    final sessionId = requeueSessionId ?? channel.state.activeSessionId;
    unawaited(
      channel.sendText(text).catchError((Object error) {
        if (!mounted || !requeueOnFailure || !channel.state.isConnected) return;
        _setState(() {
          _queuedFollowUpError =
              'Could not send queued follow-up: ${_safeHermesUiError(error)}';
          if (_queuedFollowUps.length < _maxQueuedFollowUps) {
            _queuedFollowUps.addFirst(_QueuedFollowUp(text, sessionId));
          }
        });
      }),
    );
  }

  String? _retryableFailedUserText(HermesChannelState state) {
    final turns = state.activeMessages;
    for (var index = turns.length - 1; index > 0; index--) {
      final turn = turns[index];
      if (turn.author != HermesTurnAuthor.assistant ||
          turn.status != HermesTurnStatus.failed) {
        continue;
      }
      for (var userIndex = index - 1; userIndex >= 0; userIndex--) {
        final userTurn = turns[userIndex];
        if (userTurn.author == HermesTurnAuthor.user &&
            userTurn.text.trim().isNotEmpty) {
          return userTurn.text.trim();
        }
      }
    }
    return null;
  }

  String _queuedFollowUpSummary(HermesChannelState state) {
    final count = _queuedFollowUps.length;
    final label = count == 1 ? 'follow-up' : 'follow-ups';
    final preview = _queuedFollowUps
        .take(2)
        .map((queued) => _queuedFollowUpPreview(queued.text))
        .join(' • ');
    final remaining = count - 2;
    final suffix = remaining > 0 ? ' • +$remaining more' : '';
    final waiting = !_canSendTurns(state)
        ? ' Waiting for a supported Hermes chat transport.'
        : _queuedFollowUps.first.sessionId != state.activeSessionId
        ? ' Waiting for the original session.'
        : '';
    return 'Queued $count $label after current reply: $preview$suffix$waiting';
  }

  String _queuedFollowUpPreview(String text) =>
      _safeHermesUiPreview(text, maxLength: 48);

  String _queuedFollowUpDetailsSummary(HermesChannelState state) {
    final buffer = StringBuffer()
      ..writeln('Hermes queued follow-ups')
      ..writeln('Queued: ${_queuedFollowUps.length}')
      ..writeln(
        'Active session: ${_safeHermesUiPreview(state.activeSessionId ?? 'none', maxLength: 80)}',
      )
      ..writeln(
        'Next session: ${_safeHermesUiPreview(_queuedFollowUps.first.sessionId ?? 'none', maxLength: 80)}',
      )
      ..writeln('Can send now: ${_canSendQueuedFollowUp(state)}');
    var index = 1;
    for (final queued in _queuedFollowUps.take(_maxQueuedFollowUps)) {
      buffer.writeln(
        '$index. ${_safeHermesUiPreview(queued.text, maxLength: 160)}',
      );
      index += 1;
    }
    buffer.write('Secrets: redacted');
    return buffer.toString();
  }

  Future<void> _confirmClearQueuedFollowUps(BuildContext context) async {
    if (_queuedFollowUps.isEmpty) return;
    final count = _queuedFollowUps.length;
    final label = count == 1 ? 'follow-up' : 'follow-ups';
    final preview = _queuedFollowUps
        .take(3)
        .map((queued) => _safeHermesUiPreview(queued.text, maxLength: 80))
        .join('\n');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-queued-follow-up-clear-dialog'),
        title: Text('Cancel $count queued $label?'),
        content: Text(
          '$preview${count > 3 ? '\n+${count - 3} more' : ''}\n\n'
          'Queued text is redacted and bounded in this confirmation.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-queued-follow-up-clear-keep'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            key: const ValueKey('hermes-queued-follow-up-clear-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _setState(() {
      _queuedFollowUps.clear();
      _queuedFollowUpError = null;
    });
  }
}
