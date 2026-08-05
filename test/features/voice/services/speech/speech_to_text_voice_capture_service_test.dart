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
    final partialTranscript = service.partialTranscripts.first;

    final capture = await service.capture(timeout: const Duration(seconds: 5));

    expect(await partialTranscript, 'my private transcript');
    expect(capture.transcript, 'my private transcript');
    expect(logs.join('\n'), isNot(contains('my private transcript')));
    expect(logs.join('\n'), contains('result wordsLength=21'));
    expect(engine.lastOnDevice, isTrue);
    expect(engine.lastPauseFor, const Duration(seconds: 4));
  });

  test(
    'forwards live microphone levels when the engine exposes them',
    () async {
      final engine = _SoundLevelSpeechToTextEngine('hello');
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final level = service.soundLevels.first;

      await service.capture(timeout: const Duration(seconds: 1));

      expect(await level, 10);
    },
  );

  test('stops after partial transcript inactivity', () async {
    final engine = _PartialResultSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(
      engine: engine,
      partialResultPauseFor: Duration.zero,
    );

    final capture = await service.capture(timeout: const Duration(seconds: 1));

    expect(capture.transcript, 'hello');
    expect(engine.stopCalls, greaterThanOrEqualTo(1));
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

  test(
    'a hung engine cancel cannot strand the capture past its timeout',
    () async {
      // Android's recognizer can leave `cancel()` pending forever after it
      // reports NO_SPEECH_DETECTED. The capture must still time out, or the mic
      // spins with no transcript and no error.
      final service = SpeechToTextVoiceCaptureService(
        engine: _UncancellableHangingSpeechToTextEngine(),
      );

      await expectLater(
        service
            .capture(timeout: const Duration(milliseconds: 50))
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () =>
                  throw StateError('capture stranded past timeout'),
            ),
        throwsA(isA<VoiceCaptureTimeout>()),
      );
    },
  );
}

/// Never resolves `listen`, and its `cancel()` hangs forever.
class _UncancellableHangingSpeechToTextEngine implements SpeechToTextEngine {
  final _neverCancels = Completer<void>();

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
  Future<void> cancel() => _neverCancels.future;
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

class _PartialResultSpeechToTextEngine implements SpeechToTextEngine {
  void Function(String status)? _onStatus;
  int stopCalls = 0;

  @override
  Future<bool?> hasPermission() async => true;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    _onStatus = onStatus;
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
    onResult(
      const SpeechToTextSnapshot(
        words: 'hello',
        confidence: 0.9,
        finalResult: false,
      ),
    );
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _onStatus?.call('done');
  }

  @override
  Future<void> cancel() async {}
}

class _FakeSpeechToTextEngine implements SpeechToTextEngine {
  _FakeSpeechToTextEngine(this.words);

  final String words;
  bool? lastOnDevice;
  Duration? lastPauseFor;

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
    lastPauseFor = pauseFor;
    onResult(
      SpeechToTextSnapshot(words: words, confidence: 0.9, finalResult: true),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class _SoundLevelSpeechToTextEngine extends _FakeSpeechToTextEngine
    implements SpeechToTextSoundLevelEngine {
  _SoundLevelSpeechToTextEngine(super.words);

  final _soundLevels = StreamController<double>.broadcast();

  @override
  Stream<double> get soundLevels => _soundLevels.stream;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {
    _soundLevels.add(10);
    await super.listen(
      onResult: onResult,
      listenFor: listenFor,
      pauseFor: pauseFor,
      localeId: localeId,
      onDevice: onDevice,
    );
  }
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
