// E2E test entry point for Playwright testing.

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

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

@JS('wingE2EReduceMotion')
external set _wingE2EReduceMotion(JSFunction callback);

void main() {
  final hermesChannel = HermesApiChannel();
  final reduceMotion = ValueNotifier(false);
  _wingE2EHermesConnect = (([JSString? baseUrl, JSString? apiKey]) {
    unawaited(
      hermesChannel.connect(
        baseUrl: baseUrl?.toDart ?? web.window.location.origin,
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
  _wingE2EReduceMotion = (() {
    reduceMotion.value = true;
  }).toJS;

  runApp(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(hermesChannel)],
      child: _E2ETestApp(reduceMotion: reduceMotion),
    ),
  );
}

class _E2ETestApp extends ConsumerWidget {
  const _E2ETestApp({required this.reduceMotion});

  final ValueListenable<bool> reduceMotion;

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
      builder: (context, child) => ValueListenableBuilder(
        valueListenable: reduceMotion,
        builder: (context, disabled, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: disabled),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
