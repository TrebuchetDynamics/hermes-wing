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

    final channel = AndroidHermesVoiceSmokeChannel();
    final tts = FakeTextToSpeechService();
    final capture = QueueVoiceCaptureService([
      voiceSmokeCapture('android first voice'),
      voiceSmokeCapture('android second voice'),
    ]);

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

    final desktopSwitch = find.byKey(
      const ValueKey('hermes-continuous-voice-switch'),
    );
    if (desktopSwitch.evaluate().isNotEmpty) {
      await tester.tap(desktopSwitch);
    } else {
      await tester.tap(
        find.byKey(const ValueKey('hermes-composer-menu-button')),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.text('Hands-free voice')));
    }
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(channel.sentVoiceTranscripts, [
      'android first voice',
      'android second voice',
    ]);
    expect(tts.spoken, [
      'echo: android first voice',
      'echo: android second voice',
    ]);
    expect(find.text('android first voice'), findsOneWidget);
    expect(find.text('echo: android second voice'), findsOneWidget);
  });
}
