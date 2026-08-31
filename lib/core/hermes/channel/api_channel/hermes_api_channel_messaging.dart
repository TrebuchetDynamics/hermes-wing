part of '../hermes_api_channel.dart';

final class _DetachedRunAdmissionFailure implements Exception {
  const _DetachedRunAdmissionFailure({
    required this.runId,
    required this.sessionId,
    required this.createdAt,
    required this.cause,
  });

  final String runId;
  final String sessionId;
  final DateTime createdAt;
  final Object cause;
}

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
    final safeLabel = canonicalHermesAttachmentName(
      attachmentName,
      fallback: hasTextFile ? 'attachment.txt' : 'attachment',
    );
    final textFilePart = hasTextFile
        ? '<file name="${escapeHermesAttachmentName(safeLabel)}" mime="text/plain">\n$textAttachment\n</file>'
        : null;
    final Object requestMessage = hasImage || hasTextFile
        ? [
            if (message.isNotEmpty) {'type': 'input_text', 'text': message},
            if (textFilePart != null)
              {'type': 'input_text', 'text': textFilePart},
            if (hasImage) {'type': 'input_image', 'image_url': image},
          ]
        : message;
    final client = _client;
    final sessionId = _state.activeSessionId;
    final profileId = _state.selectedProfileId;
    if (client == null || sessionId == null) {
      throw StateError('Hermes channel is not connected to a session.');
    }
    await _ensureDetachedRunsLoaded();
    if (_detachedRunsLoadFailed) {
      const message =
          'Wing could not load durable Hermes run recovery state. Reconnect before sending.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
    if (_hasUnresolvedLegacyDetachedRun(
      baseUrl: _state.connectedBaseUrl,
      profileId: profileId,
    )) {
      const message =
          'Wing could not verify a previous Hermes run. Reconnect before sending.';
      _setState(_state.copyWith(errorMessage: message));
      throw StateError(message);
    }
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
        text: message,
        attachment: hasImage || hasTextFile
            ? HermesTurnAttachment(
                name: safeLabel,
                kind: hasImage
                    ? HermesAttachmentKind.image
                    : HermesAttachmentKind.file,
              )
            : null,
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
    var serverAssistantReplyObserved = false;
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
    String? runOwnershipSessionId;
    try {
      if (useRunTransport) {
        final store = _detachedRunStore;
        if (store == null) {
          final run = await client.startRun(
            sessionId: sessionId,
            message: requestMessage,
            profile: profileId,
          );
          if (run.id.isEmpty) {
            throw StateError('Hermes returned a run without an id.');
          }
          runId = run.id;
          runOwnershipSessionId = run.sessionId;
        } else {
          final admission = await _runDetachedStoreOperation(store, () async {
            final merged = <String, HermesDetachedRunLease>{};
            for (final lease in await store.load()) {
              merged[_detachedRunKey(lease)] = lease;
            }
            if (merged.length >= 16) {
              throw StateError(
                'Wing durable Hermes run recovery capacity is full. Reconnect before sending.',
              );
            }
            if (!isCurrentStream()) {
              throw StateError('Hermes run submission was cancelled.');
            }
            final run = await client.startRun(
              sessionId: sessionId,
              message: requestMessage,
              profile: profileId,
            );
            if (run.id.isEmpty) {
              throw StateError('Hermes returned a run without an id.');
            }
            final lease = HermesDetachedRunLease(
              runId: run.id,
              sessionId: run.sessionId,
              baseUrl: _detachedRunBaseUrl(connectedBaseUrl!),
              profileId: profileId,
              createdAt: DateTime.now().toUtc(),
            );
            merged[_detachedRunKey(lease)] = lease;
            if (merged.length > 16) {
              throw StateError(
                'Wing durable Hermes run recovery capacity is full. Reconnect before sending.',
              );
            }
            final leases = merged.values.toList(growable: false);
            try {
              await store.save(leases);
            } catch (error) {
              throw _DetachedRunAdmissionFailure(
                runId: run.id,
                sessionId: run.sessionId,
                createdAt: lease.createdAt,
                cause: error,
              );
            }
            return (runId: run.id, sessionId: run.sessionId, leases: leases);
          });
          runId = admission.runId;
          runOwnershipSessionId = admission.sessionId;
          _replaceDetachedRuns(admission.leases);
        }
        if (runOwnershipSessionId != sessionId) {
          throw StateError(
            'Hermes returned a run that does not match the requested session.',
          );
        }
      } else {
        events = client.streamSessionChat(
          sessionId,
          message: requestMessage,
          profile: profileId,
        );
      }
    } catch (error) {
      if (error is _DetachedRunAdmissionFailure) {
        runId = error.runId;
        runOwnershipSessionId = error.sessionId;
        if (connectedBaseUrl != null) {
          final provisionalLease = HermesDetachedRunLease(
            runId: error.runId,
            sessionId: error.sessionId,
            baseUrl: _detachedRunBaseUrl(connectedBaseUrl),
            profileId: profileId,
            createdAt: error.createdAt,
          );
          _detachedRuns[_detachedRunKey(provisionalLease)] = provisionalLease;
        }
      }
      final runOwnershipUncertain = runId != null;
      var runStopped = false;
      if (runOwnershipUncertain &&
          (capabilities == null ||
              HermesTransportPolicy(capabilities).supportsRunStop)) {
        try {
          await client.stopRun(runId, profile: profileId);
          runStopped = true;
          await _releaseDetachedRunBestEffort(
            runId: runId,
            sessionId: runOwnershipSessionId!,
            profileId: profileId,
            baseUrl: connectedBaseUrl,
            expectedCreatedAt: error is _DetachedRunAdmissionFailure
                ? error.createdAt
                : null,
          );
        } catch (_) {
          // Keep exact provisional/durable ownership when Stop cannot complete.
        }
      }
      if (!identical(_client, client) ||
          _state.status != HermesConnectionStatus.connected ||
          !isCurrentStream()) {
        return;
      }
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      final message = runStopped
          ? 'Hermes run was stopped because Wing could not persist its recovery lease.'
          : runOwnershipUncertain
          ? 'Hermes run started, but Wing could not persist its recovery lease. The run remains blocked from duplicate submission.'
          : _safeHermesError(error);
      _setState(
        _state.copyWith(
          hasUnreconciledRun: runOwnershipUncertain
              ? _sessionHasDetachedRun(
                  sessionId: sessionId,
                  profileId: profileId,
                )
              : _state.hasUnreconciledRun,
        ),
      );
      _setTurns(sessionId, turns, errorMessage: message);
      if (runOwnershipUncertain) throw StateError(message);
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
    HermesRun? recoveredRun;
    final canReadRunStatus =
        runId != null &&
        capabilities != null &&
        HermesTransportPolicy(capabilities).supportsRunStatus;
    Timer? idleTimer;
    Timer? runStatusTimer;
    var runStatusProbeActive = false;
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

    void armRunStatusTimer() {
      runStatusTimer?.cancel();
      if (!canReadRunStatus ||
          completer.isCompleted ||
          runStatusReconcileInterval <= Duration.zero) {
        return;
      }
      runStatusTimer = Timer(runStatusReconcileInterval, () async {
        if (!isCurrentStream() ||
            completer.isCompleted ||
            runStatusProbeActive) {
          return;
        }
        runStatusProbeActive = true;
        try {
          final status = await client.getRunStatus(runId!, profile: profileId);
          if (!isCurrentStream() || completer.isCompleted) return;
          if (status.id != runId || status.sessionId != sessionId) return;
          recoveredRun = status;
          runUsage ??= status.usage;
          switch (status.status) {
            case HermesRunLifecycle.completed:
              final output = status.output?.trim();
              if (output?.isNotEmpty == true) {
                assistantTurn = assistantTurn.copyWith(
                  text: reconcileAssistantText(
                    streamed: assistantTurn.text,
                    canonical: output!,
                  ),
                  usage: runUsage,
                );
                turns[assistantIndex] = assistantTurn;
              }
              terminalRunEventReceived = true;
              terminalRunLifecycleReceived = true;
              _setTurns(sessionId, List.of(turns), clearErrorMessage: true);
              completer.complete();
            case HermesRunLifecycle.failed:
              streamFailed = true;
              terminalRunEventReceived = true;
              terminalRunLifecycleReceived = true;
              assistantTurn = assistantTurn.copyWith(
                status: HermesTurnStatus.failed,
              );
              turns[assistantIndex] = assistantTurn;
              final detail = status.error?.trim();
              _setTurns(
                sessionId,
                List.of(turns),
                errorMessage: detail?.isNotEmpty == true
                    ? 'Hermes run failed: ${_safeHermesError(detail!)}'
                    : 'Hermes run failed.',
              );
              completer.complete();
            case HermesRunLifecycle.cancelled:
              streamFailed = true;
              terminalRunEventReceived = true;
              terminalRunLifecycleReceived = true;
              assistantTurn = assistantTurn.copyWith(
                status: HermesTurnStatus.failed,
              );
              turns[assistantIndex] = assistantTurn;
              _setTurns(
                sessionId,
                List.of(turns),
                errorMessage: 'Hermes run was cancelled.',
              );
              completer.complete();
            case HermesRunLifecycle.queued:
            case HermesRunLifecycle.running:
            case HermesRunLifecycle.unknown:
              break;
          }
        } catch (_) {
          // The event stream remains authoritative when status probing fails.
        } finally {
          runStatusProbeActive = false;
          if (!completer.isCompleted) armRunStatusTimer();
        }
      });
    }

    late final StreamSubscription<HermesStreamEvent> subscription;
    try {
      subscription = events.listen(
        (event) {
          if (!isCurrentStream() || terminalRunEventReceived) {
            return;
          }
          if (useRunTransport &&
              runId != null &&
              !_eventMatchesOwnedRun(
                event,
                expectedRunId: runId,
                expectedSessionId: sessionId,
              )) {
            return;
          }
          armIdleTimer();
          if (event.isDone) {
            if (useRunTransport) return;
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
            if (runId != null) {
              _approvalResponder.registerApproval(request.id, runId);
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
          assistantTurn = assistantTurn.copyWith(
            status: HermesTurnStatus.failed,
          );
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
    } catch (error) {
      if (_activeRunIds[sessionId] == runId) {
        _activeRunIds.remove(sessionId);
      }
      if (identical(_activeStreamCompleters[sessionId], completer)) {
        _activeStreamCompleters.remove(sessionId);
      }
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      final message =
          'Hermes run event stream failed to open: ${_safeHermesError(error)}';
      _setTurns(sessionId, List.of(turns), errorMessage: message);
      if (useRunTransport && runId != null) {
        _setState(_state.copyWith(hasUnreconciledRun: true));
      }
      return;
    }
    _activeStreams[sessionId] = subscription;
    armIdleTimer();
    armRunStatusTimer();
    await completer.future;
    idleTimer?.cancel();
    runStatusTimer?.cancel();
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
      _approvalResponder.forgetApprovalsForRun(runId);
      if (terminalRunLifecycleReceived) {
        await _releaseDetachedRunBestEffort(
          runId: runId,
          sessionId: sessionId,
          profileId: profileId,
          baseUrl: connectedBaseUrl,
        );
      }
    }
    if (!isCurrentStream()) return;
    if (canReadRunStatus &&
        recoveredRun == null &&
        (streamFailed || runUsage == null)) {
      try {
        final status = await client.getRunStatus(runId, profile: profileId);
        if (!isCurrentStream()) return;
        if (status.id != runId || status.sessionId != sessionId) {
          _setState(
            _state.copyWith(hasUnreconciledRun: _activeSessionHasDetachedRun()),
          );
        } else {
          recoveredRun = status;
          runUsage ??= status.usage;
          final recoveredError = status.error?.trim();
          final currentError = _state.errorMessage ?? '';
          final alreadyHasServerDetail =
              currentError.startsWith('Hermes run failed:') ||
              currentError.startsWith('Hermes stream reported an error:');
          if (streamFailed &&
              status.status == HermesRunLifecycle.failed &&
              !alreadyHasServerDetail &&
              recoveredError?.isNotEmpty == true) {
            _setTurns(
              sessionId,
              List.of(turns),
              errorMessage:
                  'Hermes run failed: ${_safeHermesError(recoveredError!)}',
            );
          }
          if (status.status == HermesRunLifecycle.completed ||
              status.status == HermesRunLifecycle.failed ||
              status.status == HermesRunLifecycle.cancelled) {
            await _releaseDetachedRunBestEffort(
              runId: runId,
              sessionId: sessionId,
              profileId: profileId,
              baseUrl: connectedBaseUrl,
            );
          }
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
        _setState(
          _state.copyWith(hasUnreconciledRun: _activeSessionHasDetachedRun()),
        );
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
        serverAssistantReplyObserved =
            _serverHistoryHasAssistantReplyForCurrentTurn(
              serverTurns,
              message,
              preSendTurnCount,
            );
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
    final terminalRunFollowedActiveStatus =
        recoveredRun?.status == HermesRunLifecycle.queued ||
        recoveredRun?.status == HermesRunLifecycle.running;
    if ((!useRunTransport || terminalRunFollowedActiveStatus) &&
        !streamFailed &&
        terminalRunEventReceived &&
        assistantTurn.text.trim().isEmpty &&
        !serverAssistantReplyObserved) {
      _setTurns(
        sessionId,
        List.of(_recentTurns[_recentTurnKey(client, sessionId)] ?? turns),
        errorMessage: 'Hermes finished without an assistant reply.',
      );
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

  bool _eventMatchesOwnedRun(
    HermesStreamEvent event, {
    required String expectedRunId,
    required String expectedSessionId,
  }) {
    final eventRunId = wingOptionalStringFromJson(event.payload['run_id']);
    if (eventRunId != null && eventRunId != expectedRunId) return false;
    final eventSessionId = wingOptionalStringFromJson(
      event.payload['session_id'],
    );
    return eventSessionId == null || eventSessionId == expectedSessionId;
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

  Future<void> _ensureDetachedRunsLoaded() {
    return _detachedRunsLoadFuture ??= _loadDetachedRuns();
  }

  Future<void> _loadDetachedRuns() async {
    final store = _detachedRunStore;
    if (store == null) return;
    try {
      final leases = await _runDetachedStoreOperation(store, store.load);
      _replaceDetachedRuns(leases);
    } catch (_) {
      _detachedRunsLoadFailed = true;
    }
  }

  void _replaceDetachedRuns(Iterable<HermesDetachedRunLease> leases) {
    _detachedRuns.clear();
    for (final lease in leases) {
      _detachedRuns[_detachedRunKey(lease)] = lease;
    }
  }

  Future<T> _runDetachedStoreOperation<T>(
    HermesDetachedRunStore store,
    Future<T> Function() operation,
  ) {
    final key = store.coordinationKey;
    final predecessor =
        HermesApiChannel._detachedRunOperationTails[key] ??
        Future<void>.value();
    final result = predecessor.then((_) => operation());
    final tail = result.then<void>((_) {}, onError: (_, _) {});
    HermesApiChannel._detachedRunOperationTails[key] = tail;
    tail.whenComplete(() {
      if (identical(HermesApiChannel._detachedRunOperationTails[key], tail)) {
        HermesApiChannel._detachedRunOperationTails.remove(key);
      }
    });
    return result;
  }

  Future<void> _persistDetachedMutation({
    Iterable<HermesDetachedRunLease> upserts = const [],
    Iterable<String> removals = const [],
  }) async {
    final store = _detachedRunStore;
    if (store == null) return;
    final committed = await _runDetachedStoreOperation(store, () async {
      final merged = <String, HermesDetachedRunLease>{};
      for (final lease in await store.load()) {
        merged[_detachedRunKey(lease)] = lease;
      }
      for (final key in removals) {
        merged.remove(key);
      }
      for (final lease in upserts) {
        merged[_detachedRunKey(lease)] = lease;
      }
      final leases = merged.values.toList(growable: false);
      if (leases.length > 16) {
        throw StateError(
          'Wing durable Hermes run recovery capacity is full. Reconnect before sending.',
        );
      }
      await store.save(leases);
      return leases;
    });
    _replaceDetachedRuns(committed);
  }

  Future<void> _trackDetachedRun({
    required String runId,
    required String sessionId,
    required String? profileId,
  }) async {
    await _ensureDetachedRunsLoaded();
    final baseUrl = _state.connectedBaseUrl;
    if (baseUrl == null) return;
    final lease = HermesDetachedRunLease(
      runId: runId,
      sessionId: sessionId,
      baseUrl: _detachedRunBaseUrl(baseUrl),
      profileId: profileId,
      createdAt: DateTime.now().toUtc(),
    );
    final key = _detachedRunKey(lease);
    if (!_detachedRuns.containsKey(key) && _detachedRuns.length >= 16) {
      throw StateError(
        'Wing durable Hermes run recovery capacity is full. Reconnect before sending.',
      );
    }
    _detachedRuns[key] = lease;
    await _persistDetachedMutation(upserts: [lease]);
  }

  String _detachedRunKey(HermesDetachedRunLease lease) => [
    lease.baseUrl,
    lease.profileId ?? '',
    lease.sessionId,
    lease.runId,
  ].join('\u0000');

  Future<void> _releaseDetachedRun({
    required String runId,
    required String sessionId,
    required String? profileId,
    String? baseUrl,
    DateTime? expectedCreatedAt,
  }) async {
    await _ensureDetachedRunsLoaded();
    final resolvedBaseUrl = baseUrl ?? _state.connectedBaseUrl;
    if (resolvedBaseUrl == null) return;
    final lease = HermesDetachedRunLease(
      runId: runId,
      sessionId: sessionId,
      baseUrl: _detachedRunBaseUrl(resolvedBaseUrl),
      profileId: profileId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    final key = _detachedRunKey(lease);
    _confirmedDetachedRunKeys.remove(key);
    final current = _detachedRuns[key];
    if (expectedCreatedAt != null &&
        current != null &&
        current.createdAt != expectedCreatedAt) {
      return;
    }
    _detachedRuns.remove(key);
    if (expectedCreatedAt == null) {
      await _persistDetachedMutation(removals: [key]);
      return;
    }
    final store = _detachedRunStore;
    if (store == null) return;
    final committed = await _runDetachedStoreOperation(store, () async {
      final merged = <String, HermesDetachedRunLease>{};
      for (final persisted in await store.load()) {
        merged[_detachedRunKey(persisted)] = persisted;
      }
      final persisted = merged[key];
      if (persisted == null || persisted.createdAt == expectedCreatedAt) {
        merged.remove(key);
        await store.save(merged.values.toList(growable: false));
      }
      return merged.values.toList(growable: false);
    });
    _replaceDetachedRuns(committed);
  }

  Future<void> _releaseDetachedRunBestEffort({
    required String runId,
    required String sessionId,
    required String? profileId,
    String? baseUrl,
    DateTime? expectedCreatedAt,
  }) async {
    try {
      await _releaseDetachedRun(
        runId: runId,
        sessionId: sessionId,
        profileId: profileId,
        baseUrl: baseUrl,
        expectedCreatedAt: expectedCreatedAt,
      );
    } catch (_) {
      // A stale durable lease remains conservative and is reconciled later.
    }
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

  bool _hasUnresolvedLegacyDetachedRun({
    required String? baseUrl,
    required String? profileId,
  }) =>
      baseUrl != null &&
      _detachedRuns.values.any(
        (run) =>
            run.baseUrl == _detachedRunBaseUrl(baseUrl) &&
            run.profileId == profileId &&
            run.sessionId.isEmpty,
      );

  bool _sessionHasDetachedRun({
    required String? sessionId,
    String? baseUrl,
    String? profileId,
  }) {
    final resolvedBaseUrl = baseUrl ?? _state.connectedBaseUrl;
    if (resolvedBaseUrl == null || sessionId == null) return false;
    return _hasDetachedRun(
      baseUrl: resolvedBaseUrl,
      profileId: profileId ?? _state.selectedProfileId,
      sessionId: sessionId,
    );
  }

  bool _activeSessionHasDetachedRun() =>
      _sessionHasDetachedRun(sessionId: _state.activeSessionId);

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
      if (_confirmedDetachedRunKeys.contains(_detachedRunKey(candidate))) {
        lease = candidate;
        break;
      }
    }
    if (lease == null || !_isConnectedProfile(client, profileId)) return;
    final runId = lease.runId;
    if (_activeRunIds[sessionId] == runId &&
        _activeStreams.containsKey(sessionId)) {
      return;
    }

    final streamGeneration = ++_nextStreamGeneration;
    _sessionStreamGenerations[sessionId] = streamGeneration;
    bool isCurrentStream() =>
        _isConnectedProfile(client, profileId) &&
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
              if (!_eventMatchesOwnedRun(
                event,
                expectedRunId: runId,
                expectedSessionId: sessionId,
              )) {
                return;
              }
              if (event.isDone) return;
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
                  _approvalResponder.registerApproval(request.id, runId);
                  _approvalController.add(request);
                }
                return;
              }
              if (_isSuccessfulTerminalRunEvent(event.name)) {
                terminal = true;
                successful = true;
                if (!completer.isCompleted) completer.complete();
                return;
              }
              if (_isFailedTerminalRunEvent(event.name)) {
                terminal = true;
                if (!completer.isCompleted) completer.complete();
                return;
              }
              if (_isStreamErrorEvent(event.name)) {
                _setTurns(
                  sessionId,
                  List.of(turns),
                  errorMessage: _streamErrorMessage(event),
                );
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
      if (identical(_activeStreamCompleters[sessionId], completer)) {
        _activeStreamCompleters.remove(sessionId);
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
    if (terminal && _activeRunIds[sessionId] == runId) {
      _activeRunIds.remove(sessionId);
    }
    if (!terminal) {
      assistantTurn = assistantTurn.copyWith(status: HermesTurnStatus.failed);
      turns[assistantIndex] = assistantTurn;
      _setTurns(sessionId, List.of(turns));
      return;
    }
    _approvalResponder.forgetApprovalsForRun(runId);
    await _releaseDetachedRunBestEffort(
      runId: runId,
      sessionId: sessionId,
      profileId: profileId,
      baseUrl: baseUrl,
    );
    if (!isCurrentStream()) return;
    _setState(
      _state.copyWith(hasUnreconciledRun: _activeSessionHasDetachedRun()),
    );
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
    final removedKeys = <String>[];
    for (final detached in matches) {
      try {
        final run = await client.getRunStatus(
          detached.runId,
          profile: profileId,
        );
        if (run.id != detached.runId || run.sessionId != sessionId) {
          // A status response for another ownership tuple is not authoritative.
          // Keep the lease and fail closed without reattaching.
          stillActive = true;
          continue;
        }
        if (run.status == HermesRunLifecycle.completed ||
            run.status == HermesRunLifecycle.failed ||
            run.status == HermesRunLifecycle.cancelled) {
          final key = _detachedRunKey(detached);
          _detachedRuns.remove(key);
          _confirmedDetachedRunKeys.remove(key);
          removedKeys.add(key);
        } else {
          _confirmedDetachedRunKeys.add(_detachedRunKey(detached));
          stillActive = true;
        }
      } catch (error) {
        if (error.toString().contains(hermesApiHttpStatusMessage(404))) {
          // The run registry is process-local; a gateway restart makes an old
          // lease authoritatively absent rather than indefinitely active.
          final key = _detachedRunKey(detached);
          _detachedRuns.remove(key);
          _confirmedDetachedRunKeys.remove(key);
          removedKeys.add(key);
        } else {
          // Fail closed: a transient status failure must not authorize a retry.
          stillActive = true;
        }
      }
    }
    if (removedKeys.isNotEmpty) {
      try {
        await _persistDetachedMutation(removals: removedKeys);
      } catch (_) {
        // Matching terminal status or 404 already resolved current ownership.
        // A stale durable lease remains conservative until later recovery.
      }
    }
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
    final connectionGeneration = _connectionGeneration;
    final sessionId = _state.activeSessionId;
    final runId = sessionId == null ? null : _activeRunIds[sessionId];
    final profileId = _state.selectedProfileId;
    final baseUrl = _state.connectedBaseUrl;
    final detachedLeaseCreatedAt =
        runId == null || sessionId == null || baseUrl == null
        ? null
        : _detachedRuns.values
              .where(
                (lease) =>
                    lease.runId == runId &&
                    lease.sessionId == sessionId &&
                    lease.profileId == profileId &&
                    lease.baseUrl == _detachedRunBaseUrl(baseUrl),
              )
              .firstOrNull
              ?.createdAt;
    if (sessionId != null) {
      _finishSessionTurnLocally(sessionId);
      _setState(
        _state.copyWith(
          hasUnreconciledRun: _sessionHasDetachedRun(
            sessionId: sessionId,
            profileId: profileId,
          ),
        ),
      );
    }
    final capabilities = _state.capabilities;
    final canStopRun = capabilities == null
        ? true
        : HermesTransportPolicy(capabilities).supportsRunStop;
    if (client != null && sessionId != null && runId != null && canStopRun) {
      fireAndForget(
        client.stopRun(runId, profile: profileId).then((_) async {
          final stillCurrent =
              _isCurrentConnection(connectionGeneration, client) &&
              _state.selectedProfileId == profileId;
          if (!stillCurrent &&
              _state.status != HermesConnectionStatus.disconnected) {
            return;
          }
          await _releaseDetachedRunBestEffort(
            runId: runId,
            sessionId: sessionId,
            profileId: profileId,
            baseUrl: baseUrl,
            expectedCreatedAt: detachedLeaseCreatedAt,
          );
          if (!stillCurrent) return;
          final activeHasDetachedRun = _activeSessionHasDetachedRun();
          _setState(
            _state.copyWith(
              hasUnreconciledRun: activeHasDetachedRun,
              clearErrorMessage: !activeHasDetachedRun,
            ),
          );
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
      _approvalResponder.forgetApprovalsForRun(runId);
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
