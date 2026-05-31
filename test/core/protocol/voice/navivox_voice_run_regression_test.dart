import 'package:navivox/core/protocol/navivox_voice_run.dart';

void main() {
  markSubmittedDoesNotCarryStaleFailureReason();
  markSubmittedUsesCurrentNullableSession();
}

void markSubmittedDoesNotCarryStaleFailureReason() {
  final failedRun = _pendingRun().markFailed('Gateway is not connected.');

  final submitted = failedRun.markSubmitted(
    requestId: 'request-2',
    sessionId: 'session-2',
  );

  _expect(
    submitted.status == NavivoxVoiceRunStatus.submitted,
    'run should be submitted after retry transition',
  );
  _expect(
    submitted.reason == null,
    'submitted retry should not keep a stale terminal failure reason',
  );
}

void markSubmittedUsesCurrentNullableSession() {
  final submittedRun = _pendingRun().markSubmitted(
    requestId: 'request-1',
    sessionId: 'session-1',
  );

  final resubmitted = submittedRun.markSubmitted(
    requestId: 'request-2',
    sessionId: null,
  );

  _expect(
    resubmitted.requestId == 'request-2',
    'resubmission should replace the request id',
  );
  _expect(
    resubmitted.sessionId == null,
    'resubmission should reflect the current absent session id',
  );
}

NavivoxVoiceRun _pendingRun() {
  return NavivoxVoiceRun.recording(
    id: 'voice-1',
    serverId: 'server-1',
    profileId: 'profile-1',
    createdAt: DateTime.utc(2026),
  ).withDeviceTranscript(
    transcript: 'hello',
    duration: const Duration(milliseconds: 500),
    confidence: 0.9,
    updatedAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
