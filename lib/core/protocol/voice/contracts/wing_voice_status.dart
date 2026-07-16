/// Shared voice-run status and media-state contracts.
///
/// Keep these enums separate from the full [WingVoiceRun] record so
/// transcript, channel, and presentation layers can depend on status values
/// without importing the run value object.
enum WingVoiceRunStatus {
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

enum WingTranscriptSource { device, manual, server }

enum WingTtsStatus { unavailable, queued, ready, playing, stopped, failed }

bool wingVoiceRunStatusIsTerminal(WingVoiceRunStatus status) {
  return switch (status) {
    WingVoiceRunStatus.completed ||
    WingVoiceRunStatus.cancelled ||
    WingVoiceRunStatus.failed => true,
    _ => false,
  };
}
