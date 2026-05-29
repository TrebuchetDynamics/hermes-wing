import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/controllers/voice/transcript_voice_capture_flow.dart';
import 'package:navivox/features/voice/services/speech/speech_to_text_voice_capture_service.dart';
import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

void main() {
  const flow = TranscriptVoiceCaptureFlow();

  test(
    'returns captured outcome and calls started before service capture',
    () async {
      final events = <String>[];
      final service = _RecordingVoiceCaptureService(events);

      final outcome = await flow.capture(
        service: service,
        timeout: const Duration(seconds: 1),
        onStarted: () => events.add('started'),
      );

      expect(events, ['started', 'capture']);
      expect(outcome.status, TranscriptVoiceCaptureStatus.captured);
      expect(outcome.capture?.transcript, 'hello voice');
      expect(outcome.errorMessage, isNull);
    },
  );

  test('returns unavailable when no capture service is available', () async {
    var started = false;

    final outcome = await flow.capture(
      service: null,
      timeout: const Duration(seconds: 1),
      onStarted: () => started = true,
    );

    expect(started, isFalse);
    expect(outcome.status, TranscriptVoiceCaptureStatus.unavailable);
    expect(outcome.capture, isNull);
    expect(outcome.error, isNull);
    expect(outcome.errorMessage, isNull);
  });

  test('maps timeout to stable operator recovery copy', () async {
    final outcome = await flow.capture(
      service: FakeVoiceCaptureService(
        audio: Uint8List.fromList([1]),
        transcript: 'late voice',
        duration: const Duration(milliseconds: 10),
        confidence: 1,
        captureLatency: const Duration(milliseconds: 50),
      ),
      timeout: const Duration(milliseconds: 1),
    );

    expect(outcome.status, TranscriptVoiceCaptureStatus.failed);
    expect(outcome.error, isA<VoiceCaptureTimeout>());
    expect(outcome.errorMessage, 'Voice capture timed out.');
  });

  test('maps no transcript to actionable recovery copy', () async {
    final outcome = await flow.capture(
      service: _ThrowingVoiceCaptureService(
        const SpeechToTextCaptureFailure('no transcript'),
      ),
      timeout: const Duration(seconds: 1),
    );

    expect(outcome.status, TranscriptVoiceCaptureStatus.failed);
    expect(outcome.error, isA<SpeechToTextCaptureFailure>());
    expect(outcome.errorMessage, noSpeechDetectedVoiceCaptureMessage);
  });

  test('maps device STT unavailable to actionable recovery copy', () async {
    final outcome = await flow.capture(
      service: const _ThrowingVoiceCaptureService(DeviceSpeechUnavailable()),
      timeout: const Duration(seconds: 1),
    );

    expect(outcome.status, TranscriptVoiceCaptureStatus.failed);
    expect(outcome.error, isA<DeviceSpeechUnavailable>());
    expect(outcome.errorMessage, deviceSpeechUnavailableVoiceCaptureMessage);
  });

  test(
    'maps microphone permission denied to actionable recovery copy',
    () async {
      final outcome = await flow.capture(
        service: const _ThrowingVoiceCaptureService(
          DeviceSpeechUnavailable('microphone permission denied'),
        ),
        timeout: const Duration(seconds: 1),
      );

      expect(outcome.status, TranscriptVoiceCaptureStatus.failed);
      expect(outcome.error, isA<DeviceSpeechUnavailable>());
      expect(
        outcome.errorMessage,
        microphonePermissionDeniedVoiceCaptureMessage,
      );
    },
  );

  test('maps unexpected errors to stable operator failure copy', () async {
    final outcome = await flow.capture(
      service: _ThrowingVoiceCaptureService(StateError('microphone exploded')),
      timeout: const Duration(seconds: 1),
    );

    expect(outcome.status, TranscriptVoiceCaptureStatus.failed);
    expect(outcome.error, isA<StateError>());
    expect(
      outcome.errorMessage,
      'Voice capture failed: Bad state: microphone exploded',
    );
  });
}

class _RecordingVoiceCaptureService implements VoiceCaptureService {
  _RecordingVoiceCaptureService(this.events);

  final List<String> events;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    events.add('capture');
    return VoiceCapture(
      audio: Uint8List.fromList([1, 2, 3]),
      transcript: 'hello voice',
      duration: const Duration(milliseconds: 700),
      confidence: 0.88,
    );
  }
}

class _ThrowingVoiceCaptureService implements VoiceCaptureService {
  const _ThrowingVoiceCaptureService(this.error);

  final Object error;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    throw error;
  }
}
