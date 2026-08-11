import 'dart:typed_data';

/// Immutable description of one synthesis operation.
final class TtsSynthesisRequest {
  const TtsSynthesisRequest({
    required this.generation,
    required this.languageHint,
    required this.text,
  });

  final int generation;
  final String languageHint;
  final String text;
}

/// Raw PCM bytes emitted incrementally for a synthesis generation.
final class PcmAudioChunk {
  PcmAudioChunk({
    required this.generation,
    required Uint8List bytes,
    this.sampleRate = 24000,
    this.channelCount = 1,
  }) : bytes = Uint8List.fromList(bytes);

  final int generation;
  final Uint8List bytes;
  final int sampleRate;
  final int channelCount;
}

/// Pure-Dart boundary implemented by a streaming offline synthesis engine.
abstract interface class IncrementalTtsEngine {
  Stream<PcmAudioChunk> synthesize(TtsSynthesisRequest request);
  Future<void> stop();
  Future<void> dispose();
}

/// Pure-Dart boundary implemented by the platform PCM output adapter.
abstract interface class IncrementalPcmPlayback {
  Future<void> write(PcmAudioChunk chunk);
  Future<void> stop();
  Future<void> dispose();
}
