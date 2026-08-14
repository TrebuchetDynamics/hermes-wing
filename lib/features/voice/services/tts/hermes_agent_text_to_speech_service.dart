import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../../../../shared/voice/text_to_speech_service.dart';

typedef HermesSpeechSynthesizer = Future<Uint8List> Function(String text);

abstract interface class HermesSpeechAudioPlayer {
  Stream<void> get onComplete;
  Future<void> play(Uint8List audio);
  Future<void> stop();
  Future<void> dispose();
}

final class AudioplayersHermesSpeechAudioPlayer
    implements HermesSpeechAudioPlayer {
  AudioplayersHermesSpeechAudioPlayer([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  Future<void> play(Uint8List audio) => _player.play(BytesSource(audio));

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

final class HermesAgentTextToSpeechService implements TextToSpeechService {
  HermesAgentTextToSpeechService(
    this._synthesize, {
    HermesSpeechAudioPlayer? player,
  }) : _player = player ?? AudioplayersHermesSpeechAudioPlayer() {
    _completionSubscription = _player.onComplete.listen((_) {
      final completion = _playbackCompletion;
      if (completion != null && !completion.isCompleted) completion.complete();
    });
  }

  final HermesSpeechSynthesizer _synthesize;
  final HermesSpeechAudioPlayer _player;
  late final StreamSubscription<void> _completionSubscription;
  Completer<void>? _playbackCompletion;
  int _generation = 0;

  @override
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final generation = ++_generation;
    final audio = await _synthesize(trimmed);
    if (generation != _generation) return;
    if (audio.isEmpty) throw StateError('Hermes returned empty speech audio.');

    await _stopPlayback();
    if (generation != _generation) return;
    final completion = Completer<void>();
    _playbackCompletion = completion;
    try {
      await _player.play(audio);
      await completion.future;
    } finally {
      if (identical(_playbackCompletion, completion)) {
        _playbackCompletion = null;
      }
    }
  }

  @override
  Future<void> stop() async {
    _generation += 1;
    await _stopPlayback();
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    final completion = _playbackCompletion;
    _playbackCompletion = null;
    if (completion != null && !completion.isCompleted) completion.complete();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _completionSubscription.cancel();
    await _player.dispose();
  }
}
