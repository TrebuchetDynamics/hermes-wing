import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'offline_voice_capture_service.dart';

abstract interface class SherpaVadBackend {
  void accept(Float32List samples);

  bool get isDetected;

  bool get hasSegment;

  void popSegment();

  void reset();

  void dispose();
}

class SherpaSileroVoiceActivityDetector
    implements
        OfflineVoiceActivityDetector,
        OfflineVoiceActivityDetectorLifecycle {
  SherpaSileroVoiceActivityDetector(this._backend);

  factory SherpaSileroVoiceActivityDetector.fromModel({
    required String modelPath,
    double threshold = 0.5,
    double minSilenceDuration = 0.5,
    double minSpeechDuration = 0.25,
    double maxSpeechDuration = 30,
    int numThreads = 1,
  }) {
    sherpa.initBindings();
    final detector = sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: modelPath,
          threshold: threshold,
          minSilenceDuration: minSilenceDuration,
          minSpeechDuration: minSpeechDuration,
          windowSize: 512,
          maxSpeechDuration: maxSpeechDuration,
        ),
        sampleRate: 16000,
        numThreads: numThreads,
        provider: 'cpu',
        debug: false,
      ),
      bufferSizeInSeconds: maxSpeechDuration + 5,
    );
    return SherpaSileroVoiceActivityDetector(_NativeSherpaVadBackend(detector));
  }

  final SherpaVadBackend _backend;

  @override
  VoiceActivity accept(Uint8List pcm16) {
    if (pcm16.length.isOdd) {
      throw ArgumentError.value(
        pcm16.length,
        'pcm16.length',
        'must contain complete 16-bit samples',
      );
    }
    final samples = Float32List(pcm16.length ~/ 2);
    final bytes = ByteData.sublistView(pcm16);
    for (var index = 0; index < samples.length; index += 1) {
      samples[index] = bytes.getInt16(index * 2, Endian.little) / 32768.0;
    }
    _backend.accept(samples);
    if (_backend.hasSegment) {
      do {
        _backend.popSegment();
      } while (_backend.hasSegment);
      return VoiceActivity.end;
    }
    return _backend.isDetected ? VoiceActivity.speech : VoiceActivity.silence;
  }

  @override
  void reset() => _backend.reset();

  @override
  Future<void> dispose() async => _backend.dispose();
}

class _NativeSherpaVadBackend implements SherpaVadBackend {
  _NativeSherpaVadBackend(this.detector);

  final sherpa.VoiceActivityDetector detector;

  @override
  void accept(Float32List samples) => detector.acceptWaveform(samples);

  @override
  bool get hasSegment => !detector.isEmpty();

  @override
  bool get isDetected => detector.isDetected();

  @override
  void popSegment() => detector.pop();

  @override
  void reset() => detector.reset();

  @override
  void dispose() => detector.free();
}
