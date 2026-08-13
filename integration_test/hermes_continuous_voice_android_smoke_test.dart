import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';

import 'support/hermes_voice_smoke_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android Hermes continuous voice loops transcript turns', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;

    final channel = AndroidHermesVoiceSmokeChannel(streamFirstReply: true);
    final tts = FakeTextToSpeechService();
    final capture = QueueVoiceCaptureService([
      voiceSmokeCapture('android first voice'),
    ], waitWhenEmpty: true);

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

    final activeVoiceSurface = find.byKey(
      const ValueKey('hermes-voice-mode-surface'),
    );
    final desktopSwitch = find.byKey(
      const ValueKey('hermes-continuous-voice-switch'),
    );
    if (activeVoiceSurface.evaluate().isNotEmpty) {
      // Physical devices preserve voice preferences across in-place installs.
    } else if (desktopSwitch.evaluate().isNotEmpty) {
      await tester.tap(desktopSwitch);
    } else {
      await tester.tap(
        find.byKey(const ValueKey('hermes-composer-menu-button')),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.text('Hands-free voice')));
    }
    await tester.pump(const Duration(seconds: 1));

    expect(channel.sentVoiceTranscripts, ['android first voice']);
    expect(tts.spoken, ['echo: android first voice.']);

    channel.completeStreamingReply(
      'echo: android first voice. final streamed tail',
    );
    await tester.pump(const Duration(seconds: 1));

    capture.enqueue(voiceSmokeCapture('android second voice'));
    await tester.pump(const Duration(seconds: 1));

    expect(channel.sentVoiceTranscripts, [
      'android first voice',
      'android second voice',
    ]);

    expect(tts.spoken, [
      'echo: android first voice.',
      'final streamed tail',
      'echo: android second voice',
    ]);
    expect(find.text('android first voice'), findsOneWidget);
    expect(find.text('echo: android second voice'), findsOneWidget);
  });
}
