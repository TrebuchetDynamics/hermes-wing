import 'package:wing/core/protocol/wing_voice_run.dart';

WingVoiceRun recordingVoiceRun({
  String id = 'voice-1',
  String serverId = 'local',
  String profileId = 'mineru',
  DateTime? createdAt,
}) {
  return WingVoiceRun.recording(
    id: id,
    serverId: serverId,
    profileId: profileId,
    createdAt: createdAt ?? DateTime.utc(2026, 5, 21, 12),
  );
}
