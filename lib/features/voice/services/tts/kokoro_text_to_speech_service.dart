// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:kokorodart/kokorodart.dart';

import '../../../../shared/voice/text_to_speech_service.dart';

abstract interface class KokoroSpeechEngine {
  Future<Uint8List> synthesizeWav(
    String text,
    KokoroDartSynthesisOptions options,
  );
}

class PackageKokoroSpeechEngine implements KokoroSpeechEngine {
  PackageKokoroSpeechEngine({
    KokoroDart? kokoro,
    KokoroDartConfig config = const KokoroDartConfig(
      modelAsset: 'assets/kokoro/kokoro-v1.0.onnx',
      voicesAsset: 'assets/kokoro/voices.json',
    ),
  }) : _kokoro = kokoro ?? KokoroDart(config);

  final KokoroDart _kokoro;

  @override
  Future<Uint8List> synthesizeWav(
    String text,
    KokoroDartSynthesisOptions options,
  ) => _kokoro.synthesizeWavWithOptions(text, options);
}

abstract interface class KokoroAudioSink {
  Future<void> playWav(Uint8List wav);
  Future<void> stop();
}

class AudioPlayersKokoroAudioSink implements KokoroAudioSink {
  AudioPlayersKokoroAudioSink({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playWav(Uint8List wav) async {
    await _player.stop();
    await _player.play(BytesSource(wav));
  }

  @override
  Future<void> stop() => _player.stop();
}

class KokoroTextToSpeechService implements TextToSpeechService {
  // Constructor names are public API; keep them readable instead of exposing
  // private field names.
  KokoroTextToSpeechService({
    required KokoroSpeechEngine engine,
    required KokoroAudioSink audioSink,
    this.options = const KokoroDartSynthesisOptions(),
  }) : _engine = engine,
       _audioSink = audioSink;

  final KokoroSpeechEngine _engine;
  final KokoroAudioSink _audioSink;
  final KokoroDartSynthesisOptions options;

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final wav = await _engine.synthesizeWav(trimmed, options);
    if (wav.isEmpty) return;
    await _audioSink.playWav(wav);
  }

  @override
  Future<void> stop() => _audioSink.stop();
}

TextToSpeechService? createKokoroTextToSpeechService({
  bool enabled = false,
  KokoroSpeechEngine? engine,
  KokoroAudioSink? audioSink,
  KokoroDartConfig config = const KokoroDartConfig(
    modelAsset: 'assets/kokoro/kokoro-v1.0.onnx',
    voicesAsset: 'assets/kokoro/voices.json',
  ),
  KokoroDartSynthesisOptions options = const KokoroDartSynthesisOptions(),
  bool useDefaultAudioSink = true,
}) {
  if (!enabled) return null;
  final effectiveSink =
      audioSink ?? (useDefaultAudioSink ? AudioPlayersKokoroAudioSink() : null);
  if (effectiveSink == null) return null;
  return KokoroTextToSpeechService(
    engine: engine ?? PackageKokoroSpeechEngine(config: config),
    audioSink: effectiveSink,
    options: options,
  );
}
