import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/default_voice_capture_service.dart';
import 'package:navivox/features/voice/services/voice_capture_service.dart';

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
