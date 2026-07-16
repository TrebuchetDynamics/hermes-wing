import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/protocol/wing_voice_run.dart';

import 'support/wing_voice_run_test_support.dart';

void main() {
  test('creates a recording voice run for a profile contact', () {
    final run = recordingVoiceRun();

    expect(run.id, 'voice-1');
    expect(run.serverId, 'local');
    expect(run.profileId, 'mineru');
    expect(run.status, WingVoiceRunStatus.recording);
    expect(run.transcriptSource, WingTranscriptSource.device);
    expect(run.ttsStatus, WingTtsStatus.unavailable);
    expect(run.isTerminal, isFalse);
  });

  test('moves a device transcript to pending send without losing metadata', () {
    final run = recordingVoiceRun().withDeviceTranscript(
      transcript: 'check status',
      duration: const Duration(milliseconds: 900),
      confidence: 0.91,
      updatedAt: DateTime.utc(2026, 5, 21, 12, 0, 1),
    );

    expect(run.status, WingVoiceRunStatus.pendingSend);
    expect(run.transcript, 'check status');
    expect(run.duration, const Duration(milliseconds: 900));
    expect(run.confidence, 0.91);
    expect(run.transcriptSource, WingTranscriptSource.device);
  });

  test(
    'submitted completed cancelled and failed statuses are terminal-aware',
    () {
      final base = recordingVoiceRun().withDeviceTranscript(
        transcript: 'hello',
        duration: const Duration(seconds: 1),
        confidence: 1,
        updatedAt: DateTime.utc(2026, 5, 21, 12, 0, 1),
      );

      expect(base.markSubmitted(requestId: 'req-1').isTerminal, isFalse);
      expect(base.markCompleted().isTerminal, isTrue);
      expect(base.markCancelled('cancelled before send').isTerminal, isTrue);
      expect(base.markFailed('microphone denied').isTerminal, isTrue);
      expect(wingVoiceRunStatusIsTerminal(WingVoiceRunStatus.failed), isTrue);
    },
  );

  test('completed transition does not keep stale terminal reason', () {
    final completedAfterFailure = recordingVoiceRun()
        .withDeviceTranscript(
          transcript: 'hello',
          duration: const Duration(seconds: 1),
          confidence: 1,
          updatedAt: DateTime.utc(2026, 5, 21, 12, 0, 1),
        )
        .markFailed('gateway timeout')
        .markCompleted();

    expect(completedAfterFailure.status, WingVoiceRunStatus.completed);
    expect(completedAfterFailure.reason, isNull);
  });
}
