// E2E test entry point for Playwright testing.

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/hermes/channel/hermes_api_channel.dart';
import 'features/hermes_chat/providers/hermes_channel_provider.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/wing_theme.dart';

@JS('wingE2EHermesConnect')
external set _wingE2EHermesConnect(JSFunction callback);

@JS('wingE2EHermesCreateSession')
external set _wingE2EHermesCreateSession(JSFunction callback);

@JS('wingE2EHermesSendText')
external set _wingE2EHermesSendText(JSFunction callback);

@JS('wingE2EHermesSubmitVoice')
external set _wingE2EHermesSubmitVoice(JSFunction callback);

void main() {
  final hermesChannel = HermesApiChannel();
  _wingE2EHermesConnect = (([JSString? baseUrl, JSString? apiKey]) {
    unawaited(
      hermesChannel.connect(
        baseUrl: baseUrl?.toDart ?? 'http://127.0.0.1:8767',
        apiKey: apiKey?.toDart,
      ),
    );
  }).toJS;
  _wingE2EHermesCreateSession = (([JSString? title]) {
    unawaited(hermesChannel.createSession(title: title?.toDart));
  }).toJS;
  _wingE2EHermesSendText = ((JSString text) {
    unawaited(hermesChannel.sendText(text.toDart));
  }).toJS;
  _wingE2EHermesSubmitVoice = ((JSString text) {
    final id = hermesChannel.startVoiceRun();
    hermesChannel.stageVoiceRunTranscript(
      voiceRunId: id,
      transcript: text.toDart,
      duration: const Duration(seconds: 2),
      confidence: 0.95,
    );
    hermesChannel.submitVoiceRun(id);
  }).toJS;

  runApp(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(hermesChannel)],
      child: const _E2ETestApp(),
    ),
  );
}

class _E2ETestApp extends ConsumerWidget {
  const _E2ETestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Hermes Wing',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: wingLightTheme,
      darkTheme: wingDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
