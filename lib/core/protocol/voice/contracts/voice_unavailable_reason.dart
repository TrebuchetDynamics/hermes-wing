/// Shared contract for canonical local voice-capture unavailable reasons.
///
/// Gateway state, speech services, voice controllers, and presentation rows all
/// exchange these string reasons. Keep canonicalization here so policy changes
/// do not drift across feature layers.
const deviceSttUnavailableReason = 'device STT unavailable';
const microphonePermissionDeniedReason = 'microphone permission denied';

String? canonicalVoiceUnavailableReason(
  String? reason, {
  bool emptyAsNull = false,
}) {
  final trimmed = reason?.trim();
  if (trimmed == null) return null;
  if (trimmed.isEmpty) return emptyAsNull ? null : trimmed;
  final normalized = trimmed.toLowerCase();
  if (normalized == 'device stt unavailable') return deviceSttUnavailableReason;
  if (normalized == microphonePermissionDeniedReason) {
    return microphonePermissionDeniedReason;
  }
  return trimmed;
}
