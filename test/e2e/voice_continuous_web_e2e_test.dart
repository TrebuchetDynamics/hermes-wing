import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';
import 'package:navivox/features/voice/services/platform/default_voice_capture_service.dart';
import 'package:navivox/router/app_router.dart';
import 'package:navivox/shared/voice/text_to_speech_service.dart';
import 'package:navivox/testing/connect_and_talk_channel.dart';

import '../features/shared/fakes/voice_capture_service_fakes.dart';

void main() {
  testWidgets(
    'web e2e continuous voice captures a spoken turn and reads the reply aloud',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final channel = ConnectAndTalkChannel();
      addTearDown(channel.dispose);
      final tts = FakeTextToSpeechService();
      final voiceService = successfulVoiceCaptureService(
        transcript: 'summarize the workspace',
        duration: const Duration(milliseconds: 900),
        confidence: 0.9,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navivoxChannelProvider.overrideWithValue(channel),
            chatVoiceCaptureServiceProvider.overrideWithValue(voiceService),
            chatVoiceCaptureReadinessProvider.overrideWith(
              (_) async => const VoiceCaptureReadiness.available(),
            ),
            chatTextToSpeechServiceProvider.overrideWithValue(tts),
          ],
          child: const _WebE2EApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Connect from the setup screen.
      await tester.enterText(
        find.widgetWithText(TextField, 'Gateway address'),
        'http://127.0.0.1:8765',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Pairing token'),
        'nvbx_test_token',
      );
      await tester.ensureVisible(_connectAndTalkButton());
      await tester.tap(_connectAndTalkButton());
      await tester.pumpAndSettle();

      // Open the profile contact chat.
      await tester.tap(find.text('Default profile'));
      await tester.pumpAndSettle();

      // Trust the gateway so continuous voice can start, then confirm STT is ready.
      await tester.tap(find.text('Trust server'));
      await tester.pumpAndSettle();
      expect(find.text('Continuous voice ready'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      // STT: tap the mic, capture a spoken turn, and let it auto-send. A live
      // capture animation keeps frames scheduled, so drive explicit pumps rather
      // than pumpAndSettle from here on.
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump();

      expect(channel.sentVoiceTranscripts, ['summarize the workspace']);
      expect(find.text('summarize the workspace'), findsOneWidget);
      expect(find.text('voice reply from gateway'), findsOneWidget);

      // TTS: read the assistant reply aloud through the message actions sheet.
      await tester.longPress(find.text('voice reply from gateway'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Message actions'), findsOneWidget);

      await tester.tap(find.text('Read aloud'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tts.spoken, ['voice reply from gateway']);
    },
  );
}

Finder _connectAndTalkButton() {
  return find.ancestor(
    of: find.text('Connect and talk'),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  );
}

class _WebE2EApp extends ConsumerWidget {
  const _WebE2EApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}
