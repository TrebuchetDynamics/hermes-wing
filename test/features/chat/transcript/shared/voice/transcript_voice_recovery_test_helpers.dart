import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart'
    show VoiceCaptureService;

import '../../../shared/voice/voice_recovery_test_fixtures.dart';
import '../apps/transcript_interaction_contracts.dart';
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

void expectDeviceSttRecoveryCopy() {
  expect(find.text(deviceSttUnavailableReason), findsOneWidget);
  expect(find.text(deviceSttRecoveryCopy), findsOneWidget);
}

void expectMicrophonePermissionRecoveryCopy() {
  expect(find.text(microphonePermissionDeniedReason), findsOneWidget);
  expect(find.text(microphonePermissionRecoveryCopy), findsOneWidget);
}
