import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../shared/transcript_voice_recovery_test_helpers.dart';

void main() {
  testWidgets('disabled STT mic explains recovery in Transcript surface', (
    tester,
  ) async {
    await expectDeviceSttUnavailableRecovery(tester);
  });

  testWidgets('permission-denied mic explains Android permission recovery', (
    tester,
  ) async {
    await expectMicrophonePermissionRecovery(tester);
  });

  testWidgets('disabled STT mic canonicalizes recovery copy', (tester) async {
    await expectCanonicalDeviceSttRecovery(tester);
  });

  testWidgets('disabled STT mic shows supplied recovery action', (
    tester,
  ) async {
    await pumpUnavailableTranscriptSurface(
      tester,
      voiceUnavailableReason: deviceSttUnavailableReason,
      voiceRecoveryAction: deviceSttRecoveryAction,
    );

    await openVoiceUnavailableSheet(tester);

    expectDeviceSttRecoveryAction();
  });

  testWidgets('disabled STT mic can open voice settings', (tester) async {
    var opened = false;

    await pumpUnavailableTranscriptSurface(
      tester,
      voiceUnavailableReason: deviceSttUnavailableReason,
      onOpenVoiceSettings: () => opened = true,
    );

    await openVoiceUnavailableSheet(tester);

    expectOpenVoiceSettingsAction();

    await tapOpenVoiceSettingsAction(tester);

    expect(opened, isTrue);
  });

  testWidgets('unavailable STT reason disables mic even with a voice service', (
    tester,
  ) async {
    await expectUnavailableVoiceServiceDoesNotCapture(tester);
  });
}
