import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';
import 'package:navivox/features/chat/voice/controllers/voice_run_controller.dart';
import 'package:navivox/features/voice/services/speech/speech_to_text_voice_capture_service.dart';
import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

import '../../../support/test_navivox_channel.dart';

void main() {
  test('startCapture records the active Voice run id', () {
    final channel = _seedChannel();
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
    final channel = _seedChannel();
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
    final channel = _seedChannel();
    final controller = VoiceRunController()..startCapture(channel);

    final result = controller.captureFailed(
      channel,
      const DeviceSpeechUnavailable('microphone permission denied'),
    );

    expect(result.reason, 'microphone permission denied');
    expect(result.runtimeVoiceDisabledReason, 'microphone permission denied');
    expect(
      controller.runtimeVoiceDisabledReason,
      'microphone permission denied',
    );
    expect(channel.state.activeVoiceRun?.status, NavivoxVoiceRunStatus.failed);
  });

  test('clearRuntimeVoiceDisabledReason resets session voice blocker', () {
    final controller = VoiceRunController()
      ..runtimeVoiceDisabledReason = 'device STT unavailable';

    controller.clearRuntimeVoiceDisabledReason();

    expect(controller.runtimeVoiceDisabledReason, isNull);
  });

  test('captureFailed maps no transcript to actionable recovery copy', () {
    final channel = _seedChannel();
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
    final channel = _seedChannel();
    final controller = VoiceRunController();
    final voiceRunId = controller.startCapture(channel);
    final localCommands = <String>[];

    final result = controller.captureSucceeded(
      channel,
      _capture('navi cancel'),
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
      final channel = _seedChannel();
      final controller = VoiceRunController();

      final result = controller.captureSucceeded(
        channel,
        _capture('summarize workspace'),
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
    final channel = _seedChannel();
    final controller = VoiceRunController();
    final staged = controller.captureSucceeded(
      channel,
      _capture('summarize workspace'),
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
    final channel = _seedChannel();
    final controller = VoiceRunController();
    final staged = controller.captureSucceeded(
      channel,
      _capture('check status'),
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

TestNavivoxChannel _seedChannel() {
  return TestNavivoxChannel()
    ..seedServers(const [
      NavivoxServer(id: 'local', name: 'local', status: 'connected'),
    ], activeServerId: 'local')
    ..seedProfileContacts(const [
      NavivoxProfileContact(
        serverId: 'local',
        profileId: 'mineru',
        displayName: 'Mineru',
        serverLabel: 'local',
        health: NavivoxProfileHealth.online,
        latestPreview: 'Ready',
        workspaceRootCount: 1,
        micAvailable: true,
      ),
    ], selectedKey: 'local::mineru');
}

VoiceCapture _capture(String transcript) {
  return VoiceCapture(
    audio: Uint8List.fromList(transcript.codeUnits),
    transcript: transcript,
    duration: const Duration(milliseconds: 500),
    confidence: 0.95,
  );
}
