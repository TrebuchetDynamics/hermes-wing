import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/widgets/transcript_surface.dart';
import 'package:navivox/features/voice/services/text_to_speech_service.dart';

void main() {
  testWidgets('long press text message opens selectable copy actions', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add(
            (call.arguments as Map<Object?, Object?>)['text']! as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: [_textMessage('m-1', 'copy this dispatch note')],
            onSend: (_) {},
          ),
        ),
      ),
    );

    await tester.longPress(find.text('copy this dispatch note'));
    await tester.pumpAndSettle();

    expect(find.text('Message actions'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('Copy text'), findsOneWidget);

    await tester.tap(find.text('Copy text'));
    await tester.pumpAndSettle();

    expect(copied, ['copy this dispatch note']);
  });

  testWidgets('long press text message can be read aloud with TTS', (
    tester,
  ) async {
    final tts = FakeTextToSpeechService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: [_textMessage('m-1', 'read this aloud')],
            onSend: (_) {},
            textToSpeechService: tts,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('read this aloud'));
    await tester.pumpAndSettle();

    expect(find.text('Read aloud'), findsOneWidget);

    await tester.tap(find.text('Read aloud'));
    await tester.pumpAndSettle();

    expect(tts.spoken, ['read this aloud']);
  });

  testWidgets('long press text explains unavailable TTS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranscriptSurface(
            messages: [_textMessage('m-1', 'read this later')],
            onSend: (_) {},
          ),
        ),
      ),
    );

    await tester.longPress(find.text('read this later'));
    await tester.pumpAndSettle();

    expect(find.text('Read aloud unavailable'), findsOneWidget);
    expect(find.text('Device TTS is not connected.'), findsOneWidget);
  });

  testWidgets(
    'long press text message can forward to another profile contact',
    (tester) async {
      final forwarded = <({String text, String serverId, String profileId})>[];
      const support = NavivoxProfileContact(
        serverId: 'office',
        profileId: 'support',
        displayName: 'Support Triage',
        serverLabel: 'office',
        health: NavivoxProfileHealth.online,
        latestPreview: 'watching tickets',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptSurface(
              messages: [_textMessage('m-1', 'forward this finding')],
              onSend: (_) {},
              forwardTargets: const [support],
              onForward: (message, target) => forwarded.add((
                text: message.text!,
                serverId: target.serverId,
                profileId: target.profileId,
              )),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('forward this finding'));
      await tester.pumpAndSettle();

      expect(find.text('Forward to'), findsOneWidget);
      expect(find.text('Support Triage'), findsOneWidget);

      await tester.tap(find.text('Support Triage'));
      await tester.pumpAndSettle();

      expect(forwarded, [
        (
          text: 'forward this finding',
          serverId: 'office',
          profileId: 'support',
        ),
      ]);
    },
  );
}

NavivoxChatMessage _textMessage(String id, String text) => NavivoxChatMessage(
  id: id,
  author: NavivoxMessageAuthor.assistant,
  kind: NavivoxMessageKind.text,
  createdAt: DateTime(2026, 5, 19, 12),
  text: text,
);
