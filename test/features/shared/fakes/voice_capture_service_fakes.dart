import 'dart:typed_data';

import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

/// Builds a deterministic voice capture value from test-friendly primitives.
VoiceCapture testVoiceCapture(
  String transcript, {
  List<int>? audio,
  Duration duration = const Duration(milliseconds: 500),
  double confidence = 0.95,
}) {
  return VoiceCapture(
    audio: Uint8List.fromList(audio ?? transcript.codeUnits),
    transcript: transcript,
    duration: duration,
    confidence: confidence,
  );
}

/// Builds the standard successful voice capture fake used by feature tests.
FakeVoiceCaptureService successfulVoiceCaptureService({
  List<int> audio = const [1],
  String transcript = 'hello voice',
  Duration duration = const Duration(milliseconds: 700),
  double confidence = 0.88,
  Duration captureLatency = Duration.zero,
}) {
  return FakeVoiceCaptureService(
    audio: Uint8List.fromList(audio),
    transcript: transcript,
    duration: duration,
    confidence: confidence,
    captureLatency: captureLatency,
  );
}

/// Voice capture test double that replays captures in order.
class QueueVoiceCaptureService implements VoiceCaptureService {
  QueueVoiceCaptureService(List<VoiceCapture> captures)
    : _captures = List.of(captures);

  final List<VoiceCapture> _captures;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    if (_captures.isEmpty) {
      throw StateError('No queued voice capture');
    }
    return _captures.removeAt(0);
  }
}

/// Voice capture test double that fails every capture with the configured error.
class ThrowingVoiceCaptureService implements VoiceCaptureService {
  const ThrowingVoiceCaptureService(this.error);

  final Object error;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    throw error;
  }
}
