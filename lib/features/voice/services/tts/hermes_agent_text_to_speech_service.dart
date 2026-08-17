import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../../../../shared/voice/text_to_speech_service.dart';

typedef HermesSpeechSynthesizer = Future<Uint8List> Function(String text);
typedef HermesSpeechAudioPlayerFactory = HermesSpeechAudioPlayer Function();

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
    HermesSpeechAudioPlayerFactory? playerFactory,
  }) : _playerFactory =
           playerFactory ?? AudioplayersHermesSpeechAudioPlayer.new;

  final HermesSpeechSynthesizer _synthesize;
  final HermesSpeechAudioPlayerFactory _playerFactory;
  _HermesSpeechPlayback? _playback;
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
    final player = _playerFactory();
    final playback = _HermesSpeechPlayback(player);
    _playback = playback;
    try {
      await player.play(audio);
      await playback.completion;
    } finally {
      if (identical(_playback, playback)) {
        _playback = null;
      }
      await playback.dispose();
    }
  }

  @override
  Future<void> stop() async {
    _generation += 1;
    await _stopPlayback();
  }

  Future<void> _stopPlayback() async {
    final playback = _playback;
    _playback = null;
    await playback?.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}

final class _HermesSpeechPlayback {
  _HermesSpeechPlayback(this.player) {
    _subscription = player.onComplete.listen(
      (_) => _complete(),
      onError: (Object error, StackTrace stackTrace) {
        if (!_completion.isCompleted) {
          _completion.completeError(error, stackTrace);
        }
      },
    );
  }

  final HermesSpeechAudioPlayer player;
  final Completer<void> _completion = Completer<void>();
  late final StreamSubscription<void> _subscription;
  Future<void>? _disposeFuture;

  Future<void> get completion => _completion.future;

  void _complete() {
    if (!_completion.isCompleted) _completion.complete();
  }

  Future<void> stop() async {
    Object? stopError;
    StackTrace? stopStackTrace;
    try {
      await player.stop();
    } catch (error, stackTrace) {
      stopError = error;
      stopStackTrace = stackTrace;
    } finally {
      _complete();
      await dispose();
    }
    if (stopError != null) {
      Error.throwWithStackTrace(stopError, stopStackTrace!);
    }
  }

  Future<void> dispose() => _disposeFuture ??= _dispose();

  Future<void> _dispose() async {
    await _subscription.cancel();
    await player.dispose();
  }
}
