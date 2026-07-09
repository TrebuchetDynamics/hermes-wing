import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/hermes_chat/controllers/hermes_voice_input_controller.dart';
import 'package:navivox/shared/voice/text_to_speech_service.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';
import 'package:navivox/shared/voice/voice_settings.dart';

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
        settings: () => const NavivoxVoiceSettings(),
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
    'pausing voice input cancels capture and drops its late result',
    () async {
      final channel = FakeHermesChannel();
      final capture = _ControlledVoiceCaptureService();
      final drafts = <String>[];
      final controller = HermesVoiceInputController(
        channel: () => channel,
        captureService: () => capture,
        textToSpeechService: () => null,
        settings: () => const NavivoxVoiceSettings(),
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
      settings: () => const NavivoxVoiceSettings(),
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
      settings: () => const NavivoxVoiceSettings(
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

  test('continuous voice pauses when capture fails', () async {
    final channel = FakeHermesChannel();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => const _FailingVoiceCaptureService(),
      textToSpeechService: () => null,
      settings: () => const NavivoxVoiceSettings(),
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

class _FailingVoiceCaptureService implements VoiceCaptureService {
  const _FailingVoiceCaptureService();

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    throw const VoiceCaptureTimeout();
  }

  @override
  Future<void> cancel() async {}
}
