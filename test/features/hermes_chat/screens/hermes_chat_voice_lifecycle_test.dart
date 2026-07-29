import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  testWidgets('mobile composer uses Telegram-style contextual actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(FakeHermesChannel()),
        ],
        child: const MaterialApp(home: HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hermes-composer-strip')), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-composer-menu-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hermes-emoji-button')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Message Hermes')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hermes-attachment-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hermes-mic-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-send-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'Hello',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hermes-send-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-mic-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-attachment-button')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-emoji-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hermes-emoji-0')));
    await tester.pumpAndSettle();
    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(composer.controller!.text, '😀');

    await tester.tap(find.byKey(const ValueKey('hermes-composer-menu-button')));
    await tester.pumpAndSettle();
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Hands-free voice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paperclip picks and sends images and text files', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    var pickerCalls = 0;
    var pickTextFile = false;
    final png = Uint8List.fromList([
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      0x00,
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesAttachmentPickerProvider.overrideWithValue(() async {
            pickerCalls += 1;
            return pickTextFile
                ? XFile.fromData(
                    Uint8List.fromList(utf8.encode('alpha\nbeta')),
                    name: 'notes.md',
                    path: 'notes.md',
                    mimeType: 'text/markdown',
                  )
                : XFile.fromData(png, name: 'photo.png', path: 'photo.png');
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-attachment-button')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    expect(pickerCalls, 1);
    expect(find.text('photo.png'), findsOneWidget);
    expect(find.text('Ready to send'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Attached file photo.png, ready to send'),
      findsOneWidget,
    );
    expect(find.byTooltip('Remove attachment'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(
      channel.sentImageDataUrls.single,
      startsWith('data:image/png;base64,'),
    );
    expect(find.textContaining('[Image: photo.png]'), findsWidgets);

    pickTextFile = true;
    await tester.tap(find.byKey(const ValueKey('hermes-attachment-button')));
    await tester.pump();
    expect(pickerCalls, 2);
    expect(find.text('notes.md'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(channel.sentTextAttachments.last, 'alpha\nbeta');
    expect(find.textContaining('[File: notes.md]'), findsWidgets);
  });

  testWidgets('passive session changes do not show voice warnings', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await channel.createSession();
    await tester.pumpAndSettle();

    expect(find.textContaining('Continuous voice paused'), findsNothing);
  });

  testWidgets('voice icon sends the transcript immediately', (tester) async {
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
    expect(composer.controller?.text, 'existing draft');
    expect(channel.sentVoiceTranscripts, ['draft from voice']);
    expect(channel.state.activeMessages, isNotEmpty);
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
      expect(find.text('Listening'), findsOneWidget);

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
          wingVoiceSettingsProvider.overrideWith(
            () => _TestVoiceSettingsController(
              const WingVoiceSettings(continuousVoiceEnabled: false),
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
          wingVoiceSettingsProvider.overrideWith(
            () => _TestVoiceSettingsController(
              const WingVoiceSettings(speakRepliesEnabled: false),
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
      container.read(wingVoiceSettingsProvider).speakRepliesEnabled,
      isTrue,
    );
  });

  testWidgets('hands-free voice state is announced, not shown only', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
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

    expect(
      find.bySemanticsLabel(RegExp(r'Hands-free')),
      findsOneWidget,
      reason: 'idle voice state must be reachable without sight',
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    await tester.pump();

    final listening = find.bySemanticsLabel(RegExp(r'Listening'));
    expect(
      listening,
      findsOneWidget,
      reason: 'a live microphone must be named in the semantics tree',
    );
    expect(
      tester.getSemantics(listening).flagsCollection.isLiveRegion,
      isTrue,
      reason: 'voice state changes must be announced while hands-free',
    );

    semantics.dispose();
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

  @override
  Future<void> dispose() => stop();
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

class _TestVoiceSettingsController extends WingVoiceSettingsController {
  _TestVoiceSettingsController(this.initial);

  final WingVoiceSettings initial;

  @override
  WingVoiceSettings build() => initial;
}
