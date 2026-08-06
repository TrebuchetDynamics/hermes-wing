import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/protocol/voice_unavailable_reason.dart';
import 'package:wing/features/voice/services/platform/default_voice_capture_service.dart';

void main() {
  test(
    'readiness is available on non-Android speech_to_text platforms',
    () async {
      for (final platform in const [
        VoiceCapturePlatform(isAndroid: false, isIOS: true),
        VoiceCapturePlatform(isAndroid: false, isMacOS: true),
      ]) {
        final readiness = await checkDefaultVoiceCaptureReadiness(
          platform: platform,
        );

        expect(readiness.available, isTrue);
      }
    },
  );

  test('readiness rejects unsupported and non-private platforms', () async {
    for (final platform in const [
      VoiceCapturePlatform(isAndroid: false),
      VoiceCapturePlatform(isAndroid: false, isWindows: true),
      VoiceCapturePlatform(isAndroid: false, isWeb: true),
    ]) {
      final readiness = await checkDefaultVoiceCaptureReadiness(
        platform: platform,
      );

      expect(readiness.available, isFalse);
    }
  });

  test('Android readiness reports denied microphone permission', () async {
    final readiness = await checkDefaultVoiceCaptureReadiness(
      platform: const VoiceCapturePlatform(isAndroid: true),
      diagnosticsProbe: const _DiagnosticsProbe(
        DeviceSpeechRecognitionDiagnostics(
          recognitionServiceCount: 1,
          microphonePermissionGranted: false,
          onDeviceRecognitionAvailable: true,
        ),
      ),
    );

    expect(readiness.available, isFalse);
    expect(readiness.unavailableReason, microphonePermissionDeniedReason);
  });

  test(
    'Android readiness blocks network fallback before checking permission',
    () async {
      final readiness = await checkDefaultVoiceCaptureReadiness(
        platform: const VoiceCapturePlatform(isAndroid: true),
        diagnosticsProbe: const _DiagnosticsProbe(
          DeviceSpeechRecognitionDiagnostics(
            recognitionServiceCount: 1,
            microphonePermissionGranted: false,
            onDeviceRecognitionAvailable: false,
          ),
        ),
      );

      expect(readiness.available, isFalse);
      expect(readiness.unavailableReason, deviceSttUnavailableReason);
    },
  );

  test('Android readiness requires an on-device recognizer', () async {
    final readiness = await checkDefaultVoiceCaptureReadiness(
      platform: const VoiceCapturePlatform(isAndroid: true),
      diagnosticsProbe: const _DiagnosticsProbe(
        DeviceSpeechRecognitionDiagnostics(
          recognitionServiceCount: 1,
          microphonePermissionGranted: true,
          onDeviceRecognitionAvailable: false,
        ),
      ),
    );

    expect(readiness.available, isFalse);
    expect(readiness.unavailableReason, deviceSttUnavailableReason);
  });
}

class _DiagnosticsProbe implements DeviceSpeechRecognitionDiagnosticsProbe {
  const _DiagnosticsProbe(this.diagnostics);

  final DeviceSpeechRecognitionDiagnostics diagnostics;

  @override
  Future<DeviceSpeechRecognitionDiagnostics> read() async => diagnostics;
}
