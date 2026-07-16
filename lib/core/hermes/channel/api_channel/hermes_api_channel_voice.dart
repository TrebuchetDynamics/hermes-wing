part of '../hermes_api_channel.dart';

extension _VoiceExtension on HermesApiChannel {
  String _startVoiceRun() {
    final id = 'voice-${_uuid.v4()}';
    final run = WingVoiceRun.recording(
      id: id,
      serverId: 'hermes',
      profileId: _state.activeSessionId ?? '',
      createdAt: DateTime.now(),
    );
    _setState(
      _state.copyWith(
        voiceRuns: {..._state.voiceRuns, id: run},
        activeVoiceRunId: id,
      ),
    );
    return id;
  }

  void _stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
  }) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null || run.isTerminal) return;
    _updateVoiceRun(
      run.withDeviceTranscript(
        transcript: transcript,
        duration: duration,
        confidence: confidence,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _submitVoiceRun(String voiceRunId) {
    final run = _state.voiceRuns[voiceRunId];
    final transcript = run?.transcript;
    if (run == null || run.isTerminal || transcript == null) {
      return;
    }
    final trimmedTranscript = transcript.trim();
    if (trimmedTranscript.isEmpty) {
      _updateVoiceRun(run.markFailed('Hermes voice transcript was empty.'));
      return;
    }
    final submittedSessionId = _state.activeSessionId;
    final capabilities = _state.capabilities;
    if (submittedSessionId == null) {
      _updateVoiceRun(
        run.markFailed('Hermes channel is not connected to a session.'),
      );
      return;
    }
    if (capabilities != null &&
        !HermesTransportPolicy(capabilities).supportsAnyChatTransport) {
      _updateVoiceRun(
        run.markFailed(
          'Hermes did not advertise a supported chat transport for this endpoint.',
        ),
      );
      return;
    }
    _updateVoiceRun(
      run.markSubmitted(requestId: voiceRunId, sessionId: submittedSessionId),
    );
    _sendText(trimmedTranscript)
        .then((_) {
          final current = _state.voiceRuns[voiceRunId];
          if (current == null || current.isTerminal) return;
          if (current.sessionId != submittedSessionId ||
              _state.activeSessionId != submittedSessionId) {
            _updateVoiceRun(
              current.markFailed(
                'Hermes session changed before voice turn completed.',
              ),
            );
            return;
          }
          final assistantTurns =
              (_state.messages[submittedSessionId] ?? const []).where(
                (turn) => turn.author == HermesTurnAuthor.assistant,
              );
          final assistantReply = assistantTurns.lastOrNull;
          if (assistantReply == null ||
              assistantReply.status == HermesTurnStatus.failed ||
              assistantReply.text.trim().isEmpty) {
            _updateVoiceRun(
              current.markFailed('Hermes voice turn did not complete.'),
            );
            return;
          }
          _updateVoiceRun(current.markCompleted());
        })
        .catchError((Object error) {
          final current = _state.voiceRuns[voiceRunId];
          if (current != null && !current.isTerminal) {
            _updateVoiceRun(current.markFailed(_safeHermesError(error)));
          }
        });
  }

  void _cancelVoiceRun(String voiceRunId, {String reason = 'cancelled'}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null || run.isTerminal) return;
    _updateVoiceRun(run.markCancelled(reason));
  }

  void _failVoiceRun(String voiceRunId, {required String reason}) {
    final run = _state.voiceRuns[voiceRunId];
    if (run == null || run.isTerminal) return;
    _updateVoiceRun(run.markFailed(reason));
  }

  void _updateVoiceRun(WingVoiceRun run) {
    _setState(_state.copyWith(voiceRuns: {..._state.voiceRuns, run.id: run}));
  }
}
