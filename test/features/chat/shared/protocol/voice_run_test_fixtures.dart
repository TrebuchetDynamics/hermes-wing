import 'package:navivox/core/protocol/navivox_voice_run.dart';

import '../profiles/profile_scope_test_contracts.dart';

/// Shared Voice run value fixture for chat presentation/conversation tests.
NavivoxVoiceRun chatVoiceRun({
  String id = 'voice-1',
  String serverId = chatMineruServerId,
  String profileId = chatMineruProfileId,
  NavivoxVoiceRunStatus status = NavivoxVoiceRunStatus.pendingSend,
  NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
  NavivoxTtsStatus ttsStatus = NavivoxTtsStatus.unavailable,
  String transcript = 'ship this safely',
  Duration? duration,
  double? confidence,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final timestamp = createdAt ?? DateTime.utc(2026, 5, 23, 9);
  return NavivoxVoiceRun(
    id: id,
    serverId: serverId,
    profileId: profileId,
    status: status,
    transcriptSource: transcriptSource,
    ttsStatus: ttsStatus,
    transcript: transcript,
    duration: duration,
    confidence: confidence,
    createdAt: timestamp,
    updatedAt: updatedAt ?? timestamp,
  );
}

/// Shared Voice run fixture scoped through the canonical chat Profile contract.
NavivoxVoiceRun chatProfileVoiceRun({
  String id = 'voice-1',
  ChatProfileScope scope = chatMineruProfileScope,
  NavivoxVoiceRunStatus status = NavivoxVoiceRunStatus.pendingSend,
  NavivoxTranscriptSource transcriptSource = NavivoxTranscriptSource.device,
  NavivoxTtsStatus ttsStatus = NavivoxTtsStatus.unavailable,
  String transcript = 'ship this safely',
  Duration? duration,
  double? confidence,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return chatVoiceRun(
    id: id,
    serverId: scope.serverId,
    profileId: scope.profileId,
    status: status,
    transcriptSource: transcriptSource,
    ttsStatus: ttsStatus,
    transcript: transcript,
    duration: duration,
    confidence: confidence,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
