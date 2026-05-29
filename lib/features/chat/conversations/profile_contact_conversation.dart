import '../../../core/channel/navivox_channel.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../../core/protocol/navivox_voice_run.dart';

class ProfileContactConversation {
  const ProfileContactConversation({
    required this.activeProfile,
    required this.transcriptMessages,
    required this.pendingVoiceRun,
  });

  factory ProfileContactConversation.fromState(NavivoxChannelState state) {
    final activeProfile = state.activeProfileContact;
    final activeKey = activeProfile?.key;
    final pendingVoiceRun = _pendingVoiceRunForActiveProfile(
      state,
      activeKey: activeKey,
    );
    return ProfileContactConversation(
      activeProfile: activeProfile,
      pendingVoiceRun: pendingVoiceRun,
      transcriptMessages: [
        ..._visibleMessages(state.messagesList, activeKey: activeKey),
        if (pendingVoiceRun != null) _pendingVoiceMessage(pendingVoiceRun),
      ],
    );
  }

  final NavivoxProfileContact? activeProfile;
  final List<NavivoxChatMessage> transcriptMessages;
  final NavivoxVoiceRun? pendingVoiceRun;

  static List<NavivoxChatMessage> _visibleMessages(
    List<NavivoxChatMessage> messages, {
    required String? activeKey,
  }) {
    if (activeKey == null) return messages;
    return messages
        .where(
          (message) =>
              message.profileContactKey == activeKey ||
              _isUnscopedSystemRecoveryMessage(message),
        )
        .toList(growable: false);
  }

  static bool _isUnscopedSystemRecoveryMessage(NavivoxChatMessage message) {
    return message.profileContactKey == null &&
        message.author == NavivoxMessageAuthor.system;
  }

  static NavivoxVoiceRun? _pendingVoiceRunForActiveProfile(
    NavivoxChannelState state, {
    required String? activeKey,
  }) {
    final run = state.activeVoiceRun;
    if (run?.status != NavivoxVoiceRunStatus.pendingSend) return null;
    if (activeKey == null) return run;
    return _voiceRunProfileContactKey(run!) == activeKey ? run : null;
  }

  static String _voiceRunProfileContactKey(NavivoxVoiceRun run) {
    return '${run.serverId}::${run.profileId}';
  }

  static NavivoxChatMessage _pendingVoiceMessage(NavivoxVoiceRun run) {
    return NavivoxChatMessage(
      id: 'pending-${run.id}',
      author: NavivoxMessageAuthor.user,
      kind: NavivoxMessageKind.voice,
      createdAt: run.createdAt,
      serverId: run.serverId,
      profileId: run.profileId,
      voice: NavivoxVoiceMessage(
        voiceRunId: run.id,
        duration: run.duration ?? Duration.zero,
        transcript: run.transcript ?? '',
        confidence: run.confidence ?? 1,
        status: run.status,
      ),
    );
  }
}
