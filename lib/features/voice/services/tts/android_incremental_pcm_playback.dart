import 'dart:async';

import 'package:flutter/services.dart';

import 'incremental_tts_engine.dart';

/// Generation-owned Android PCM output for locally synthesized speech.
///
/// Playback starts lazily on the first chunk so a synthesis operation that is
/// cancelled before producing audio never acquires an [AudioTrack].
final class AndroidIncrementalPcmPlayback implements IncrementalPcmPlayback {
  factory AndroidIncrementalPcmPlayback({
    int? sampleRate,
    int? channelCount,
    MethodChannel methodChannel = const MethodChannel('wing/voice_engine'),
  }) =>
      AndroidIncrementalPcmPlayback._(sampleRate, channelCount, methodChannel);

  AndroidIncrementalPcmPlayback._(
    this.sampleRate,
    this.channelCount,
    this._methodChannel,
  );

  final int? sampleRate;
  final int? channelCount;
  final MethodChannel _methodChannel;
  int? _activeGeneration;
  int? _activeSampleRate;
  int? _activeChannelCount;
  bool _disposed = false;

  @override
  Future<void> write(PcmAudioChunk chunk) async {
    if (_disposed) throw StateError('PCM playback is disposed.');
    if (chunk.bytes.isEmpty) return;
    final generation = chunk.generation;
    final active = _activeGeneration;
    if (active != null && active != generation) {
      throw StateError('A different PCM playback generation is active.');
    }
    final effectiveSampleRate = sampleRate ?? chunk.sampleRate;
    final effectiveChannelCount = channelCount ?? chunk.channelCount;
    if (active == generation &&
        (_activeSampleRate != effectiveSampleRate ||
            _activeChannelCount != effectiveChannelCount)) {
      throw StateError('PCM format changed during active playback.');
    }
    if (active == null) {
      _activeGeneration = generation;
      _activeSampleRate = effectiveSampleRate;
      _activeChannelCount = effectiveChannelCount;
      late final bool? started;
      try {
        started = await _methodChannel.invokeMethod<bool>('startPlayback', {
          'generation': generation,
          'sampleRate': effectiveSampleRate,
          'channelCount': effectiveChannelCount,
        });
      } catch (_) {
        if (_activeGeneration == generation) _clearActive();
        rethrow;
      }
      if (_activeGeneration != generation) return;
      if (started != true) {
        _clearActive();
        throw StateError('PCM playback did not start.');
      }
    }
    if (_disposed || _activeGeneration != generation) return;
    await _methodChannel.invokeMethod<void>('writePlaybackPcm', {
      'generation': generation,
      'pcm16': chunk.bytes,
    });
  }

  @override
  Future<void> stop() {
    final generation = _activeGeneration;
    _clearActive();
    if (generation == null) return Future<void>.value();
    return _methodChannel.invokeMethod<void>('stopPlayback', {
      'generation': generation,
    });
  }

  @override
  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    _disposed = true;
    return Future<void>.sync(stop);
  }

  void _clearActive() {
    _activeGeneration = null;
    _activeSampleRate = null;
    _activeChannelCount = null;
  }
}
