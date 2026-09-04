import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:wing/core/protocol/voice_unavailable_reason.dart';
import 'package:wing/features/voice/services/speech/speech_to_text_voice_capture_service.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

void main() {
  test(
    'dispose during readiness closes streams and prevents listening',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final readiness = Completer<String?>();
      final service = SpeechToTextVoiceCaptureService(
        engine: engine,
        readinessCheck: () => readiness.future,
      );
      final partials = service.partialTranscripts.toList();
      final levels = service.soundLevels.toList();
      final capture = service.capture(timeout: const Duration(seconds: 1));
      final failure = expectLater(
        capture,
        throwsA(isA<SpeechToTextCaptureFailure>()),
      );
      await pumpEventQueue();
      final disposal = service.dispose();
      expect(identical(disposal, service.dispose()), isTrue);
      readiness.complete(null);
      await disposal;
      await failure;
      expect(await partials, isEmpty);
      expect(await levels, isEmpty);
      expect(engine.listenCalls, 0);
      await expectLater(
        service.capture(timeout: const Duration(seconds: 1)),
        throwsA(isA<SpeechToTextCaptureFailure>()),
      );
    },
  );

  test(
    'dispose rejects late result status error and sound callbacks',
    () async {
      final engine = _OwnedSoundLevelSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final partials = service.partialTranscripts.toList();
      final levels = service.soundLevels.toList();
      final capture = service.capture(timeout: const Duration(seconds: 1));
      final failure = expectLater(
        capture,
        throwsA(isA<SpeechToTextCaptureFailure>()),
      );
      await pumpEventQueue();
      await service.dispose();
      engine.emitResult('synthetic late words');
      engine.emitSoundLevel(99);
      engine.emitStatus('listening');
      engine.emitError(StateError('late callback'));
      await failure;
      expect(await partials, isEmpty);
      expect(await levels, isEmpty);
    },
  );

  test(
    'rejects concurrent capture without disturbing the active recognizer',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final first = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        service.capture(timeout: const Duration(milliseconds: 50)),
        throwsA(isA<SpeechToTextCaptureFailure>()),
      );
      expect(engine.listenCalls, 1);

      engine.emitResultFor(0, 'first transcript');
      engine.endCurrentRecognition();
      expect((await first).transcript, 'first transcript');
    },
  );

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

  test('waits for final recognizer teardown before the next capture', () async {
    final engine = _FinalResultEndsAsynchronouslySpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    final first = await service.capture(timeout: const Duration(seconds: 1));
    final second = await service.capture(timeout: const Duration(seconds: 1));

    expect(first.transcript, 'first transcript');
    expect(second.transcript, 'second transcript');
    expect(engine.overlappingListenCalls, 0);
    expect(engine.stopCalls, 0);
  });

  test('hosted speech_to_text has no generation-bound callbacks', () {
    expect(PluginSpeechToTextEngine().hasGenerationBoundCallbacks, isFalse);
  });

  test(
    'generation-bound terminal does not trigger ambiguous cancellation',
    () async {
      final engine = _GenerationBoundFinalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      final capture = await service.capture(
        timeout: const Duration(seconds: 1),
      );

      expect(capture.transcript, 'first transcript');
      expect(engine.cancelCalls, 0);
    },
  );

  test(
    'waits for terminal status after an error following a final result',
    () async {
      final engine = _FinalResultEndsWithErrorSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      final capture = await service.capture(
        timeout: const Duration(seconds: 1),
      );

      expect(capture.transcript, 'final before teardown error');
      expect(engine.stopCalls, 0);
    },
  );

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

  test(
    'terminal recognition owner cannot publish a late sound level',
    () async {
      final engine = _OwnedSoundLevelSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final levels = <double>[];
      final subscription = service.soundLevels.listen(levels.add);
      addTearDown(subscription.cancel);
      final capture = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);

      unawaited(service.cancel());
      engine.endCurrentRecognition();
      engine.emitSoundLevel(99);
      await expectLater(capture, throwsA(isA<SpeechToTextCaptureFailure>()));

      expect(levels, isEmpty);
    },
  );

  test('stops after partial transcript inactivity', () async {
    final engine = _PartialResultSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(
      engine: engine,
      pauseFor: Duration.zero,
      partialResultPauseFor: Duration.zero,
    );

    final capture = await service.capture(timeout: const Duration(seconds: 1));

    expect(capture.transcript, 'hello');
    expect(engine.stopCalls, greaterThanOrEqualTo(1));
  });

  test(
    'waits for partial-stop recognizer teardown before the next capture',
    () async {
      final engine = _PartialResultEndsAsynchronouslySpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(
        engine: engine,
        pauseFor: Duration.zero,
        partialResultPauseFor: Duration.zero,
      );

      final first = await service.capture(timeout: const Duration(seconds: 1));
      final second = await service.capture(timeout: const Duration(seconds: 1));

      expect(first.transcript, 'first partial');
      expect(second.transcript, 'second partial');
      expect(engine.overlappingListenCalls, 0);
    },
  );

  test(
    'missing terminal status times out instead of assuming teardown',
    () async {
      final engine = _SilentStopAfterPartialSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(
        engine: engine,
        pauseFor: Duration.zero,
        partialResultPauseFor: Duration.zero,
      );

      await expectLater(
        service.capture(timeout: const Duration(milliseconds: 100)),
        throwsA(isA<VoiceCaptureTimeout>()),
      );
    },
  );

  test('failed stop without terminal status times out safely', () async {
    final service = SpeechToTextVoiceCaptureService(
      engine: _FailingStopAfterPartialSpeechToTextEngine(),
      pauseFor: Duration.zero,
      partialResultPauseFor: Duration.zero,
    );

    await expectLater(
      service.capture(timeout: const Duration(milliseconds: 100)),
      throwsA(isA<VoiceCaptureTimeout>()),
    );
  });

  test('engine stop can flush a newer partial transcript', () async {
    final service = SpeechToTextVoiceCaptureService(
      engine: _FlushingStopSpeechToTextEngine(),
      pauseFor: Duration.zero,
      partialResultPauseFor: Duration.zero,
    );

    final capture = await service.capture(timeout: const Duration(seconds: 1));

    expect(capture.transcript, 'hello world');
  });

  test('does not stop before the configured speech pause', () async {
    final engine = _PartialResultSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(
      engine: engine,
      pauseFor: const Duration(milliseconds: 50),
      partialResultPauseFor: const Duration(milliseconds: 10),
    );
    final capture = service.capture(timeout: const Duration(seconds: 1));

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(engine.stopCalls, 0);
    unawaited(service.cancel());
    await expectLater(capture, throwsA(isA<SpeechToTextCaptureFailure>()));
  });

  test(
    'recognizer listen window fits inside the whole capture budget',
    () async {
      final service = SpeechToTextVoiceCaptureService(
        engine: _DelayedFinalSpeechToTextEngine(),
      );

      final capture = await service.capture(
        timeout: const Duration(seconds: 1),
      );

      expect(capture.transcript, 'late final transcript');
    },
  );

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

  test(
    'readiness failure blocks capture before plugin initialization',
    () async {
      final engine = _InitializeOnceSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(
        engine: engine,
        readinessCheck: () async => deviceSttUnavailableReason,
      );

      await expectLater(
        service.capture(timeout: const Duration(seconds: 1)),
        throwsA(
          isA<DeviceSpeechUnavailable>().having(
            (error) => error.message,
            'message',
            deviceSttUnavailableReason,
          ),
        ),
      );

      expect(engine.initializeCalls, 0);
    },
  );

  test('cancel during readiness cannot start the recognizer later', () async {
    final readiness = Completer<String?>();
    final engine = _InitializeOnceSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(
      engine: engine,
      readinessCheck: () => readiness.future,
    );
    final capture = service.capture(timeout: const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);

    unawaited(service.cancel());

    await expectLater(
      capture.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => throw StateError('cancel waited for readiness'),
      ),
      throwsA(isA<SpeechToTextCaptureFailure>()),
    );
    readiness.complete(null);
    await Future<void>.delayed(Duration.zero);
    expect(engine.initializeCalls, 0);
  });

  test('cancelled setup timeout cannot cancel replacement capture', () async {
    final firstReadiness = Completer<String?>();
    var readinessCalls = 0;
    final engine = _CancelRecordingSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(
      engine: engine,
      readinessCheck: () {
        readinessCalls += 1;
        return readinessCalls == 1
            ? firstReadiness.future
            : Future<String?>.value();
      },
    );
    final first = service.capture(timeout: const Duration(milliseconds: 30));
    await Future<void>.delayed(Duration.zero);
    await service.cancel();
    await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));

    final second = service.capture(timeout: const Duration(seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(engine.cancelCalls, 1);
    await service.cancel();
    await expectLater(second, throwsA(isA<SpeechToTextCaptureFailure>()));
    firstReadiness.complete(null);
  });

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

  test('failed cancel keeps replacement recognizer blocked', () async {
    final engine = _UncancellableSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);
    final first = service.capture(timeout: const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);

    await expectLater(service.cancel(), throwsA(isA<StateError>()));
    await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));
    await expectLater(
      service.capture(timeout: const Duration(milliseconds: 30)),
      throwsA(isA<VoiceCaptureTimeout>()),
    );
    expect(engine.listenCalls, 1);
  });

  test('a hung cancel after recognition error cannot strand capture', () async {
    final service = SpeechToTextVoiceCaptureService(
      engine: _ErrorThenHungCancelSpeechToTextEngine(),
    );

    await expectLater(
      service
          .capture(timeout: const Duration(seconds: 1))
          .timeout(
            const Duration(milliseconds: 100),
            onTimeout: () => throw StateError('capture stranded after error'),
          ),
      throwsA(isA<SpeechToTextCaptureFailure>()),
    );
  });

  test(
    'cancel ends capture even when the engine emits no terminal event',
    () async {
      final service = SpeechToTextVoiceCaptureService(
        engine: _UncancellableHangingSpeechToTextEngine(),
      );
      final capture = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);

      unawaited(service.cancel());

      await expectLater(
        capture.timeout(
          const Duration(milliseconds: 100),
          onTimeout: () => throw StateError('cancelled capture stayed pending'),
        ),
        throwsA(isA<SpeechToTextCaptureFailure>()),
      );
    },
  );

  test(
    'public cancel waits for terminal recognizer ownership release',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final capture = service.capture(timeout: const Duration(seconds: 1));
      unawaited(
        capture.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
      await Future<void>.delayed(Duration.zero);

      var cancelled = false;
      final cancellation = service.cancel().then((_) => cancelled = true);
      await Future<void>.delayed(Duration.zero);
      expect(cancelled, isFalse);

      engine.endCurrentRecognition();
      await cancellation;
      expect(cancelled, isTrue);
    },
  );

  test(
    'recognizer teardown barrier does not expire before terminal status',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final first = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      unawaited(service.cancel());
      await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));

      final second = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(engine.listenCalls, 1);
      engine.endCurrentRecognition();
      await engine.secondListening;
      engine.emitResult('replacement transcript');
      engine.endCurrentRecognition();

      expect((await second).transcript, 'replacement transcript');
    },
  );

  test('genuine active recognizer errors are not discarded', () async {
    final engine = _StaleTerminalSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);
    final capture = service.capture(timeout: const Duration(milliseconds: 50));
    await Future<void>.delayed(Duration.zero);

    engine.emitError(StateError('current recognizer failed'));
    engine.endCurrentRecognition();

    await expectLater(
      capture,
      throwsA(
        isA<SpeechToTextCaptureFailure>().having(
          (error) => error.toString(),
          'message',
          contains('current recognizer failed'),
        ),
      ),
    );
  });

  test(
    'transient recognizer error cannot release teardown before terminal',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final first = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      engine.emitError(SpeechRecognitionError('transient failure', false));
      await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));

      final second = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(engine.listenCalls, 1);

      engine.endCurrentRecognition();
      await engine.secondListening;
      engine.emitResultFor(1, 'replacement transcript');
      engine.endCurrentRecognition();
      expect((await second).transcript, 'replacement transcript');
    },
  );

  test(
    'permanent recognizer error waits for terminal before replacement',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final first = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      engine.emitError(SpeechRecognitionError('permanent failure', true));
      await expectLater(first, throwsA(isA<DeviceSpeechUnavailable>()));

      final second = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(engine.listenCalls, 1);

      engine.endCurrentRecognition();
      await engine.secondListening;
      engine.emitResultFor(1, 'replacement transcript');
      engine.endCurrentRecognition();
      expect((await second).transcript, 'replacement transcript');
    },
  );

  test(
    'ambiguous terminal during replacement listening fails closed',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final first = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      unawaited(service.cancel());
      await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));
      engine.endCurrentRecognition();

      final second = service.capture(timeout: const Duration(seconds: 1));
      await engine.secondListening;
      engine.emitStatus('done');

      await expectLater(
        second,
        throwsA(
          isA<SpeechToTextCaptureFailure>().having(
            (error) => error.toString(),
            'message',
            contains('ambiguous terminal'),
          ),
        ),
      );
      expect(engine.listenCalls, 2);
    },
  );

  test(
    'duplicate stale terminal cannot release a live successor without speech',
    () async {
      final engine = _DuplicateTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      final first = service.capture(timeout: const Duration(seconds: 1));
      await pumpEventQueue();
      unawaited(service.cancel());
      await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));
      engine.emitTerminal(actualEnd: true);

      final second = service.capture(timeout: const Duration(seconds: 1));
      await engine.secondListening.future;
      engine.emitTerminal(actualEnd: false);
      await expectLater(second, throwsA(isA<SpeechToTextCaptureFailure>()));

      final third = service.capture(timeout: const Duration(seconds: 1));
      await pumpEventQueue();
      expect(engine.overlappingListens, 0);
      unawaited(service.cancel());
      engine.emitTerminal(actualEnd: true);
      await expectLater(third, throwsA(anything));
    },
  );

  test(
    'duplicate stale terminal cannot complete a finalized live successor',
    () async {
      final engine = _DuplicateTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      final first = service.capture(timeout: const Duration(seconds: 1));
      await pumpEventQueue();
      unawaited(service.cancel());
      await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));
      engine.emitTerminal(actualEnd: true);

      final second = service.capture(timeout: const Duration(seconds: 1));
      await engine.secondListening.future;
      engine.emitFinal('successor transcript');
      engine.emitTerminal(actualEnd: false);
      var secondCompleted = false;
      unawaited(second.whenComplete(() => secondCompleted = true));
      await pumpEventQueue();

      expect(secondCompleted, isFalse);
      expect(engine.overlappingListens, 0);

      engine.emitTerminal(actualEnd: true);
      expect((await second).transcript, 'successor transcript');

      final third = service.capture(timeout: const Duration(seconds: 1));
      await pumpEventQueue();
      expect(engine.overlappingListens, 0);
      unawaited(service.cancel());
      engine.emitTerminal(actualEnd: true);
      await expectLater(third, throwsA(anything));
    },
  );

  test(
    'two stale terminals cannot release a finalized live successor',
    () async {
      final engine = _DuplicateTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      final first = service.capture(timeout: const Duration(seconds: 1));
      await pumpEventQueue();
      unawaited(service.cancel());
      await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));
      engine.emitTerminal(actualEnd: true);

      var secondCompleted = false;
      final second = service.capture(timeout: const Duration(seconds: 1));
      unawaited(second.then<void>((_) => secondCompleted = true));
      await engine.secondListening.future;
      engine.emitFinal('successor transcript');
      engine.emitTerminal(actualEnd: false);
      engine.emitTerminal(actualEnd: false);
      await pumpEventQueue();

      expect(secondCompleted, isFalse);
      expect(engine.overlappingListens, 0);

      engine.emitTerminal(actualEnd: true);
      expect((await second).transcript, 'successor transcript');
    },
  );

  test(
    'result after ambiguous terminal cannot replace finalized successor',
    () async {
      final engine = _DuplicateTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      final first = service.capture(timeout: const Duration(seconds: 1));
      await pumpEventQueue();
      unawaited(service.cancel());
      await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));
      engine.emitTerminal(actualEnd: true);

      final second = service.capture(timeout: const Duration(seconds: 1));
      await engine.secondListening.future;
      engine.emitFinal('successor transcript');
      engine.emitTerminal(actualEnd: false);
      engine.emitFinal('stale predecessor transcript');
      engine.emitTerminal(actualEnd: true);

      expect((await second).transcript, 'successor transcript');
      expect(engine.overlappingListens, 0);
    },
  );

  test(
    'stale terminal after successor partial cannot submit or release teardown',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final first = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      unawaited(service.cancel());
      await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));
      engine.endCurrentRecognition();

      final second = service.capture(timeout: const Duration(seconds: 1));
      await engine.secondListening;
      engine.emitResultFor(1, 'unconfirmed partial', finalResult: false);
      engine.emitStatus('done');

      await expectLater(
        second,
        throwsA(
          isA<SpeechToTextCaptureFailure>().having(
            (error) => error.toString(),
            'message',
            contains('ambiguous terminal'),
          ),
        ),
      );
      final third = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(engine.listenCalls, 2);

      engine.emitStatus('done');
      await Future<void>.delayed(Duration.zero);
      expect(engine.listenCalls, 3);
      unawaited(service.cancel());
      engine.emitStatus('done');
      await expectLater(third, throwsA(isA<SpeechToTextCaptureFailure>()));
    },
  );

  test('ambiguous error during replacement listening fails closed', () async {
    final engine = _StaleTerminalSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);
    final first = service.capture(timeout: const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);
    unawaited(service.cancel());
    await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));
    engine.endCurrentRecognition();

    final second = service.capture(timeout: const Duration(seconds: 1));
    await engine.secondListening;
    engine.emitError(StateError('uncertain recognizer error'));

    await expectLater(
      second,
      throwsA(
        isA<SpeechToTextCaptureFailure>().having(
          (error) => error.toString(),
          'message',
          contains('uncertain recognizer error'),
        ),
      ),
    );
    expect(engine.listenCalls, 2);
  });

  test(
    'late result from a completed recognizer cannot reach replacement listeners',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);
      final partials = <String>[];
      final partialSubscription = service.partialTranscripts.listen(
        partials.add,
      );
      addTearDown(partialSubscription.cancel);

      final first = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      unawaited(service.cancel());
      await expectLater(first, throwsA(isA<SpeechToTextCaptureFailure>()));
      engine.endCurrentRecognition();

      final second = service.capture(timeout: const Duration(seconds: 1));
      await engine.secondListening;
      engine.emitResultFor(0, 'stale old transcript', finalResult: false);
      await Future<void>.delayed(Duration.zero);

      expect(partials, isNot(contains('stale old transcript')));
      engine.emitResultFor(1, 'replacement transcript');
      engine.endCurrentRecognition();
      expect((await second).transcript, 'replacement transcript');
    },
  );

  test(
    'timeout cancellation blocks replacement until recognizer ends',
    () async {
      final engine = _StaleTerminalSpeechToTextEngine();
      final service = SpeechToTextVoiceCaptureService(engine: engine);

      await expectLater(
        service.capture(timeout: const Duration(milliseconds: 30)),
        throwsA(isA<VoiceCaptureTimeout>()),
      );

      final second = service.capture(timeout: const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(engine.listenCalls, 1);
      engine.endCurrentRecognition();
      await engine.secondListening;
      engine.emitResult('replacement transcript');
      engine.endCurrentRecognition();
      expect((await second).transcript, 'replacement transcript');
    },
  );

  test('listen setup failure still releases the speech engine', () async {
    final engine = _ListenFailingSpeechToTextEngine();
    final service = SpeechToTextVoiceCaptureService(engine: engine);

    await expectLater(
      service.capture(timeout: const Duration(seconds: 1)),
      throwsA(isA<SpeechToTextCaptureFailure>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(engine.cancelCalls, 1);
  });

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

class _ErrorThenHungCancelSpeechToTextEngine implements SpeechToTextEngine {
  final _neverCancels = Completer<void>();
  void Function(Object error)? _onError;

  @override
  Future<bool?> hasPermission() async => true;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    _onError = onError;
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
    scheduleMicrotask(
      () => _onError?.call(SpeechRecognitionError('error_no_match', true)),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() => _neverCancels.future;
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
  int listenCalls = 0;

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
  }) async {
    listenCalls += 1;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() => throw StateError('recognizer unavailable');
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

class _PartialResultEndsAsynchronouslySpeechToTextEngine
    extends _PartialResultSpeechToTextEngine {
  var _listening = false;
  var _listenCalls = 0;
  var overlappingListenCalls = 0;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {
    if (_listening) overlappingListenCalls++;
    _listening = true;
    _listenCalls++;
    _onStatus?.call('listening');
    onResult(
      SpeechToTextSnapshot(
        words: _listenCalls == 1 ? 'first partial' : 'second partial',
        confidence: 0.9,
        finalResult: false,
      ),
    );
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    Timer(const Duration(milliseconds: 180), () {
      _listening = false;
      _onStatus?.call('done');
      _onStatus?.call('done');
    });
  }
}

class _SilentStopAfterPartialSpeechToTextEngine
    extends _PartialResultSpeechToTextEngine {
  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

class _FailingStopAfterPartialSpeechToTextEngine
    extends _PartialResultSpeechToTextEngine {
  @override
  Future<void> stop() {
    stopCalls++;
    throw StateError('recognizer stop failed');
  }
}

class _FlushingStopSpeechToTextEngine extends _PartialResultSpeechToTextEngine {
  void Function(SpeechToTextSnapshot result)? _onResult;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {
    _onResult = onResult;
    await super.listen(
      onResult: onResult,
      listenFor: listenFor,
      pauseFor: pauseFor,
      localeId: localeId,
      onDevice: onDevice,
    );
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    Timer.run(() {
      _onResult?.call(
        const SpeechToTextSnapshot(
          words: 'hello world',
          confidence: 0.9,
          finalResult: false,
        ),
      );
      _onStatus?.call('done');
      _onStatus?.call('done');
    });
  }
}

class _FinalResultEndsAsynchronouslySpeechToTextEngine
    implements SpeechToTextEngine {
  void Function(String status)? _onStatus;
  var _listening = false;
  var _listenCalls = 0;
  var overlappingListenCalls = 0;
  var stopCalls = 0;
  var cancelCalls = 0;

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
    if (_listening) {
      overlappingListenCalls += 1;
      return;
    }
    _listening = true;
    _listenCalls += 1;
    final transcript = _listenCalls == 1
        ? 'first transcript'
        : 'second transcript';
    onResult(
      SpeechToTextSnapshot(words: transcript, confidence: 1, finalResult: true),
    );
    Timer(const Duration(milliseconds: 20), () {
      _listening = false;
      _onStatus?.call('done');
      _onStatus?.call('done');
    });
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    _listening = false;
  }

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
    _listening = false;
    _onStatus?.call('done');
  }
}

class _GenerationBoundFinalSpeechToTextEngine
    extends _FinalResultEndsAsynchronouslySpeechToTextEngine
    implements SpeechToTextGenerationBoundEngine {
  @override
  bool get hasGenerationBoundCallbacks => true;
}

class _FinalResultEndsWithErrorSpeechToTextEngine
    extends _FinalResultEndsAsynchronouslySpeechToTextEngine {
  void Function(Object error)? _onError;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    _onError = onError;
    _onStatus = onStatus;
    return true;
  }

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {
    _listening = true;
    onResult(
      const SpeechToTextSnapshot(
        words: 'final before teardown error',
        confidence: 1,
        finalResult: true,
      ),
    );
    Timer(const Duration(milliseconds: 20), () {
      _listening = false;
      _onError?.call(SpeechRecognitionError('error_client', true));
      _onStatus?.call('done');
      _onStatus?.call('done');
    });
  }
}

class _FakeSpeechToTextEngine implements SpeechToTextEngine {
  _FakeSpeechToTextEngine(this.words);

  final String words;
  void Function(String status)? _onStatus;
  bool? lastOnDevice;
  Duration? lastPauseFor;
  int stopCalls = 0;

  void emitStatus(String status) => _onStatus?.call(status);

  @override
  Future<bool?> hasPermission() async => true;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    _onStatus = onStatus;
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
    _onStatus?.call('done');
    _onStatus?.call('done');
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<void> cancel() async {}
}

class _CancelRecordingSpeechToTextEngine extends _FakeSpeechToTextEngine {
  _CancelRecordingSpeechToTextEngine() : super('');

  int cancelCalls = 0;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {}

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
    emitStatus('done');
  }
}

class _DuplicateTerminalSpeechToTextEngine
    implements SpeechToTextEngine, SpeechToTextListeningStateEngine {
  void Function(String)? _onStatus;
  void Function(SpeechToTextSnapshot result)? _onResult;
  bool _nativeActive = false;
  int _listens = 0;
  int overlappingListens = 0;
  final secondListening = Completer<void>();

  @override
  bool get isListening => _nativeActive;

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
    if (_nativeActive) overlappingListens += 1;
    _nativeActive = true;
    _onResult = onResult;
    _listens += 1;
    _onStatus?.call('listening');
    if (_listens == 2 && !secondListening.isCompleted) {
      secondListening.complete();
    }
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  void emitFinal(String transcript) {
    _onResult?.call(
      SpeechToTextSnapshot(words: transcript, confidence: 1, finalResult: true),
    );
  }

  void emitTerminal({required bool actualEnd}) {
    if (actualEnd) _nativeActive = false;
    _onStatus?.call('done');
  }
}

class _StaleTerminalSpeechToTextEngine extends _FakeSpeechToTextEngine {
  _StaleTerminalSpeechToTextEngine() : super('');

  final _onResults = <void Function(SpeechToTextSnapshot result)>[];
  void Function(Object error)? _onError;
  final _secondListening = Completer<void>();
  var _listenCalls = 0;

  Future<void> get secondListening => _secondListening.future;
  int get listenCalls => _listenCalls;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    _onError = onError;
    _onStatus = onStatus;
    return true;
  }

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {
    _listenCalls += 1;
    _onResults.add(onResult);
    _onStatus?.call('listening');
    if (_listenCalls == 2 && !_secondListening.isCompleted) {
      _secondListening.complete();
    }
  }

  @override
  void emitStatus(String status) => _onStatus?.call(status);

  void emitError(Object error) => _onError?.call(error);

  void endCurrentRecognition() {
    emitStatus('done');
    emitStatus('done');
  }

  void emitResult(String words) => emitResultFor(_onResults.length - 1, words);

  void emitResultFor(int index, String words, {bool finalResult = true}) =>
      _onResults[index](
        SpeechToTextSnapshot(
          words: words,
          confidence: 1,
          finalResult: finalResult,
        ),
      );
}

class _OwnedSoundLevelSpeechToTextEngine
    extends _StaleTerminalSpeechToTextEngine
    implements SpeechToTextSoundLevelEngine {
  final _soundLevels = StreamController<double>.broadcast(sync: true);

  @override
  Stream<double> get soundLevels => _soundLevels.stream;

  void emitSoundLevel(double level) => _soundLevels.add(level);
}

class _ListenFailingSpeechToTextEngine extends _FakeSpeechToTextEngine {
  _ListenFailingSpeechToTextEngine() : super('');

  int cancelCalls = 0;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async => throw StateError('recognizer start failed');

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
  }
}

class _SoundLevelSpeechToTextEngine extends _FakeSpeechToTextEngine
    implements SpeechToTextSoundLevelEngine {
  _SoundLevelSpeechToTextEngine(super.words);

  final _soundLevels = StreamController<double>.broadcast(sync: true);

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
  void Function(String status)? _onStatus;
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
    _onStatus ??= onStatus;
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
    _onStatus!('done');
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class _DelayedFinalSpeechToTextEngine extends _FakeSpeechToTextEngine {
  _DelayedFinalSpeechToTextEngine() : super('late final transcript');

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _onStatus = onStatus;
    onStatus('listening');
    return true;
  }

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
    required bool onDevice,
  }) async {
    Timer(listenFor, () {
      onResult(
        SpeechToTextSnapshot(words: words, confidence: 0.9, finalResult: true),
      );
      _onStatus?.call('done');
      _onStatus?.call('done');
    });
  }
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
