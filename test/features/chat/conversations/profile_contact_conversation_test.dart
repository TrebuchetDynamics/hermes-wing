import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';
import 'package:navivox/core/protocol/navivox_voice_run.dart';
import 'package:navivox/features/chat/conversations/profile_contact_conversation.dart';

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
          'mineru': NavivoxChatMessage(
            id: 'mineru',
            author: NavivoxMessageAuthor.user,
            kind: NavivoxMessageKind.text,
            createdAt: now,
            text: 'mineru turn',
            serverId: 'local',
            profileId: 'mineru',
          ),
          'support': NavivoxChatMessage(
            id: 'support',
            author: NavivoxMessageAuthor.assistant,
            kind: NavivoxMessageKind.text,
            createdAt: now,
            text: 'support turn',
            serverId: 'local',
            profileId: 'support',
          ),
          'system': NavivoxChatMessage(
            id: 'system',
            author: NavivoxMessageAuthor.system,
            kind: NavivoxMessageKind.text,
            createdAt: now,
            text: 'Gateway is not connected.',
          ),
          'legacy-user': NavivoxChatMessage(
            id: 'legacy-user',
            author: NavivoxMessageAuthor.user,
            kind: NavivoxMessageKind.text,
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
          'support-voice': NavivoxVoiceRun(
            id: 'support-voice',
            serverId: 'local',
            profileId: 'support',
            status: NavivoxVoiceRunStatus.pendingSend,
            transcriptSource: NavivoxTranscriptSource.device,
            ttsStatus: NavivoxTtsStatus.unavailable,
            transcript: 'wrong chat',
            createdAt: now,
            updatedAt: now,
          ),
        },
        activeVoiceRunId: 'support-voice',
      ),
    );

    expect(conversation.pendingVoiceRun, isNull);
    expect(conversation.transcriptMessages, isEmpty);
  });
}
