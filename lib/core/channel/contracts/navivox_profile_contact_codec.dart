import '../../protocol/navivox_json.dart';
import 'navivox_channel.dart';
import 'navivox_profile_scope.dart';

/// Gateway/test-facing decoder for the profile contact payload used by channel
/// state. Keeping it beside the channel contract avoids each channel adapter
/// re-implementing the same fallback policy.
NavivoxProfileContact navivoxProfileContactFromJson(Map<String, Object?> json) {
  final serverId = navivoxStringFromJson(
    json['server_id'],
    fallback: navivoxDefaultGatewayServerId,
  );
  final profileId = navivoxStringFromJson(
    json['profile_id'],
    fallback: navivoxDefaultProfileId,
  );
  final serverLabel = navivoxStringFromJson(
    json['server_label'],
    fallback: navivoxDefaultGatewayServerLabel,
  );
  final micAvailable = navivoxStrictBoolFromJson(json['mic_available']);
  return NavivoxProfileContact(
    serverId: serverId,
    profileId: profileId,
    displayName: navivoxStringFromJson(
      json['display_name'],
      fallback: profileId == navivoxDefaultProfileId
          ? 'Default profile'
          : profileId,
    ),
    serverLabel: serverLabel,
    health: navivoxProfileHealthFromJson(json['health']),
    latestPreview: navivoxStringFromJson(
      json['latest_preview'],
      fallback: 'Profile ready',
    ),
    latestPreviewKind: navivoxStringFromJson(
      json['latest_preview_kind'],
      fallback: 'status',
    ),
    latestAt: navivoxDateTimeFromJson(json['latest_preview_at']),
    workspaceRootCount: navivoxIntFromJson(json['workspace_root_count']),
    workspaceRootsOk: navivoxStrictBoolFromJson(
      json['workspace_roots_ok'],
      fallback: true,
    ),
    workspaceRootsWarning: navivoxIntFromJson(json['workspace_roots_warning']),
    workspaceRootsError: navivoxIntFromJson(json['workspace_roots_error']),
    attentionBadges: navivoxStringListFromJson(json['attention_badges']),
    micAvailable: micAvailable,
    voiceCapability: navivoxVoiceCapabilityFromJson(
      json['voice_capability'],
      micAvailable: micAvailable,
    ),
    activeTurnState: navivoxStringFromJson(
      json['active_turn_state'],
      fallback: 'idle',
    ),
    avatarSeed: navivoxStringFromJson(
      json['avatar_seed'],
      fallback: '$serverId:$profileId',
    ),
  );
}

NavivoxVoiceCapability navivoxVoiceCapabilityFromJson(
  Object? value, {
  required bool micAvailable,
}) {
  if (value is Map) {
    return NavivoxVoiceCapability(
      deviceStt: navivoxStringFromJson(
        value['device_stt'],
        fallback: micAvailable ? 'available' : 'unavailable',
      ),
      serverStt: navivoxStringFromJson(
        value['server_stt'],
        fallback: 'unavailable',
      ),
      serverTts: navivoxStringFromJson(
        value['server_tts'],
        fallback: 'unavailable',
      ),
      disabledReason: navivoxStringFromJson(
        value['disabled_reason'],
        fallback: micAvailable ? '' : 'mic unavailable',
      ),
      recoveryAction: navivoxStringFromJson(
        value['recovery_action'],
        fallback: '',
      ),
      isReported: true,
    );
  }
  return NavivoxVoiceCapability(
    deviceStt: micAvailable ? 'available' : 'unavailable',
    disabledReason: micAvailable ? '' : 'mic unavailable',
  );
}
