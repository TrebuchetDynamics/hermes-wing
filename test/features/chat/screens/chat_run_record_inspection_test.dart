import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';

import '../../../support/test_navivox_channel.dart';
import '../transcript/shared/transcript_test_fixtures.dart';
import '../../shared/app/test_material_app.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

void main() {
  testWidgets(
    'chat action opens redacted backend run record inspection panel',
    (tester) async {
      final channel =
          TestNavivoxChannel(
              initial: const NavivoxChannelState(
                runRecordInspectionAvailable: true,
              ),
            )
            ..seedServers(const [localReadyServer], activeServerId: 'local')
            ..seedProfileContacts([
              mineruBuilderProfile(latestPreview: 'building'),
            ], selectedKey: 'local::mineru')
            ..seedMessages([
              transcriptTextMessage(
                id: 'req-run-record',
                createdAt: DateTime(2026, 5, 23, 10),
                text: 'assistant final answer',
                serverId: 'local',
                profileId: 'mineru',
                runRecordReference: 'req-run-record',
              ),
            ])
            ..seedRunRecord(
              const NavivoxRunRecordSnapshot(
                runId: 'req-run-record',
                sessionId: 's-run-record',
                status: 'completed',
                createdAt: null,
                updatedAt: null,
                completedAt: null,
                raw: {
                  'transcript': [
                    {'role': 'user', 'text': 'hello'},
                    {'role': 'assistant', 'text': 'assistant final answer'},
                  ],
                  'provider_usage': {'status': 'unknown'},
                  'provider_cost': {'status': 'unknown'},
                  'voice': {
                    'device_transcript': 'hello',
                    'audio': {
                      'raw_audio_stored': false,
                      'retention': 'not_stored',
                    },
                  },
                },
              ),
            );

      await tester.pumpWidget(
        TestNavivoxMaterialApp(
          channel: channel,
          home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
        ),
      );
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
    final channel = TestNavivoxChannel()
      ..seedServers(const [localReadyServer], activeServerId: 'local')
      ..seedProfileContacts([
        mineruBuilderProfile(latestPreview: 'building'),
      ], selectedKey: 'local::mineru')
      ..seedMessages([
        transcriptTextMessage(
          id: 'assistant-row',
          createdAt: DateTime(2026, 5, 23, 10),
          text: 'assistant final answer',
          serverId: 'local',
          profileId: 'mineru',
          runRecordReference: 'req-run-record',
        ),
      ]);

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ChatScreen(serverId: 'local', profileId: 'mineru'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('assistant final answer'));
    await tester.pumpAndSettle();

    expect(find.text('Message actions'), findsOneWidget);
    expect(find.text('View evidence'), findsNothing);
    expect(channel.runRecordCalls, isEmpty);
  });
}
