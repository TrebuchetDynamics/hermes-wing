import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:wing/features/voice/services/speech/speech_to_text_voice_capture_service.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

void main() {
  test('speech diagnostics do not log recognized words', () async {
    final logs = <String>[];
    final engine = _FakeSpeechToTextEngine('my private transcript');
    final service = SpeechToTextVoiceCaptureService(
      engine: engine,
      diagnosticLog: logs.add,
    );

    final capture = await service.capture(timeout: const Duration(seconds: 5));

    expect(capture.transcript, 'my private transcript');
    expect(logs.join('\n'), isNot(contains('my private transcript')));
    expect(logs.join('\n'), contains('result wordsLength=21'));
    expect(engine.lastOnDevice, isTrue);
  });

  test(
    'reuses initialization while routing errors to the current capture',
    () async {
      final engine = _InitializeOnceSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      for (var attempt = 0; attempt < 2; attempt++) {
        await expectLater(
          service.capture(timeout: const Duration(milliseconds: 100)),
          throwsA(isA<SpeechToTextCaptureFailure>()),
        );
      }

      expect(engine.initializeCalls, 1);
    },
  );

  test('capture timeout also bounds speech engine initialization', () async {
    final engine = _HangingSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    await expectLater(
      service.capture(timeout: const Duration(milliseconds: 10)),
      throwsA(isA<VoiceCaptureTimeout>()),
    );
    expect(engine.cancelCalls, 1);
  });

  test(
    'an exhausted capture budget cannot raise from a failed cancel',
    () async {
      final service = SpeechToTextVoiceCaptureService(
        engine: _UncancellableSpeechToTextEngine(),
      );

      await expectLater(
        service.capture(timeout: Duration.zero),
        throwsA(isA<VoiceCaptureTimeout>()),
      );
      await Future<void>.delayed(Duration.zero);
    },
  );
}

/// Mirrors a recognizer that is already gone, so cancelling it fails.
class _UncancellableSpeechToTextEngine implements SpeechToTextEngine {
  @override
  Future<bool?> hasPermission() async => true;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async => true;

  @override
  Future<SpeechToTextLocale?> systemLocale() async => null;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async => throw StateError('recognizer unavailable');
}

class _FakeSpeechToTextEngine implements SpeechToTextEngine {
  _FakeSpeechToTextEngine(this.words);

  final String words;
  bool? lastOnDevice;

  @override
  Future<bool?> hasPermission() async => true;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    onStatus('listening');
    return true;
  }

  @override
  Future<SpeechToTextLocale?> systemLocale() async => null;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {
    lastOnDevice = onDevice;
    onResult(
      SpeechToTextSnapshot(words: words, confidence: 0.9, finalResult: true),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class _InitializeOnceSpeechToTextEngine implements SpeechToTextEngine {
  void Function(Object error)? _onError;
  int initializeCalls = 0;

  @override
  Future<bool?> hasPermission() async => true;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    initializeCalls += 1;
    _onError ??= onError;
    return true;
  }

  @override
  Future<SpeechToTextLocale?> systemLocale() async => null;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {
    _onError!(SpeechRecognitionError('error_no_match', false));
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class _HangingSpeechToTextEngine implements SpeechToTextEngine {
  final _initialization = Completer<bool>();
  int cancelCalls = 0;

  @override
  Future<bool?> hasPermission() async => true;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) => _initialization.future;

  @override
  Future<SpeechToTextLocale?> systemLocale() async => null;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
  }
}
