import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/controllers/hermes_voice_input_controller.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_capture_failures.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';
import 'package:wing/shared/voice/voice_settings.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  test(
    'voice input returns a composer draft without sending to Hermes',
    () async {
      final channel = FakeHermesChannel();
      final drafts = <String>[];
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => FakeVoiceCaptureService(
          audio: Uint8List(0),
          transcript: 'draft from voice',
          duration: const Duration(seconds: 1),
          confidence: 0.9,
        ),
        textToSpeechService: () => null,
        settings: () => const WingVoiceSettings(),
        onDraft: drafts.add,
      );
      addTearDown(controller.dispose);

      await controller.captureDraft();

      expect(drafts, ['draft from voice']);
      expect(controller.capturing, isFalse);
      expect(controller.error, isNull);
      expect(channel.state.voiceRuns, isEmpty);
      expect(channel.state.activeMessages, isEmpty);
    },
  );

  test(
    'one-shot voice sends and speaks the Hermes reply without rearming',
    () async {
      final channel = FakeHermesChannel();
      final tts = FakeTextToSpeechService();
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => FakeVoiceCaptureService(
          audio: Uint8List(0),
          transcript: 'send this now',
          duration: const Duration(seconds: 1),
          confidence: 0.9,
        ),
        textToSpeechService: () => tts,
        settings: () => const WingVoiceSettings(),
        onDraft: (_) {},
      );
      void continueOnChannelChange() {
        unawaited(controller.maybeContinue());
      }

      channel.addListener(continueOnChannelChange);
      addTearDown(() => channel.removeListener(continueOnChannelChange));
      addTearDown(controller.dispose);

      await controller.captureAndSend();
      await pumpEventQueue();

      expect(channel.sentVoiceTranscripts, ['send this now']);
      expect(tts.spoken, ['echo: send this now']);
      expect(controller.continuousEnabled, isFalse);
      expect(controller.capturing, isFalse);
    },
  );

  test(
    'pausing voice input cancels capture and drops its late result',
    () async {
      final channel = FakeHermesChannel();
      final capture = _ControlledVoiceCaptureService();
      final drafts = <String>[];
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => capture,
        textToSpeechService: () => null,
        settings: () => const WingVoiceSettings(),
        onDraft: drafts.add,
      );
      addTearDown(controller.dispose);

      final pendingCapture = controller.captureDraft();
      await pumpEventQueue();
      expect(controller.capturing, isTrue);

      controller.pause();
      expect(capture.cancelCalls, 1);

      capture.complete('late transcript');
      await pendingCapture;

      expect(controller.capturing, isFalse);
      expect(drafts, isEmpty);
    },
  );

  test('voice input exposes interim speech while listening', () async {
    final channel = FakeHermesChannel();
    final capture = _PartialTranscriptCaptureService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
    );
    addTearDown(controller.dispose);

    unawaited(controller.captureDraft());
    await pumpEventQueue();
    capture.emit('hello Hermes');
    await pumpEventQueue();

    expect(controller.liveTranscript, 'hello Hermes');
  });

  test('continuous voice allows long dictation before timing out', () async {
    final channel = FakeHermesChannel();
    final capture = _RecordingVoiceCaptureService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();

    expect(capture.timeout, const Duration(seconds: 30));
  });

  test('continuous voice submits the captured transcript to Hermes', () async {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => FakeVoiceCaptureService(
        audio: Uint8List(0),
        transcript: 'send this continuously',
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      ),
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();

    expect(controller.continuousEnabled, isTrue);
    expect(channel.sentVoiceTranscripts, ['send this continuously']);
  });

  test('continuous voice speaks one reply and re-arms capture', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstCaptureThenBlockService('hello Hermes');
    final tts = FakeTextToSpeechService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => tts,
      settings: () => const WingVoiceSettings(
        continuousVoiceEnabled: true,
        speakRepliesEnabled: true,
      ),
      onDraft: (_) {},
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();
    await controller.maybeContinue();
    await pumpEventQueue();

    expect(tts.spoken, ['echo: hello Hermes']);
    expect(capture.captureCalls, 2);
    expect(controller.capturing, isTrue);
  });

  test(
    'continuous voice waits for speaker audio to clear before rearming',
    () async {
      final channel = FakeHermesChannel();
      final capture = _FirstCaptureThenBlockService('hello Hermes');
      final tts = _ControlledTextToSpeechService();
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => capture,
        textToSpeechService: () => tts,
        settings: () => const WingVoiceSettings(
          continuousVoiceEnabled: true,
          speakRepliesEnabled: true,
        ),
        onDraft: (_) {},
        rearmDelay: const Duration(milliseconds: 20),
      );
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      unawaited(controller.maybeContinue());
      await pumpEventQueue();
      expect(capture.captureCalls, 1);

      tts.complete();
      await Future<void>.delayed(Duration.zero);
      expect(capture.captureCalls, 1);
      await Future<void>.delayed(const Duration(milliseconds: 25));

      expect(capture.captureCalls, 2);
    },
  );

  test(
    'continuous voice discards a transcript echoed from its spoken reply',
    () async {
      final channel = FakeHermesChannel();
      final capture = _TranscriptQueueThenBlockService([
        'hello Hermes',
        'echo hello Hermes',
      ]);
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => capture,
        textToSpeechService: () => FakeTextToSpeechService(),
        settings: () => const WingVoiceSettings(
          continuousVoiceEnabled: true,
          speakRepliesEnabled: true,
        ),
        onDraft: (_) {},
        rearmDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      await controller.maybeContinue();
      await pumpEventQueue();

      expect(channel.sentVoiceTranscripts, ['hello Hermes']);
      expect(capture.captureCalls, 3);
    },
  );

  test(
    'continuous voice speaks only the reply to the new transcript',
    () async {
      final channel = FakeHermesChannel();
      await channel.sendText('words I already said');
      final capture = _FirstCaptureThenBlockService('new question');
      final tts = FakeTextToSpeechService();
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => capture,
        textToSpeechService: () => tts,
        settings: () => const WingVoiceSettings(
          continuousVoiceEnabled: true,
          speakRepliesEnabled: true,
        ),
        onDraft: (_) {},
      );
      void continueOnChannelChange() {
        unawaited(controller.maybeContinue());
      }

      channel.addListener(continueOnChannelChange);
      addTearDown(() => channel.removeListener(continueOnChannelChange));
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      await pumpEventQueue();

      expect(tts.spoken, ['echo: new question']);
    },
  );

  test('voice waits for an active Hermes run before speaking', () async {
    final channel = FakeHermesChannel();
    await channel.sendText('first question');
    final tts = FakeTextToSpeechService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => null,
      textToSpeechService: () => tts,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
    );
    addTearDown(controller.dispose);

    controller.speakNextReply();
    await channel.sendText('second question');
    channel.startVoiceRun();
    await controller.maybeContinue();

    expect(tts.spoken, isEmpty);
  });

  test('continuous voice pauses when capture fails', () async {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => const _FailingVoiceCaptureService(),
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();

    expect(controller.continuousEnabled, isFalse);
    expect(
      controller.error,
      'Voice capture timed out. Continuous voice paused.',
    );
  });

  test('continuous voice re-arms after no speech', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstNoSpeechThenBlockService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
      rearmDelay: const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();
    await pumpEventQueue();
    expect(capture.captureCalls, 1);
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(capture.captureCalls, 2);
    expect(controller.continuousEnabled, isTrue);
    expect(controller.capturing, isTrue);
    expect(controller.error, isNull);
  });

  test('commandWord stop pauses continuous mode', () async {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => FakeVoiceCaptureService(
        audio: Uint8List(0),
        transcript: 'navi stop',
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      ),
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();

    expect(controller.continuousEnabled, isFalse);
  });

  test('disposing mid-capture cannot raise from the microphone', () async {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => const _UncancellableVoiceCaptureService(),
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
    );

    unawaited(controller.captureDraft());
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
  });
}

/// Mirrors a platform speech engine whose cancel fails while a capture is
/// still active, which is what happens when the recognizer is already gone.
class _PartialTranscriptCaptureService
    implements VoiceCaptureService, VoiceCaptureProgressService {
  final _partialTranscripts = StreamController<String>.broadcast();
  final _capture = Completer<VoiceCapture>();

  @override
  Stream<String> get partialTranscripts => _partialTranscripts.stream;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) => _capture.future;

  @override
  Future<void> cancel() async {
    if (!_capture.isCompleted) _capture.completeError(StateError('cancelled'));
    await _partialTranscripts.close();
  }

  void emit(String transcript) => _partialTranscripts.add(transcript);
}

class _UncancellableVoiceCaptureService implements VoiceCaptureService {
  const _UncancellableVoiceCaptureService();

  @override
  Future<VoiceCapture> capture({required Duration timeout}) =>
      Completer<VoiceCapture>().future;

  @override
  Future<void> cancel() async => throw StateError('recognizer unavailable');
}

class _RecordingVoiceCaptureService implements VoiceCaptureService {
  Duration? timeout;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    this.timeout = timeout;
    return VoiceCapture(
      audio: Uint8List(0),
      transcript: 'long dictation',
      duration: const Duration(seconds: 20),
      confidence: 1,
    );
  }

  @override
  Future<void> cancel() async {}
}

class _ControlledVoiceCaptureService implements VoiceCaptureService {
  final _completion = Completer<VoiceCapture>();
  int cancelCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) =>
      _completion.future;

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
  }

  void complete(String transcript) {
    if (_completion.isCompleted) return;
    _completion.complete(
      VoiceCapture(
        audio: Uint8List(0),
        transcript: transcript,
        duration: const Duration(seconds: 1),
        confidence: 1,
      ),
    );
  }
}

class _ControlledTextToSpeechService implements TextToSpeechService {
  final _completion = Completer<void>();

  @override
  Future<void> speak(String text) => _completion.future;

  @override
  Future<void> stop() async {
    complete();
  }

  @override
  Future<void> dispose() => stop();

  void complete() {
    if (!_completion.isCompleted) _completion.complete();
  }
}

class _TranscriptQueueThenBlockService implements VoiceCaptureService {
  _TranscriptQueueThenBlockService(this._transcripts);

  final List<String> _transcripts;
  final _pending = Completer<VoiceCapture>();
  int captureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls++;
    if (_transcripts.isEmpty) return _pending.future;
    return Future.value(
      VoiceCapture(
        audio: Uint8List(0),
        transcript: _transcripts.removeAt(0),
        duration: const Duration(seconds: 1),
        confidence: 1,
      ),
    );
  }

  @override
  Future<void> cancel() async {
    if (!_pending.isCompleted) _pending.completeError(StateError('cancelled'));
  }
}

class _FirstCaptureThenBlockService implements VoiceCaptureService {
  _FirstCaptureThenBlockService(this.firstTranscript);

  final String firstTranscript;
  final _secondCapture = Completer<VoiceCapture>();
  int captureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    if (captureCalls > 1) return _secondCapture.future;
    return Future.value(
      VoiceCapture(
        audio: Uint8List(0),
        transcript: firstTranscript,
        duration: const Duration(seconds: 1),
        confidence: 1,
      ),
    );
  }

  @override
  Future<void> cancel() async {}
}

class _FirstNoSpeechThenBlockService implements VoiceCaptureService {
  final Completer<VoiceCapture> _pending = Completer<VoiceCapture>();
  int captureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls++;
    if (captureCalls == 1) {
      throw const SpeechToTextCaptureFailure('no transcript');
    }
    return _pending.future;
  }

  @override
  Future<void> cancel() async {
    if (!_pending.isCompleted) {
      _pending.completeError(StateError('cancelled'));
    }
  }
}

class _FailingVoiceCaptureService implements VoiceCaptureService {
  const _FailingVoiceCaptureService();

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    throw const VoiceCaptureTimeout();
  }

  @override
  Future<void> cancel() async {}
}
