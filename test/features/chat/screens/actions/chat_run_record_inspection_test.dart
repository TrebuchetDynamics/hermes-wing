import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import '../../transcript/shared/transcript_test_fixtures.dart';
import '../../shared/protocol/chat_message_test_fixtures.dart';
import '../../shared/widgets/chat_screen_test_fixtures.dart';
import '../../../shared/fixtures/profile_contact_channel_fixtures.dart';
import '../../../shared/fixtures/profile_contact_fixtures.dart';

void main() {
  testWidgets(
    'chat action opens redacted backend run record inspection panel',
    (tester) async {
      final channel =
          profileContactChannel(
              initial: const NavivoxChannelState(
                runRecordInspectionAvailable: true,
              ),
              contacts: [mineruBuilderProfile(latestPreview: 'building')],
            )
            ..seedMessages([
              chatProfileTextMessage(
                id: 'req-run-record',
                createdAt: DateTime(2026, 5, 23, 10),
                text: 'assistant final answer',
                runRecordReference: 'req-run-record',
              ),
            ])
            ..seedRunRecord(transcriptRunRecordSnapshot());

      await pumpChatProfileScopeScreen(tester, channel: channel);
      await tester.pumpAndSettle();

      await tester.longPress(find.text('assistant final answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View evidence'));
      await tester.pumpAndSettle();

      expect(channel.runRecordCalls, ['req-run-record']);
      expect(find.text('Evidence'), findsOneWidget);
      expect(find.text('s-run-record'), findsOneWidget);

      expect(find.text('Provider usage'), findsOneWidget);
      expect(find.text('Provider cost'), findsOneWidget);
      expect(find.text('unknown'), findsWidgets);
      expect(find.textContaining('raw audio not stored'), findsOneWidget);
    },
  );

  testWidgets('chat action hides evidence when run records are unavailable', (
    tester,
  ) async {
    final channel =
        profileContactChannel(
          contacts: [mineruBuilderProfile(latestPreview: 'building')],
        )..seedMessages([
          chatProfileTextMessage(
            id: 'assistant-row',
            createdAt: DateTime(2026, 5, 23, 10),
            text: 'assistant final answer',
            runRecordReference: 'req-run-record',
          ),
        ]);

    await pumpChatProfileScopeScreen(tester, channel: channel);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('assistant final answer'));
    await tester.pumpAndSettle();

    expect(find.text('Message actions'), findsOneWidget);
    expect(find.text('View evidence'), findsNothing);
    expect(channel.runRecordCalls, isEmpty);
  });
}
