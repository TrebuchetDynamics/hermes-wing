import '../../protocol/navivox_event.dart';
import '../../protocol/navivox_voice_run.dart';
import '../contracts/navivox_channel.dart';
import '../contracts/navivox_profile_scope.dart';

/// Gateway voice-run lifecycle policy.
///
/// The channel owns notification and transport; this module owns the value
/// transitions for recording, staging, and submitting voice turns so the local
/// voice-run state and transcript message payload stay aligned.
NavivoxVoiceRun navivoxGatewayRecordingVoiceRun({
  required String id,
  required NavivoxProfileContact? profile,
  required DateTime createdAt,
}) {
  final scope = navivoxProfileScopeFor(
    activeProfile: profile,
    fallbackServerId: navivoxDefaultGatewayServerId,
  );
  return NavivoxVoiceRun.recording(
    id: id,
    serverId: scope.serverId ?? navivoxDefaultGatewayServerId,
    profileId: scope.profileId,
    createdAt: createdAt,
  );
}

NavivoxVoiceRun navivoxGatewayStagedVoiceRun({
  required NavivoxVoiceRun run,
  required String transcript,
  required Duration duration,
  required double confidence,
  required NavivoxTranscriptSource transcriptSource,
  required DateTime updatedAt,
}) {
  return run.copyWith(
    status: NavivoxVoiceRunStatus.pendingSend,
    transcriptSource: transcriptSource,
    transcript: transcript,
    duration: duration,
    confidence: confidence,
    updatedAt: updatedAt,
  );
}

NavivoxVoiceRun navivoxGatewaySubmittedVoiceRun({
  required NavivoxVoiceRun run,
  required String requestId,
  required String? sessionId,
}) {
  return run.markSubmitted(requestId: requestId, sessionId: sessionId);
}

NavivoxVoiceMessage navivoxGatewaySubmittedVoiceMessage({
  required NavivoxVoiceRun run,
  required String voiceRunId,
  required String transcript,
}) {
  return NavivoxVoiceMessage(
    voiceRunId: voiceRunId,
    duration: run.duration ?? Duration.zero,
    transcript: transcript,
    confidence: run.confidence ?? 1,
    status: run.status,
  );
}
