import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/speech/sherpa_silero_vad.dart';
import 'package:wing/features/voice/services/speech/offline_voice_capture_service.dart';

void main() {
  test('reports speech while Silero detects an active segment', () {
    final backend = _FakeVadBackend(detected: true);
    final vad = SherpaSileroVoiceActivityDetector(backend);

    final result = vad.accept(Uint8List.fromList([0x00, 0x80, 0xff, 0x7f]));

    expect(result, VoiceActivity.speech);
    expect(backend.samples[0], closeTo(-1, 0.0001));
    expect(backend.samples[1], closeTo(0.99997, 0.0001));
  });

  test('reports endpoint when Silero queues a completed segment', () {
    final backend = _FakeVadBackend(segments: 1);
    final vad = SherpaSileroVoiceActivityDetector(backend);

    expect(vad.accept(Uint8List(640)), VoiceActivity.end);
    expect(backend.segments, 0, reason: 'completed segments are drained');
  });

  test('reset clears native VAD history', () {
    final backend = _FakeVadBackend();
    final vad = SherpaSileroVoiceActivityDetector(backend);

    vad.reset();

    expect(backend.resetCalls, 1);
  });
}

class _FakeVadBackend implements SherpaVadBackend {
  _FakeVadBackend({this.detected = false, this.segments = 0});

  bool detected;
  int segments;
  int resetCalls = 0;
  Float32List samples = Float32List(0);

  @override
  void accept(Float32List samples) => this.samples = samples;

  @override
  bool get isDetected => detected;

  @override
  bool get hasSegment => segments > 0;

  @override
  void popSegment() => segments -= 1;

  @override
  void reset() => resetCalls += 1;

  @override
  void dispose() {}
}
