import 'dart:async';

import '../../../../shared/voice/text_to_speech_service.dart';
import 'incremental_tts_engine.dart';
import 'language_segmenter.dart';

/// Coordinates segmented streaming synthesis while enforcing hard generation
/// boundaries between utterances.
final class IncrementalTtsCoordinator implements TextToSpeechService {
  factory IncrementalTtsCoordinator({
    required IncrementalTtsEngine engine,
    required IncrementalPcmPlayback playback,
    required TextToSpeechService fallback,
    TtsLanguageSegmenter segmenter =
        const ConservativeEnglishSpanishSegmenter(),
  }) => IncrementalTtsCoordinator._(engine, playback, fallback, segmenter);

  IncrementalTtsCoordinator._(
    this._engine,
    this._playback,
    this._fallback,
    this._segmenter,
  );

  final IncrementalTtsEngine _engine;
  final IncrementalPcmPlayback _playback;
  final TextToSpeechService _fallback;
  final TtsLanguageSegmenter _segmenter;
  int _activeGeneration = 0;

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    final generation = ++_activeGeneration;
    await _cancelOutput();
    if (!_isActive(generation)) return;

    for (final segment in _segmenter.segment(text)) {
      if (!_isActive(generation)) return;
      final request = TtsSynthesisRequest(
        generation: generation,
        languageHint: segment.languageHint,
        text: segment.text,
      );
      final completed = await _stream(request, originalText: text);
      if (!completed) return;
    }
  }

  Future<bool> _stream(
    TtsSynthesisRequest request, {
    required String originalText,
  }) async {
    late final StreamIterator<PcmAudioChunk> iterator;
    try {
      iterator = StreamIterator(_engine.synthesize(request));
    } catch (error, stackTrace) {
      if (!_isActive(request.generation)) return false;
      await _failOver(request.generation, originalText, error, stackTrace);
      return false;
    }

    try {
      while (true) {
        late final bool hasChunk;
        try {
          hasChunk = await iterator.moveNext();
        } catch (error, stackTrace) {
          if (!_isActive(request.generation)) return false;
          await _failOver(request.generation, originalText, error, stackTrace);
          return false;
        }
        if (!hasChunk) return _isActive(request.generation);

        final chunk = iterator.current;
        if (!_isActive(request.generation)) return false;
        if (chunk.generation != request.generation) continue;
        await _playback.write(chunk);
        if (!_isActive(request.generation)) return false;
      }
    } finally {
      try {
        await iterator.cancel();
      } catch (_) {
        if (_isActive(request.generation)) rethrow;
      }
    }
  }

  Future<void> _failOver(
    int generation,
    String text,
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      await Future.wait<void>([
        Future<void>.sync(_engine.stop),
        Future<void>.sync(_playback.stop),
      ]);
      if (!_isActive(generation)) return;
      await _fallback.speak(text);
    } catch (_) {
      if (_isActive(generation)) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  bool _isActive(int generation) => generation == _activeGeneration;

  Future<void> _cancelOutput() => Future.wait<void>([
    Future<void>.sync(_engine.stop),
    Future<void>.sync(_playback.stop),
    Future<void>.sync(_fallback.stop),
  ]);

  @override
  Future<void> stop() {
    _activeGeneration += 1;
    return _cancelOutput();
  }

  @override
  Future<void> dispose() {
    _activeGeneration += 1;
    return Future.wait<void>([
      Future<void>.sync(_engine.dispose),
      Future<void>.sync(_playback.dispose),
      Future<void>.sync(_fallback.dispose),
    ]);
  }
}
