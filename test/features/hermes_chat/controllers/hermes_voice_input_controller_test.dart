import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/hermes_chat/controllers/hermes_voice_input_controller.dart';
import 'package:navivox/features/voice_commands/models/voice_command.dart';
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

  test('continuous voice allows long dictation before timing out', () async {
    final channel = FakeHermesChannel();
    final capture = _RecordingVoiceCaptureService();
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => capture,
      textToSpeechService: () => null,
      settings: () => const NavivoxVoiceSettings(),
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

  test('routed transcript is consumed instead of drafted', () async {
    final channel = FakeHermesChannel();
    final routed = <VoiceRouteResult>[];
    final routedAutoSendFlags = <bool>[];
    final drafts = <String>[];
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => FakeVoiceCaptureService(
        audio: Uint8List(0),
        transcript: 'open the settings screen',
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      ),
      textToSpeechService: () => null,
      settings: () => const NavivoxVoiceSettings(),
      onDraft: drafts.add,
      routeTranscript: (t) async => VoiceRouteResult(
        command: VoiceCommandId.navigateToScreen,
        args: const {'screen': 'settings'},
        tier: VoiceCommandTier.instant,
        transcript: t,
      ),
      onRoutedCommand: (result, {required autoSend}) {
        routed.add(result);
        routedAutoSendFlags.add(autoSend);
      },
    );
    addTearDown(controller.dispose);

    await controller.captureDraft();

    expect(routed, hasLength(1));
    expect(routedAutoSendFlags, [false]);
    expect(drafts, isEmpty);
    expect(channel.state.voiceRuns, isEmpty);
  });

  test('continuous routed transcript reports autoSend true', () async {
    final channel = FakeHermesChannel();
    final routedAutoSendFlags = <bool>[];
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () => FakeVoiceCaptureService(
        audio: Uint8List(0),
        transcript: 'open the settings screen',
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      ),
      textToSpeechService: () => null,
      settings: () => const NavivoxVoiceSettings(),
      onDraft: (_) {},
      routeTranscript: (t) async => VoiceRouteResult(
        command: VoiceCommandId.navigateToScreen,
        args: const {'screen': 'settings'},
        tier: VoiceCommandTier.instant,
        transcript: t,
      ),
      onRoutedCommand: (result, {required autoSend}) =>
          routedAutoSendFlags.add(autoSend),
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();

    expect(routedAutoSendFlags, [true]);
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  test('throwing router falls through to the draft path', () async {
    final channel = FakeHermesChannel();
    final routed = <VoiceRouteResult>[];
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
      routeTranscript: (_) async => throw StateError('router exploded'),
      onRoutedCommand: (result, {required autoSend}) => routed.add(result),
    );
    addTearDown(controller.dispose);

    await controller.captureDraft();

    expect(drafts, ['draft from voice']);
    expect(routed, isEmpty);
    expect(controller.capturing, isFalse);
    expect(controller.error, isNull);
  });

  test('capture stays exclusive while routing is pending', () async {
    final channel = FakeHermesChannel();
    final gate = Completer<VoiceRouteResult?>();
    final routed = <VoiceRouteResult>[];
    final drafts = <String>[];
    var captureServiceRequests = 0;
    final controller = HermesVoiceInputController(
      channel: () => channel,
      captureService: () {
        captureServiceRequests += 1;
        return FakeVoiceCaptureService(
          audio: Uint8List(0),
          transcript: 'first transcript',
          duration: const Duration(seconds: 1),
          confidence: 0.9,
        );
      },
      textToSpeechService: () => null,
      settings: () => const NavivoxVoiceSettings(),
      onDraft: drafts.add,
      routeTranscript: (_) => gate.future,
      onRoutedCommand: (result, {required autoSend}) => routed.add(result),
    );
    addTearDown(controller.dispose);

    final first = controller.captureDraft();
    await pumpEventQueue();

    // The routing await is still pending: the capture window must stay
    // closed so a second mic tap cannot interleave and drop the transcript.
    expect(controller.capturing, isTrue);
    final second = controller.captureDraft();
    await pumpEventQueue();
    expect(controller.capturing, isTrue);
    expect(captureServiceRequests, 1);

    gate.complete(null);
    await first;
    await second;

    expect(drafts, ['first transcript']);
    expect(routed, isEmpty);
    expect(controller.capturing, isFalse);
  });

  test(
    'session change during routing discards a continuous transcript',
    () async {
      final channel = FakeHermesChannel();
      final gate = Completer<VoiceRouteResult?>();
      final routed = <VoiceRouteResult>[];
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
        routeTranscript: (_) => gate.future,
        onRoutedCommand: (result, {required autoSend}) => routed.add(result),
      );
      addTearDown(controller.dispose);

      final pending = controller.enableContinuous();
      await pumpEventQueue();
      await channel.selectSession('sess_2');
      gate.complete(
        const VoiceRouteResult(
          command: VoiceCommandId.showStatus,
          args: {},
          tier: VoiceCommandTier.instant,
          transcript: 'send this continuously',
        ),
      );
      await pending;

      expect(routed, isEmpty);
      expect(channel.sentVoiceTranscripts, isEmpty);
      expect(controller.continuousEnabled, isFalse);
      expect(
        controller.error,
        'Voice capture was discarded because the Hermes session changed. '
        'Continuous voice paused.',
      );
    },
  );

  test('null route falls through to the draft path unchanged', () async {
    final channel = FakeHermesChannel();
    final routed = <VoiceRouteResult>[];
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
      routeTranscript: (_) async => null,
      onRoutedCommand: (result, {required autoSend}) => routed.add(result),
    );
    addTearDown(controller.dispose);

    await controller.captureDraft();

    expect(drafts, ['draft from voice']);
    expect(routed, isEmpty);
    expect(channel.state.voiceRuns, isEmpty);
  });

  test('commandWord stop beats the router in continuous mode', () async {
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
      settings: () => const NavivoxVoiceSettings(),
      onDraft: (_) {},
      routeTranscript: (_) async => fail('router must not run'),
      onRoutedCommand: (result, {required autoSend}) =>
          fail('router must not run'),
    );
    addTearDown(controller.dispose);

    await controller.enableContinuous();

    expect(controller.continuousEnabled, isFalse);
  });
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
