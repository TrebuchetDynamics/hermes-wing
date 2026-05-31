export 'navivox_voice_status.dart';

import 'navivox_voice_status.dart';

class NavivoxVoiceRun {
  const NavivoxVoiceRun({
    required this.id,
    required this.serverId,
    required this.profileId,
    required this.status,
    required this.transcriptSource,
    required this.ttsStatus,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
    this.requestId,
    this.transcript,
    this.duration,
    this.confidence,
    this.reason,
    this.retentionPolicy = 'transcript_only',
  });

  factory NavivoxVoiceRun.recording({
    required String id,
    required String serverId,
    required String profileId,
    required DateTime createdAt,
  }) {
    return NavivoxVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      status: NavivoxVoiceRunStatus.recording,
      transcriptSource: NavivoxTranscriptSource.device,
      ttsStatus: NavivoxTtsStatus.unavailable,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  final String id;
  final String serverId;
  final String profileId;
  final String? sessionId;
  final String? requestId;
  final NavivoxVoiceRunStatus status;
  final NavivoxTranscriptSource transcriptSource;
  final NavivoxTtsStatus ttsStatus;
  final String? transcript;
  final Duration? duration;
  final double? confidence;
  final String? reason;
  final String retentionPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => navivoxVoiceRunStatusIsTerminal(status);

  NavivoxVoiceRun withDeviceTranscript({
    required String transcript,
    required Duration duration,
    required double confidence,
    required DateTime updatedAt,
  }) {
    return copyWith(
      status: NavivoxVoiceRunStatus.pendingSend,
      transcriptSource: NavivoxTranscriptSource.device,
      transcript: transcript,
      duration: duration,
      confidence: confidence,
      updatedAt: updatedAt,
    );
  }

  NavivoxVoiceRun markSubmitted({
    required String requestId,
    String? sessionId,
  }) {
    return copyWith(
      status: NavivoxVoiceRunStatus.submitted,
      requestId: requestId,
      sessionId: sessionId,
    );
  }

  NavivoxVoiceRun markCompleted() {
    return copyWith(status: NavivoxVoiceRunStatus.completed);
  }

  NavivoxVoiceRun markCancelled(String reason) {
    return copyWith(status: NavivoxVoiceRunStatus.cancelled, reason: reason);
  }

  NavivoxVoiceRun markFailed(String reason) {
    return copyWith(status: NavivoxVoiceRunStatus.failed, reason: reason);
  }

  NavivoxVoiceRun copyWith({
    String? sessionId,
    String? requestId,
    NavivoxVoiceRunStatus? status,
    NavivoxTranscriptSource? transcriptSource,
    NavivoxTtsStatus? ttsStatus,
    String? transcript,
    Duration? duration,
    double? confidence,
    String? reason,
    String? retentionPolicy,
    DateTime? updatedAt,
  }) {
    return NavivoxVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      sessionId: sessionId ?? this.sessionId,
      requestId: requestId ?? this.requestId,
      status: status ?? this.status,
      transcriptSource: transcriptSource ?? this.transcriptSource,
      ttsStatus: ttsStatus ?? this.ttsStatus,
      transcript: transcript ?? this.transcript,
      duration: duration ?? this.duration,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      retentionPolicy: retentionPolicy ?? this.retentionPolicy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
