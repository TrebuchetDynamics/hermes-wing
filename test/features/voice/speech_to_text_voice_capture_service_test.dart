import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:navivox/features/voice/services/speech/speech_to_text_voice_capture_service.dart';
import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

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

  test('uses the latest partial transcript when the engine finishes', () async {
    final engine = _FakeSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    final future = service.capture(timeout: const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);

    engine.emit(
      const SpeechToTextSnapshot(
        words: 'hello mineru',
        confidence: 0.64,
        finalResult: false,
      ),
    );
    engine.emitStatus('done');

    final capture = await future;

    expect(capture.transcript, 'hello mineru');
    expect(capture.confidence, 0.64);
    expect(engine.stopCalls, 1);
    expect(engine.cancelCalls, 0);
  });

  test('reports no transcript when done arrives without words', () async {
    final engine = _FakeSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    final future = service.capture(timeout: const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);

    engine.emitStatus('done');

    await expectLater(
      future,
      throwsA(
        isA<SpeechToTextCaptureFailure>().having(
          (error) => error.cause,
          'cause',
          'no transcript',
        ),
      ),
    );
    expect(engine.cancelCalls, 1);
  });

  test(
    'reports no transcript when notListening arrives without words',
    () async {
      final engine = _FakeSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      final future = service.capture(timeout: const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);

      engine.emitStatus('notListening');

      await expectLater(
        future,
        throwsA(
          isA<SpeechToTextCaptureFailure>().having(
            (error) => error.cause,
            'cause',
            'no transcript',
          ),
        ),
      );
      expect(engine.cancelCalls, 1);
    },
  );

  test('reports empty transcript when the final result has no words', () async {
    final engine = _FakeSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    final future = service.capture(timeout: const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);

    engine.emit(
      const SpeechToTextSnapshot(
        words: '   ',
        confidence: 0,
        finalResult: true,
      ),
    );

    await expectLater(
      future,
      throwsA(
        isA<SpeechToTextCaptureFailure>().having(
          (error) => error.cause,
          'cause',
          'empty transcript',
        ),
      ),
    );
    expect(engine.stopCalls, 1);
    expect(engine.cancelCalls, 0);
  });

  test('logs STT diagnostics and passes a longer pause window', () async {
    final engine = _FakeSpeechToTextEngine();
    final logs = <String>[];
    final service = SpeechToTextVoiceCaptureService(
      engine: engine,
      diagnosticLog: logs.add,
    );

    final future = service.capture(timeout: const Duration(seconds: 10));
    await Future<void>.delayed(Duration.zero);

    expect(engine.hasPermissionCalls, 1);
    expect(engine.systemLocaleCalls, 1);
    expect(engine.listenFor, const Duration(seconds: 10));
    expect(engine.pauseFor, const Duration(seconds: 4));
    expect(engine.localeId, 'en_US');

    engine.emit(
      const SpeechToTextSnapshot(
        words: 'diagnose voice',
        confidence: 0.72,
        finalResult: true,
      ),
    );

    await future;
    final text = logs.join('\n');
    expect(text, contains('hasPermission=true before initialize'));
    expect(text, contains('initialize=true'));
    expect(text, contains('systemLocale=en_US (English US)'));
    expect(text, contains('listen locale=en_US'));
    expect(text, contains('pauseFor=4000ms partialResults=true'));
    expect(text, contains('recognizedWords="diagnose voice"'));
    expect(text, contains('confidence=0.72 finalResult=true'));
  });

  test('reports device STT unavailable when initialization is unavailable', () {
    final engine = _FakeSpeechToTextEngine()..available = false;
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    expect(
      () => service.capture(timeout: const Duration(seconds: 5)),
      throwsA(isA<DeviceSpeechUnavailable>()),
    );
  });

  test(
    'maps initialization failure after denied permission to microphone copy',
    () async {
      final engine = _FakeSpeechToTextEngine()
        ..available = false
        ..permissionGranted = false;
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      await expectLater(
        () => service.capture(timeout: const Duration(seconds: 5)),
        throwsA(
          isA<DeviceSpeechUnavailable>().having(
            (error) => error.message,
            'message',
            'microphone permission denied',
          ),
        ),
      );
    },
  );

  test('maps permanent no-match errors to no transcript copy', () async {
    final engine = _FakeSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    final future = service.capture(timeout: const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);

    engine.emitError(SpeechRecognitionError('error_no_match', true));

    await expectLater(
      future,
      throwsA(
        isA<SpeechToTextCaptureFailure>().having(
          (error) => error.cause,
          'cause',
          'no transcript',
        ),
      ),
    );
    expect(engine.cancelCalls, 1);
  });

  test('maps listen start failures to device STT unavailable', () async {
    final engine = _FakeSpeechToTextEngine()
      ..listenError = stt.ListenFailedException(
        'No speech recognition service available',
      );
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    await expectLater(
      () => service.capture(timeout: const Duration(seconds: 5)),
      throwsA(
        isA<DeviceSpeechUnavailable>().having(
          (error) => error.message,
          'message',
          'device STT unavailable',
        ),
      ),
    );
    expect(engine.listenCalls, 1);
    expect(engine.cancelCalls, 0);
  });

  test(
    'maps permanent permission errors to microphone permission copy',
    () async {
      final engine = _FakeSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      final future = service.capture(timeout: const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);

      engine.emitError(SpeechRecognitionError('error_permission', true));

      await expectLater(
        future,
        throwsA(
          isA<DeviceSpeechUnavailable>().having(
            (error) => error.message,
            'message',
            'microphone permission denied',
          ),
        ),
      );
      expect(engine.cancelCalls, 1);
    },
  );

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
  bool? permissionGranted = true;
  SpeechToTextLocale? systemLocaleResult = const SpeechToTextLocale(
    localeId: 'en_US',
    name: 'English US',
  );
  int hasPermissionCalls = 0;
  int initializeCalls = 0;
  int systemLocaleCalls = 0;
  int listenCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  Duration? listenFor;
  Duration? pauseFor;
  String? localeId;
  Object? listenError;
  void Function(SpeechToTextSnapshot result)? _onResult;
  void Function(Object error)? _onError;
  void Function(String status)? _onStatus;

  @override
  Future<bool?> hasPermission() async {
    hasPermissionCalls++;
    return permissionGranted;
  }

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    initializeCalls++;
    _onError = onError;
    _onStatus = onStatus;
    return available;
  }

  @override
  Future<SpeechToTextLocale?> systemLocale() async {
    systemLocaleCalls++;
    return systemLocaleResult;
  }

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
  }) async {
    listenCalls++;
    this.listenFor = listenFor;
    this.pauseFor = pauseFor;
    this.localeId = localeId;
    final error = listenError;
    if (error != null) throw error;
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

  void emitStatus(String status) {
    _onStatus?.call(status);
  }

  void emitError(Object error) {
    _onError?.call(error);
  }
}
