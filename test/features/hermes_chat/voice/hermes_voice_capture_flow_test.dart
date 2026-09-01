import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/voice/hermes_voice_capture_flow.dart';
import 'package:wing/features/hermes_chat/voice/hermes_voice_failure.dart';
import 'package:wing/shared/voice/voice_capture_failures.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

class _LanguageUnavailableService implements VoiceCaptureService {
  @override
  Future<VoiceCapture> capture({required Duration timeout}) async =>
      throw const DeviceSpeechUnavailable('device STT language unavailable');
  @override
  Future<void> cancel() async {}
}

void main() {
  test(
    'classifies a language-unavailable capture for localized guidance',
    () async {
      final outcome = await const HermesVoiceCaptureFlow().capture(
        service: _LanguageUnavailableService(),
        timeout: const Duration(seconds: 1),
      );
      expect(outcome.failure, HermesVoiceFailure.deviceLanguageUnavailable);
      expect(outcome.errorDetail, isNull);
    },
  );
}
