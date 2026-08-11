import 'package:flutter/services.dart';

class VoiceAudioCapabilities {
  const VoiceAudioCapabilities({
    required this.sampleRate,
    required this.aecAvailable,
    required this.noiseSuppressorAvailable,
    required this.automaticGainControlAvailable,
  });

  final int sampleRate;
  final bool aecAvailable;
  final bool noiseSuppressorAvailable;
  final bool automaticGainControlAvailable;
}

class VoiceAudioChunk {
  const VoiceAudioChunk({required this.generation, required this.pcm16});

  final int generation;
  final Uint8List pcm16;
}

abstract interface class VoicePcmCaptureEngine {
  Stream<VoiceAudioChunk> get audioChunks;

  Future<void> startCapture({required int generation});

  Future<void> stopCapture({required int generation});
}

class AndroidVoiceAudioEngine implements VoicePcmCaptureEngine {
  AndroidVoiceAudioEngine({
    this._methodChannel = const MethodChannel('wing/voice_engine'),
    this._eventChannel = const EventChannel('wing/voice_engine/events'),
  });

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  @override
  Stream<VoiceAudioChunk> get audioChunks => _eventChannel
      .receiveBroadcastStream()
      .map(_parseChunk)
      .where((chunk) => chunk != null)
      .cast<VoiceAudioChunk>();

  Future<VoiceAudioCapabilities> capabilities() async {
    final result = await _methodChannel.invokeMapMethod<String, Object?>(
      'capabilities',
    );
    if (result == null) {
      throw StateError('Voice audio capabilities unavailable.');
    }
    return VoiceAudioCapabilities(
      sampleRate: result['sampleRate'] as int? ?? 16000,
      aecAvailable: result['aecAvailable'] as bool? ?? false,
      noiseSuppressorAvailable:
          result['noiseSuppressorAvailable'] as bool? ?? false,
      automaticGainControlAvailable:
          result['automaticGainControlAvailable'] as bool? ?? false,
    );
  }

  @override
  Future<void> startCapture({required int generation}) async {
    final started = await _methodChannel.invokeMethod<bool>('startCapture', {
      'generation': generation,
    });
    if (started != true) throw StateError('Voice audio capture did not start.');
  }

  @override
  Future<void> stopCapture({required int generation}) => _methodChannel
      .invokeMethod<void>('stopCapture', {'generation': generation});

  static VoiceAudioChunk? _parseChunk(dynamic event) {
    if (event is! Map) return null;
    final generation = event['generation'];
    final pcm = event['pcm16'];
    if (generation is! int || pcm is! Uint8List) return null;
    return VoiceAudioChunk(generation: generation, pcm16: pcm);
  }
}
