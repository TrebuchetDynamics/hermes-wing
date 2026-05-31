import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/features/chat/conversations/profile_contact_conversation.dart';

import '../shared/protocol/chat_message_test_fixtures.dart';
import '../shared/protocol/voice_run_test_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 5, 27, 21);

  const mineru = NavivoxProfileContact(
    serverId: 'local',
    profileId: 'mineru',
    displayName: 'Mineru',
    serverLabel: 'Local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
  );
  const supportScope = (serverId: 'local', profileId: 'support');
  final support = NavivoxProfileContact(
    serverId: supportScope.serverId,
    profileId: supportScope.profileId,
    displayName: 'Support',
    serverLabel: 'Local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
  );

  test('projects active Profile contact messages plus system recovery', () {
    final conversation = ProfileContactConversation.fromState(
      NavivoxChannelState(
        profileContacts: [mineru, support],
        selectedProfileContactKey: mineru.key,
        messages: {
          'mineru': chatProfileTextMessage(
            id: 'mineru',
            createdAt: now,
            text: 'mineru turn',
          ),
          'support': chatProfileTextMessage(
            id: 'support',
            scope: supportScope,
            author: NavivoxMessageAuthor.assistant,
            createdAt: now,
            text: 'support turn',
          ),
          'system': chatTextMessage(
            id: 'system',
            author: NavivoxMessageAuthor.system,
            createdAt: now,
            text: 'Gateway is not connected.',
          ),
          'legacy-user': chatTextMessage(
            id: 'legacy-user',
            createdAt: now,
            text: 'legacy unscoped turn',
          ),
        },
      ),
    );

    expect(conversation.transcriptMessages.map((message) => message.id), [
      'mineru',
      'system',
    ]);
  });

  test('projects only the active Profile contact pending Voice run', () {
    final conversation = ProfileContactConversation.fromState(
      NavivoxChannelState(
        profileContacts: [mineru, support],
        selectedProfileContactKey: mineru.key,
        voiceRuns: {
          'support-voice': chatProfileVoiceRun(
            id: 'support-voice',
            scope: supportScope,
            transcript: 'wrong chat',
            createdAt: now,
          ),
        },
        activeVoiceRunId: 'support-voice',
      ),
    );

    expect(conversation.pendingVoiceRun, isNull);
    expect(conversation.transcriptMessages, isEmpty);
  });
}
