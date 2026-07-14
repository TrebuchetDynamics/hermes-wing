// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:pocket_speech/pocket_speech.dart';

import '../../../../shared/voice/text_to_speech_service.dart';
import '../../../../shared/voice/voice_settings.dart';
import 'text_to_speech_service.dart' show TtsSettingsReader;

abstract interface class PocketSpeechEngine {
  Future<Uint8List> synthesizeWav(
    String text, {
    String? voice,
    double speed = 1.0,
  });
  Future<void> dispose();
}

typedef _Synthesize =
    Future<Uint8List> Function(String text, {String? voice, double speed});

class PackagePocketSpeechEngine implements PocketSpeechEngine {
  PackagePocketSpeechEngine(PocketSpeechVoicePack voicePack) {
    switch (voicePack.model) {
      case PocketSpeechModel.kitten:
        final tts = PocketSpeech.kitten(
          KittenTtsConfig(
            modelAsset: voicePack.modelPath,
            voicesAsset: voicePack.voicesPath,
            model: KittenTtsModel.nanoInt8,
          ),
        );
        _synthesize = (text, {voice, speed = 1.0}) {
          final supported = voice != null && KittenCatalog.supportsVoice(voice);
          return supported
              ? tts.synthesizeWav(text, voice: voice, speed: speed)
              : tts.synthesizeWav(text, speed: speed);
        };
        _dispose = tts.dispose;
      case PocketSpeechModel.kokoro:
        final tts = PocketSpeech.kokoro(
          KokoroTtsConfig(
            modelAsset: voicePack.modelPath,
            voicesAsset: voicePack.voicesPath,
          ),
        );
        _synthesize = (text, {voice, speed = 1.0}) => voice != null
            ? tts.synthesizeWav(text, voice: voice, speed: speed)
            : tts.synthesizeWav(text, speed: speed);
        _dispose = tts.dispose;
    }
  }

  late final _Synthesize _synthesize;
  late final Future<void> Function() _dispose;

  @override
  Future<Uint8List> synthesizeWav(
    String text, {
    String? voice,
    double speed = 1.0,
  }) => _synthesize(text, voice: voice, speed: speed);

  @override
  Future<void> dispose() => _dispose();
}

abstract interface class PocketSpeechAudioSink {
  Future<void> playWav(Uint8List wav);
  Future<void> stop();
  Future<void> dispose();
}

abstract interface class PocketSpeechAudioPlayer {
  Stream<void> get onPlayerComplete;
  Future<void> playBytes(Uint8List wav);
  Future<void> stop();
  Future<void> dispose();
}

class PackagePocketSpeechAudioPlayer implements PocketSpeechAudioPlayer {
  PackagePocketSpeechAudioPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<void> get onPlayerComplete => _player.onPlayerComplete;

  @override
  Future<void> playBytes(Uint8List wav) => _player.play(BytesSource(wav));

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class AudioPlayersPocketSpeechAudioSink implements PocketSpeechAudioSink {
  AudioPlayersPocketSpeechAudioSink({PocketSpeechAudioPlayer? player})
    : _player = player ?? PackagePocketSpeechAudioPlayer() {
    _completionSubscription = _player.onPlayerComplete.listen((_) {
      final completion = _playbackCompletion;
      if (completion != null && !completion.isCompleted) completion.complete();
    });
  }

  final PocketSpeechAudioPlayer _player;
  late final StreamSubscription<void> _completionSubscription;
  Completer<void>? _playbackCompletion;

  @override
  Future<void> playWav(Uint8List wav) async {
    await stop();
    final completion = Completer<void>();
    _playbackCompletion = completion;
    try {
      await _player.playBytes(wav);
      await completion.future;
    } finally {
      if (identical(_playbackCompletion, completion)) {
        _playbackCompletion = null;
      }
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } finally {
      final completion = _playbackCompletion;
      _playbackCompletion = null;
      if (completion != null && !completion.isCompleted) completion.complete();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _completionSubscription.cancel();
    await _player.dispose();
  }
}

class PocketSpeechTextToSpeechService implements TextToSpeechService {
  PocketSpeechTextToSpeechService({
    required PocketSpeechEngine engine,
    required PocketSpeechAudioSink audioSink,
    TtsSettingsReader? settings,
  }) : _engine = engine,
       _audioSink = audioSink,
       _settings = settings;

  final PocketSpeechEngine _engine;
  final PocketSpeechAudioSink _audioSink;
  final TtsSettingsReader? _settings;

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final settings = _settings?.call();
    // pocket_speech's KokoroCatalog.speed.check rejects values outside
    // 0.5-2.0; the app-level 0.25-3.0 clamp is wider by design for
    // flutter_tts, so re-clamp here to the package-safe range.
    final speed = (settings?.speechRate ?? 1.0).clamp(0.5, 2.0);
    final voice = settings?.ttsVoiceName;
    Uint8List wav;
    try {
      wav = await _engine.synthesizeWav(trimmed, voice: voice, speed: speed);
    } on ArgumentError {
      // Defense per the never-break-speech constraint: a rejected voice or
      // speed (pocket_speech throws ArgumentError/RangeError) must not
      // silence the utterance — retry once with the engine defaults. If the
      // retry also throws, let it propagate; the outer service contract
      // already treats speak failures.
      wav = await _engine.synthesizeWav(trimmed);
    }
    if (wav.isEmpty) return;
    await _audioSink.playWav(wav);
  }

  @override
  Future<void> stop() => _audioSink.stop();

  @override
  Future<void> dispose() async {
    try {
      await _audioSink.dispose();
    } finally {
      await _engine.dispose();
    }
  }
}

TextToSpeechService? createPocketSpeechTextToSpeechService({
  bool enabled = false,
  PocketSpeechVoicePack? voicePack,
  PocketSpeechEngine? engine,
  PocketSpeechAudioSink? audioSink,
  bool useDefaultAudioSink = true,
  TtsSettingsReader? settings,
}) {
  if (!enabled || (voicePack == null && engine == null)) return null;
  final effectiveSink =
      audioSink ??
      (useDefaultAudioSink ? AudioPlayersPocketSpeechAudioSink() : null);
  if (effectiveSink == null) return null;
  return PocketSpeechTextToSpeechService(
    engine: engine ?? PackagePocketSpeechEngine(voicePack!),
    audioSink: effectiveSink,
    settings: settings,
  );
}
