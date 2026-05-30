import '../../../../core/channel/navivox_channel.dart';
import '../../../../core/protocol/navivox_voice_run.dart';
import '../../../../core/protocol/voice_unavailable_reason.dart';
import '../../../voice/services/speech/speech_to_text_voice_capture_service.dart';
import '../../../voice/services/capture/voice_capture_service.dart';

class VoiceRunFailureResult {
  const VoiceRunFailureResult({
    required this.reason,
    this.runtimeVoiceDisabledReason,
  });

  final String reason;
  final String? runtimeVoiceDisabledReason;
}

class VoiceRunCaptureResult {
  const VoiceRunCaptureResult({
    required this.handledLocalCommand,
    this.scheduleAutoSendFor,
  });

  final bool handledLocalCommand;
  final String? scheduleAutoSendFor;
}

class VoiceRunAutoSendResult {
  const VoiceRunAutoSendResult({required this.submitted});

  final bool submitted;
}

class VoiceRunCancelResult {
  const VoiceRunCancelResult({this.cancelledVoiceRunId});

  final String? cancelledVoiceRunId;
}

class VoiceRunController {
  String? pendingVoiceRunId;
  String? runtimeVoiceDisabledReason;
  String? notice;

  void clearRuntimeVoiceDisabledReason() {
    runtimeVoiceDisabledReason = null;
  }

  String startCapture(NavivoxChannel channel) {
    pendingVoiceRunId = channel.startVoiceRun();
    return pendingVoiceRunId!;
  }

  VoiceRunFailureResult captureFailed(NavivoxChannel channel, Object error) {
    final reason = _failureReason(error);
    final id = pendingVoiceRunId;
    if (id != null) {
      channel.failVoiceRun(id, reason: reason);
    }
    pendingVoiceRunId = null;
    final runtimeReason = error is DeviceSpeechUnavailable ? reason : null;
    if (runtimeReason != null) {
      runtimeVoiceDisabledReason = runtimeReason;
    }
    return VoiceRunFailureResult(
      reason: reason,
      runtimeVoiceDisabledReason: runtimeReason,
    );
  }

  VoiceRunCaptureResult captureSucceeded(
    NavivoxChannel channel,
    VoiceCapture capture, {
    required bool Function(String transcript) handleLocalCommand,
  }) {
    if (handleLocalCommand(capture.transcript)) {
      final id = pendingVoiceRunId;
      if (id != null) {
        channel.cancelVoiceRun(id, reason: 'local voice command');
        pendingVoiceRunId = null;
      }
      return const VoiceRunCaptureResult(handledLocalCommand: true);
    }

    final voiceRunId = pendingVoiceRunId ?? channel.startVoiceRun();
    pendingVoiceRunId = voiceRunId;
    channel.stageVoiceRunTranscript(
      voiceRunId: voiceRunId,
      transcript: capture.transcript,
      duration: capture.duration,
      confidence: capture.confidence,
    );
    notice = 'Sending...';
    return VoiceRunCaptureResult(
      handledLocalCommand: false,
      scheduleAutoSendFor: voiceRunId,
    );
  }

  VoiceRunAutoSendResult autoSendIfPending(
    NavivoxChannel channel,
    String voiceRunId,
  ) {
    if (pendingVoiceRunId != voiceRunId) {
      return const VoiceRunAutoSendResult(submitted: false);
    }
    final run = channel.state.voiceRuns[voiceRunId];
    if (run?.status != NavivoxVoiceRunStatus.pendingSend) {
      return const VoiceRunAutoSendResult(submitted: false);
    }
    pendingVoiceRunId = null;
    notice = null;
    channel.submitVoiceRun(voiceRunId);
    return const VoiceRunAutoSendResult(submitted: true);
  }

  VoiceRunCancelResult cancelPending(NavivoxChannel? channel) {
    final voiceRunId = pendingVoiceRunId ?? channel?.state.activeVoiceRun?.id;
    if (channel != null && voiceRunId != null) {
      channel.cancelVoiceRun(voiceRunId);
    }
    pendingVoiceRunId = null;
    notice = 'Voice turn cancelled before server commit.';
    return VoiceRunCancelResult(cancelledVoiceRunId: voiceRunId);
  }

  String _failureReason(Object error) {
    if (error is VoiceCaptureTimeout) return 'Voice capture timed out.';
    if (error is DeviceSpeechUnavailable) {
      return canonicalVoiceUnavailableReason(
            error.message,
            emptyAsNull: true,
          ) ??
          deviceSttUnavailableReason;
    }
    if (error is SpeechToTextCaptureFailure && error.isNoTranscript) {
      return noSpeechDetectedVoiceCaptureMessage;
    }
    return 'Voice capture failed.';
  }
}
