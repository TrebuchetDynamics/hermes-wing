import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/tts/pocket_speech_text_to_speech_service.dart';
import 'package:navivox/shared/voice/voice_settings.dart';

/// Fake [PocketSpeechEngine] that records the exact `(text, voice, speed)`
/// tuple passed to [synthesizeWav] for each call, so tests can assert on
/// what [PocketSpeechTextToSpeechService] actually threads through.
class _RecordingPocketSpeechEngine implements PocketSpeechEngine {
  _RecordingPocketSpeechEngine({this.throwsOnFirstCall = false});

  /// When set, the first [synthesizeWav] call throws a [RangeError] the way
  /// pocket_speech's `KokoroCatalog.speed.check` does for out-of-range
  /// speeds; later calls succeed and are recorded.
  final bool throwsOnFirstCall;
  final calls = <(String, String?, double)>[];
  var _synthCalls = 0;

  @override
  Future<Uint8List> synthesizeWav(
    String text, {
    String? voice,
    double speed = 1.0,
  }) async {
    _synthCalls += 1;
    if (throwsOnFirstCall && _synthCalls == 1) {
      throw RangeError.value(speed, 'speed', 'must be between 0.5 and 2.0');
    }
    calls.add((text, voice, speed));
    return Uint8List.fromList([1]);
  }

  @override
  Future<void> dispose() async {}
}

class _NoopPocketSpeechAudioSink implements PocketSpeechAudioSink {
  @override
  Future<void> playWav(Uint8List wav) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  test(
    'no settings reader: back-compat default voice null, speed 1.0',
    () async {
      final engine = _RecordingPocketSpeechEngine();
      final service = PocketSpeechTextToSpeechService(
        engine: engine,
        audioSink: _NoopPocketSpeechAudioSink(),
      );

      await service.speak('hi');

      expect(engine.calls, [('hi', null, 1.0)]);
    },
  );

  test('settings reader with voice and rate applies both', () async {
    final engine = _RecordingPocketSpeechEngine();
    final service = PocketSpeechTextToSpeechService(
      engine: engine,
      audioSink: _NoopPocketSpeechAudioSink(),
      settings: () =>
          const NavivoxVoiceSettings(speechRate: 2.0, ttsVoiceName: 'Bella'),
    );

    await service.speak('hi');

    expect(engine.calls, [('hi', 'Bella', 2.0)]);
  });

  test(
    'settings reader present with default settings is augment-only',
    () async {
      final engine = _RecordingPocketSpeechEngine();
      final service = PocketSpeechTextToSpeechService(
        engine: engine,
        audioSink: _NoopPocketSpeechAudioSink(),
        settings: () => const NavivoxVoiceSettings(),
      );

      await service.speak('hi');

      expect(engine.calls, [('hi', null, 1.0)]);
    },
  );

  test(
    'app-range speech rate is clamped to the pocket_speech-safe range',
    () async {
      // The app clamps speechRate to 0.25-3.0, but pocket_speech's
      // KokoroCatalog.speed.check rejects anything outside 0.5-2.0.
      final engine = _RecordingPocketSpeechEngine();
      final service = PocketSpeechTextToSpeechService(
        engine: engine,
        audioSink: _NoopPocketSpeechAudioSink(),
        settings: () => const NavivoxVoiceSettings(speechRate: 3.0),
      );

      await service.speak('hi');

      expect(engine.calls, [('hi', null, 2.0)]);
    },
  );

  test(
    'synthesis failure retries once with engine defaults; speak never throws',
    () async {
      final engine = _RecordingPocketSpeechEngine(throwsOnFirstCall: true);
      final service = PocketSpeechTextToSpeechService(
        engine: engine,
        audioSink: _NoopPocketSpeechAudioSink(),
        settings: () =>
            const NavivoxVoiceSettings(speechRate: 2.0, ttsVoiceName: 'ghost'),
      );

      await service.speak('hi');

      expect(engine.calls, [('hi', null, 1.0)]);
    },
  );
}
