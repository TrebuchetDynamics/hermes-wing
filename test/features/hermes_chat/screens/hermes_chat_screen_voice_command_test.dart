import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:navivox/features/voice_commands/core/needle_engine.dart';
import 'package:navivox/features/voice_commands/providers/voice_command_providers.dart';
import 'package:navivox/features/voice_commands/services/voice_command_router.dart';
import 'package:navivox/features/voice_commands/services/voice_command_validator.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

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
        child: MaterialApp(
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
        child: MaterialApp(
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
        child: MaterialApp(
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
}
