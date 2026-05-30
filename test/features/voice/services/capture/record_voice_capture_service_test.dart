import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/capture/audio_recorder.dart';
import 'package:navivox/features/voice/services/capture/record_voice_capture_service.dart';
import 'package:navivox/features/voice/services/speech/speech_recognizer.dart';

void main() {
  group('RecordVoiceCaptureService.captureUntilStopped', () {
    test(
      'starts both recorder and recognizer, returns combined result',
      () async {
        final recorder = _FakeRecorder()
          ..stopResult = Uint8List.fromList([1, 2, 3, 4]);
        final recognizer = _FakeRecognizer()
          ..stopResult = const SpeechResult(
            transcript: 'hello world',
            confidence: 0.91,
          );
        final clock = _FakeClock();
        final service = RecordVoiceCaptureService(
          recorder: recorder,
          recognizer: recognizer,
          clock: clock.now,
        );

        final controller = service.start();
        // Recorder + recognizer must be active.
        expect(recorder.startCalls, 1);
        expect(recognizer.startCalls, 1);

        // Simulate the user holding the button for ~1.5 seconds.
        clock.advance(const Duration(milliseconds: 1500));

        final capture = await controller.stop();

        expect(capture.audio, [1, 2, 3, 4]);
        expect(capture.transcript, 'hello world');
        expect(capture.duration, const Duration(milliseconds: 1500));
        expect(capture.confidence, 0.91);

        expect(recorder.stopCalls, 1);
        expect(recognizer.stopCalls, 1);
      },
    );

    test('stops both even when recognizer fails', () async {
      final recorder = _FakeRecorder()..stopResult = Uint8List(0);
      final recognizer = _FakeRecognizer()..stopError = StateError('boom');
      final service = RecordVoiceCaptureService(
        recorder: recorder,
        recognizer: recognizer,
        clock: () => DateTime.utc(2026, 5, 7, 12),
      );

      final controller = service.start();
      await expectLater(
        () => controller.stop(),
        throwsA(isA<VoiceCaptureFailure>()),
      );

      expect(recorder.stopCalls, 1, reason: 'recorder must always be stopped');
      expect(
        recognizer.stopCalls,
        1,
        reason: 'recognizer must always be stopped',
      );
    });

    test('cancel() releases resources without producing a capture', () async {
      final recorder = _FakeRecorder()..stopResult = Uint8List(0);
      final recognizer = _FakeRecognizer()
        ..stopResult = const SpeechResult(transcript: '', confidence: 0);
      final service = RecordVoiceCaptureService(
        recorder: recorder,
        recognizer: recognizer,
        clock: () => DateTime.utc(2026, 5, 7, 12),
      );

      final controller = service.start();
      await controller.cancel();

      expect(recorder.stopCalls, 1);
      expect(recognizer.stopCalls, 1);
      expect(controller.isActive, isFalse);
    });

    test('exposes interim transcripts as a stream during capture', () async {
      final recorder = _FakeRecorder()..stopResult = Uint8List(0);
      final recognizer = _FakeRecognizer()
        ..stopResult = const SpeechResult(transcript: 'final', confidence: 1);
      final service = RecordVoiceCaptureService(
        recorder: recorder,
        recognizer: recognizer,
        clock: () => DateTime.utc(2026, 5, 7, 12),
      );

      final controller = service.start();
      final received = <String>[];
      final sub = controller.interimTranscripts.listen(received.add);

      recognizer.emitInterim('he');
      recognizer.emitInterim('hel');
      recognizer.emitInterim('hello');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await controller.stop();
      await sub.cancel();

      expect(received, ['he', 'hel', 'hello']);
    });
  });

  group('VoiceCaptureService contract via RecordVoiceCaptureService', () {
    test(
      'capture(timeout) returns when recognizer finalises before timeout',
      () async {
        final recorder = _FakeRecorder()..stopResult = Uint8List.fromList([7]);
        final recognizer = _FakeRecognizer()
          ..stopResult = const SpeechResult(
            transcript: 'short',
            confidence: 0.5,
          );
        final service = RecordVoiceCaptureService(
          recorder: recorder,
          recognizer: recognizer,
          clock: () => DateTime.utc(2026, 5, 7, 12),
        );

        // Trigger the auto-stop very quickly to keep the test fast.
        final result = service.capture(timeout: const Duration(seconds: 1));
        // Auto-stop pulse: simulate the recognizer signaling a final result.
        Future<void>.microtask(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          recognizer.completeFinal();
        });

        final capture = await result;
        expect(capture.transcript, 'short');
        expect(capture.audio, [7]);
      },
    );
  });
}

class _FakeRecorder implements AudioRecorder {
  int startCalls = 0;
  int stopCalls = 0;
  Uint8List stopResult = Uint8List(0);
  Object? stopError;

  @override
  Future<void> start() async {
    startCalls++;
  }

  @override
  Future<Uint8List> stop() async {
    stopCalls++;
    final err = stopError;
    if (err != null) throw err;
    return stopResult;
  }

  @override
  Future<void> cancel() async {
    stopCalls++;
  }
}

class _FakeRecognizer implements SpeechRecognizer {
  int startCalls = 0;
  int stopCalls = 0;
  SpeechResult stopResult = const SpeechResult(transcript: '', confidence: 0);
  Object? stopError;
  StreamController<String>? _interim;
  Completer<void>? _finalSignal;

  @override
  Stream<String> get interimTranscripts {
    return (_interim ??= StreamController<String>.broadcast()).stream;
  }

  @override
  Future<void> get onFinal {
    return (_finalSignal ??= Completer<void>()).future;
  }

  @override
  Future<void> start() async {
    startCalls++;
  }

  @override
  Future<SpeechResult> stop() async {
    stopCalls++;
    final err = stopError;
    if (err != null) throw err;
    return stopResult;
  }

  @override
  Future<void> cancel() async {
    stopCalls++;
    await _interim?.close();
  }

  void emitInterim(String text) {
    (_interim ??= StreamController<String>.broadcast()).add(text);
  }

  void completeFinal() {
    (_finalSignal ??= Completer<void>()).complete();
  }
}

class _FakeClock {
  DateTime _now = DateTime.utc(2026, 5, 7, 12);
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}
