import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import '../../../../support/test_navivox_channel.dart';
import '../../shared/protocol/chat_message_test_fixtures.dart';
import '../../shared/widgets/chat_screen_test_fixtures.dart';
import '../../../shared/fixtures/profile_contact_channel_fixtures.dart';
import '../../../shared/fixtures/profile_contact_fixtures.dart';

void main() {
  testWidgets('chat thread shows assistant typing indicator while streaming', (
    tester,
  ) async {
    final channel = _streamingMineruChannel();

    await pumpChatProfileScopeScreen(tester, channel: channel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mineru is typing…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assistant-typing-indicator')),
      findsOneWidget,
    );
  });

  testWidgets('long press assistant bubble can pause an active stream', (
    tester,
  ) async {
    final channel = _streamingMineruChannel()
      ..seedMessages([
        chatProfileTextMessage(
          id: 'assistant-1',
          author: NavivoxMessageAuthor.assistant,
          createdAt: DateTime(2026, 5, 21, 10),
          text: 'Drafting the deployment plan.',
        ),
      ]);

    await pumpChatProfileScopeScreen(tester, channel: channel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.longPress(find.text('Drafting the deployment plan.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Pause stream'), findsOneWidget);

    await tester.tap(find.text('Pause stream'));
    await tester.pump();

    expect(channel.cancelRequests, 1);
  });
}

TestNavivoxChannel _streamingMineruChannel() => profileContactChannel(
  servers: const [NavivoxServer(id: 'local', name: 'Local', status: 'online')],
  contacts: [
    mineruBuilderProfile(
      displayName: 'Mineru',
      latestPreview: 'Working on it',
      activeTurnState: 'streaming',
    ),
  ],
);
