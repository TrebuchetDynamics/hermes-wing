import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const voiceChannel = MethodChannel('wing/voice_engine');

  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      voiceChannel,
      (call) async => call.method == 'startPlayback' ? true : null,
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(voiceChannel, null);
  });

  test('Hermes Agent TTS is preferred over device TTS', () async {
    SharedPreferences.setMockInitialValues({});
    final agent = _FallbackTts();
    final platform = _FallbackTts();
    final container = ProviderContainer(
      overrides: [
        hermesAgentTtsFactoryProvider.overrideWithValue((_) => agent),
        hermesPlatformTtsFactoryProvider.overrideWithValue((_) => platform),
      ],
    );
    addTearDown(container.dispose);

    await container.read(hermesTextToSpeechServiceProvider)!.speak('reply');

    expect(agent.spoken, ['reply']);
    expect(platform.spoken, isEmpty);
  });

  test('platform TTS waits for offline predecessor disposal', () async {
    SharedPreferences.setMockInitialValues({
      'wing.voice.kokoro_tts_enabled': false,
    });
    final owner = OfflineTtsRuntimeOwner();
    final predecessor = _BlockingDisposeTts();
    await owner.adopt(predecessor, ownsOfflineModels: true);
    final platform = _FallbackTts();
    final container = ProviderContainer(
      overrides: [
        offlineTtsRuntimeOwnerProvider.overrideWithValue(owner),
        hermesAgentTtsFactoryProvider.overrideWithValue((_) => _FailingTts()),
        hermesPlatformTtsFactoryProvider.overrideWithValue((_) => platform),
      ],
    );
    addTearDown(container.dispose);
    final service = container.read(hermesTextToSpeechServiceProvider)!;

    final speaking = service.speak('successor');
    await Future<void>.delayed(Duration.zero);
    expect(predecessor.disposeStarted, isTrue);
    expect(platform.spoken, isEmpty);

    predecessor.disposeGate.complete();
    await speaking;
    expect(platform.spoken, ['successor']);
  });
}

final class _FallbackTts implements TextToSpeechService {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

final class _FailingTts implements TextToSpeechService {
  @override
  Future<void> speak(String text) => Future.error(StateError('unavailable'));

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

final class _BlockingDisposeTts implements TextToSpeechService {
  final disposeGate = Completer<void>();
  bool disposeStarted = false;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    disposeStarted = true;
    await disposeGate.future;
  }
}
