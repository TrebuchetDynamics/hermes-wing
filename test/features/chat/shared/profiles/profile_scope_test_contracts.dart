/// Shared Profile-scope identifiers used by chat feature tests.
///
/// Keeping the canonical server/profile ids in one place makes fixture values
/// and scope assertions agree without coupling tests to individual contact
/// objects.
typedef ChatProfileScope = ({String serverId, String profileId});

const chatMineruServerId = 'local';
const chatMineruProfileId = 'mineru';
const chatMineruProfileScope = (
  serverId: chatMineruServerId,
  profileId: chatMineruProfileId,
);

const chatSupportServerId = 'office';
const chatSupportProfileId = 'support';
const chatSupportProfileScope = (
  serverId: chatSupportServerId,
  profileId: chatSupportProfileId,
);

const chatActiveAgentKey = 'chat-active-agent';
const chatActiveProfileAvatarKey = 'chat-active-profile-avatar';
const chatContextActionKey = 'chat-context-action';
const chatProfileSearchFieldKey = 'profile-search-field';
const chatAllServersFilterKey = 'server-filter-all';

String chatServerFilterKey(String serverId) => 'server-filter-$serverId';

String chatProfileScopeKey(ChatProfileScope scope) {
  return '${scope.serverId}::${scope.profileId}';
}

String chatProfileContactKey(ChatProfileScope scope) {
  return 'profile-contact-${scope.serverId}-${scope.profileId}';
}

String chatProfileContactTitleKey(ChatProfileScope scope) {
  return 'profile-contact-title-${scope.serverId}-${scope.profileId}';
}

String chatProfileAttentionKey(ChatProfileScope scope) {
  return 'profile-attention-${scope.serverId}-${scope.profileId}';
}

String chatProfileVoiceKey(ChatProfileScope scope) {
  return 'profile-contact-voice-${scope.serverId}-${scope.profileId}';
}

String chatProfilePresenceKey(ChatProfileScope scope) {
  return 'profile-presence-${scope.serverId}-${scope.profileId}';
}

String chatProfileVoiceReadyKey(ChatProfileScope scope) {
  return 'profile-voice-ready-${scope.serverId}-${scope.profileId}';
}

String chatProfileActiveTurnKey(ChatProfileScope scope) {
  return 'profile-active-turn-${scope.serverId}-${scope.profileId}';
}

String chatProfileTypingDotKey(ChatProfileScope scope, int index) {
  return 'profile-typing-dot-${scope.serverId}-${scope.profileId}-$index';
}
