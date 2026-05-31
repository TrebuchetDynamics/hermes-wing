import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

import '../../shared/voice_recovery_test_fixtures.dart';
import 'transcript_surface_test_app.dart';

export '../../shared/voice_recovery_test_fixtures.dart';

Future<void> pumpUnavailableTranscriptSurface(
  WidgetTester tester, {
  required String voiceUnavailableReason,
  String? voiceRecoveryAction,
  VoidCallback? onOpenVoiceSettings,
  VoiceCaptureService? voiceCaptureService,
  ValueChanged<VoiceCapture>? onVoice,
}) async {
  await tester.pumpWidget(
    transcriptSurfaceTestApp(
      messages: const <NavivoxChatMessage>[],
      onSend: (_) {},
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
  expect(
    find.text(
      'Install or enable device speech recognition, then return to Navivox.',
    ),
    findsOneWidget,
  );
}

void expectMicrophonePermissionRecoveryCopy() {
  expect(find.text(microphonePermissionDeniedReason), findsOneWidget);
  expect(
    find.text(
      'Grant microphone permission in Android App info, then return to Navivox.',
    ),
    findsOneWidget,
  );
}
