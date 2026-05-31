import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/shared/voice/voice_capture_service.dart';

import '../../../shared/fakes/voice_capture_service_fakes.dart';
import '../shared/transcript_surface_test_app.dart';
import '../shared/transcript_test_fixtures.dart';
import '../shared/transcript_voice_recovery_test_helpers.dart';

void main() {
  testWidgets('renders a captured voice transcript bubble', (tester) async {
    await tester.pumpWidget(
      transcriptSurfaceTestApp(
        messages: [
          transcriptVoiceMessage(
            id: 'voice-1',
            transcript: 'hello voice',
            createdAt: DateTime(2026, 5, 16, 9, 30),
            duration: const Duration(milliseconds: 1200),
            confidence: 0.91,
          ),
        ],
        onSend: transcriptNoopSend,
      ),
    );

    expect(find.text('Voice message'), findsOneWidget);
    expect(find.textContaining('hello voice'), findsOneWidget);
  });

  testWidgets('disabled STT mic explains why voice is unavailable', (
    tester,
  ) async {
    await pumpUnavailableTranscriptSurface(
      tester,
      voiceUnavailableReason: deviceSttUnavailableReason,
    );

    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
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

  testWidgets(
    'tap mic invokes the voice service and forwards result via onVoice',
    (tester) async {
      final service = successfulVoiceCaptureService(audio: [10, 20, 30, 40]);
      VoiceCapture? captured;

      await tester.pumpWidget(
        transcriptSurfaceTestApp(
          messages: const <NavivoxChatMessage>[],
          onSend: transcriptNoopSend,
          voiceCaptureService: service,
          onVoice: (capture) => captured = capture,
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.transcript, 'hello voice');
      expect(captured!.audio, [10, 20, 30, 40]);
    },
  );

  testWidgets('mic shows recording indicator while capture is in flight', (
    tester,
  ) async {
    final service = successfulVoiceCaptureService(
      transcript: 't',
      duration: const Duration(milliseconds: 50),
      confidence: 1.0,
      captureLatency: const Duration(milliseconds: 100),
    );

    await tester.pumpWidget(
      transcriptSurfaceTestApp(
        messages: const <NavivoxChatMessage>[],
        onSend: transcriptNoopSend,
        voiceCaptureService: service,
        onVoice: (_) {},
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump(); // start frame
    await tester.pump(const Duration(milliseconds: 30));

    // While recording the mic icon flips to a stop icon and the surface label
    // announces the active state.
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);

    await tester.pumpAndSettle();

    // After the capture resolves the mic icon is back.
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsNothing);
  });
}
