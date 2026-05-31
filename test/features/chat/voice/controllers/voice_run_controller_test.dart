import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';
import 'package:navivox/features/chat/voice/controllers/voice_run_controller.dart';
import 'package:navivox/shared/voice/voice_capture_failures.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

import '../../../shared/fakes/voice_capture_service_fakes.dart';
import '../../shared/profile_contact_chat_test_fixtures.dart';
import '../../shared/voice_recovery_test_fixtures.dart';

void main() {
  test('startCapture records the active Voice run id', () {
    final channel = mineruReadyProfileChannel(micAvailable: true);
    final controller = VoiceRunController();

    final voiceRunId = controller.startCapture(channel);

    expect(controller.pendingVoiceRunId, voiceRunId);
    expect(channel.state.activeVoiceRun?.id, voiceRunId);
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.recording,
    );
  });

  test('captureFailed maps timeout copy, fails run, and clears pending id', () {
    final channel = mineruReadyProfileChannel(micAvailable: true);
    final controller = VoiceRunController();
    final voiceRunId = controller.startCapture(channel);

    final result = controller.captureFailed(
      channel,
      const VoiceCaptureTimeout(),
    );

    expect(result.reason, 'Voice capture timed out.');
    expect(result.runtimeVoiceDisabledReason, isNull);
    expect(controller.pendingVoiceRunId, isNull);
    expect(controller.runtimeVoiceDisabledReason, isNull);
    expect(
      channel.state.voiceRuns[voiceRunId]?.status,
      NavivoxVoiceRunStatus.failed,
    );
    expect(
      channel.state.voiceRuns[voiceRunId]?.reason,
      'Voice capture timed out.',
    );
  });

  test('captureFailed canonicalizes runtime device STT failures', () {
    final channel = mineruReadyProfileChannel(micAvailable: true);
    final controller = VoiceRunController()..startCapture(channel);

    final result = controller.captureFailed(
      channel,
      const DeviceSpeechUnavailable(microphonePermissionDeniedReason),
    );

    expect(result.reason, microphonePermissionDeniedReason);
    expect(result.runtimeVoiceDisabledReason, microphonePermissionDeniedReason);
    expect(
      controller.runtimeVoiceDisabledReason,
      microphonePermissionDeniedReason,
    );
    expect(channel.state.activeVoiceRun?.status, NavivoxVoiceRunStatus.failed);
  });

  test('clearRuntimeVoiceDisabledReason resets session voice blocker', () {
    final controller = VoiceRunController()
      ..runtimeVoiceDisabledReason = deviceSttUnavailableReason;

    controller.clearRuntimeVoiceDisabledReason();

    expect(controller.runtimeVoiceDisabledReason, isNull);
  });

  test('captureFailed maps no transcript to actionable recovery copy', () {
    final channel = mineruReadyProfileChannel(micAvailable: true);
    final controller = VoiceRunController();
    final voiceRunId = controller.startCapture(channel);

    final result = controller.captureFailed(
      channel,
      const SpeechToTextCaptureFailure('no transcript'),
    );

    expect(result.reason, noSpeechDetectedVoiceCaptureMessage);
    expect(result.runtimeVoiceDisabledReason, isNull);
    expect(
      channel.state.voiceRuns[voiceRunId]?.status,
      NavivoxVoiceRunStatus.failed,
    );
    expect(
      channel.state.voiceRuns[voiceRunId]?.reason,
      noSpeechDetectedVoiceCaptureMessage,
    );
  });

  test('captureSucceeded cancels a started Voice run for Local commands', () {
    final channel = mineruReadyProfileChannel(micAvailable: true);
    final controller = VoiceRunController();
    final voiceRunId = controller.startCapture(channel);
    final localCommands = <String>[];

    final result = controller.captureSucceeded(
      channel,
      testVoiceCapture('navi cancel'),
      handleLocalCommand: (transcript) {
        localCommands.add(transcript);
        return true;
      },
    );

    expect(localCommands, ['navi cancel']);
    expect(result.handledLocalCommand, isTrue);
    expect(result.scheduleAutoSendFor, isNull);
    expect(controller.pendingVoiceRunId, isNull);
    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(
      channel.state.voiceRuns[voiceRunId]?.status,
      NavivoxVoiceRunStatus.cancelled,
    );
    expect(channel.state.voiceRuns[voiceRunId]?.reason, 'local voice command');
  });

  test(
    'captureSucceeded stages transcript and requests auto-send scheduling',
    () {
      final channel = mineruReadyProfileChannel(micAvailable: true);
      final controller = VoiceRunController();

      final result = controller.captureSucceeded(
        channel,
        testVoiceCapture('summarize workspace'),
        handleLocalCommand: (_) => false,
      );

      final voiceRunId = result.scheduleAutoSendFor;
      expect(voiceRunId, isNotNull);
      expect(controller.pendingVoiceRunId, voiceRunId);
      expect(controller.notice, 'Sending...');
      expect(channel.sentVoiceTranscripts, isEmpty);
      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.pendingSend,
      );
      expect(
        channel.state.voiceRuns[voiceRunId]?.transcript,
        'summarize workspace',
      );
    },
  );

  test('autoSendIfPending submits the matching pending Voice run', () {
    final channel = mineruReadyProfileChannel(micAvailable: true);
    final controller = VoiceRunController();
    final staged = controller.captureSucceeded(
      channel,
      testVoiceCapture('summarize workspace'),
      handleLocalCommand: (_) => false,
    );

    final result = controller.autoSendIfPending(
      channel,
      staged.scheduleAutoSendFor!,
    );

    expect(result.submitted, isTrue);
    expect(controller.pendingVoiceRunId, isNull);
    expect(controller.notice, isNull);
    expect(channel.sentVoiceTranscripts, ['summarize workspace']);
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.submitted,
    );
  });

  test('cancelPending cancels active pending Voice run with operator copy', () {
    final channel = mineruReadyProfileChannel(micAvailable: true);
    final controller = VoiceRunController();
    final staged = controller.captureSucceeded(
      channel,
      testVoiceCapture('check status'),
      handleLocalCommand: (_) => false,
    );

    final result = controller.cancelPending(channel);

    expect(result.cancelledVoiceRunId, staged.scheduleAutoSendFor);
    expect(controller.pendingVoiceRunId, isNull);
    expect(controller.notice, 'Voice turn cancelled before server commit.');
    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(
      channel.state.activeVoiceRun?.status,
      NavivoxVoiceRunStatus.cancelled,
    );
  });
}
