import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/platform/default_voice_capture_service.dart';
import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

void main() {
  test('creates a speech-to-text voice service for Android devices', () {
    final fake = _FakeVoiceCaptureService();
    var factoryCalls = 0;

    final service = createDefaultVoiceCaptureService(
      platform: const VoiceCapturePlatform(isAndroid: true),
      speechToTextServiceFactory: () {
        factoryCalls++;
        return fake;
      },
    );

    expect(service, same(fake));
    expect(factoryCalls, 1);
  });

  test('keeps non-Android targets in text-only fallback', () {
    var factoryCalls = 0;

    final service = createDefaultVoiceCaptureService(
      platform: const VoiceCapturePlatform(isAndroid: false),
      speechToTextServiceFactory: () {
        factoryCalls++;
        return _FakeVoiceCaptureService();
      },
    );

    expect(service, isNull);
    expect(factoryCalls, 0);
  });

  test(
    'readiness marks Android unavailable without a RecognitionService',
    () async {
      final readiness = await checkDefaultVoiceCaptureReadiness(
        platform: const VoiceCapturePlatform(isAndroid: true),
        diagnosticsProbe: const _FakeSpeechDiagnosticsProbe(
          DeviceSpeechRecognitionDiagnostics(recognitionServiceCount: 0),
        ),
      );

      expect(readiness.available, isFalse);
      expect(readiness.unavailableReason, 'device STT unavailable');
    },
  );

  test('readiness degrades safely when diagnostics channel fails', () async {
    final readiness = await checkDefaultVoiceCaptureReadiness(
      platform: const VoiceCapturePlatform(isAndroid: true),
      diagnosticsProbe: _ThrowingSpeechDiagnosticsProbe(
        PlatformException(code: 'channel-failed'),
      ),
    );

    expect(readiness.available, isFalse);
    expect(readiness.unavailableReason, 'device STT unavailable');
  });

  test(
    'readiness allows Android recognizer before first microphone grant',
    () async {
      final readiness = await checkDefaultVoiceCaptureReadiness(
        platform: const VoiceCapturePlatform(isAndroid: true),
        diagnosticsProbe: const _FakeSpeechDiagnosticsProbe(
          DeviceSpeechRecognitionDiagnostics(
            recognitionServiceCount: 1,
            microphonePermissionGranted: false,
          ),
        ),
      );

      expect(readiness.available, isTrue);
      expect(readiness.unavailableReason, isNull);
      expect(readiness.diagnostics?.microphonePermissionGranted, isFalse);
    },
  );
}

class _FakeSpeechDiagnosticsProbe
    implements DeviceSpeechRecognitionDiagnosticsProbe {
  const _FakeSpeechDiagnosticsProbe(this.diagnostics);

  final DeviceSpeechRecognitionDiagnostics diagnostics;

  @override
  Future<DeviceSpeechRecognitionDiagnostics> read() async => diagnostics;
}

class _ThrowingSpeechDiagnosticsProbe
    implements DeviceSpeechRecognitionDiagnosticsProbe {
  _ThrowingSpeechDiagnosticsProbe(this.error);

  final Object error;

  @override
  Future<DeviceSpeechRecognitionDiagnostics> read() async {
    throw error;
  }
}

class _FakeVoiceCaptureService implements VoiceCaptureService {
  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    return VoiceCapture(
      audio: Uint8List(0),
      transcript: 'hello',
      duration: Duration.zero,
      confidence: 1,
    );
  }
}
