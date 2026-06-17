import '../../../../core/protocol/navivox_event.dart';

/// Decides which assistant reply (if any) hands-free continuous voice should
/// speak aloud now.
///
/// Pure: callers own TTS playback, last-spoken tracking, and re-arming capture.
/// Returns the newest completed assistant text reply for the active profile that
/// has not been spoken yet, or null when auto-speak should not fire.
NavivoxChatMessage? continuousVoiceReplyToSpeak({
  required List<NavivoxChatMessage> messages,
  required String? activeProfileContactKey,
  required bool enabled,
  required bool turnComplete,
  required String? lastSpokenMessageId,
}) {
  if (!enabled || !turnComplete) return null;

  NavivoxChatMessage? latest;
  for (final message in messages) {
    if (message.author != NavivoxMessageAuthor.assistant) continue;
    if (message.kind != NavivoxMessageKind.text) continue;
    final text = message.text?.trim();
    if (text == null || text.isEmpty) continue;
    final scope = message.profileContactKey;
    if (activeProfileContactKey != null &&
        scope != null &&
        scope != activeProfileContactKey) {
      continue;
    }
    latest = message;
  }

  if (latest == null || latest.id == lastSpokenMessageId) return null;
  return latest;
}
