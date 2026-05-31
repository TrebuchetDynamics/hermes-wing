import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

import '../../../shared/fakes/voice_capture_service_fakes.dart';
import '../shared/transcript_voice_recovery_test_helpers.dart';

void main() {
  testWidgets('disabled STT mic explains recovery in Transcript surface', (
    tester,
  ) async {
    await pumpUnavailableTranscriptSurface(
      tester,
      voiceUnavailableReason: deviceSttUnavailableReason,
    );

    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expectVoiceUnavailableTooltip(deviceSttUnavailableReason);

    await openVoiceUnavailableSheet(tester);

    expectDeviceSttRecoverySheet();
  });

  testWidgets('permission-denied mic explains Android permission recovery', (
    tester,
  ) async {
    await pumpUnavailableTranscriptSurface(
      tester,
      voiceUnavailableReason: microphonePermissionDeniedReason,
    );

    expectVoiceUnavailableTooltip(microphonePermissionDeniedReason);

    await openVoiceUnavailableSheet(tester);

    expectMicrophonePermissionRecoveryCopy();
  });

  testWidgets('disabled STT mic canonicalizes recovery copy', (tester) async {
    await pumpUnavailableTranscriptSurface(
      tester,
      voiceUnavailableReason: rawDeviceSttUnavailableReason,
    );

    expectVoiceUnavailableTooltip(deviceSttUnavailableReason);
    expect(
      find.byTooltip('Voice unavailable: Device STT unavailable'),
      findsNothing,
    );

    await openVoiceUnavailableSheet(tester);

    expectCanonicalDeviceSttRecoverySheet();
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

    expect(find.text('Recovery action'), findsOneWidget);
    expect(find.text(deviceSttRecoveryAction), findsOneWidget);
  });

  testWidgets('disabled STT mic can open voice settings', (tester) async {
    var opened = false;

    await pumpUnavailableTranscriptSurface(
      tester,
      voiceUnavailableReason: deviceSttUnavailableReason,
      onOpenVoiceSettings: () => opened = true,
    );

    await openVoiceUnavailableSheet(tester);

    expect(find.text('Open voice settings'), findsOneWidget);
    expect(find.text(deviceSttSettingsReviewCopy), findsOneWidget);

    await tester.tap(find.text('Open voice settings'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('unavailable STT reason disables mic even with a voice service', (
    tester,
  ) async {
    final service = successfulVoiceCaptureService(
      transcript: 'should not capture',
      duration: const Duration(milliseconds: 1),
      confidence: 1,
    );
    VoiceCapture? captured;

    await pumpUnavailableTranscriptSurface(
      tester,
      voiceUnavailableReason: deviceSttUnavailableReason,
      voiceCaptureService: service,
      onVoice: (capture) => captured = capture,
    );

    expect(find.byIcon(Icons.mic), findsNothing);
    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expectVoiceUnavailableTooltip(deviceSttUnavailableReason);

    await openVoiceUnavailableSheet(tester);

    expectVoiceUnavailableSheetTitle();
    expect(captured, isNull);
  });
}
