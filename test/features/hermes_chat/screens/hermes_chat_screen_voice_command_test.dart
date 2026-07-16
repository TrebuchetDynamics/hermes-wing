import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/features/voice_commands/core/needle_engine.dart';
import 'package:wing/features/voice_commands/providers/voice_command_providers.dart';
import 'package:wing/features/voice_commands/services/voice_command_router.dart';
import 'package:wing/features/voice_commands/services/voice_command_validator.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_hermes_channel.dart';

/// Scripted [NeedleEngineApi] double mirroring the one in
/// voice_command_router_test.dart — cycles through canned responses so a
/// widget test can drive a real [VoiceCommandRouter] without touching FFI.
class _ScriptedEngine implements NeedleEngineApi {
  _ScriptedEngine(this.responses);

  final List<Future<String> Function()> responses;
  int calls = 0;
  bool loaded = false;

  @override
  bool get isLoaded => loaded;

  @override
  Future<void> load(String modelDir) async => loaded = true;

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) {
    return responses[calls++ % responses.length]();
  }

  @override
  Future<void> unload() async => loaded = false;
}

const _newSessionCall =
    '{"success": true, "response": "", "function_calls": '
    '[{"name": "new_session", "arguments": {}}]}';

const _showStatusCall =
    '{"success": true, "response": "", "function_calls": '
    '[{"name": "show_status", "arguments": {}}]}';

const _stopVoiceRunCall =
    '{"success": true, "response": "", "function_calls": '
    '[{"name": "stop_voice_run", "arguments": {}}]}';

const _toggleOffCall =
    '{"success": true, "response": "", "function_calls": '
    '[{"name": "toggle_continuous_mode", "arguments": {"enabled": false}}]}';

const _toggleOnCall =
    '{"success": true, "response": "", "function_calls": '
    '[{"name": "toggle_continuous_mode", "arguments": {"enabled": true}}]}';

VoiceCommandRouter _router(NeedleEngineApi engine) => VoiceCommandRouter(
  engine: engine,
  modelDirProvider: () async => '/model',
  contextProvider: () =>
      const VoiceCommandContext(sessionTitles: [], voiceNames: []),
);

VoiceCaptureService _captureFor(String transcript) => FakeVoiceCaptureService(
  audio: Uint8List(0),
  transcript: transcript,
  duration: const Duration(seconds: 1),
  confidence: 0.9,
);

Widget _localizedApp({required Widget home}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets('a confirm-tier routed command shows the chip', (tester) async {
    final channel = FakeHermesChannel();
    final router = _router(_ScriptedEngine([() async => _newSessionCall]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          voiceCommandRouterProvider.overrideWithValue(router),
        ],
        child: _localizedApp(
          home: HermesChatScreen(
            voiceCaptureServiceOverride: _captureFor(
              'start a new conversation',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pumpAndSettle();

    expect(find.text('Start a new session?'), findsOneWidget);
    // The chip only proposes the command; it must not have dispatched yet.
    expect(channel.createSessionCalls, isEmpty);
  });

  testWidgets("'Not now' puts the transcript into the composer", (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final router = _router(_ScriptedEngine([() async => _newSessionCall]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          voiceCommandRouterProvider.overrideWithValue(router),
        ],
        child: _localizedApp(
          home: HermesChatScreen(
            voiceCaptureServiceOverride: _captureFor(
              'start a new conversation',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
    await tester.pumpAndSettle();
    expect(find.text('Start a new session?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('voice-command-chip-decline')));
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(composer.controller?.text, 'start a new conversation');
    expect(find.text('Start a new session?'), findsNothing);
    expect(channel.createSessionCalls, isEmpty);
  });

  testWidgets('suspension hint is shown once after repeated router failures', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final router = _router(
      _ScriptedEngine([() async => throw const NeedleEngineException('boom')]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          voiceCommandRouterProvider.overrideWithValue(router),
        ],
        child: _localizedApp(
          home: HermesChatScreen(
            voiceCaptureServiceOverride: _captureFor('anything'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
      await tester.pumpAndSettle();
    }

    expect(router.suspended, isTrue);
    expect(
      find.text(
        'On-device commands paused after repeated errors. They resume on '
        'app restart.',
      ),
      findsOneWidget,
    );
  });

  group('re-arm rule', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Finder continuousSwitch() =>
        find.byKey(const ValueKey('hermes-continuous-voice-switch'));

    // A re-armed loop keeps the mic-button spinner animating forever, so
    // pumpAndSettle would time out; drain the routing/dispatch microtask
    // chain with bounded pumps instead.
    Future<void> pumpTurns(WidgetTester tester, [int times = 4]) async {
      for (var i = 0; i < times; i++) {
        await tester.pump();
      }
    }

    // SnackBars own real dismissal timers; expire them (two can queue:
    // notice + describe) so teardown sees no pending timers.
    Future<void> expireSnackBars(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 6));
    }

    Future<void> pumpScreen(
      WidgetTester tester, {
      required FakeHermesChannel channel,
      required VoiceCommandRouter router,
      required VoiceCaptureService capture,
      TextToSpeechService? tts,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            voiceCommandRouterProvider.overrideWithValue(router),
          ],
          child: _localizedApp(
            home: HermesChatScreen(
              voiceCaptureServiceOverride: capture,
              textToSpeechServiceOverride: tts,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('instant dispatch re-arms continuous capture', (tester) async {
      final channel = FakeHermesChannel();
      final capture = _CommandThenBlockCaptureService('is the agent connected');
      final router = _router(_ScriptedEngine([() async => _showStatusCall]));

      await pumpScreen(
        tester,
        channel: channel,
        router: router,
        capture: capture,
      );

      await tester.tap(continuousSwitch());
      await pumpTurns(tester);

      // Capture 1 routed to show_status (instant, no chip); the loop must
      // have restarted capture instead of silently ending hands-free mode.
      expect(capture.captureCalls, 2);
      expect(tester.widget<Switch>(continuousSwitch()).value, isTrue);
      expect(channel.sentVoiceTranscripts, isEmpty);
      await expireSnackBars(tester);
    });

    testWidgets('chip timeout in continuous mode sends text and re-arms', (
      tester,
    ) async {
      final channel = FakeHermesChannel();
      final capture = _CommandThenBlockCaptureService(
        'start a new conversation',
      );
      final router = _router(_ScriptedEngine([() async => _newSessionCall]));

      await pumpScreen(
        tester,
        channel: channel,
        router: router,
        capture: capture,
        tts: FakeTextToSpeechService(),
      );

      await tester.tap(continuousSwitch());
      await pumpTurns(tester);
      expect(find.text('Start a new session?'), findsOneWidget);

      // Continuous-mode chips auto-decline after 5 s; the declined command
      // sends as plain text and the loop re-arms.
      await tester.pump(const Duration(seconds: 5));
      await pumpTurns(tester);

      expect(find.text('Start a new session?'), findsNothing);
      expect(channel.createSessionCalls, isEmpty);
      expect(
        channel.state.activeMessages.map((turn) => turn.text),
        contains('start a new conversation'),
      );
      expect(capture.captureCalls, 2);
      expect(tester.widget<Switch>(continuousSwitch()).value, isTrue);
      await expireSnackBars(tester);
    });

    testWidgets('stop_voice_run pauses hands-free and does not re-arm', (
      tester,
    ) async {
      final channel = FakeHermesChannel();
      final capture = _CommandThenBlockCaptureService('stop listening');
      final router = _router(_ScriptedEngine([() async => _stopVoiceRunCall]));

      await pumpScreen(
        tester,
        channel: channel,
        router: router,
        capture: capture,
      );

      await tester.tap(continuousSwitch());
      await pumpTurns(tester);

      expect(capture.captureCalls, 1);
      expect(tester.widget<Switch>(continuousSwitch()).value, isFalse);
      expect(find.text('Stopped by voice command.'), findsOneWidget);
      await expireSnackBars(tester);
    });

    testWidgets('voice toggle-off pauses the controller and does not re-arm', (
      tester,
    ) async {
      final channel = FakeHermesChannel();
      final capture = _CommandThenBlockCaptureService(
        'turn off continuous voice',
      );
      final router = _router(_ScriptedEngine([() async => _toggleOffCall]));

      await pumpScreen(
        tester,
        channel: channel,
        router: router,
        capture: capture,
      );

      await tester.tap(continuousSwitch());
      await pumpTurns(tester);

      expect(capture.captureCalls, 1);
      // The setting flip alone must not strand the controller: the switch
      // has to read OFF, mirroring stop_voice_run's pause behavior.
      expect(tester.widget<Switch>(continuousSwitch()).value, isFalse);
      expect(
        find.text('Continuous voice turned off by voice command.'),
        findsOneWidget,
      );
      await expireSnackBars(tester);
    });

    testWidgets('confirmed toggle-on starts continuous listening', (
      tester,
    ) async {
      final channel = FakeHermesChannel();
      final capture = _CommandThenBlockCaptureService(
        'turn on continuous voice',
      );
      final router = _router(_ScriptedEngine([() async => _toggleOnCall]));

      await pumpScreen(
        tester,
        channel: channel,
        router: router,
        capture: capture,
      );

      // Manual mic tap (capture 1) produces the confirm-tier toggle-on chip.
      await tester.tap(find.byKey(const ValueKey('hermes-mic-button')));
      await tester.pumpAndSettle();
      expect(find.text('Turn on continuous voice?'), findsOneWidget);
      expect(tester.widget<Switch>(continuousSwitch()).value, isFalse);

      await tester.tap(
        find.byKey(const ValueKey('voice-command-chip-confirm')),
      );
      await pumpTurns(tester);

      // 'Turn on' means start listening, not just flip the setting.
      expect(capture.captureCalls, 2);
      expect(tester.widget<Switch>(continuousSwitch()).value, isTrue);
      // Mirror the UI switch exactly: it also enables speak-replies
      // (hermes_chat_layout.dart). Without it, maybeContinue() would pause
      // after the FIRST reply — hands-free would survive one exchange and
      // then silently die.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HermesChatScreen)),
      );
      expect(
        container.read(wingVoiceSettingsProvider).speakRepliesEnabled,
        isTrue,
      );
      await expireSnackBars(tester);
    });

    testWidgets('decline-send failure shows a notice and still re-arms', (
      tester,
    ) async {
      final channel = _SendFailsChannel();
      final capture = _CommandThenBlockCaptureService(
        'start a new conversation',
      );
      final router = _router(_ScriptedEngine([() async => _newSessionCall]));

      await pumpScreen(
        tester,
        channel: channel,
        router: router,
        capture: capture,
      );

      await tester.tap(continuousSwitch());
      await pumpTurns(tester);
      expect(find.text('Start a new session?'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await pumpTurns(tester);

      // The failed send surfaces as a transcript-free notice, never as an
      // uncaught zone error, and hands-free capture still restarts.
      expect(tester.takeException(), isNull);
      expect(
        find.text('Could not send the declined transcript to Hermes.'),
        findsOneWidget,
      );
      expect(capture.captureCalls, 2);
      expect(tester.widget<Switch>(continuousSwitch()).value, isTrue);
      await expireSnackBars(tester);
    });
  });
}

/// First capture yields [command]; every later capture blocks forever so a
/// re-armed hands-free loop is observable (captureCalls) without spinning.
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

/// Simulates HermesApiChannel.sendText throwing (turn already streaming or
/// channel disconnected) during the chip's decline-send path.
class _SendFailsChannel extends FakeHermesChannel {
  @override
  Future<void> sendText(String text) async {
    throw StateError('another turn is streaming');
  }
}
