import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';
import 'package:navivox/features/settings/providers/voice_settings_provider.dart';
import 'package:navivox/shared/voice/text_to_speech_service.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/fakes/voice_capture_service_fakes.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

TestNavivoxChannel _channelWithReply({NavivoxChatMessage? reply}) {
  final channel = TestNavivoxChannel()
    ..seedServers(const [localGormesServer], activeServerId: 'local')
    ..seedProfileContacts([
      mineruBuilderProfile(
        displayName: 'Mineru',
        latestPreview: 'Ready',
        workspaceRootCount: 1,
      ),
    ], selectedKey: 'local::mineru');
  if (reply != null) channel.seedMessages([reply]);
  return channel;
}

NavivoxChatMessage _assistantReply(String text) {
  return NavivoxChatMessage(
    id: 'assistant-reply-1',
    author: NavivoxMessageAuthor.assistant,
    kind: NavivoxMessageKind.text,
    createdAt: DateTime(2026, 6, 16, 12),
    text: text,
    serverId: 'local',
    profileId: 'mineru',
  );
}

Future<void> _pumpChat(
  WidgetTester tester, {
  required TestNavivoxChannel channel,
  required FakeTextToSpeechService tts,
  required dynamic voiceService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        navivoxChannelProvider.overrideWithValue(channel),
        chatTextToSpeechServiceProvider.overrideWithValue(tts),
      ],
      child: MaterialApp(
        home: ChatScreen(
          serverId: 'local',
          profileId: 'mineru',
          voiceCaptureServiceOverride: voiceService,
          voiceAutoSendGrace: const Duration(milliseconds: 100),
        ),
      ),
    ),
  );
  await tester.pump();
}

void _configure(
  WidgetTester tester, {
  required bool speakReplies,
}) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ChatScreen)),
  );
  final settings = container.read(navivoxVoiceSettingsProvider.notifier);
  settings.setServerTrusted('local', true);
  settings.setSpeakRepliesEnabled(speakReplies);
}

void main() {
  testWidgets(
    'hands-free loop speaks a completed reply and auto-captures the next turn',
    (tester) async {
      final channel = _channelWithReply(reply: _assistantReply('how can I help'));
      final tts = FakeTextToSpeechService();
      final voiceService = QueueVoiceCaptureService([
        testVoiceCapture('next question'),
      ]);

      await _pumpChat(
        tester,
        channel: channel,
        tts: tts,
        voiceService: voiceService,
      );
      _configure(tester, speakReplies: true);
      await tester.pump();

      // Post-frame auto-speak runs, then re-arms the next capture.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      expect(tts.spoken, contains('how can I help'));
      expect(channel.sentVoiceTranscripts, contains('next question'));
    },
  );

  testWidgets('auto-speak stays off when the opt-in setting is disabled', (
    tester,
  ) async {
    final channel = _channelWithReply(reply: _assistantReply('how can I help'));
    final tts = FakeTextToSpeechService();
    final voiceService = QueueVoiceCaptureService([
      testVoiceCapture('should not capture'),
    ]);

    await _pumpChat(
      tester,
      channel: channel,
      tts: tts,
      voiceService: voiceService,
    );
    _configure(tester, speakReplies: false);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(tts.spoken, isEmpty);
    expect(channel.sentVoiceTranscripts, isEmpty);
  });

  testWidgets('starting a capture barges in and stops any spoken reply', (
    tester,
  ) async {
    final channel = _channelWithReply();
    final tts = FakeTextToSpeechService();
    final voiceService = successfulVoiceCaptureService(
      transcript: 'manual turn',
      duration: const Duration(milliseconds: 400),
      confidence: 0.9,
    );

    await _pumpChat(
      tester,
      channel: channel,
      tts: tts,
      voiceService: voiceService,
    );
    _configure(tester, speakReplies: true);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(tts.stopCalls, greaterThanOrEqualTo(1));
  });
}
