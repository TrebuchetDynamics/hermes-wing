import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/voice/hermes_voice_capture_flow.dart';

void main() {
  test('chat voice package owns capture orchestration', () {
    expect(const HermesVoiceCaptureFlow(), isA<HermesVoiceCaptureFlow>());
  });
}
