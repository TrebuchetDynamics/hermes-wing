import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/voice/services/engine/android_voice_audio_engine.dart';
import 'package:wing/features/voice/services/tts/android_incremental_pcm_playback.dart';
import 'package:wing/features/voice/services/tts/incremental_tts_engine.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const enabled = bool.fromEnvironment('WING_RUN_ACOUSTIC_PROBE');

  testWidgets(
    'physical render-reference probe reports aggregate echo metrics',
    (_) async {
      const sampleRate = 16000;
      const captureGeneration = 8701;
      const playbackGeneration = 8702;
      const frameSamples = sampleRate ~/ 50;
      const preRollFrames = 5;
      const referenceFrames = 75;
      const postRollFrames = 10;
      const targetFrames = preRollFrames + referenceFrames + postRollFrames;

      final capture = AndroidVoiceAudioEngine();
      final playback = AndroidIncrementalPcmPlayback(sampleRate: sampleRate);
      final captured = BytesBuilder(copy: false);
      final firstFrame = Completer<void>();
      final targetReached = Completer<void>();
      var captureFrames = 0;
      final subscription = capture.audioChunks.listen((chunk) {
        if (chunk.generation != captureGeneration) return;
        captured.add(chunk.pcm16);
        captureFrames += 1;
        if (!firstFrame.isCompleted) firstFrame.complete();
        if (captureFrames >= targetFrames && !targetReached.isCompleted) {
          targetReached.complete();
        }
      });

      try {
        final capabilities = await capture.capabilities();
        expect(capabilities.sampleRate, sampleRate);
        await capture.startCapture(generation: captureGeneration);
        await firstFrame.future.timeout(const Duration(seconds: 3));

        final reference = _chirpPcm16(
          sampleRate: sampleRate,
          samples: frameSamples * referenceFrames,
        );
        for (
          var offset = 0;
          offset < reference.length;
          offset += frameSamples * 2
        ) {
          final end = math.min(offset + frameSamples * 2, reference.length);
          await playback.write(
            PcmAudioChunk(
              generation: playbackGeneration,
              sampleRate: sampleRate,
              channelCount: 1,
              bytes: Uint8List.sublistView(reference, offset, end),
            ),
          );
        }
        await playback.stop();
        await targetReached.future.timeout(const Duration(seconds: 5));
        await capture.stopCapture(generation: captureGeneration);

        final metrics = _measureEcho(
          referencePcm16: reference,
          capturedPcm16: captured.takeBytes(),
          sampleRate: sampleRate,
        );
        expect(metrics.captureSamples, greaterThan(0));
        expect(metrics.peakNormalizedCorrelation.isFinite, isTrue);
        expect(metrics.peakNormalizedCorrelation, inInclusiveRange(0, 1));

        // Aggregate-only diagnostics: no microphone PCM is persisted or logged.
        // Thresholds deliberately remain a qualification decision because room,
        // route, volume, and OEM AEC behavior are physical-test variables.
        // ignore: avoid_print
        print(
          'WING_ACOUSTIC_PROBE '
          'aecAvailable=${capabilities.aecAvailable} '
          'noiseSuppressorAvailable=${capabilities.noiseSuppressorAvailable} '
          'captureSamples=${metrics.captureSamples} '
          'captureRms=${metrics.captureRms.toStringAsFixed(6)} '
          'peakCorrelation=${metrics.peakNormalizedCorrelation.toStringAsFixed(6)} '
          'peakLagMs=${metrics.peakLagMs.toStringAsFixed(2)}',
        );
      } finally {
        await Future.wait<void>([
          Future<void>.sync(playback.dispose),
          Future<void>.sync(
            () => capture.stopCapture(generation: captureGeneration),
          ),
        ]);
        await subscription.cancel();
      }
    },
    skip: !Platform.isAndroid || !enabled,
  );
}

Uint8List _chirpPcm16({required int sampleRate, required int samples}) {
  final bytes = Uint8List(samples * 2);
  final data = ByteData.sublistView(bytes);
  var phase = 0.0;
  for (var index = 0; index < samples; index++) {
    final fraction = index / math.max(1, samples - 1);
    final frequency = 350 + (2200 * fraction);
    phase += 2 * math.pi * frequency / sampleRate;
    final envelope = math.sin(math.pi * fraction);
    final value = (math.sin(phase) * envelope * 12000).round();
    data.setInt16(index * 2, value, Endian.little);
  }
  return bytes;
}

_AcousticMetrics _measureEcho({
  required Uint8List referencePcm16,
  required Uint8List capturedPcm16,
  required int sampleRate,
}) {
  const downsample = 8;
  final reference = _pcm16Samples(referencePcm16, stride: downsample);
  final captured = _pcm16Samples(capturedPcm16, stride: downsample);
  final maxLag = math.min(captured.length - 1, sampleRate ~/ downsample);
  var peak = 0.0;
  var peakLag = 0;
  for (var lag = 0; lag <= maxLag; lag++) {
    final count = math.min(reference.length, captured.length - lag);
    if (count <= 0) break;
    var dot = 0.0;
    var referenceEnergy = 0.0;
    var captureEnergy = 0.0;
    for (var index = 0; index < count; index++) {
      final far = reference[index];
      final near = captured[index + lag];
      dot += far * near;
      referenceEnergy += far * far;
      captureEnergy += near * near;
    }
    if (referenceEnergy == 0 || captureEnergy == 0) continue;
    final correlation = (dot / math.sqrt(referenceEnergy * captureEnergy))
        .abs();
    if (correlation > peak) {
      peak = correlation;
      peakLag = lag;
    }
  }
  var captureEnergy = 0.0;
  final allCaptured = _pcm16Samples(capturedPcm16);
  for (final sample in allCaptured) {
    captureEnergy += sample * sample;
  }
  final rms = allCaptured.isEmpty
      ? 0.0
      : math.sqrt(captureEnergy / allCaptured.length) / 32768;
  return _AcousticMetrics(
    captureSamples: allCaptured.length,
    captureRms: rms,
    peakNormalizedCorrelation: peak,
    peakLagMs: peakLag * downsample * 1000 / sampleRate,
  );
}

List<double> _pcm16Samples(Uint8List bytes, {int stride = 1}) {
  final data = ByteData.sublistView(bytes);
  return <double>[
    for (var index = 0; index + 1 < bytes.length; index += 2 * stride)
      data.getInt16(index, Endian.little).toDouble(),
  ];
}

final class _AcousticMetrics {
  const _AcousticMetrics({
    required this.captureSamples,
    required this.captureRms,
    required this.peakNormalizedCorrelation,
    required this.peakLagMs,
  });

  final int captureSamples;
  final double captureRms;
  final double peakNormalizedCorrelation;
  final double peakLagMs;
}
