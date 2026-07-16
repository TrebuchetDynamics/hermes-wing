import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/voice/services/platform/device_speech_recognition_availability.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android device speech diagnostics are ready for mic smoke', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;

    const probe = MethodChannelDeviceSpeechRecognitionDiagnosticsProbe(
      channel: MethodChannel('com.trebuchetdynamics.hermes.wing/device_speech'),
    );
    final diagnostics = await probe.read();

    expect(
      diagnostics.recognitionServiceCount,
      greaterThan(0),
      reason:
          'Android microphone/continuous-voice smoke needs an installed speech recognition service.',
    );
    expect(
      diagnostics.recognitionServices,
      isNotEmpty,
      reason: 'The smoke report should name the Android recognition service.',
    );
    expect(
      diagnostics.microphonePermissionGranted,
      isTrue,
      reason:
          'Grant RECORD_AUDIO before running the Android voice smoke so real capture can proceed.',
    );
  });
}
