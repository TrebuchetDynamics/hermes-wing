import 'dart:async';
import 'dart:typed_data';

class VoiceEngineProvenance {
  const VoiceEngineProvenance({
    required this.engine,
    required this.adapter,
    required this.model,
    required this.offlineRequested,
    required this.appOwnedModel,
  });

  final String engine;
  final String adapter;
  final String? model;
  final bool offlineRequested;
  final bool appOwnedModel;

  @override
  bool operator ==(Object other) =>
      other is VoiceEngineProvenance &&
      other.engine == engine &&
      other.adapter == adapter &&
      other.model == model &&
      other.offlineRequested == offlineRequested &&
      other.appOwnedModel == appOwnedModel;

  @override
  int get hashCode =>
      Object.hash(engine, adapter, model, offlineRequested, appOwnedModel);
}

abstract interface class VoiceCaptureProvenanceService {
  VoiceEngineProvenance get provenance;
}

class VoiceCapture {
  const VoiceCapture({
    required this.audio,
    required this.transcript,
    required this.duration,
    required this.confidence,
  });

  final Uint8List audio;
  final String transcript;
  final Duration duration;
  final double confidence;
}

abstract interface class VoiceCaptureService {
  Future<VoiceCapture> capture({required Duration timeout});

  /// Cancels any active capture and releases the microphone promptly.
  Future<void> cancel();
}

abstract interface class VoiceCaptureLifecycleService {
  Future<void> dispose();
}

/// Optional live recognition updates from a [VoiceCaptureService].
abstract interface class VoiceCaptureProgressService {
  Stream<String> get partialTranscripts;
}

/// Optional microphone levels for a live capture indicator.
abstract interface class VoiceCaptureSoundLevelService {
  Stream<double> get soundLevels;
}

class VoiceCaptureTimeout implements Exception {
  const VoiceCaptureTimeout();

  @override
  String toString() => 'VoiceCaptureTimeout';
}

/// In-memory capture adapter used by tests and the offline fake-channel mode.
/// Production capture adapters live behind [VoiceCaptureService].
class FakeVoiceCaptureService implements VoiceCaptureService {
  FakeVoiceCaptureService({
    required this.audio,
    required this.transcript,
    required this.duration,
    required this.confidence,
    this.captureLatency = Duration.zero,
  });

  final Uint8List audio;
  final String transcript;
  final Duration duration;
  final double confidence;
  final Duration captureLatency;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    final completer = Completer<VoiceCapture>();
    final timer = Timer(captureLatency, () {
      if (!completer.isCompleted) {
        completer.complete(
          VoiceCapture(
            audio: audio,
            transcript: transcript,
            duration: duration,
            confidence: confidence,
          ),
        );
      }
    });

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => throw const VoiceCaptureTimeout(),
      );
    } finally {
      timer.cancel();
    }
  }

  @override
  Future<void> cancel() async {}
}
