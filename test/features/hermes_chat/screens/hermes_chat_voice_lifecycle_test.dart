import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:navivox/features/settings/providers/voice_settings_provider.dart';
import 'package:navivox/shared/voice/text_to_speech_service.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  testWidgets('voice input fills the composer without sending to Hermes', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final capture = FakeVoiceCaptureService(
      audio: Uint8List(0),
      transcript: 'draft from voice',
      duration: const Duration(seconds: 1),
      confidence: 0.9,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          home: HermesChatScreen(voiceCaptureServiceOverride: capture),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'existing draft',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(composer.controller?.text, 'existing draft draft from voice');
    expect(channel.state.activeMessages, isEmpty);
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets(
    'turning continuous voice off cancels capture and drops its late result',
    (tester) async {
      final channel = FakeHermesChannel();
      final capture = _ControlledVoiceCaptureService();
      final tts = _RecordingTextToSpeechService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: MaterialApp(
            home: HermesChatScreen(
              voiceCaptureServiceOverride: capture,
              textToSpeechServiceOverride: tts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final voiceSwitch = find.byKey(
        const ValueKey('hermes-continuous-voice-switch'),
      );
      await tester.tap(voiceSwitch);
      await tester.pump();
      expect(capture.captureCalls, 1);

      await tester.tap(voiceSwitch);
      await tester.pump();
      expect(capture.cancelCalls, 1);

      capture.complete('must not be sent');
      await tester.pumpAndSettle();

      expect(channel.sentVoiceTranscripts, isEmpty);
      expect(tts.spoken, isEmpty);
    },
  );

  testWidgets('backgrounding cancels capture and pauses continuous voice', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final capture = _ControlledVoiceCaptureService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          home: HermesChatScreen(voiceCaptureServiceOverride: capture),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(capture.cancelCalls, 1);
    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('hermes-continuous-voice-switch')),
          )
          .value,
      isFalse,
    );

    capture.complete('also discarded');
    await tester.pumpAndSettle();
    expect(channel.sentVoiceTranscripts, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('command word stop pauses the loop without sending to Hermes', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final capture = _CommandThenBlockCaptureService('navi stop listening');
    final tts = _RecordingTextToSpeechService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          home: HermesChatScreen(
            voiceCaptureServiceOverride: capture,
            textToSpeechServiceOverride: tts,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    await tester.pump();
    await tester.pump();

    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('hermes-continuous-voice-switch')),
          )
          .value,
      isFalse,
    );
  });

  testWidgets('voice master setting disables the Hermes voice controls', (
    tester,
  ) async {
    final channel = FakeHermesChannel();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          navivoxVoiceSettingsProvider.overrideWith(
            () => _TestVoiceSettingsController(
              const NavivoxVoiceSettings(continuousVoiceEnabled: false),
            ),
          ),
        ],
        child: const MaterialApp(home: HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('hermes-continuous-voice-switch')),
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('hermes-mic-button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('Hermes voice switch persists the hands-free reply preference', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final capture = _ControlledVoiceCaptureService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          navivoxVoiceSettingsProvider.overrideWith(
            () => _TestVoiceSettingsController(
              const NavivoxVoiceSettings(speakRepliesEnabled: false),
            ),
          ),
        ],
        child: MaterialApp(
          home: HermesChatScreen(voiceCaptureServiceOverride: capture),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HermesChatScreen)),
    );
    expect(
      container.read(navivoxVoiceSettingsProvider).speakRepliesEnabled,
      isTrue,
    );
  });
}

class _ControlledVoiceCaptureService implements VoiceCaptureService {
  final _completion = Completer<VoiceCapture>();
  int captureCalls = 0;
  int cancelCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    return _completion.future;
  }

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
        confidence: 0.9,
      ),
    );
  }
}

class _RecordingTextToSpeechService implements TextToSpeechService {
  final spoken = <String>[];
  int stopCalls = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }
}

class _CommandThenBlockCaptureService implements VoiceCaptureService {
  _CommandThenBlockCaptureService(this.command);

  final String command;
  final _blocked = Completer<VoiceCapture>();
  int captureCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    if (captureCalls > 1) return _blocked.future;
    return Future.value(
      VoiceCapture(
        audio: Uint8List(0),
        transcript: command,
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      ),
    );
  }

  @override
  Future<void> cancel() async {}
}

class _TestVoiceSettingsController extends NavivoxVoiceSettingsController {
  _TestVoiceSettingsController(this.initial);

  final NavivoxVoiceSettings initial;

  @override
  NavivoxVoiceSettings build() => initial;
}
