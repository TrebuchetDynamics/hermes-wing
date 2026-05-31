import 'package:navivox/core/protocol/navivox_event.dart';

import '../profiles/profile_scope_test_contracts.dart';

/// Shared chat message fixture for tests that need scoped Profile-contact turns.
NavivoxChatMessage chatTextMessage({
  required String id,
  required String? text,
  required DateTime createdAt,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.user,
  String? runRecordReference,
  String? serverId,
  String? profileId,
}) {
  return NavivoxChatMessage(
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

/// Shared chat text fixture scoped through the canonical chat Profile contract.
NavivoxChatMessage chatProfileTextMessage({
  required String id,
  required String? text,
  required DateTime createdAt,
  ChatProfileScope scope = chatMineruProfileScope,
  NavivoxMessageAuthor author = NavivoxMessageAuthor.user,
  String? runRecordReference,
}) {
  return chatTextMessage(
    id: id,
    author: author,
    text: text,
    createdAt: createdAt,
    runRecordReference: runRecordReference,
    serverId: scope.serverId,
    profileId: scope.profileId,
  );
}
