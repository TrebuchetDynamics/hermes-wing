part of '../hermes_api_channel.dart';

extension _MessagingExtension on HermesApiChannel {
  Future<void> _sendText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
  }) async {
    final message = text.trim();
    final image = imageDataUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;
    final hasTextFile = textAttachment != null;
    if (message.isEmpty && !hasImage && !hasTextFile) {
      throw ArgumentError.value(
        text,
        'text',
        'Hermes message cannot be blank.',
      );
    }
    if (hasImage && hasTextFile) {
      throw ArgumentError('Send either an image or a text file, not both.');
    }
    if (hasImage &&
        !image.startsWith(RegExp(r'data:image/(png|jpeg|gif|webp);base64,'))) {
      throw ArgumentError.value(
        imageDataUrl,
        'imageDataUrl',
        'Hermes attachments must be supported image data URLs.',
      );
    }
    final attachmentLabel = attachmentName?.trim();
    final safeLabel = attachmentLabel?.isNotEmpty == true
        ? attachmentLabel!
        : hasTextFile
        ? 'attachment.txt'
        : 'attachment';
    final requestText = [
      if (message.isNotEmpty) message,
      if (hasTextFile)
        '<file name="${_escapeAttachmentXml(safeLabel)}" mime="text/plain">\n$textAttachment\n</file>',
    ].join('\n\n');
    final displayMessage = [
      if (message.isNotEmpty) message,
      if (hasImage) '[Image: $safeLabel]',
      if (hasTextFile) '[File: $safeLabel]',
    ].join('\n\n');
    final Object requestMessage = hasImage
        ? [
            if (requestText.isNotEmpty)
              {'type': 'input_text', 'text': requestText},
            {'type': 'input_image', 'image_url': image},
          ]
        : requestText;
    final client = _client;
    final sessionId = _state.activeSessionId;
    final profileId = _state.selectedProfileId;
    if (client == null || sessionId == null) {
      throw StateError('Hermes channel is not connected to a session.');
    }
    await _ensureDetachedRunsLoaded();
    if (!_isConnectedProfile(client, profileId) ||
        _state.activeSessionId != sessionId) {
      return;
    }
    final connectedBaseUrl = _state.connectedBaseUrl;
    if (connectedBaseUrl != null &&
        _hasDetachedRun(
          baseUrl: connectedBaseUrl,
          profileId: profileId,
          sessionId: sessionId,
        )) {
      const message =
          'Hermes run is still active. Reconnect later before retrying.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
    final activeCompleter = _activeStreamCompleters[sessionId];
    if ((activeCompleter != null && !activeCompleter.isCompleted) ||
        _state.messages[sessionId]?.lastOrNull?.status ==
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
        text: displayMessage,
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

    final streamGeneration = ++_nextStreamGeneration;
    _sessionStreamGenerations[sessionId] = streamGeneration;
    bool isCurrentStream() =>
        identical(_client, client) &&
        _state.status == HermesConnectionStatus.connected &&
        _state.selectedProfileId == profileId &&
        _sessionStreamGenerations[sessionId] == streamGeneration;
    Stream<HermesStreamEvent>? events;
    String? runId;
    try {
      if (useRunTransport) {
        final run = await client.startRun(
          sessionId: sessionId,
          message: requestMessage,
          profile: profileId,
        );
        runId = run.id;
        await _trackDetachedRun(
          runId: runId,
          sessionId: sessionId,
          profileId: profileId,
        );
      } else {
        events = client.streamSessionChat(
          sessionId,
          message: requestMessage,
          profile: profileId,
        );
      }
    } catch (error) {
      if (!identical(_client, client) ||
          _state.status != HermesConnectionStatus.connected ||
          !isCurrentStream()) {
        return;
      }
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      _setTurns(sessionId, turns, errorMessage: _safeHermesError(error));
      rethrow;
    }

    if (!identical(_client, client) ||
        _state.status != HermesConnectionStatus.connected ||
        !isCurrentStream()) {
      return;
    }

    try {
      events ??= client.runEvents(runId!, profile: profileId);
    } catch (error) {
      if (!identical(_client, client) ||
          _state.status != HermesConnectionStatus.connected ||
          !isCurrentStream()) {
        return;
      }
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      final message =
          'Hermes run event stream failed to open: ${_safeHermesError(error)}';
      _setTurns(sessionId, turns, errorMessage: message);
      throw StateError(message);
    }
    if (runId != null) _activeRunIds[sessionId] = runId;
    final toolTurnIndexByCallId = <String, int>{};
    final completer = Completer<void>();
    _activeStreamCompleters[sessionId] = completer;
    var streamFailed = false;
    var streamEndedBeforeTerminal = false;
    var terminalRunEventReceived = false;
    var terminalRunLifecycleReceived = false;
    HermesRunUsage? runUsage;
    Timer? idleTimer;
    void armIdleTimer() {
      idleTimer?.cancel();
      idleTimer = Timer(streamIdleTimeout, () {
        if (!isCurrentStream() || completer.isCompleted) {
          return;
        }
        streamFailed = true;
        streamEndedBeforeTerminal = true;
        assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
        turns[assistantIndex] = assistantTurn;
        _setTurns(
          sessionId,
          List.of(turns),
          errorMessage:
              'Hermes event stream timed out while waiting for activity.',
        );
        completer.complete();
        final stream = _activeStreams[sessionId];
        if (stream != null) unawaited(stream.cancel());
      });
    }

    late final StreamSubscription<HermesStreamEvent> subscription;
    subscription = events.listen(
      (event) {
        if (!isCurrentStream() || terminalRunEventReceived) {
          return;
        }
        armIdleTimer();
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
        if (event.name == 'reasoning.available') {
          if (_applyReasoningEvent(
            sessionId: sessionId,
            runId: runId,
            event: event,
            turns: turns,
            insertBefore: assistantIndex,
          )) {
            assistantIndex = turns.length - 1;
            _setTurns(sessionId, List.of(turns));
          }
          return;
        }
        if (_isToolEvent(event.name)) {
          final closesAssistantSegment = assistantTurn.text.trim().isNotEmpty;
          _applyToolEvent(
            sessionId: sessionId,
            runId: runId,
            event: event,
            turns: turns,
            toolTurnIndexByCallId: toolTurnIndexByCallId,
            insertBefore: closesAssistantSegment
                ? assistantIndex + 1
                : assistantIndex,
          );
          if (closesAssistantSegment) {
            turns[assistantIndex] = assistantTurn.copyWith(
              status: HermesTurnStatus.completed,
            );
            assistantTurn = HermesChatTurn(
              id: '${assistantTurn.id}-segment-${toolTurnIndexByCallId.length}',
              sessionId: sessionId,
              author: HermesTurnAuthor.assistant,
              createdAt: DateTime.now(),
              status: HermesTurnStatus.streaming,
            );
            turns.add(assistantTurn);
          }
          assistantIndex = turns.length - 1;
          _setTurns(sessionId, List.of(turns));
          return;
        }
        if (_isApprovalRequestEvent(event.name)) {
          final request = _approvalRequestFromEvent(
            event,
            runId: runId,
            sessionId: sessionId,
          );
          if (request.id.isEmpty) {
            _setTurns(
              sessionId,
              List.of(turns),
              errorMessage:
                  'Hermes approval request was missing an approval id. The run is still active.',
            );
            return;
          }
          if (runId != null) _approvalRunIds[request.id] = runId;
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
          final canonicalFinal = _canonicalFinalForEvent(
            event,
            expectedRunId: runId,
            expectedSessionId: sessionId,
          );
          if (canonicalFinal != null) {
            assistantTurn = assistantTurn.copyWith(
              text: reconcileAssistantText(
                streamed: assistantTurn.text,
                canonical: canonicalFinal,
              ),
            );
            turns[assistantIndex] = assistantTurn;
          }
          final usageJson = wingMapFromJson(event.payload['usage']);
          if (usageJson.isNotEmpty) {
            runUsage = HermesRunUsage.fromJson(usageJson);
          }
          terminalRunEventReceived = true;
          terminalRunLifecycleReceived = true;
          _setTurns(sessionId, List.of(turns), clearErrorMessage: true);
          if (!completer.isCompleted) completer.complete();
          return;
        }
        if (_isFailedTerminalRunEvent(event.name)) {
          terminalRunEventReceived = true;
          terminalRunLifecycleReceived = true;
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
                : _runFailureMessage(event),
          );
          if (!completer.isCompleted) completer.complete();
        }
      },
      onError: (Object error) {
        idleTimer?.cancel();
        if (!isCurrentStream() || terminalRunEventReceived) {
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
        idleTimer?.cancel();
        if (!isCurrentStream()) return;
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
    _activeStreams[sessionId] = subscription;
    armIdleTimer();
    await completer.future;
    idleTimer?.cancel();
    if (!isCurrentStream()) {
      return;
    }
    if (terminalRunEventReceived) {
      unawaited(subscription.cancel());
    }
    if (identical(_activeStreamCompleters[sessionId], completer)) {
      _activeStreamCompleters.remove(sessionId);
    }
    if (identical(_activeStreams[sessionId], subscription)) {
      _activeStreams.remove(sessionId);
    }
    if (_activeRunIds[sessionId] == runId) {
      _activeRunIds.remove(sessionId);
    }
    if (runId != null) {
      _approvalRunIds.removeWhere((_, approvalRunId) => approvalRunId == runId);
      if (terminalRunLifecycleReceived) {
        await _releaseDetachedRun(runId);
      }
    }
    if (!isCurrentStream()) return;
    final canReadRunStatus =
        runId != null &&
        capabilities != null &&
        HermesTransportPolicy(capabilities).supportsRunStatus;
    HermesRun? recoveredRun;
    if (canReadRunStatus && (streamFailed || runUsage == null)) {
      try {
        recoveredRun = await client.getRunStatus(runId, profile: profileId);
        if (!isCurrentStream()) return;
        runUsage ??= recoveredRun.usage;
        final recoveredError = recoveredRun.error?.trim();
        final currentError = _state.errorMessage ?? '';
        final alreadyHasServerDetail =
            currentError.startsWith('Hermes run failed:') ||
            currentError.startsWith('Hermes stream reported an error:');
        if (streamFailed &&
            recoveredRun.status == HermesRunLifecycle.failed &&
            !alreadyHasServerDetail &&
            recoveredError?.isNotEmpty == true) {
          _setTurns(
            sessionId,
            List.of(turns),
            errorMessage:
                'Hermes run failed: ${_safeHermesError(recoveredError!)}',
          );
        }
        if (recoveredRun.status == HermesRunLifecycle.completed ||
            recoveredRun.status == HermesRunLifecycle.failed ||
            recoveredRun.status == HermesRunLifecycle.cancelled) {
          await _releaseDetachedRun(runId);
        }
      } catch (_) {
        // Status and usage recovery are best-effort; preserve the transcript.
      }
      if (!identical(_client, client) ||
          _state.status != HermesConnectionStatus.connected ||
          !isCurrentStream()) {
        return;
      }
    }
    if (assistantTurn.status == HermesTurnStatus.streaming) {
      assistantTurn = assistantTurn.copyWith(
        status: HermesTurnStatus.completed,
        usage: runUsage,
      );
      turns[assistantIndex] = assistantTurn;
      assistantIndex = _removeReasoningDuplicatingAssistant(
        turns,
        assistantIndex,
        preSendTurnCount,
      );
      _setTurns(sessionId, List.of(turns));
    }

    if (streamFailed && streamEndedBeforeTerminal) {
      final recoveredOutput = recoveredRun?.output?.trim();
      if (recoveredRun?.status == HermesRunLifecycle.completed &&
          recoveredOutput?.isNotEmpty == true) {
        assistantTurn = assistantTurn.copyWith(
          status: HermesTurnStatus.completed,
          text: recoveredOutput,
          usage: runUsage,
        );
        turns[assistantIndex] = assistantTurn;
        assistantIndex = _removeReasoningDuplicatingAssistant(
          turns,
          assistantIndex,
          preSendTurnCount,
        );
        _setTurns(sessionId, List.of(turns), clearErrorMessage: true);
        return;
      }
      if (recoveredRun?.status
          case HermesRunLifecycle.running || HermesRunLifecycle.queued) {
        await _trackDetachedRun(
          runId: runId!,
          sessionId: sessionId,
          profileId: profileId,
        );
        if (!isCurrentStream()) return;
        _setTurns(
          sessionId,
          List.of(turns),
          errorMessage:
              'Hermes run is still active after its event stream closed. Reconnect before retrying.',
        );
        return;
      }
      try {
        final serverTurns = await _fetchTurns(
          client,
          sessionId,
          profileId: profileId,
        );
        if (!identical(_client, client) ||
            _state.status != HermesConnectionStatus.connected ||
            !isCurrentStream()) {
          return;
        }
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

    if (!streamFailed) {
      try {
        final serverTurns = await _fetchTurns(
          client,
          sessionId,
          profileId: profileId,
        );
        if (!identical(_client, client) ||
            _state.status != HermesConnectionStatus.connected ||
            !isCurrentStream()) {
          return;
        }
        if (!_serverHistoryDropsStreamedAssistant(
          serverTurns,
          assistantTurn,
          message,
          preSendTurnCount,
        )) {
          final reconciledServerTurns = _reconcileCurrentAssistantReply(
            serverTurns,
            assistantTurn,
            message,
            preSendTurnCount,
          );
          _setTurns(
            sessionId,
            _attachUsageToLatestAssistant(
              _mergeRunDetailTurns(
                reconciledServerTurns,
                turns.skip(preSendTurnCount),
              ),
              runUsage,
            ),
          );
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
    return wingOptionalStringFromJson(value);
  }

  bool _isDeltaEvent(String name) {
    return name == 'message' ||
        name == 'message.delta' ||
        name == 'assistant.delta' ||
        name == 'response.delta' ||
        name == 'response.text.delta' ||
        name == 'response.output_text.delta';
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
    return _currentAssistantReplyIndex(
          serverTurns,
          sentMessage,
          preSendTurnCount,
        ) !=
        null;
  }

  int? _currentAssistantReplyIndex(
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
        return _assistantReplyIndexAfter(serverTurns, index);
      }
    }
    if (serverTurns.length <= preSendTurnCount) return null;
    return _assistantReplyIndexAfter(serverTurns, preSendTurnCount - 1);
  }

  int? _assistantReplyIndexAfter(List<HermesChatTurn> serverTurns, int index) {
    for (
      var candidateIndex = index + 1;
      candidateIndex < serverTurns.length;
      candidateIndex++
    ) {
      final candidate = serverTurns[candidateIndex];
      if (candidate.author == HermesTurnAuthor.user) return null;
      if (candidate.author == HermesTurnAuthor.assistant &&
          candidate.text.trim().isNotEmpty) {
        return candidateIndex;
      }
    }
    return null;
  }

  List<HermesChatTurn> _reconcileCurrentAssistantReply(
    List<HermesChatTurn> serverTurns,
    HermesChatTurn localAssistantTurn,
    String sentMessage,
    int preSendTurnCount,
  ) {
    final assistantIndex = _currentAssistantReplyIndex(
      serverTurns,
      sentMessage,
      preSendTurnCount,
    );
    if (assistantIndex == null || localAssistantTurn.text.trim().isEmpty) {
      return serverTurns;
    }
    final serverAssistant = serverTurns[assistantIndex];
    if (serverAssistant.sessionId != localAssistantTurn.sessionId) {
      return serverTurns;
    }
    final reconciled = List<HermesChatTurn>.from(serverTurns);
    reconciled[assistantIndex] = serverAssistant.copyWith(
      text: reconcileAssistantText(
        streamed: localAssistantTurn.text,
        canonical: serverAssistant.text,
      ),
    );
    return reconciled;
  }

  List<HermesChatTurn> _mergeRunDetailTurns(
    List<HermesChatTurn> serverTurns,
    Iterable<HermesChatTurn> localRunTurns,
  ) {
    final local = localRunTurns.toList(growable: false);
    final finalAssistantIndex = local.lastIndexWhere(
      (turn) => turn.author == HermesTurnAuthor.assistant,
    );
    final details = <HermesChatTurn>[
      for (var index = 0; index < local.length; index++)
        if (local[index].kind != HermesTurnKind.text ||
            (local[index].author == HermesTurnAuthor.assistant &&
                index != finalAssistantIndex))
          local[index],
    ];
    if (details.isEmpty) return serverTurns;
    final merged = List<HermesChatTurn>.from(serverTurns);
    final assistantIndex = merged.lastIndexWhere(
      (turn) => turn.author == HermesTurnAuthor.assistant,
    );
    merged.insertAll(
      assistantIndex < 0 ? merged.length : assistantIndex,
      details,
    );
    return merged;
  }

  List<HermesChatTurn> _attachUsageToLatestAssistant(
    List<HermesChatTurn> turns,
    HermesRunUsage? usage,
  ) {
    if (usage == null) return turns;
    final merged = List<HermesChatTurn>.from(turns);
    for (var index = merged.length - 1; index >= 0; index--) {
      final turn = merged[index];
      if (turn.author != HermesTurnAuthor.assistant ||
          turn.text.trim().isEmpty) {
        continue;
      }
      merged[index] = turn.copyWith(usage: usage);
      break;
    }
    return merged;
  }

  bool _isApprovalRequestEvent(String name) {
    return name == 'approval.request' ||
        name == 'approval.requested' ||
        name == 'approval.required';
  }

  bool _isStreamErrorEvent(String name) {
    return name == 'error' ||
        name == 'stream.error' ||
        name == 'run.error' ||
        name == 'assistant.error' ||
        name == 'message.error' ||
        name == 'response.error';
  }

  String _streamErrorMessage(HermesStreamEvent event) {
    final detail = _streamErrorDetail(event.payload);
    if (detail == null || detail.trim().isEmpty) {
      return 'Hermes stream reported an error.';
    }
    return 'Hermes stream reported an error: ${_safeHermesError(detail)}';
  }

  String _runFailureMessage(HermesStreamEvent event) {
    final detail = _streamErrorDetail(event.payload)?.trim();
    return detail == null || detail.isEmpty
        ? 'Hermes run failed.'
        : 'Hermes run failed: ${_safeHermesError(detail)}';
  }

  String? _streamErrorDetail(Map<String, Object?> payload) {
    final code = wingOptionalStringFromJson(payload['code']);
    final message =
        wingOptionalStringFromJson(payload['message']) ??
        wingOptionalStringFromJson(payload['detail']) ??
        wingOptionalStringFromJson(payload['reason']);
    if (code != null && message != null) return '$code: $message';
    if (message != null) return message;
    final nested = wingMapFromJson(payload['error']);
    if (nested.isNotEmpty) {
      final nestedCode =
          wingOptionalStringFromJson(nested['code']) ??
          wingOptionalStringFromJson(nested['type']);
      final nestedMessage =
          wingOptionalStringFromJson(nested['message']) ??
          wingOptionalStringFromJson(nested['detail']) ??
          wingOptionalStringFromJson(nested['reason']);
      if (nestedCode != null && nestedMessage != null) {
        return '$nestedCode: $nestedMessage';
      }
      return nestedMessage ?? nestedCode;
    }
    final error = wingOptionalStringFromJson(payload['error']);
    if (code != null && error != null) return '$code: $error';
    return error ?? code;
  }

  bool _isSuccessfulTerminalRunEvent(String name) {
    return name == 'run.completed' ||
        name == 'assistant.completed' ||
        name == 'message.completed' ||
        name == 'response.completed' ||
        name == 'response.done';
  }

  String? _canonicalFinalForEvent(
    HermesStreamEvent event, {
    required String? expectedRunId,
    required String expectedSessionId,
  }) {
    final eventRunId = wingOptionalStringFromJson(event.payload['run_id']);
    if (eventRunId != null && eventRunId != expectedRunId) {
      return null;
    }
    final eventSessionId = wingOptionalStringFromJson(
      event.payload['session_id'],
    );
    if (eventSessionId != null && eventSessionId != expectedSessionId) {
      return null;
    }
    final output =
        _rawStreamText(event.payload['output']) ??
        _rawStreamText(event.payload['text']) ??
        _rawStreamText(event.payload['content']);
    return output?.trim().isNotEmpty == true ? output : null;
  }

  bool _isFailedTerminalRunEvent(String name) {
    return name == 'run.failed' ||
        name == 'assistant.failed' ||
        name == 'message.failed' ||
        name == 'response.failed' ||
        _isCancelledTerminalRunEvent(name);
  }

  bool _isCancelledTerminalRunEvent(String name) {
    return name == 'run.cancelled' ||
        name == 'assistant.cancelled' ||
        name == 'message.cancelled' ||
        name == 'response.cancelled' ||
        name == 'response.canceled';
  }

  bool _applyReasoningEvent({
    required String sessionId,
    required String? runId,
    required HermesStreamEvent event,
    required List<HermesChatTurn> turns,
    required int insertBefore,
  }) {
    final rawText = wingOptionalStringFromJson(event.payload['text'])?.trim();
    if (rawText == null || rawText.isEmpty) return false;
    const maximumLength = 16384;
    final text = rawText.length <= maximumLength
        ? rawText
        : '${rawText.substring(0, maximumLength - 1)}…';
    turns.insert(
      insertBefore,
      HermesChatTurn(
        id: 'reasoning-${runId ?? sessionId}-${turns.length}',
        sessionId: sessionId,
        author: HermesTurnAuthor.system,
        createdAt: DateTime.now(),
        kind: HermesTurnKind.reasoning,
        text: text,
      ),
    );
    return true;
  }

  int _removeReasoningDuplicatingAssistant(
    List<HermesChatTurn> turns,
    int assistantIndex,
    int firstRunTurnIndex,
  ) {
    final reply = turns[assistantIndex].text.trim();
    if (reply.isEmpty) return assistantIndex;
    for (var index = assistantIndex - 1; index >= firstRunTurnIndex; index--) {
      final turn = turns[index];
      if (turn.kind == HermesTurnKind.reasoning && turn.text.trim() == reply) {
        turns.removeAt(index);
        assistantIndex -= 1;
      }
    }
    return assistantIndex;
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
    required String? runId,
    required HermesStreamEvent event,
    required List<HermesChatTurn> turns,
    required Map<String, int> toolTurnIndexByCallId,
    required int insertBefore,
  }) {
    final toolName =
        wingOptionalStringFromJson(event.payload['tool']) ??
        wingOptionalStringFromJson(event.payload['tool_name']) ??
        'tool';
    final status = switch (event.name) {
      'tool.completed' => 'completed',
      'tool.failed' => 'failed',
      _ => 'running',
    };
    final preview = wingOptionalStringFromJson(event.payload['preview']);
    final result =
        wingOptionalStringFromJson(event.payload['result_text']) ??
        wingOptionalStringFromJson(event.payload['output']) ??
        wingOptionalStringFromJson(event.payload['result']);
    final eventCallId =
        wingOptionalStringFromJson(event.payload['tool_call_id']) ??
        wingOptionalStringFromJson(event.payload['call_id']) ??
        wingOptionalStringFromJson(event.payload['id']);
    final runKey = runId ?? sessionId;
    final callId = eventCallId == null || eventCallId.trim().isEmpty
        ? '$runKey:$toolName'
        : '$runKey:${eventCallId.trim()}';

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

  HermesApprovalRequest _approvalRequestFromEvent(
    HermesStreamEvent event, {
    required String? runId,
    required String sessionId,
  }) {
    return HermesApprovalRequest(
      id:
          wingOptionalStringFromJson(event.payload['approval_id']) ??
          wingOptionalStringFromJson(event.payload['approvalId']) ??
          wingOptionalStringFromJson(event.payload['id']) ??
          '',
      toolCallId:
          wingOptionalStringFromJson(event.payload['tool_call_id']) ??
          wingOptionalStringFromJson(event.payload['toolCallId']) ??
          '',
      prompt:
          wingOptionalStringFromJson(event.payload['prompt']) ??
          'Approval requested',
      risk: wingOptionalStringFromJson(event.payload['risk']),
      runId: runId,
      sessionId: sessionId,
    );
  }

  Future<void> _ensureDetachedRunsLoaded() async {
    if (_detachedRunsLoaded) return;
    _detachedRunsLoaded = true;
    final store = _detachedRunStore;
    if (store == null) return;
    try {
      final now = DateTime.now().toUtc();
      for (final lease in await store.load()) {
        final age = now.difference(lease.createdAt.toUtc());
        if (age.isNegative || age > const Duration(hours: 1)) continue;
        _detachedRuns[lease.runId] = lease;
      }
    } catch (_) {
      // Recovery is best-effort; never fail connection on client-store errors.
    }
  }

  Future<void> _saveDetachedRuns() async {
    final store = _detachedRunStore;
    if (store == null) return;
    final leases = _detachedRuns.values.toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    try {
      await store.save(leases);
    } catch (_) {
      // The in-memory guard still prevents duplicates in this process.
    }
  }

  Future<void> _trackDetachedRun({
    required String runId,
    required String sessionId,
    required String? profileId,
  }) async {
    await _ensureDetachedRunsLoaded();
    final baseUrl = _state.connectedBaseUrl;
    if (baseUrl == null) return;
    _detachedRuns[runId] = HermesDetachedRunLease(
      runId: runId,
      sessionId: sessionId,
      baseUrl: _detachedRunBaseUrl(baseUrl),
      profileId: profileId,
      createdAt: DateTime.now().toUtc(),
    );
    while (_detachedRuns.length > 16) {
      final oldest = _detachedRuns.values.reduce(
        (left, right) =>
            left.createdAt.isBefore(right.createdAt) ? left : right,
      );
      _detachedRuns.remove(oldest.runId);
    }
    await _saveDetachedRuns();
  }

  Future<void> _releaseDetachedRun(String runId) async {
    await _ensureDetachedRunsLoaded();
    if (_detachedRuns.remove(runId) != null) await _saveDetachedRuns();
  }

  bool _hasDetachedRun({
    required String baseUrl,
    required String? profileId,
    required String sessionId,
  }) => _detachedRuns.values.any(
    (run) =>
        run.baseUrl == _detachedRunBaseUrl(baseUrl) &&
        run.profileId == profileId &&
        run.sessionId == sessionId,
  );

  Future<void> _reattachDetachedRun({
    required HermesApiClient client,
    required String baseUrl,
    required String? profileId,
    required String sessionId,
  }) async {
    await _ensureDetachedRunsLoaded();
    final candidates =
        _detachedRuns.values
            .where(
              (run) =>
                  run.baseUrl == _detachedRunBaseUrl(baseUrl) &&
                  run.profileId == profileId &&
                  run.sessionId == sessionId,
            )
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    HermesDetachedRunLease? lease;
    for (final candidate in candidates) {
      if (_confirmedDetachedRunIds.contains(candidate.runId)) {
        lease = candidate;
        break;
      }
    }
    if (lease == null || !_isConnectedProfile(client, profileId)) return;
    final runId = lease.runId;

    final streamGeneration = ++_nextStreamGeneration;
    _sessionStreamGenerations[sessionId] = streamGeneration;
    bool isCurrentStream() =>
        _isConnectedProfile(client, profileId) &&
        _state.activeSessionId == sessionId &&
        _sessionStreamGenerations[sessionId] == streamGeneration;

    final turns = List<HermesChatTurn>.from(
      _state.messages[sessionId] ?? const [],
    );
    var assistantIndex = turns.lastIndexWhere(
      (turn) => turn.author == HermesTurnAuthor.assistant,
    );
    if (assistantIndex == -1 ||
        turns[assistantIndex].status != HermesTurnStatus.streaming) {
      turns.add(
        HermesChatTurn(
          id: 'reattached-assistant-${turns.length}',
          sessionId: sessionId,
          author: HermesTurnAuthor.assistant,
          createdAt: DateTime.now(),
          status: HermesTurnStatus.streaming,
        ),
      );
      assistantIndex = turns.length - 1;
    }
    var assistantTurn = turns[assistantIndex];
    _activeRunIds[sessionId] = runId;
    _setTurns(sessionId, List.of(turns), clearErrorMessage: true);

    final completer = Completer<void>();
    _activeStreamCompleters[sessionId] = completer;
    var terminal = false;
    var successful = false;
    late final StreamSubscription<HermesStreamEvent> subscription;
    try {
      subscription = client
          .runEvents(runId, profile: profileId)
          .listen(
            (event) {
              if (!isCurrentStream() || terminal) return;
              final delta = _streamDelta(event);
              if (delta != null && delta.isNotEmpty) {
                assistantTurn = assistantTurn.appendDelta(delta);
                turns[assistantIndex] = assistantTurn;
                _setTurns(sessionId, List.of(turns));
                return;
              }
              if (_isApprovalRequestEvent(event.name)) {
                final request = _approvalRequestFromEvent(
                  event,
                  runId: runId,
                  sessionId: sessionId,
                );
                if (request.id.isEmpty) {
                  _setTurns(
                    sessionId,
                    List.of(turns),
                    errorMessage:
                        'Hermes approval request was missing an approval id. The run is still active.',
                  );
                } else {
                  _approvalRunIds[request.id] = runId;
                  _approvalController.add(request);
                }
                return;
              }
              if (_isSuccessfulTerminalRunEvent(event.name) || event.isDone) {
                terminal = true;
                successful = true;
                if (!completer.isCompleted) completer.complete();
                return;
              }
              if (_isFailedTerminalRunEvent(event.name) ||
                  _isStreamErrorEvent(event.name)) {
                terminal = true;
                if (!completer.isCompleted) completer.complete();
              }
            },
            onError: (Object error) {
              if (!isCurrentStream() || terminal) return;
              _setTurns(
                sessionId,
                List.of(turns),
                errorMessage:
                    'Hermes run event stream failed while reconnecting: ${_safeHermesError(error)}',
              );
              if (!completer.isCompleted) completer.complete();
            },
            onDone: () {
              if (!isCurrentStream() || terminal) return;
              _setTurns(
                sessionId,
                List.of(turns),
                errorMessage:
                    'Hermes run is still active after its event stream closed. Reconnect before retrying.',
              );
              if (!completer.isCompleted) completer.complete();
            },
            cancelOnError: true,
          );
    } catch (error) {
      if (isCurrentStream()) {
        _setTurns(
          sessionId,
          List.of(turns),
          errorMessage:
              'Hermes run event stream failed to reopen: ${_safeHermesError(error)}',
        );
      }
      return;
    }
    _activeStreams[sessionId] = subscription;
    await completer.future;
    if (!isCurrentStream()) return;
    if (terminal) unawaited(subscription.cancel());
    if (identical(_activeStreams[sessionId], subscription)) {
      _activeStreams.remove(sessionId);
    }
    if (identical(_activeStreamCompleters[sessionId], completer)) {
      _activeStreamCompleters.remove(sessionId);
    }
    if (_activeRunIds[sessionId] == runId) {
      _activeRunIds.remove(sessionId);
    }
    _approvalRunIds.removeWhere((_, approvalRunId) => approvalRunId == runId);
    if (!terminal) {
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      _setTurns(sessionId, List.of(turns));
      return;
    }
    await _releaseDetachedRun(runId);
    if (!isCurrentStream()) return;
    _setState(_state.copyWith(hasUnreconciledRun: false));
    try {
      final serverTurns = await _fetchTurns(
        client,
        sessionId,
        profileId: profileId,
      );
      if (!isCurrentStream()) return;
      _setTurns(
        sessionId,
        serverTurns,
        clearErrorMessage: successful,
        errorMessage: successful ? null : 'Hermes run did not complete.',
      );
    } catch (_) {
      assistantTurn = assistantTurn.copyWith(
        status: successful
            ? HermesTurnStatus.completed
            : HermesTurnStatus.failed,
      );
      turns[assistantIndex] = assistantTurn;
      _setTurns(
        sessionId,
        List.of(turns),
        clearErrorMessage: successful,
        errorMessage: successful ? null : 'Hermes run did not complete.',
      );
    }
  }

  Future<String?> _recoverActiveDetachedSession({
    required HermesApiClient client,
    required HermesCapabilityDocument capabilities,
    required String baseUrl,
    required String? profileId,
    required Iterable<String> sessionIds,
  }) async {
    await _ensureDetachedRunsLoaded();
    final availableSessionIds = sessionIds.toSet();
    final candidates =
        _detachedRuns.values
            .where(
              (run) =>
                  run.baseUrl == _detachedRunBaseUrl(baseUrl) &&
                  run.profileId == profileId &&
                  availableSessionIds.contains(run.sessionId),
            )
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final checkedSessionIds = <String>{};
    for (final candidate in candidates) {
      if (!checkedSessionIds.add(candidate.sessionId)) continue;
      if (await _recoverDetachedRun(
        client: client,
        capabilities: capabilities,
        baseUrl: baseUrl,
        profileId: profileId,
        sessionId: candidate.sessionId,
      )) {
        return candidate.sessionId;
      }
    }
    return null;
  }

  Future<bool> _recoverDetachedRun({
    required HermesApiClient client,
    required HermesCapabilityDocument capabilities,
    required String baseUrl,
    required String? profileId,
    required String sessionId,
  }) async {
    await _ensureDetachedRunsLoaded();
    final matches = _detachedRuns.values
        .where(
          (run) =>
              run.baseUrl == _detachedRunBaseUrl(baseUrl) &&
              run.profileId == profileId &&
              run.sessionId == sessionId,
        )
        .toList(growable: false);
    if (matches.isEmpty) return false;
    if (!HermesTransportPolicy(capabilities).supportsRunStatus) return true;

    var stillActive = false;
    var changed = false;
    for (final detached in matches) {
      try {
        final run = await client.getRunStatus(
          detached.runId,
          profile: profileId,
        );
        if (run.status == HermesRunLifecycle.completed ||
            run.status == HermesRunLifecycle.failed ||
            run.status == HermesRunLifecycle.cancelled) {
          _detachedRuns.remove(detached.runId);
          _confirmedDetachedRunIds.remove(detached.runId);
          changed = true;
        } else {
          _confirmedDetachedRunIds.add(detached.runId);
          stillActive = true;
        }
      } catch (error) {
        if (error.toString().contains(hermesApiHttpStatusMessage(404))) {
          // The run registry is process-local; a gateway restart makes an old
          // lease authoritatively absent rather than indefinitely active.
          _detachedRuns.remove(detached.runId);
          _confirmedDetachedRunIds.remove(detached.runId);
          changed = true;
        } else {
          // Fail closed: a transient status failure must not authorize a retry.
          stillActive = true;
        }
      }
    }
    if (changed) await _saveDetachedRuns();
    return stillActive;
  }

  void _setTurns(
    String sessionId,
    List<HermesChatTurn> turns, {
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    final client = _client;
    if (client != null) {
      final key = _recentTurnKey(client, sessionId);
      _recentTurns.remove(key);
      _recentTurns[key] = turns.length <= 500
          ? List.unmodifiable(turns)
          : List.unmodifiable(turns.sublist(turns.length - 500));
      while (_recentTurns.length > 32) {
        _recentTurns.remove(_recentTurns.keys.first);
      }
    }
    final isActiveSession = _state.activeSessionId == sessionId;
    _setState(
      _state.copyWith(
        messages: {..._state.messages, sessionId: turns},
        errorMessage: isActiveSession ? errorMessage : null,
        clearErrorMessage: isActiveSession && clearErrorMessage,
      ),
    );
  }

  void _cancelActiveTurn() {
    final sessionId = _state.activeSessionId;
    if (sessionId != null) _finishSessionTurnLocally(sessionId);
  }

  void _stopActiveTurn() {
    final client = _client;
    final sessionId = _state.activeSessionId;
    final runId = sessionId == null ? null : _activeRunIds[sessionId];
    if (sessionId != null) _finishSessionTurnLocally(sessionId);
    final capabilities = _state.capabilities;
    final canStopRun = capabilities == null
        ? true
        : HermesTransportPolicy(capabilities).supportsRunStop;
    if (client != null && runId != null && canStopRun) {
      fireAndForget(
        client.stopRun(runId, profile: _state.selectedProfileId).then((
          _,
        ) async {
          await _releaseDetachedRun(runId);
          if (_state.activeSessionId == sessionId) {
            _setState(
              _state.copyWith(
                hasUnreconciledRun: false,
                clearErrorMessage: true,
              ),
            );
          }
        }),
        'stop detached run',
      );
    }
  }

  void _finishAllTurnsLocally() {
    final sessionIds = <String>{
      ..._activeStreamCompleters.keys,
      ..._activeStreams.keys,
      ..._activeRunIds.keys,
      for (final entry in _state.messages.entries)
        if (entry.value.lastOrNull?.status == HermesTurnStatus.streaming)
          entry.key,
    };
    for (final sessionId in sessionIds) {
      _finishSessionTurnLocally(sessionId);
    }
  }

  void _finishSessionTurnLocally(String sessionId) {
    _sessionStreamGenerations[sessionId] = ++_nextStreamGeneration;
    _markSessionStreamingTurnStopped(sessionId);
    final stream = _activeStreams.remove(sessionId);
    if (stream != null) unawaited(stream.cancel());
    final runId = _activeRunIds.remove(sessionId);
    if (runId != null) {
      _approvalRunIds.removeWhere((_, approvalRunId) => approvalRunId == runId);
    }
    final completer = _activeStreamCompleters.remove(sessionId);
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _markSessionStreamingTurnStopped(String sessionId) {
    final turns = List<HermesChatTurn>.from(
      _state.messages[sessionId] ?? const [],
    );
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

String _detachedRunBaseUrl(String value) => hermesPublicEndpointBaseUrl(value);

String _escapeAttachmentXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
