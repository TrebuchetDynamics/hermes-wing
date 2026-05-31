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
  const support = NavivoxProfileContact(
    serverId: 'local',
    profileId: 'support',
    displayName: 'Support',
    serverLabel: 'Local',
    health: NavivoxProfileHealth.online,
    latestPreview: 'Ready',
  );

  test('projects active Profile contact messages plus system recovery', () {
    final conversation = ProfileContactConversation.fromState(
      NavivoxChannelState(
        profileContacts: const [mineru, support],
        selectedProfileContactKey: mineru.key,
        messages: {
          'mineru': chatProfileTextMessage(
            id: 'mineru',
            createdAt: now,
            text: 'mineru turn',
          ),
          'support': chatTextMessage(
            id: 'support',
            author: NavivoxMessageAuthor.assistant,
            createdAt: now,
            text: 'support turn',
            serverId: 'local',
            profileId: 'support',
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
        profileContacts: const [mineru, support],
        selectedProfileContactKey: mineru.key,
        voiceRuns: {
          'support-voice': chatVoiceRun(
            id: 'support-voice',
            profileId: 'support',
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
