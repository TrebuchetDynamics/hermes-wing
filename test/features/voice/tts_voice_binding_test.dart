import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wing/features/voice/services/tts/text_to_speech_service.dart';
import 'package:wing/shared/voice/voice_settings.dart';

/// Constructs the flutter_tts-backed [TextToSpeechService] under test. This
/// stands in for `buildFlutterTtsService` in the plan skeleton — the real
/// construction path is the `FlutterTextToSpeechService` constructor.
TextToSpeechService buildFlutterTtsService({
  required FlutterTtsEngine engine,
  required TtsSettingsReader settings,
}) => FlutterTextToSpeechService(engine: engine, settings: settings);

class _RecordingEngine implements FlutterTtsEngine {
  final calls = <String>[];
  bool failVoice = false;

  @override
  Future<void> awaitSpeakCompletion(bool awaitCompletion) async {
    calls.add('awaitSpeakCompletion:$awaitCompletion');
  }

  @override
  Future<void> setLanguage(String language) async {
    calls.add('setLanguage:$language');
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    calls.add('rate:$rate');
  }

  @override
  Future<void> setVolume(double volume) async {
    calls.add('setVolume:$volume');
  }

  @override
  Future<void> setPitch(double pitch) async {
    calls.add('setPitch:$pitch');
  }

  @override
  Future<void> speak(String text) async {
    calls.add('speak');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<List<String>> voiceNames() async => const ['nova', 'en-GB-standard'];

  @override
  Future<void> setVoiceByName(String name) async {
    if (failVoice) {
      throw StateError('Unknown TTS voice: $name');
    }
    calls.add('voice:$name');
  }
}

/// Scripted [FlutterTts] whose getVoices returns the queued responses in
/// order (repeating the last one). Exercises [PluginFlutterTtsEngine]'s
/// voice-list caching against the real plugin surface.
class _ScriptedFlutterTts extends FlutterTts {
  _ScriptedFlutterTts(this.voicesResponses);

  final List<Object?> voicesResponses;
  int voicesCalls = 0;

  @override
  Future<dynamic> get getVoices async {
    final index = voicesCalls < voicesResponses.length
        ? voicesCalls
        : voicesResponses.length - 1;
    voicesCalls += 1;
    return voicesResponses[index];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'empty cold-start voice list is not cached; next call re-fetches',
    () async {
      final flutterTts = _ScriptedFlutterTts([
        const <Object?>[],
        const [
          {'name': 'nova', 'locale': 'en-US'},
        ],
      ]);
      final engine = PluginFlutterTtsEngine(flutterTts: flutterTts);

      // Cold start: some Android OEMs report an empty voice list before the
      // TTS engine finishes initializing. That result must not be cached.
      expect(await engine.voiceNames(), isEmpty);
      expect(await engine.voiceNames(), ['nova']);
      expect(flutterTts.voicesCalls, 2);
    },
  );

  test('non-empty voice list is cached and not re-fetched', () async {
    final flutterTts = _ScriptedFlutterTts([
      const [
        {'name': 'nova', 'locale': 'en-US'},
      ],
    ]);
    final engine = PluginFlutterTtsEngine(flutterTts: flutterTts);

    expect(await engine.voiceNames(), ['nova']);
    expect(await engine.voiceNames(), ['nova']);
    expect(flutterTts.voicesCalls, 1);
  });

  test('speak applies clamped rate and voice before speaking', () async {
    final engine = _RecordingEngine();
    final service = buildFlutterTtsService(
      engine: engine,
      settings: () =>
          const WingVoiceSettings(speechRate: 1.5, ttsVoiceName: 'nova'),
    );
    await service.speak('hello');
    expect(
      engine.calls,
      containsAllInOrder(['rate:0.675', 'voice:nova', 'speak']),
    );
  });

  test(
    'default settings speech rate preserves the service baseline rate',
    () async {
      // Regression: the applied rate must scale from the service's own
      // baseline (constructor default 0.45), not a hardcoded 0.5 — a
      // default-settings utterance (speechRate 1.0) must speak at exactly
      // the pre-existing baseline, matching main's behavior with the
      // feature OFF.
      final engine = _RecordingEngine();
      final service = buildFlutterTtsService(
        engine: engine,
        settings: () => const WingVoiceSettings(),
      );
      await service.speak('hello');
      // The last rate call is the one _applySettings makes at speak-time
      // (overwriting _configure's initial baseline rate call) — assert on
      // it specifically so a regression in the scaling factor is caught
      // even though _configure also happens to call setSpeechRate(0.45).
      final rateCalls = engine.calls.where((call) => call.startsWith('rate:'));
      expect(rateCalls.last, 'rate:0.45');
    },
  );

  test('unknown voice is swallowed, speech still happens', () async {
    final engine = _RecordingEngine()..failVoice = true;
    final service = buildFlutterTtsService(
      engine: engine,
      settings: () => const WingVoiceSettings(ttsVoiceName: 'ghost'),
    );
    await service.speak('hello');
    expect(engine.calls, contains('speak'));
  });
}
