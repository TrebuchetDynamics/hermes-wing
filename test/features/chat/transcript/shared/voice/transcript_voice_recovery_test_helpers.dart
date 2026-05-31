import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart'
    show VoiceCapture, VoiceCaptureService;

import '../../../../shared/fakes/voice_capture_service_fakes.dart';
import '../../../shared/voice/voice_recovery_test_fixtures.dart';
import '../contracts/transcript_interaction_contracts.dart';
import '../apps/transcript_surface_test_app.dart';

export '../../../shared/voice/voice_recovery_test_fixtures.dart';

Future<void> pumpUnavailableTranscriptSurface(
  WidgetTester tester, {
  required String voiceUnavailableReason,
  String? voiceRecoveryAction,
  VoidCallback? onOpenVoiceSettings,
  VoiceCaptureService? voiceCaptureService,
  TranscriptVoiceCaptureCallback? onVoice,
}) async {
  await tester.pumpWidget(
    transcriptSurfaceTestApp(
      messages: const <NavivoxChatMessage>[],
      onSend: transcriptNoopSend,
      voiceUnavailableReason: voiceUnavailableReason,
      voiceRecoveryAction: voiceRecoveryAction,
      onOpenVoiceSettings: onOpenVoiceSettings,
      voiceCaptureService: voiceCaptureService,
      onVoice: onVoice,
    ),
  );
}

Future<void> openVoiceUnavailableSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.mic_off));
  await tester.pumpAndSettle();
}

void expectVoiceUnavailableTooltip(String reason) {
  expect(find.byTooltip('Voice unavailable: $reason'), findsOneWidget);
}

void expectVoiceUnavailableMic(String reason) {
  expect(find.byIcon(Icons.mic), findsNothing);
  expect(find.byIcon(Icons.mic_off), findsOneWidget);
  expectVoiceUnavailableTooltip(reason);
}

void expectVoiceCaptureInFlightIndicator() {
  expect(find.byIcon(Icons.stop), findsOneWidget);
  expect(find.byIcon(Icons.mic), findsNothing);
}

void expectVoiceCaptureReadyIndicator() {
  expect(find.byIcon(Icons.mic), findsOneWidget);
  expect(find.byIcon(Icons.stop), findsNothing);
}

Future<void> expectDeviceSttUnavailableRecovery(WidgetTester tester) async {
  await pumpUnavailableTranscriptSurface(
    tester,
    voiceUnavailableReason: deviceSttUnavailableReason,
  );

  expectVoiceUnavailableMic(deviceSttUnavailableReason);

  await openVoiceUnavailableSheet(tester);

  expectDeviceSttRecoverySheet();
}

Future<void> expectMicrophonePermissionRecovery(WidgetTester tester) async {
  await pumpUnavailableTranscriptSurface(
    tester,
    voiceUnavailableReason: microphonePermissionDeniedReason,
  );

  expectVoiceUnavailableTooltip(microphonePermissionDeniedReason);

  await openVoiceUnavailableSheet(tester);

  expectMicrophonePermissionRecoveryCopy();
}

Future<void> expectCanonicalDeviceSttRecovery(WidgetTester tester) async {
  await pumpUnavailableTranscriptSurface(
    tester,
    voiceUnavailableReason: rawDeviceSttUnavailableReason,
  );

  expectVoiceUnavailableTooltip(deviceSttUnavailableReason);
  expectNoRawDeviceSttUnavailableTooltip();

  await openVoiceUnavailableSheet(tester);

  expectCanonicalDeviceSttRecoverySheet();
}

Future<void> expectUnavailableVoiceServiceDoesNotCapture(
  WidgetTester tester,
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

  expectVoiceUnavailableMic(deviceSttUnavailableReason);

  await openVoiceUnavailableSheet(tester);

  expectVoiceUnavailableSheetTitle();
  expect(captured, isNull);
}

void expectVoiceUnavailableSheetTitle() {
  expect(find.text('Voice unavailable'), findsOneWidget);
}

void expectDeviceSttRecoveryCopy() {
  expect(find.text(deviceSttUnavailableReason), findsOneWidget);
  expect(find.text(deviceSttRecoveryCopy), findsOneWidget);
}

void expectDeviceSttRecoverySheet() {
  expectVoiceUnavailableSheetTitle();
  expectDeviceSttRecoveryCopy();
}

void expectCanonicalDeviceSttRecoverySheet() {
  expect(find.text(deviceSttUnavailableReason), findsOneWidget);
  expect(find.text(rawDeviceSttUnavailableReason), findsNothing);
  expectDeviceSttRecoveryCopy();
}

void expectNoRawDeviceSttUnavailableTooltip() {
  expect(
    find.byTooltip('Voice unavailable: Device STT unavailable'),
    findsNothing,
  );
}

void expectDeviceSttRecoveryAction() {
  expect(find.text('Recovery action'), findsOneWidget);
  expect(find.text(deviceSttRecoveryAction), findsOneWidget);
}

void expectOpenVoiceSettingsAction() {
  expect(find.text('Open voice settings'), findsOneWidget);
  expect(find.text(deviceSttSettingsReviewCopy), findsOneWidget);
}

Future<void> tapOpenVoiceSettingsAction(WidgetTester tester) async {
  await tester.tap(find.text('Open voice settings'));
  await tester.pumpAndSettle();
}

void expectMicrophonePermissionRecoveryCopy() {
  expect(find.text(microphonePermissionDeniedReason), findsOneWidget);
  expect(find.text(microphonePermissionRecoveryCopy), findsOneWidget);
}
