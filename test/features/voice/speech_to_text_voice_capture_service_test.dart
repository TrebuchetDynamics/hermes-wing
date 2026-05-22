import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/speech_to_text_voice_capture_service.dart';
import 'package:navivox/features/voice/services/voice_capture_service.dart';

void main() {
  test('returns a final transcript from the platform speech engine', () async {
    final engine = _FakeSpeechToTextEngine();
    var now = DateTime.utc(2026, 5, 22, 17);
    final service = SpeechToTextVoiceCaptureService(
      engine: engine,
      clock: () => now,
    );

    final future = service.capture(timeout: const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);
    expect(engine.initializeCalls, 1);
    expect(engine.listenCalls, 1);

    now = now.add(const Duration(milliseconds: 850));
    engine.emit(
      const SpeechToTextSnapshot(
        words: 'navi mineru',
        confidence: 0.82,
        finalResult: true,
      ),
    );

    final capture = await future;

    expect(capture.transcript, 'navi mineru');
    expect(capture.confidence, 0.82);
    expect(capture.duration, const Duration(milliseconds: 850));
    expect(capture.audio, isEmpty);
    expect(engine.stopCalls, 1);
    expect(engine.cancelCalls, 0);
  });

  test('reports device STT unavailable when initialization is unavailable', () {
    final engine = _FakeSpeechToTextEngine()..available = false;
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    expect(
      () => service.capture(timeout: const Duration(seconds: 5)),
      throwsA(isA<DeviceSpeechUnavailable>()),
    );
  });

  test('cancels the platform speech engine on timeout', () async {
    final engine = _FakeSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    await expectLater(
      () => service.capture(timeout: const Duration(milliseconds: 1)),
      throwsA(isA<VoiceCaptureTimeout>()),
    );

    expect(engine.cancelCalls, 1);
  });
}

class _FakeSpeechToTextEngine implements SpeechToTextEngine {
  bool available = true;
  int initializeCalls = 0;
  int listenCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  void Function(SpeechToTextSnapshot result)? _onResult;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    initializeCalls++;
    return available;
  }

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
  }) async {
    listenCalls++;
    _onResult = onResult;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }

  void emit(SpeechToTextSnapshot result) {
    _onResult?.call(result);
  }
}
