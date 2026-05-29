import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/widgets/transcript/transcript_surface.dart';
import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

void main() {
  testWidgets('renders a captured voice transcript bubble', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: [
              NavivoxChatMessage(
                id: 'voice-1',
                author: NavivoxMessageAuthor.user,
                kind: NavivoxMessageKind.voice,
                createdAt: DateTime(2026, 5, 16, 9, 30),
                voice: const NavivoxVoiceMessage(
                  transcript: 'hello voice',
                  duration: Duration(milliseconds: 1200),
                  confidence: 0.91,
                ),
              ),
            ],
            onSend: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Voice message'), findsOneWidget);
    expect(find.textContaining('hello voice'), findsOneWidget);
  });

  testWidgets('disabled STT mic explains why voice is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
            voiceUnavailableReason: 'device STT unavailable',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(
      find.byTooltip('Voice unavailable: device STT unavailable'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle();

    expect(find.text('Voice unavailable'), findsOneWidget);
    expect(find.text('device STT unavailable'), findsOneWidget);
    expect(
      find.text(
        'Install or enable device speech recognition, then return to Navivox.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('permission-denied mic explains Android permission recovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
            voiceUnavailableReason: 'microphone permission denied',
          ),
        ),
      ),
    );

    expect(
      find.byTooltip('Voice unavailable: microphone permission denied'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle();

    expect(find.text('microphone permission denied'), findsOneWidget);
    expect(
      find.text(
        'Grant microphone permission in Android App info, then return to Navivox.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('disabled STT mic canonicalizes recovery copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
            voiceUnavailableReason: ' Device STT unavailable ',
          ),
        ),
      ),
    );

    expect(
      find.byTooltip('Voice unavailable: device STT unavailable'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('Voice unavailable: Device STT unavailable'),
      findsNothing,
    );

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle();

    expect(find.text('device STT unavailable'), findsOneWidget);
    expect(find.text('Device STT unavailable'), findsNothing);
    expect(
      find.text(
        'Install or enable device speech recognition, then return to Navivox.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('unavailable STT reason disables mic even with a voice service', (
    tester,
  ) async {
    final service = FakeVoiceCaptureService(
      audio: Uint8List.fromList([1]),
      transcript: 'should not capture',
      duration: const Duration(milliseconds: 1),
      confidence: 1,
    );
    VoiceCapture? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
            voiceCaptureService: service,
            voiceUnavailableReason: 'device STT unavailable',
            onVoice: (capture) => captured = capture,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic), findsNothing);
    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expect(
      find.byTooltip('Voice unavailable: device STT unavailable'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle();

    expect(find.text('Voice unavailable'), findsOneWidget);
    expect(captured, isNull);
  });

  testWidgets(
    'tap mic invokes the voice service and forwards result via onVoice',
    (tester) async {
      final service = FakeVoiceCaptureService(
        audio: Uint8List.fromList([10, 20, 30, 40]),
        transcript: 'hello voice',
        duration: const Duration(milliseconds: 700),
        confidence: 0.88,
      );
      VoiceCapture? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptSurface(
              messages: const <NavivoxChatMessage>[],
              onSend: (_) {},
              voiceCaptureService: service,
              onVoice: (capture) => captured = capture,
            ),
          ),
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
    final service = FakeVoiceCaptureService(
      audio: Uint8List.fromList([1]),
      transcript: 't',
      duration: const Duration(milliseconds: 50),
      confidence: 1.0,
      captureLatency: const Duration(milliseconds: 100),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
            voiceCaptureService: service,
            onVoice: (_) {},
          ),
        ),
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
