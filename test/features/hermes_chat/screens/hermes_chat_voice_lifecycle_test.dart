import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
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
    expect(
      find.byKey(const ValueKey('hermes-message-attachment-photo.png')),
      findsOneWidget,
    );

    pickTextFile = true;
    await tester.tap(find.byKey(const ValueKey('hermes-attachment-button')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    expect(pickerCalls, 2);
    expect(find.text('notes.md'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();

    expect(channel.sentTextAttachments.last, 'alpha\nbeta');
    expect(
      find.byKey(const ValueKey('hermes-message-attachment-notes.md')),
      findsOneWidget,
    );
  });

  testWidgets('attachment follow-up waits in the busy queue and sends next', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
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
          hermesAttachmentPickerProvider.overrideWithValue(
            () async => XFile.fromData(
              png,
              name: 'queued-photo.png',
              path: 'queued-photo.png',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    channel.beginStreamingTurn('first message');
    await tester.pump();
    expect(
      channel.state.isSessionStreaming(channel.state.activeSessionId!),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-attachment-button')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    expect(find.text('queued-photo.png'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'follow up with this',
    );
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pump();

    expect(channel.sentImageDataUrls, isEmpty);
    expect(find.text('queued-photo.png'), findsNothing);
    expect(
      find.byKey(const ValueKey('hermes-queued-follow-up')),
      findsOneWidget,
    );
    final strings = AppLocalizations.of(
      tester.element(find.byType(HermesChatScreen)),
    );
    expect(
      find.text(
        strings.chatQueuedSummary(
          1,
          'follow up with this · ${strings.chatQueuedAttachmentPreview('queued-photo.png')}',
        ),
      ),
      findsOneWidget,
    );

    channel.completeStreamingTurn();
    await tester.pumpAndSettle();

    expect(
      channel.sentImageDataUrls.single,
      startsWith('data:image/png;base64,'),
    );
    expect(
      channel.state.activeMessages
          .lastWhere((turn) => turn.attachment != null)
          .attachment
          ?.name,
      'queued-photo.png',
    );
  });

  testWidgets('paperclip preserves the currently staged attachment', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    var pickerCalls = 0;
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
            return XFile.fromData(png, name: 'photo.png', path: 'photo.png');
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

    final attach = find.byKey(const ValueKey('hermes-attachment-button'));
    await tester.tap(attach);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    await tester.tap(attach);
    await tester.pump();

    expect(pickerCalls, 1);
    expect(find.text('photo.png'), findsOneWidget);
    final strings = AppLocalizations.of(
      tester.element(find.byType(HermesChatScreen)),
    );
    expect(find.text(strings.chatAttachmentRemoveCurrentError), findsOneWidget);
    final attachmentError = find.byKey(
      const ValueKey('hermes-attachment-error'),
    );
    expect(attachmentError, findsOneWidget);
    expect(
      tester.getSemantics(attachmentError).flagsCollection.isLiveRegion,
      isTrue,
    );
    await tester.pump(const Duration(seconds: 5));
    expect(attachmentError, findsOneWidget);

    await tester.tap(find.byTooltip('Remove attachment'));
    await tester.pump();
    expect(attachmentError, findsNothing);
  });

  testWidgets('picker errors hide sensitive details and recover inline', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    var failPicker = true;
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
            if (failPicker) {
              throw StateError(
                'open failed for /home/alice/private.txt '
                'Authorization: Bearer secret-sentinel',
              );
            }
            return XFile.fromData(
              png,
              name: 'recovered.png',
              path: 'recovered.png',
            );
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

    final attach = find.byKey(const ValueKey('hermes-attachment-button'));
    await tester.tap(attach);
    await tester.pump();

    final error = find.byKey(const ValueKey('hermes-attachment-error'));
    final errorText = tester.widget<Text>(
      find.descendant(of: error, matching: find.byType(Text)),
    );
    expect(errorText.data, contains('Could not open attachment'));
    expect(errorText.data, contains('[redacted-path]'));
    expect(errorText.data, contains('Authorization: [redacted]'));
    expect(errorText.data, isNot(contains('/home/alice')));
    expect(errorText.data, isNot(contains('secret-sentinel')));
    expect(errorText.data, isNot(contains('Bad state:')));

    failPicker = false;
    await tester.tap(attach);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();

    expect(find.text('recovered.png'), findsOneWidget);
    expect(error, findsNothing);
  });

  testWidgets('session and disconnect changes clear staged attachments', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    final insertion = composer.contentInsertionConfiguration!;
    void stageImage() => insertion.onContentInserted(
      KeyboardInsertedContent(
        mimeType: 'image/png',
        uri: 'content://keyboard/session-owned-image',
        data: Uint8List.fromList([
          0x89,
          0x50,
          0x4e,
          0x47,
          0x0d,
          0x0a,
          0x1a,
          0x0a,
          0x00,
        ]),
      ),
    );
    stageImage();
    await tester.pump();
    expect(find.text('pasted-image.png'), findsOneWidget);

    await channel.sendText('Same-session update');
    await tester.pumpAndSettle();
    expect(find.text('pasted-image.png'), findsOneWidget);

    await channel.createSession(title: 'Second session');
    await tester.pumpAndSettle();

    expect(find.text('pasted-image.png'), findsNothing);
    expect(find.text('Ready to send'), findsNothing);

    stageImage();
    await tester.pump();
    expect(find.text('pasted-image.png'), findsOneWidget);

    await channel.disconnect();
    await tester.pumpAndSettle();

    expect(find.text('pasted-image.png'), findsNothing);
    expect(find.text('Ready to send'), findsNothing);

    await channel.connect(baseUrl: 'http://fake-hermes:8642');
    await tester.pumpAndSettle();

    expect(find.text('pasted-image.png'), findsNothing);
    expect(find.text('Ready to send'), findsNothing);
  });

  testWidgets('keyboard image insertion stages and sends a sniffed image', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
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
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    final insertion = composer.contentInsertionConfiguration;
    expect(insertion, isNotNull);

    insertion!.onContentInserted(
      KeyboardInsertedContent(
        mimeType: 'image/png',
        uri: 'content://keyboard/pasted-image',
        data: png,
      ),
    );
    await tester.pump();

    expect(find.text('pasted-image.png'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Attached file pasted-image.png, ready to send'),
      findsOneWidget,
    );

    insertion.onContentInserted(
      KeyboardInsertedContent(
        mimeType: 'image/gif',
        uri: 'content://keyboard/replacement-image',
        data: Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]),
      ),
    );
    await tester.pump();

    expect(find.text('pasted-image.png'), findsOneWidget);
    expect(find.text('pasted-image.gif'), findsNothing);
    expect(
      find.text('Remove the current attachment before adding another.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await tester.pumpAndSettle();
    expect(
      channel.sentImageDataUrls.single,
      startsWith('data:image/png;base64,'),
    );
  });

  testWidgets('passive session changes do not show voice warnings', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await channel.createSession();
    await tester.pumpAndSettle();

    expect(find.textContaining('Continuous voice paused'), findsNothing);
  });

  testWidgets('voice icon enables persistent listening for interruption', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final capture = _CommandThenBlockCaptureService('draft from voice');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(
            voiceCaptureServiceOverride: capture,
            textToSpeechServiceOverride: _RecordingTextToSpeechService(),
          ),
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

    expect(channel.sentVoiceTranscripts, ['draft from voice']);
    expect(channel.state.activeMessages, isNotEmpty);
    expect(
      find.byKey(const ValueKey('hermes-voice-mode-surface')),
      findsOneWidget,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HermesChatScreen)),
    );
    expect(
      container.read(wingVoiceSettingsProvider).speakRepliesEnabled,
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-voice-mode-end-button')),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('hands-free voice shows a live waveform while capturing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final channel = FakeHermesChannel();
    final capture = _ControlledVoiceCaptureService();

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

    await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pumpAndSettle();

    expect(capture.captureCalls, 1);
    capture.emitLevel(0);
    await tester.pump(const Duration(milliseconds: 100));

    final waveform = find.descendant(
      of: find.byKey(const ValueKey('hermes-voice-mode-surface')),
      matching: find.byKey(const ValueKey('hermes-voice-waveform')),
    );
    final bars = find.descendant(
      of: waveform,
      matching: find.byType(AnimatedContainer),
    );
    expect(waveform, findsOneWidget);
    expect(bars, findsNWidgets(5));
    final quietHeight = tester
        .widget<AnimatedContainer>(bars.first)
        .constraints!
        .minHeight;

    capture.emitLevel(10);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<AnimatedContainer>(bars.first).constraints!.minHeight,
      greaterThan(quietHeight),
    );

    await tester.tap(
      find.byKey(const ValueKey('hermes-voice-mode-end-button')),
    );
    await tester.pump();
    expect(waveform, findsNothing);
  });

  testWidgets(
    'ending mobile voice mode cancels capture and drops its late result',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final channel = FakeHermesChannel();
      final capture = _ControlledVoiceCaptureService();
      final tts = _RecordingTextToSpeechService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HermesChatScreen(
              voiceCaptureServiceOverride: capture,
              textToSpeechServiceOverride: tts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('hermes-composer-menu-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text('Hands-free voice'),
          matching: find.byWidgetPredicate(
            (widget) => widget is CheckedPopupMenuItem,
          ),
        ),
      );
      await tester.pump();
      expect(capture.captureCalls, 1);
      expect(find.text('Listening'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hermes-voice-mode-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-voice-mode-end-button')),
        findsOneWidget,
      );
      final waveformBars = find.descendant(
        of: find.byKey(const ValueKey('hermes-voice-waveform')),
        matching: find.byType(AnimatedContainer),
      );
      expect(waveformBars, findsNothing);
      capture.emitLevel(double.nan);
      await tester.pump(const Duration(milliseconds: 100));
      expect(waveformBars, findsNothing);
      capture.emitLevel(-21);
      await tester.pump(const Duration(milliseconds: 100));
      expect(waveformBars, findsNWidgets(5));
      final quietHeight = tester
          .widget<AnimatedContainer>(waveformBars.first)
          .constraints!
          .minHeight;
      final minusTwentyOneHeight = tester
          .widget<AnimatedContainer>(waveformBars.first)
          .constraints!
          .minHeight;
      capture.emitLevel(-20);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<AnimatedContainer>(waveformBars.first)
            .constraints!
            .minHeight,
        greaterThanOrEqualTo(minusTwentyOneHeight),
      );
      capture.emitLevel(10);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<AnimatedContainer>(waveformBars.first)
            .constraints!
            .minHeight,
        greaterThan(quietHeight),
      );
      capture.emit('testing one two');
      await tester.pump();
      expect(find.text('testing one two'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('hermes-voice-mode-end-button')),
      );
      await tester.pump();
      expect(capture.cancelCalls, 1);
      expect(
        find.byKey(const ValueKey('hermes-voice-mode-surface')),
        findsNothing,
      );

      capture.complete('must not be sent');
      await tester.pumpAndSettle();

      expect(channel.sentVoiceTranscripts, isEmpty);
      expect(tts.spoken, isEmpty);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('desktop hands-free mode shows live voice controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final channel = FakeHermesChannel();
    final capture = _ControlledVoiceCaptureService();

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

    await tester.tap(
      find.byKey(const ValueKey('hermes-continuous-voice-switch')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('hermes-voice-mode-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-voice-mode-end-button')),
      findsOneWidget,
    );
  });

  testWidgets('backgrounding cancels capture and pauses continuous voice', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final capture = _ControlledVoiceCaptureService();

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('long-pressing the mic dictates into the composer for review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final channel = FakeHermesChannel();
    final capture = _ControlledVoiceCaptureService();

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

    await tester.longPress(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pump();
    expect(capture.captureCalls, 1);

    capture.complete('dictated for review');
    await tester.pumpAndSettle();

    // The transcript lands in the composer for review; nothing was sent.
    expect(find.text('dictated for review'), findsOneWidget);
    expect(channel.state.voiceRuns, isEmpty);
    expect(find.byKey(const ValueKey('hermes-send-button')), findsOneWidget);
  });

  testWidgets('desktop dictation restores composer focus for review', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    final capture = _ControlledVoiceCaptureService();

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

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      'existing draft',
    );
    await tester.longPress(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pump();
    composer.focusNode!.unfocus();
    await tester.pump();
    expect(composer.focusNode!.hasFocus, isFalse);

    capture.complete('dictated addition');
    await tester.pumpAndSettle();

    expect(composer.controller!.text, 'existing draft dictated addition');
    expect(composer.focusNode!.hasFocus, isTrue);
    expect(channel.state.voiceRuns, isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the mic button carries its name into the semantics tree', (
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
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A screen reader must announce more than "button": the visual tooltip
    // moved onto a wrapper so long-press could dictate, which silently
    // stripped the name off the button's own node.
    final mic = tester.getSemantics(
      find.byKey(const ValueKey('hermes-mic-button')),
    );
    expect('${mic.label} ${mic.tooltip}', contains('Hands-free voice'));
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(voiceCaptureServiceOverride: capture),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp(r'Hands-free')),
      findsWidgets,
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

  testWidgets(
    'unavailable voice output offers an honest text fallback without hiding input',
    (tester) async {
      final channel = FakeHermesChannel();
      final capture = _CommandThenBlockCaptureService('play this reply');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HermesChatScreen(voiceCaptureServiceOverride: capture),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-voice-playback-unavailable')),
        findsOneWidget,
      );
      expect(find.text('Voice output unavailable'), findsOneWidget);
      expect(find.textContaining('reply is available as text'), findsOneWidget);
      expect(
        find.textContaining('Voice input remains available'),
        findsOneWidget,
      );
      expect(find.text('Continue in text'), findsOneWidget);
      expect(find.byKey(const ValueKey('hermes-mic-button')), findsOneWidget);

      await tester.tap(find.text('Continue in text'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-voice-playback-unavailable')),
        findsNothing,
      );
      expect(find.text('echo: play this reply'), findsOneWidget);
    },
  );

  testWidgets('voice failures are announced as live status', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(FakeHermesChannel()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(
            voiceCaptureServiceOverride: _FailingVoiceCaptureService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pumpAndSettle();

    final error = tester.getSemantics(
      find.byKey(const ValueKey('hermes-voice-error')),
    );
    expect(error.label, contains('recognizer failure'));
    expect(error.flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
  });
}

class _FailingVoiceCaptureService implements VoiceCaptureService {
  const _FailingVoiceCaptureService();

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async =>
      throw StateError('recognizer failure');

  @override
  Future<void> cancel() async {}
}

class _ControlledVoiceCaptureService
    implements
        VoiceCaptureService,
        VoiceCaptureProgressService,
        VoiceCaptureSoundLevelService {
  final _completion = Completer<VoiceCapture>();
  final _partialTranscripts = StreamController<String>.broadcast();
  final _soundLevels = StreamController<double>.broadcast();
  int captureCalls = 0;
  int cancelCalls = 0;

  @override
  Stream<String> get partialTranscripts => _partialTranscripts.stream;

  @override
  Stream<double> get soundLevels => _soundLevels.stream;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) {
    captureCalls += 1;
    return _completion.future;
  }

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
  }

  void emit(String transcript) => _partialTranscripts.add(transcript);

  void emitLevel(double level) => _soundLevels.add(level);

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
