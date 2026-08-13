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

  test('rapid pause and re-enable waits for recognizer cancellation', () async {
    final channel = FakeHermesChannel();
    final capture = _SlowCancellationCaptureService();
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

    unawaited(controller.enableContinuous());
    await pumpEventQueue();
    expect(capture.captureCalls, 1);

    controller.pause();
    unawaited(controller.enableContinuous());
    await pumpEventQueue();

    expect(capture.captureCalls, 1);
    capture.completeCancellation();
    await pumpEventQueue();
    expect(capture.captureCalls, 2);
    expect(capture.overlappingCaptureCalls, 0);
  });

  test('hung recognizer teardown pauses rapid re-enable safely', () async {
    final capture = _SlowCancellationCaptureService();
    final controller = HermesVoiceInputController(
      channel: FakeHermesChannel.new,
      captureService: () => capture,
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(continuousVoiceEnabled: true),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
      teardownTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);

    unawaited(controller.enableContinuous());
    await pumpEventQueue();
    controller.pause();
    await controller.enableContinuous();

    expect(capture.captureCalls, 1);
    expect(controller.capturing, isFalse);
    expect(controller.continuousEnabled, isFalse);
    expect(controller.error, contains('shutdown timed out'));
  });

  test('failed recognizer teardown pauses rapid re-enable safely', () async {
    final capture = _FailingCancellationCaptureService();
    final controller = HermesVoiceInputController(
      channel: FakeHermesChannel.new,
      captureService: () => capture,
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(continuousVoiceEnabled: true),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    unawaited(controller.enableContinuous());
    await pumpEventQueue();
    controller.pause();
    await controller.enableContinuous();

    expect(capture.captureCalls, 1);
    expect(controller.capturing, isFalse);
    expect(controller.continuousEnabled, isFalse);
    expect(controller.error, contains('shutdown failed'));
  });

  test('pause observes a failed cancellation without re-enable', () async {
    final capture = _FailingCancellationCaptureService();
    final controller = HermesVoiceInputController(
      channel: FakeHermesChannel.new,
      captureService: () => capture,
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
    );

    unawaited(controller.captureDraft());
    await pumpEventQueue();
    controller.pause();
    await pumpEventQueue();
    controller.dispose();
  });

  test('rapid pause and re-enable waits for TTS shutdown', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstThenControlledCaptureService('hello Hermes');
    final tts = _SlowStoppingTextToSpeechService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => tts,
      settings: () => const WingVoiceSettings(
        speakRepliesEnabled: true,
        continuousVoiceEnabled: true,
      ),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
    );

    await controller.enableContinuous();
    unawaited(controller.maybeContinue());
    await pumpEventQueue();
    expect(capture.captureCalls, 2);

    controller.pause();
    unawaited(controller.enableContinuous());
    await pumpEventQueue();

    expect(capture.captureCalls, 2);
    tts.completeStop();
    await pumpEventQueue();
    expect(capture.captureCalls, 3);

    controller.dispose();
  });

  test('hung TTS shutdown pauses rapid re-enable safely', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstThenControlledCaptureService('hello Hermes');
    final tts = _SlowStoppingTextToSpeechService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => tts,
      settings: () => const WingVoiceSettings(
        continuousVoiceEnabled: true,
        speakRepliesEnabled: true,
      ),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
      teardownTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();
    unawaited(controller.maybeContinue());
    await pumpEventQueue();
    controller.pause();
    await controller.enableContinuous();

    expect(capture.captureCalls, 2);
    expect(controller.capturing, isFalse);
    expect(controller.continuousEnabled, isFalse);
    expect(controller.error, contains('shutdown timed out'));
  });

  test('failed TTS shutdown pauses rapid re-enable safely', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstThenControlledCaptureService('hello Hermes');
    final tts = _FailingStoppingTextToSpeechService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => tts,
      settings: () => const WingVoiceSettings(
        continuousVoiceEnabled: true,
        speakRepliesEnabled: true,
      ),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();
    unawaited(controller.maybeContinue());
    await pumpEventQueue();
    expect(capture.captureCalls, 2);
    expect(controller.speaking, isTrue);
    controller.pause();
    await controller.enableContinuous();

    expect(capture.captureCalls, 2);
    expect(controller.capturing, isFalse);
    expect(controller.continuousEnabled, isFalse);
    expect(controller.error, contains('shutdown failed'));
  });

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

  test('enabling continuous mode during a draft capture re-arms it', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstDraftThenBlockService();
    final drafts = <String>[];
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: drafts.add,
      rearmDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    final draft = controller.captureDraft();
    await pumpEventQueue();
    await controller.enableContinuous();
    capture.completeDraft();
    await draft;
    await pumpEventQueue();

    expect(drafts, ['draft in progress']);
    expect(capture.captureCalls, 2);
    expect(controller.continuousEnabled, isTrue);
    expect(controller.capturing, isTrue);
  });

  test('continuous mode re-arms after an in-flight draft times out', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstDraftThenBlockService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    final draft = controller.captureDraft();
    await pumpEventQueue();
    await controller.enableContinuous();
    capture.failDraft(const VoiceCaptureTimeout());
    await draft;
    await pumpEventQueue();

    expect(capture.captureCalls, 2);
    expect(controller.continuousEnabled, isTrue);
    expect(controller.capturing, isTrue);
  });

  test('enabling continuous mode during one-shot voice re-arms it', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstDraftThenBlockService();
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
      rearmDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    final oneShot = controller.captureAndSend();
    await pumpEventQueue();
    await controller.enableContinuous();
    capture.completeDraft();
    await oneShot;
    await pumpEventQueue();

    expect(channel.sentVoiceTranscripts, ['draft in progress']);
    expect(tts.spoken, ['echo: draft in progress']);
    expect(capture.captureCalls, 2);
    expect(controller.continuousEnabled, isTrue);
    expect(controller.capturing, isTrue);
  });

  test(
    'continuous voice allows extended dictation before timing out',
    () async {
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

      expect(capture.timeout, const Duration(minutes: 5));
    },
  );

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
    'continuous voice listens during speech and interrupts on partial input',
    () async {
      final channel = FakeHermesChannel();
      final capture = _FirstThenControlledCaptureService('hello Hermes');
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

      expect(capture.captureCalls, 2);
      expect(controller.capturing, isTrue);
      expect(controller.speaking, isTrue);

      capture.emitPartial('interrupting follow-up');
      await pumpEventQueue();

      expect(tts.stopCalls, 1);
      expect(controller.speaking, isFalse);
      expect(controller.continuousEnabled, isTrue);

      capture.completeSecond('interrupting follow-up');
      await pumpEventQueue();

      expect(channel.sentVoiceTranscripts, [
        'hello Hermes',
        'interrupting follow-up',
      ]);
    },
  );

  test(
    'short partial speech interrupts a long Hermes reply immediately',
    () async {
      final channel = FakeHermesChannel();
      final capture = _FirstThenControlledCaptureService('hello Hermes');
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
        rearmDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      unawaited(controller.maybeContinue());
      await pumpEventQueue();
      expect(controller.speaking, isTrue);

      capture.emitPartial('no');
      await pumpEventQueue();

      expect(tts.stopCalls, 1);
      expect(controller.speaking, isFalse);
      capture.completeSecond('no');
      await pumpEventQueue();
      expect(channel.sentVoiceTranscripts, ['hello Hermes', 'no']);
    },
  );

  test(
    'short reply-prefix speech still interrupts Hermes immediately',
    () async {
      final channel = FakeHermesChannel();
      final capture = _FirstThenControlledCaptureService('hello Hermes');
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
        rearmDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      unawaited(controller.maybeContinue());
      await pumpEventQueue();
      expect(controller.speaking, isTrue);

      capture.emitPartial('echo');
      await pumpEventQueue();

      expect(tts.stopCalls, 1);
      expect(controller.speaking, isFalse);
      capture.completeSecond('echo');
      await pumpEventQueue();
      expect(channel.sentVoiceTranscripts, ['hello Hermes', 'echo']);
    },
  );

  test('hung TTS stop cannot swallow a barge-in transcript', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstThenControlledCaptureService('hello Hermes');
    final tts = _SlowStoppingTextToSpeechService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => tts,
      settings: () => const WingVoiceSettings(
        continuousVoiceEnabled: true,
        speakRepliesEnabled: true,
      ),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
      teardownTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();
    unawaited(controller.maybeContinue());
    await pumpEventQueue();
    capture.emitPartial('no');
    await pumpEventQueue();
    controller.speakNextReply();
    await controller.maybeContinue().timeout(
      const Duration(milliseconds: 100),
      onTimeout: () =>
          throw StateError('speech teardown stranded continuation'),
    );
    capture.completeSecond('no');
    await pumpEventQueue();

    expect(channel.sentVoiceTranscripts, ['hello Hermes']);
    expect(capture.cancelCalls, 1);
    expect(controller.capturing, isFalse);
    expect(controller.continuousEnabled, isFalse);
    expect(controller.error, contains('shutdown timed out'));
  });

  test('final barge-in survives a timed-out TTS shutdown', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstThenControlledCaptureService('hello Hermes');
    final tts = _SlowStoppingTextToSpeechService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => tts,
      settings: () => const WingVoiceSettings(
        continuousVoiceEnabled: true,
        speakRepliesEnabled: true,
      ),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
      teardownTimeout: const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();
    unawaited(controller.maybeContinue());
    await pumpEventQueue();
    expect(controller.speaking, isTrue);

    capture.completeSecond('final interruption');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await pumpEventQueue();

    expect(channel.sentVoiceTranscripts, [
      'hello Hermes',
      'final interruption',
    ]);
    expect(controller.capturing, isFalse);
    expect(controller.continuousEnabled, isFalse);
    expect(controller.error, contains('shutdown timed out'));
  });

  test('pause during final-result TTS teardown drops the late turn', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstThenControlledCaptureService('hello Hermes');
    final tts = _SlowStoppingTextToSpeechService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => tts,
      settings: () => const WingVoiceSettings(
        continuousVoiceEnabled: true,
        speakRepliesEnabled: true,
      ),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();
    unawaited(controller.maybeContinue());
    await pumpEventQueue();
    expect(controller.speaking, isTrue);

    capture.completeSecond('late paused transcript');
    await pumpEventQueue();
    controller.pause();
    tts.completeStop();
    await pumpEventQueue();

    expect(channel.sentVoiceTranscripts, ['hello Hermes']);
  });

  test(
    'hung TTS stops playback and capture instead of freezing voice mode',
    () async {
      final channel = FakeHermesChannel();
      final capture = _FirstThenControlledCaptureService('hello Hermes');
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
        rearmDelay: Duration.zero,
        speechTimeout: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      unawaited(controller.maybeContinue());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await pumpEventQueue();

      expect(tts.stopCalls, 1);
      expect(capture.cancelCalls, 1);
      expect(controller.speaking, isFalse);
      expect(controller.capturing, isFalse);
      expect(controller.continuousEnabled, isFalse);
      expect(controller.error, contains('Could not speak Hermes reply'));
    },
  );

  test('continuous voice discards a short exact spoken-reply echo', () async {
    final channel = FakeHermesChannel();
    final capture = _TranscriptQueueThenBlockService(['hi', 'echo hi']);
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

    expect(channel.sentVoiceTranscripts, ['hi']);
    expect(capture.captureCalls, 3);
  });

  test(
    'continuous voice discards a transcript echoed from its spoken reply',
    () async {
      final channel = FakeHermesChannel();
      final capture = _TranscriptQueueThenBlockService([
        'hello Hermes',
        'echo hello Hermes from the speaker output',
        'echo hello Hermes from the speaker output',
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
      // The same tail audio can be finalized twice by Android. Neither result
      // may become a new Hermes turn.
      expect(capture.captureCalls, 4);
    },
  );

  test(
    'continuous voice listens while Hermes writes and interrupts on speech',
    () async {
      final channel = _StreamingVoiceChannel();
      final capture = _TranscriptQueueThenBlockService([
        'first question',
        'interrupting follow-up',
      ]);
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => capture,
        textToSpeechService: () => null,
        settings: () => const WingVoiceSettings(
          continuousVoiceEnabled: true,
          speakRepliesEnabled: true,
        ),
        onDraft: (_) {},
        rearmDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      await pumpEventQueue();

      expect(capture.captureCalls, 2);
      expect(channel.stopActiveTurnCalls, 1);
      expect(channel.sentVoiceTranscripts, [
        'first question',
        'interrupting follow-up',
      ]);
    },
  );

  test(
    'speak next reply does not replay the baseline assistant turn',
    () async {
      final channel = FakeHermesChannel();
      await channel.sendText('already answered');
      final tts = FakeTextToSpeechService();
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => null,
        textToSpeechService: () => tts,
        settings: () => const WingVoiceSettings(speakRepliesEnabled: true),
        onDraft: (_) {},
      );
      addTearDown(controller.dispose);

      controller.speakNextReply();
      await controller.maybeContinue();

      expect(tts.spoken, isEmpty);
    },
  );

  test(
    'continuous voice speaks stable reply sentences before generation ends',
    () async {
      final channel = _StreamingVoiceChannel();
      final tts = FakeTextToSpeechService();
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => null,
        textToSpeechService: () => tts,
        settings: () => const WingVoiceSettings(
          continuousVoiceEnabled: true,
          speakRepliesEnabled: true,
        ),
        onDraft: (_) {},
        rearmDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      controller.speakNextReply();
      channel.beginStreamingTurn('question');
      channel.appendStreamingTurnText('First sentence. Tail');

      await controller.maybeContinue();
      expect(tts.spoken, ['First sentence.']);

      await controller.maybeContinue();
      expect(tts.spoken, ['First sentence.']);

      channel.completeStreamingTurn(text: 'First sentence. Final tail');
      await controller.maybeContinue();

      expect(tts.spoken, ['First sentence.', 'Final tail']);
    },
  );

  test('canonical completion rewrites do not shift the spoken tail', () async {
    final channel = _StreamingVoiceChannel();
    final tts = FakeTextToSpeechService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => null,
      textToSpeechService: () => tts,
      settings: () => const WingVoiceSettings(speakRepliesEnabled: true),
      onDraft: (_) {},
      rearmDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    controller.speakNextReply();
    channel.beginStreamingTurn('question');
    channel.appendStreamingTurnText('Answer is 10. Tail arriving');
    await controller.maybeContinue();

    channel.completeStreamingTurn(text: 'Answer: 10. Tail');
    await controller.maybeContinue();

    expect(tts.spoken, ['Answer is 10.', 'Tail']);
  });

  test(
    'streaming speech drains a sentence that arrived during playback',
    () async {
      final channel = _StreamingVoiceChannel();
      final tts = _ControlledTextToSpeechService();
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => null,
        textToSpeechService: () => tts,
        settings: () => const WingVoiceSettings(speakRepliesEnabled: true),
        onDraft: (_) {},
        rearmDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      controller.speakNextReply();
      channel.beginStreamingTurn('question');
      channel.appendStreamingTurnText('First sentence.');
      unawaited(controller.maybeContinue());
      await pumpEventQueue();
      expect(tts.spoken, ['First sentence.']);

      channel.appendStreamingTurnText(' Second sentence!');
      await controller.maybeContinue();
      expect(tts.spoken, ['First sentence.']);

      tts.complete();
      await pumpEventQueue();

      expect(tts.spoken, ['First sentence.', 'Second sentence!']);
    },
  );

  test(
    'short echo of a later streaming chunk does not interrupt playback',
    () async {
      final channel = _StreamingVoiceChannel();
      final capture = _FirstThenControlledCaptureService('question');
      final tts = _BlockSecondTextToSpeechService();
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => capture,
        textToSpeechService: () => tts,
        settings: () => const WingVoiceSettings(
          continuousVoiceEnabled: true,
          speakRepliesEnabled: true,
        ),
        onDraft: (_) {},
        rearmDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      channel.appendStreamingTurnText(' First sentence.');
      await controller.maybeContinue();
      channel.appendStreamingTurnText(' Tail.');
      unawaited(controller.maybeContinue());
      await pumpEventQueue();

      expect(tts.spoken, ['First sentence.', 'Tail.']);
      capture.emitPartial('Tail.');
      await pumpEventQueue();

      expect(tts.stopCalls, 0);
      expect(controller.speaking, isTrue);
      tts.completeSecond();
    },
  );

  test(
    'partial input barges into speech started from a streaming reply',
    () async {
      final channel = _StreamingVoiceChannel();
      final capture = _FirstThenControlledCaptureService('question');
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
        rearmDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      channel.appendStreamingTurnText(' First sentence.');
      unawaited(controller.maybeContinue());
      await pumpEventQueue();
      expect(tts.spoken, ['First sentence.']);
      expect(controller.speaking, isTrue);

      capture.emitPartial('interrupt now');
      await pumpEventQueue();

      expect(tts.stopCalls, 1);
      expect(controller.speaking, isFalse);
      expect(controller.continuousEnabled, isTrue);
    },
  );

  test(
    'continuous voice speaks a reply after listening finds no interruption',
    () async {
      final channel = _StreamingVoiceChannel();
      final capture = _FirstTranscriptThenNoSpeechService();
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
        rearmDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      await controller.enableContinuous();
      await pumpEventQueue();
      expect(capture.captureCalls, 2);

      channel.completeStreamingTurn(text: 'finished answer');
      await controller.maybeContinue();
      await pumpEventQueue();

      expect(tts.spoken, ['finished answer']);
      expect(controller.capturing, isTrue);
      expect(capture.captureCalls, 2);

      capture.completeNoSpeech();
      await pumpEventQueue();
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
    expect(controller.error, contains('Continuous voice paused.'));
  });

  test('continuous voice re-arms after its capture window expires', () async {
    final channel = FakeHermesChannel();
    final capture = _FirstTimeoutThenBlockService();
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
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(capture.captureCalls, 2);
    expect(controller.continuousEnabled, isTrue);
    expect(controller.capturing, isTrue);
    expect(controller.error, isNull);
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

  test('multi-word command phrase stops continuous mode', () async {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => FakeVoiceCaptureService(
        audio: Uint8List(0),
        transcript: 'hey navi stop',
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      ),
      textToSpeechService: () => null,
      settings: () => const WingVoiceSettings(commandWord: 'hey navi'),
      onDraft: (_) {},
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();

    expect(controller.continuousEnabled, isFalse);
  });

  test(
    'dispose attempts capture and TTS cleanup despite synchronous throws',
    () async {
      final channel = FakeHermesChannel();
      final capture = _SynchronouslyThrowingCaptureService('hello Hermes');
      final tts = _SynchronouslyThrowingStoppingTextToSpeechService();
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => capture,
        textToSpeechService: () => tts,
        settings: () => const WingVoiceSettings(
          continuousVoiceEnabled: true,
          speakRepliesEnabled: true,
        ),
        onDraft: (_) {},
        rearmDelay: Duration.zero,
      );

      await controller.enableContinuous();
      unawaited(controller.maybeContinue());
      await pumpEventQueue();
      expect(controller.capturing, isTrue);
      expect(controller.speaking, isTrue);

      expect(controller.dispose, returnsNormally);
      await pumpEventQueue();

      expect(capture.cancelCalls, 1);
      expect(tts.stopCalls, 1);
    },
  );

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

class _FailingCancellationCaptureService implements VoiceCaptureService {
  Completer<VoiceCapture>? _capture;
  int captureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    return (_capture = Completer<VoiceCapture>()).future;
  }

  @override
  Future<void> cancel() async {
    final capture = _capture;
    if (capture != null && !capture.isCompleted) {
      capture.completeError(StateError('cancelled'));
    }
    throw StateError('recognizer cancellation failed');
  }
}

class _SlowCancellationCaptureService implements VoiceCaptureService {
  final _cancellation = Completer<void>();
  final _captures = <Completer<VoiceCapture>>[];
  var _active = false;
  var _cancelling = false;
  var _cancelCalls = 0;
  int captureCalls = 0;
  int overlappingCaptureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    if (_active || _cancelling) overlappingCaptureCalls += 1;
    _active = true;
    captureCalls += 1;
    final capture = Completer<VoiceCapture>();
    _captures.add(capture);
    return capture.future;
  }

  @override
  Future<void> cancel() {
    _cancelCalls += 1;
    _cancelling = true;
    _active = false;
    final capture = _captures.isEmpty ? null : _captures.last;
    if (capture != null && !capture.isCompleted) {
      capture.completeError(StateError('cancelled'));
    }
    if (_cancelCalls == 1) return _cancellation.future;
    _cancelling = false;
    return Future<void>.value();
  }

  void completeCancellation() {
    _cancelling = false;
    if (!_cancellation.isCompleted) _cancellation.complete();
  }
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

class _FirstDraftThenBlockService implements VoiceCaptureService {
  final _draft = Completer<VoiceCapture>();
  final _continuous = Completer<VoiceCapture>();
  int captureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    return captureCalls == 1 ? _draft.future : _continuous.future;
  }

  void completeDraft() {
    _draft.complete(
      VoiceCapture(
        audio: Uint8List(0),
        transcript: 'draft in progress',
        duration: const Duration(seconds: 1),
        confidence: 1,
      ),
    );
  }

  void failDraft(Object error) => _draft.completeError(error);

  @override
  Future<void> cancel() async {
    if (!_continuous.isCompleted) {
      _continuous.completeError(StateError('cancelled'));
    }
  }
}

class _FailingStoppingTextToSpeechService implements TextToSpeechService {
  final _speaking = Completer<void>();

  @override
  Future<void> speak(String text) => _speaking.future;

  @override
  Future<void> stop() async {
    if (!_speaking.isCompleted) _speaking.complete();
    throw StateError('TTS stop failed');
  }

  @override
  Future<void> dispose() => stop();
}

class _SlowStoppingTextToSpeechService implements TextToSpeechService {
  final _speaking = Completer<void>();
  final _stopped = Completer<void>();
  int stopCalls = 0;

  @override
  Future<void> speak(String text) => _speaking.future;

  @override
  Future<void> stop() {
    stopCalls += 1;
    if (!_speaking.isCompleted) _speaking.complete();
    return _stopped.future;
  }

  @override
  Future<void> dispose() => stop();

  void completeStop() {
    if (!_stopped.isCompleted) _stopped.complete();
  }
}

class _BlockSecondTextToSpeechService implements TextToSpeechService {
  final _secondCompletion = Completer<void>();
  final List<String> spoken = [];
  int stopCalls = 0;

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    return spoken.length == 1 ? Future<void>.value() : _secondCompletion.future;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    completeSecond();
  }

  @override
  Future<void> dispose() => stop();

  void completeSecond() {
    if (!_secondCompletion.isCompleted) _secondCompletion.complete();
  }
}

class _ControlledTextToSpeechService implements TextToSpeechService {
  final _completion = Completer<void>();
  final List<String> spoken = [];
  int stopCalls = 0;

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    return _completion.future;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    complete();
  }

  @override
  Future<void> dispose() => stop();

  void complete() {
    if (!_completion.isCompleted) _completion.complete();
  }
}

class _FirstThenControlledCaptureService
    implements VoiceCaptureService, VoiceCaptureProgressService {
  _FirstThenControlledCaptureService(this.firstTranscript);

  final String firstTranscript;
  final _secondCapture = Completer<VoiceCapture>();
  final _pending = Completer<VoiceCapture>();
  final _partialTranscripts = StreamController<String>.broadcast();
  int captureCalls = 0;
  int cancelCalls = 0;

  @override
  Stream<String> get partialTranscripts => _partialTranscripts.stream;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    if (captureCalls == 1) {
      return Future.value(_capture(firstTranscript));
    }
    return captureCalls == 2 ? _secondCapture.future : _pending.future;
  }

  void emitPartial(String transcript) => _partialTranscripts.add(transcript);

  void completeSecond(String transcript) {
    if (!_secondCapture.isCompleted) {
      _secondCapture.complete(_capture(transcript));
    }
  }

  VoiceCapture _capture(String transcript) => VoiceCapture(
    audio: Uint8List(0),
    transcript: transcript,
    duration: const Duration(seconds: 1),
    confidence: 1,
  );

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
    if (captureCalls >= 2 && !_secondCapture.isCompleted) {
      _secondCapture.completeError(StateError('cancelled'));
    }
    if (captureCalls >= 3 && !_pending.isCompleted) {
      _pending.completeError(StateError('cancelled'));
    }
    await _partialTranscripts.close();
  }
}

class _SynchronouslyThrowingCaptureService
    extends _FirstThenControlledCaptureService {
  _SynchronouslyThrowingCaptureService(super.firstTranscript);

  @override
  Future<void> cancel() {
    cancelCalls += 1;
    throw StateError('synchronous capture cancellation failure');
  }
}

class _SynchronouslyThrowingStoppingTextToSpeechService
    implements TextToSpeechService {
  final _speaking = Completer<void>();
  int stopCalls = 0;

  @override
  Future<void> speak(String text) => _speaking.future;

  @override
  Future<void> stop() {
    stopCalls += 1;
    throw StateError('synchronous TTS stop failure');
  }

  @override
  Future<void> dispose() => stop();
}

class _StreamingVoiceChannel extends FakeHermesChannel {
  int _voiceSubmissions = 0;

  @override
  void submitVoiceRun(String voiceRunId) {
    _voiceSubmissions += 1;
    super.submitVoiceRun(voiceRunId);
    if (_voiceSubmissions == 1) beginStreamingTurn('Hermes is writing');
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

class _FirstTranscriptThenNoSpeechService implements VoiceCaptureService {
  final _noSpeech = Completer<VoiceCapture>();
  final _pending = Completer<VoiceCapture>();
  int captureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    if (captureCalls == 1) {
      return Future.value(
        VoiceCapture(
          audio: Uint8List(0),
          transcript: 'first question',
          duration: const Duration(seconds: 1),
          confidence: 1,
        ),
      );
    }
    return captureCalls == 2 ? _noSpeech.future : _pending.future;
  }

  void completeNoSpeech() {
    _noSpeech.completeError(const SpeechToTextCaptureFailure('no transcript'));
  }

  @override
  Future<void> cancel() async {
    if (!_noSpeech.isCompleted) {
      _noSpeech.completeError(StateError('cancelled'));
    }
    if (!_pending.isCompleted) {
      _pending.completeError(StateError('cancelled'));
    }
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

class _FirstTimeoutThenBlockService implements VoiceCaptureService {
  final _pending = Completer<VoiceCapture>();
  int captureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    if (captureCalls == 1) throw const VoiceCaptureTimeout();
    return _pending.future;
  }

  @override
  Future<void> cancel() async {
    if (!_pending.isCompleted) {
      _pending.completeError(StateError('cancelled'));
    }
  }
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
    throw StateError('recognizer failed');
  }

  @override
  Future<void> cancel() async {}
}
