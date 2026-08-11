import 'dart:typed_data';

import '../../../../shared/voice/voice_settings.dart';

class OfflineWhisperResult {
  const OfflineWhisperResult({required this.text, required this.language});

  final String text;
  final String language;
}

abstract interface class OfflineWhisperRuntime {
  Future<OfflineWhisperResult> transcribe({
    required Float32List samples,
    required int sampleRate,
    required String? language,
  });

  Future<void> dispose();
}

abstract interface class OfflineVoiceTranscriber {
  Future<OfflineWhisperResult> transcribe({
    required int generation,
    required Uint8List pcm16,
    required VoiceLanguageMode languageMode,
  });

  void invalidate(int generation);
}

abstract interface class OfflineVoiceTranscriberLifecycle {
  Future<void> dispose();
}

class StaleOfflineWhisperResult implements Exception {
  const StaleOfflineWhisperResult();

  @override
  String toString() => 'StaleOfflineWhisperResult';
}

/// Converts app-owned PCM to Whisper input while enforcing immutable result
/// ownership independently of native runtime completion ordering.
class OfflineWhisperEngine
    implements OfflineVoiceTranscriber, OfflineVoiceTranscriberLifecycle {
  OfflineWhisperEngine(this._runtime);

  static const sampleRate = 16000;

  final OfflineWhisperRuntime _runtime;
  int? _activeGeneration;
  bool _disposed = false;

  @override
  Future<OfflineWhisperResult> transcribe({
    required int generation,
    required Uint8List pcm16,
    required VoiceLanguageMode languageMode,
  }) async {
    if (_disposed) throw StateError('Offline Whisper engine is disposed.');
    if (generation <= 0) throw ArgumentError.value(generation, 'generation');
    if (pcm16.length.isOdd) {
      throw const FormatException('PCM16 input must contain complete samples.');
    }
    _activeGeneration = generation;
    final result = await _runtime.transcribe(
      samples: _normalizePcm16(pcm16),
      sampleRate: sampleRate,
      language: switch (languageMode) {
        VoiceLanguageMode.autoEnglishSpanish => null,
        VoiceLanguageMode.english => 'en',
        VoiceLanguageMode.spanish => 'es',
      },
    );
    if (_disposed || _activeGeneration != generation) {
      throw const StaleOfflineWhisperResult();
    }
    return result;
  }

  @override
  void invalidate(int generation) {
    if (_activeGeneration == generation) _activeGeneration = null;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _activeGeneration = null;
    await _runtime.dispose();
  }

  static Float32List _normalizePcm16(Uint8List pcm16) {
    final samples = Float32List(pcm16.length ~/ 2);
    final bytes = ByteData.sublistView(pcm16);
    for (var index = 0; index < samples.length; index += 1) {
      samples[index] = bytes.getInt16(index * 2, Endian.little) / 32768.0;
    }
    return samples;
  }
}
