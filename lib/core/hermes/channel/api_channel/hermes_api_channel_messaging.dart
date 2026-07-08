part of '../hermes_api_channel.dart';

extension _MessagingExtension on HermesApiChannel {
  Future<void> _sendText(String text) async {
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
        name == 'assistant.error';
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
    return name == 'run.completed' || name == 'assistant.completed';
  }

  bool _isFailedTerminalRunEvent(String name) {
    return name == 'run.failed' ||
        name == 'assistant.failed' ||
        _isCancelledTerminalRunEvent(name);
  }

  bool _isCancelledTerminalRunEvent(String name) {
    return name == 'run.cancelled' || name == 'assistant.cancelled';
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

  HermesApprovalRequest _approvalRequestFromEvent(HermesStreamEvent event) {
    return HermesApprovalRequest(
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

  void _cancelActiveTurn() {
    _finishActiveTurnLocally();
  }

  void _stopActiveTurn() {
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
}
