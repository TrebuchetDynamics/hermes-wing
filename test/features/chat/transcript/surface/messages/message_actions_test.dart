import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/shared/voice/text_to_speech_service.dart';

import '../../shared/transcript_surface_test_app.dart';
import '../../shared/transcript_test_fixtures.dart';

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
      transcriptSurfaceTestApp(
        messages: [
          transcriptTextMessage(
            id: 'm-1',
            text: 'copy this dispatch note',
            createdAt: DateTime(2026, 5, 19, 12),
          ),
        ],
        onSend: transcriptNoopSend,
      ),
    );

    await tester.longPress(find.text('copy this dispatch note'));
    await tester.pumpAndSettle();

    expect(find.text('Message actions'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
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
      transcriptSurfaceTestApp(
        messages: [
          transcriptTextMessage(
            id: 'm-1',
            text: 'read this aloud',
            createdAt: DateTime(2026, 5, 19, 12),
          ),
        ],
        onSend: transcriptNoopSend,
        textToSpeechService: tts,
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
      transcriptSurfaceTestApp(
        messages: [
          transcriptTextMessage(
            id: 'm-1',
            text: 'read this later',
            createdAt: DateTime(2026, 5, 19, 12),
          ),
        ],
        onSend: transcriptNoopSend,
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
      await tester.pumpWidget(
        transcriptSurfaceTestApp(
          messages: [
            transcriptTextMessage(
              id: 'm-1',
              text: 'forward this finding',
              createdAt: DateTime(2026, 5, 19, 12),
            ),
          ],
          onSend: transcriptNoopSend,
          forwardTargets: const [transcriptSupportContact],
          onForward: (message, target) => forwarded.add((
            text: message.text!,
            serverId: target.serverId,
            profileId: target.profileId,
          )),
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
