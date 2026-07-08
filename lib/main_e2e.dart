// E2E test entry point for Playwright testing.

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/hermes/channel/hermes_api_channel.dart';
import 'features/hermes_chat/providers/hermes_channel_provider.dart';
import 'router/app_router.dart';
import 'theme/navivox_theme.dart';

@JS('navivoxE2EHermesConnect')
external set _navivoxE2EHermesConnect(JSFunction callback);

@JS('navivoxE2EHermesCreateSession')
external set _navivoxE2EHermesCreateSession(JSFunction callback);

@JS('navivoxE2EHermesSendText')
external set _navivoxE2EHermesSendText(JSFunction callback);

@JS('navivoxE2EHermesSubmitVoice')
external set _navivoxE2EHermesSubmitVoice(JSFunction callback);

void main() {
  final hermesChannel = HermesApiChannel();
  _navivoxE2EHermesConnect = (([JSString? baseUrl, JSString? apiKey]) {
    unawaited(
      hermesChannel.connect(
        baseUrl: baseUrl?.toDart ?? 'http://127.0.0.1:8767',
        apiKey: apiKey?.toDart,
      ),
    );
  }).toJS;
  _navivoxE2EHermesCreateSession = (([JSString? title]) {
    unawaited(hermesChannel.createSession(title: title?.toDart));
  }).toJS;
  _navivoxE2EHermesSendText = ((JSString text) {
    unawaited(hermesChannel.sendText(text.toDart));
  }).toJS;
  _navivoxE2EHermesSubmitVoice = ((JSString text) {
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
      title: 'Navivox',
      theme: navivoxLightTheme,
      darkTheme: navivoxDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
