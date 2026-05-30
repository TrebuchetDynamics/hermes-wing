import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/transcript/widgets/transcript_surface.dart';
import 'package:navivox/features/voice/services/capture/voice_capture_service.dart';

void main() {
  testWidgets('disabled STT mic explains recovery in Transcript surface', (
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

  testWidgets('disabled STT mic shows supplied recovery action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
            voiceUnavailableReason: 'device STT unavailable',
            voiceRecoveryAction: 'Enable device speech recognition',
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle();

    expect(find.text('Recovery action'), findsOneWidget);
    expect(find.text('Enable device speech recognition'), findsOneWidget);
  });

  testWidgets('disabled STT mic can open voice settings', (tester) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: const <NavivoxChatMessage>[],
            onSend: (_) {},
            voiceUnavailableReason: 'device STT unavailable',
            onOpenVoiceSettings: () => opened = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.mic_off));
    await tester.pumpAndSettle();

    expect(find.text('Open voice settings'), findsOneWidget);
    expect(
      find.text(
        'Review continuous voice after enabling device speech recognition.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Open voice settings'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
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
}
