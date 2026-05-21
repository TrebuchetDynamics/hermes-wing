import 'dart:async';
import 'dart:typed_data';

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
}

class VoiceCaptureTimeout implements Exception {
  const VoiceCaptureTimeout();

  @override
  String toString() => 'VoiceCaptureTimeout';
}

/// In-memory capture service used by tests and the offline fake-channel mode.
/// Real microphone integration ships in a later slice.
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
}
