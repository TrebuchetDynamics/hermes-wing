part of '../hermes_api_channel.dart';

extension _ServeChatExtension on HermesApiChannel {
  void _retireServeChat() {
    if (_serveReader == null && _serveLifecycle == null) return;
    _serveQualification++;
    _qualifyingServeChat = false;
    unawaited(_serveChanges?.cancel());
    _serveChanges = null;
    _serveLifecycle = null;
    _serveReader?.closeLifecycle();
    for (final request in _pendingApprovals.values) {
      _approvalInvalidationController.add(request);
    }
    _pendingApprovals.clear();
  }

  Future<void> _qualifyServeChat() async {
    final reader = _serveReader;
    final session = _state.activeSessionId;
    if (reader == null ||
        session == null ||
        !_state.isConnected ||
        _state.isSelectingProfile ||
        _qualifyingServeChat) {
      return;
    }
    final checkpoint = _serveLifecycle?.recovery ?? _serveRecovery?.checkpoint;
    _retireServeChat();
    final qualification = _serveQualification;
    final selection = _sessionSelectionGeneration;
    _qualifyingServeChat = true;
    _setState(_state.copyWith(clearServeChat: true, clearErrorMessage: true));
    bool current() =>
        identical(reader, _serveReader) &&
        qualification == _serveQualification &&
        selection == _sessionSelectionGeneration &&
        !_state.isSelectingProfile &&
        session == _state.activeSessionId;
    try {
      final lifecycle = await reader.connectLifecycleForProduct();
      if (!current()) return;
      _serveLifecycle = lifecycle;
      if (checkpoint != null &&
          checkpoint.profile == _state.selectedProfileId &&
          checkpoint.storedSessionId == session &&
          checkpoint.origin.toString() == _state.connectedBaseUrl) {
        await lifecycle.recover(checkpoint);
      } else {
        await lifecycle.resumeSession(session);
      }
      if (!current()) return;
      await _persistServeRecovery(lifecycle);
      if (!current()) return;
      _serveChanges = lifecycle.changes.listen(
        (_) {
          if (current()) _syncServeChat(lifecycle);
        },
        onDone: () {
          if (current()) _syncServeChat(lifecycle);
        },
      );
      _syncServeChat(lifecycle);
    } catch (error) {
      if (!current()) return;
      reader.closeLifecycle();
      _serveLifecycle = null;
      _setState(
        _state.copyWith(
          clearServeChat: true,
          errorMessage:
              'Local serve chat is unavailable. Check session authentication and retry explicitly.',
          connectionFailureKind: _serveFailure(error),
        ),
      );
    } finally {
      if (current()) _qualifyingServeChat = false;
    }
  }

  void _syncServeChat(HermesServeLifecycle lifecycle) {
    if (!identical(lifecycle, _serveLifecycle)) return;
    final session = lifecycle.storedSessionId;
    if (session == null ||
        session != _state.activeSessionId ||
        _state.isSelectingProfile) {
      return;
    }
    final open = lifecycle.approvals;
    for (final request in _pendingApprovals.values.toList()) {
      if (open[request.id]?.serverId != request.toolCallId) {
        _pendingApprovals.remove(request.id);
        _approvalInvalidationController.add(request);
      }
    }
    for (final entry in open.entries) {
      if (_pendingApprovals.containsKey(entry.key)) continue;
      final detail = entry.value;
      final request = HermesApprovalRequest(
        id: entry.key,
        toolCallId: detail.serverId,
        prompt: detail.description.isEmpty
            ? 'Hermes requests approval.'
            : detail.description,
        command: detail.command,
        description: detail.description,
        choices: {
          HermesApprovalDecision.deny,
          if (detail.allowOnce) HermesApprovalDecision.once,
        },
        sessionId: session,
        runId: lifecycle.runtimeSessionId,
        profileId: _state.selectedProfileId,
        connectionGeneration: _connectionGeneration,
        profileSelectionGeneration: _profileSelectionGeneration,
      );
      _pendingApprovals[entry.key] = request;
      _approvalController.add(request);
    }
    _setState(
      _state.copyWith(
        serveChat: HermesServeChatState(
          canSubmit: lifecycle.canSubmit && !_serveSubmissionPending,
          running: lifecycle.running,
          stopRequested:
              lifecycle.stopRequested ||
              identical(_serveStopPending, lifecycle),
          needsReconciliation: lifecycle.needsReconciliation,
        ),
        hasUnreconciledRun: lifecycle.needsReconciliation,
        messages: {..._state.messages, session: lifecycle.turns},
      ),
    );
  }

  Future<void> _sendServeText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
  }) async {
    final lifecycle = _serveLifecycle;
    if (lifecycle == null ||
        !_state.isConnected ||
        _state.isSelectingProfile ||
        _serveSubmissionPending ||
        !lifecycle.canSubmit ||
        imageDataUrl != null ||
        textAttachment != null) {
      throw StateError('This local serve connection cannot submit this turn.');
    }
    _serveSubmissionPending = true;
    _syncServeChat(lifecycle);
    try {
      await _persistServeRecovery(lifecycle, uncertain: true);
      await lifecycle.submitText(text);
    } catch (_) {
      if (identical(lifecycle, _serveLifecycle)) {
        _setState(
          _state.copyWith(
            errorMessage:
                'Send outcome is uncertain. Reconcile this session explicitly; do not resend.',
          ),
        );
      }
      rethrow;
    } finally {
      _serveSubmissionPending = false;
      if (identical(lifecycle, _serveLifecycle)) _syncServeChat(lifecycle);
    }
  }

  Future<bool> _stopServeTurn() async {
    final lifecycle = _serveLifecycle;
    final target = activeTurnInterruptionTarget;
    if (lifecycle == null ||
        target == null ||
        identical(_serveStopPending, lifecycle) ||
        lifecycle.stopRequested) {
      return false;
    }
    _serveStopPending = lifecycle;
    _syncServeChat(lifecycle);
    try {
      await _persistServeRecovery(lifecycle, uncertain: true);
      if (!identical(lifecycle, _serveLifecycle) ||
          !target.matches(activeTurnInterruptionTarget) ||
          lifecycle.stopRequested) {
        return false;
      }
      return await lifecycle.interrupt();
    } catch (_) {
      if (identical(lifecycle, _serveLifecycle)) {
        _setState(
          _state.copyWith(
            errorMessage:
                'Stop outcome is uncertain. Reconcile this session explicitly.',
          ),
        );
      }
      return false;
    } finally {
      if (identical(_serveStopPending, lifecycle)) _serveStopPending = null;
      if (identical(lifecycle, _serveLifecycle)) _syncServeChat(lifecycle);
    }
  }

  Future<void> _answerServeApproval(
    String id,
    HermesApprovalDecision decision,
    String? runtime,
    HermesApprovalRequest? origin,
  ) async {
    final lifecycle = _serveLifecycle;
    if (lifecycle == null ||
        lifecycle.disconnected ||
        _state.isSelectingProfile ||
        origin == null ||
        !identical(_pendingApprovals[id], origin) ||
        origin.runId != runtime ||
        runtime != lifecycle.runtimeSessionId ||
        origin.sessionId != _state.activeSessionId ||
        origin.profileId != _state.selectedProfileId ||
        origin.connectionGeneration != _connectionGeneration ||
        origin.profileSelectionGeneration != _profileSelectionGeneration ||
        lifecycle.approvals[id]?.serverId != origin.toolCallId ||
        !origin.allows(decision) ||
        !{
          HermesApprovalDecision.once,
          HermesApprovalDecision.deny,
        }.contains(decision)) {
      throw StateError(
        'This approval no longer belongs to the current Hermes request.',
      );
    }
    try {
      await lifecycle.answerApproval(
        id,
        decision == HermesApprovalDecision.once,
      );
    } finally {
      if (identical(lifecycle, _serveLifecycle)) _syncServeChat(lifecycle);
    }
  }
}
