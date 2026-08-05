import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/voice/services/speech/speech_to_text_voice_capture_service.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'support/hermes_voice_smoke_harness.dart';

void main() {
  final channel = AndroidHermesVoiceSmokeChannel();
  final capture = SpeechToTextVoiceCaptureService(
    localeId: 'en_US',
    engine: PluginSpeechToTextEngine(
      androidIntentLookup: true,
      androidNoBluetooth: true,
    ),
  );
  runApp(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HermesChatScreen(voiceCaptureServiceOverride: capture),
      ),
    ),
  );
}
