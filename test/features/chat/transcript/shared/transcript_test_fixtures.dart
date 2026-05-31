import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/protocol/navivox_event.dart';

import '../../shared/profile_contact_chat_test_fixtures.dart';

/// Shared Profile contact target used by transcript forwarding/action tests.
const transcriptSupportContact = chatSupportTriageContact;

/// Secondary Profile contact target used when tests need multiple destinations.
const transcriptOpsContact = NavivoxProfileContact(
  serverId: 'lab',
  profileId: 'ops',
  displayName: 'Ops Desk',
  serverLabel: 'lab',
  health: NavivoxProfileHealth.warning,
  latestPreview: 'Watching devices',
);

NavivoxChatMessage transcriptChatMessage({
  String id = 'message-1',
  required NavivoxMessageKind kind,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.assistant,
  DateTime? createdAt,
  String? text,
  NavivoxToolCall? toolCall,
  NavivoxVoiceMessage? voice,
  NavivoxSafetyNotice? safetyNotice,
  String? runRecordReference,
  String? serverId,
  String? profileId,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: kind,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 23, 11, 15),
    text: text,
    toolCall: toolCall,
    voice: voice,
    safetyNotice: safetyNotice,
    runRecordReference: runRecordReference,
    serverId: serverId,
    profileId: profileId,
  );
}

NavivoxChatMessage transcriptTextMessage({
  String id = 'text-1',
  String? text,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.assistant,
  DateTime? createdAt,
  String? runRecordReference,
  String? serverId,
  String? profileId,
}) {
  return transcriptChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.text,
    createdAt: createdAt,
    text: text,
    runRecordReference: runRecordReference,
    serverId: serverId,
    profileId: profileId,
  );
}

NavivoxChatMessage transcriptVoiceMessage({
  String id = 'voice-1',
  String transcript = '',
  NavivoxMessageAuthor author = NavivoxMessageAuthor.user,
  DateTime? createdAt,
  Duration duration = const Duration(seconds: 1),
  double confidence = 0.9,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.voice,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 23, 11, 15),
    voice: NavivoxVoiceMessage(
      duration: duration,
      transcript: transcript,
      confidence: confidence,
    ),
  );
}

NavivoxChatMessage transcriptToolMessage({
  String id = 'tool-1',
  required NavivoxToolCall toolCall,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.system,
  DateTime? createdAt,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: NavivoxMessageKind.toolCall,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 23, 11, 15),
    toolCall: toolCall,
  );
}

NavivoxChatMessage transcriptNoticeMessage({
  String id = 'notice-1',
  required NavivoxMessageKind kind,
  required NavivoxSafetyNotice notice,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.system,
  DateTime? createdAt,
}) {
  return NavivoxChatMessage(
    id: id,
    author: author,
    kind: kind,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 23, 11, 15),
    safetyNotice: notice,
  );
}
