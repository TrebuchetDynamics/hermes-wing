export '../contracts/wing_voice_status.dart';

import '../contracts/wing_voice_status.dart';

class WingVoiceRun {
  const WingVoiceRun({
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

  factory WingVoiceRun.recording({
    required String id,
    required String serverId,
    required String profileId,
    required DateTime createdAt,
  }) {
    return WingVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      status: WingVoiceRunStatus.recording,
      transcriptSource: WingTranscriptSource.device,
      ttsStatus: WingTtsStatus.unavailable,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  final String id;
  final String serverId;
  final String profileId;
  final String? sessionId;
  final String? requestId;
  final WingVoiceRunStatus status;
  final WingTranscriptSource transcriptSource;
  final WingTtsStatus ttsStatus;
  final String? transcript;
  final Duration? duration;
  final double? confidence;
  final String? reason;
  final String retentionPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => wingVoiceRunStatusIsTerminal(status);

  WingVoiceRun withDeviceTranscript({
    required String transcript,
    required Duration duration,
    required double confidence,
    required DateTime updatedAt,
  }) {
    return copyWith(
      status: WingVoiceRunStatus.pendingSend,
      transcriptSource: WingTranscriptSource.device,
      transcript: transcript,
      duration: duration,
      confidence: confidence,
      updatedAt: updatedAt,
    );
  }

  WingVoiceRun markSubmitted({required String requestId, String? sessionId}) {
    return _withLifecycleStatus(
      status: WingVoiceRunStatus.submitted,
      requestId: requestId,
      replaceRequestId: true,
      sessionId: sessionId,
      replaceSessionId: true,
      clearReason: true,
    );
  }

  WingVoiceRun markCompleted() {
    return _withLifecycleStatus(
      status: WingVoiceRunStatus.completed,
      clearReason: true,
    );
  }

  WingVoiceRun markCancelled(String reason) {
    return _withLifecycleStatus(
      status: WingVoiceRunStatus.cancelled,
      reason: reason,
    );
  }

  WingVoiceRun markFailed(String reason) {
    return _withLifecycleStatus(
      status: WingVoiceRunStatus.failed,
      reason: reason,
    );
  }

  WingVoiceRun _withLifecycleStatus({
    required WingVoiceRunStatus status,
    String? sessionId,
    bool replaceSessionId = false,
    String? requestId,
    bool replaceRequestId = false,
    String? reason,
    bool clearReason = false,
  }) {
    assert(
      !clearReason || reason == null,
      'A voice-run transition cannot set and clear reason at the same time.',
    );
    return WingVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      sessionId: replaceSessionId ? sessionId : this.sessionId,
      requestId: replaceRequestId ? requestId : this.requestId,
      status: status,
      transcriptSource: transcriptSource,
      ttsStatus: ttsStatus,
      transcript: transcript,
      duration: duration,
      confidence: confidence,
      reason: clearReason ? null : reason ?? this.reason,
      retentionPolicy: retentionPolicy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  WingVoiceRun copyWith({
    String? sessionId,
    bool clearSessionId = false,
    String? requestId,
    bool clearRequestId = false,
    WingVoiceRunStatus? status,
    WingTranscriptSource? transcriptSource,
    WingTtsStatus? ttsStatus,
    String? transcript,
    bool clearTranscript = false,
    Duration? duration,
    bool clearDuration = false,
    double? confidence,
    bool clearConfidence = false,
    String? reason,
    bool clearReason = false,
    String? retentionPolicy,
    DateTime? updatedAt,
  }) {
    assert(
      !clearSessionId || sessionId == null,
      'copyWith cannot set and clear sessionId at the same time.',
    );
    assert(
      !clearRequestId || requestId == null,
      'copyWith cannot set and clear requestId at the same time.',
    );
    assert(
      !clearTranscript || transcript == null,
      'copyWith cannot set and clear transcript at the same time.',
    );
    assert(
      !clearDuration || duration == null,
      'copyWith cannot set and clear duration at the same time.',
    );
    assert(
      !clearConfidence || confidence == null,
      'copyWith cannot set and clear confidence at the same time.',
    );
    assert(
      !clearReason || reason == null,
      'copyWith cannot set and clear reason at the same time.',
    );
    return WingVoiceRun(
      id: id,
      serverId: serverId,
      profileId: profileId,
      sessionId: clearSessionId ? null : sessionId ?? this.sessionId,
      requestId: clearRequestId ? null : requestId ?? this.requestId,
      status: status ?? this.status,
      transcriptSource: transcriptSource ?? this.transcriptSource,
      ttsStatus: ttsStatus ?? this.ttsStatus,
      transcript: clearTranscript ? null : transcript ?? this.transcript,
      duration: clearDuration ? null : duration ?? this.duration,
      confidence: clearConfidence ? null : confidence ?? this.confidence,
      reason: clearReason ? null : reason ?? this.reason,
      retentionPolicy: retentionPolicy ?? this.retentionPolicy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
