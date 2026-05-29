import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/widgets/transcript/transcript_input_panel.dart';
import 'package:navivox/features/voice/services/speech/speech_to_text_voice_capture_service.dart';
import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

void main() {
  testWidgets('sends typed text and clears the composer controller', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hello Gormes');
    addTearDown(controller.dispose);
    final sent = <String>[];

    await tester.pumpWidget(
      _InputPanelHost(controller: controller, onSend: sent.add),
    );

    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(sent, ['hello Gormes']);
    expect(controller.text, isEmpty);
  });

  testWidgets('captures voice and reports start before captured voice', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final events = <String>[];
    VoiceCapture? captured;

    await tester.pumpWidget(
      _InputPanelHost(
        controller: controller,
        onSend: (_) {},
        voiceCaptureService: FakeVoiceCaptureService(
          audio: Uint8List.fromList([1, 2, 3]),
          transcript: 'hello voice',
          duration: const Duration(milliseconds: 700),
          confidence: 0.88,
        ),
        onVoiceCaptureStarted: () => events.add('started'),
        onVoice: (capture) {
          events.add('captured');
          captured = capture;
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(events, ['started', 'captured']);
    expect(captured?.transcript, 'hello voice');
  });

  testWidgets('shows capture failure copy and reports failed capture', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    Object? failed;

    await tester.pumpWidget(
      _InputPanelHost(
        controller: controller,
        onSend: (_) {},
        voiceCaptureService: _ThrowingVoiceCaptureService(
          StateError('microphone exploded'),
        ),
        onVoiceCaptureFailed: (error) => failed = error,
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(failed, isA<StateError>());
    expect(
      find.text('Voice capture failed: Bad state: microphone exploded'),
      findsOneWidget,
    );
  });

  testWidgets('shows actionable no-speech recovery copy', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    Object? failed;

    await tester.pumpWidget(
      _InputPanelHost(
        controller: controller,
        onSend: (_) {},
        voiceCaptureService: const _ThrowingVoiceCaptureService(
          SpeechToTextCaptureFailure('no transcript'),
        ),
        onVoiceCaptureFailed: (error) => failed = error,
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(failed, isA<SpeechToTextCaptureFailure>());
    expect(find.text(noSpeechDetectedVoiceCaptureMessage), findsOneWidget);
  });

  testWidgets('shows actionable permission recovery copy', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    Object? failed;

    await tester.pumpWidget(
      _InputPanelHost(
        controller: controller,
        onSend: (_) {},
        voiceCaptureService: const _ThrowingVoiceCaptureService(
          DeviceSpeechUnavailable('microphone permission denied'),
        ),
        onVoiceCaptureFailed: (error) => failed = error,
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    expect(failed, isA<DeviceSpeechUnavailable>());
    expect(
      find.text(microphonePermissionDeniedVoiceCaptureMessage),
      findsOneWidget,
    );
  });

  testWidgets('shows stop state while capture is in flight', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _InputPanelHost(
        controller: controller,
        onSend: (_) {},
        voiceCaptureService: FakeVoiceCaptureService(
          audio: Uint8List.fromList([1]),
          transcript: 'slow voice',
          duration: const Duration(milliseconds: 50),
          confidence: 1,
          captureLatency: const Duration(milliseconds: 100),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);

    await tester.pumpAndSettle();
  });
}

class _InputPanelHost extends StatelessWidget {
  const _InputPanelHost({
    required this.controller,
    required this.onSend,
    this.voiceCaptureService,
    this.onVoice,
    this.onVoiceCaptureStarted,
    this.onVoiceCaptureFailed,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final VoiceCaptureService? voiceCaptureService;
  final ValueChanged<VoiceCapture>? onVoice;
  final VoidCallback? onVoiceCaptureStarted;
  final ValueChanged<Object>? onVoiceCaptureFailed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: TranscriptInputPanel(
          controller: controller,
          onSend: onSend,
          voiceCaptureService: voiceCaptureService,
          onVoice: onVoice,
          onVoiceCaptureStarted: onVoiceCaptureStarted,
          onVoiceCaptureFailed: onVoiceCaptureFailed,
        ),
      ),
    );
  }
}

class _ThrowingVoiceCaptureService implements VoiceCaptureService {
  const _ThrowingVoiceCaptureService(this.error);

  final Object error;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    throw error;
  }
}
