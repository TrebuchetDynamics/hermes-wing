/// Shared voice-run status and media-state contracts.
///
/// Keep these enums separate from the full [NavivoxVoiceRun] record so
/// transcript, channel, and presentation layers can depend on status values
/// without importing the run value object.
enum NavivoxVoiceRunStatus {
  idle,
  recording,
  transcribing,
  pendingSend,
  submitted,
  serverProcessing,
  serverSttComplete,
  agentTurnRunning,
  ttsQueued,
  ttsReady,
  playing,
  completed,
  cancelled,
  failed,
}

enum NavivoxTranscriptSource { device, manual, server }

enum NavivoxTtsStatus { unavailable, queued, ready, playing, stopped, failed }

bool navivoxVoiceRunStatusIsTerminal(NavivoxVoiceRunStatus status) {
  return switch (status) {
    NavivoxVoiceRunStatus.completed ||
    NavivoxVoiceRunStatus.cancelled ||
    NavivoxVoiceRunStatus.failed => true,
    _ => false,
  };
}
