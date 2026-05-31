import '../identity/navivox_profile_contact_key.dart';
import '../voice/contracts/navivox_voice_status.dart';

enum NavivoxMessageKind {
  text,
  toolCall,
  voice,
  safetyWarning,
  approvalRequest,
}

enum NavivoxMessageAuthor { user, assistant, system }

class NavivoxChatMessage {
  const NavivoxChatMessage({
    required this.id,
    required this.author,
    required this.kind,
    required this.createdAt,
    this.text,
    this.toolCall,
    this.voice,
    this.safetyNotice,
    this.runRecordReference,
    this.serverId,
    this.profileId,
  });

  final String id;
  final NavivoxMessageAuthor author;
  final NavivoxMessageKind kind;
  final DateTime createdAt;
  final String? text;
  final NavivoxToolCall? toolCall;
  final NavivoxVoiceMessage? voice;
  final NavivoxSafetyNotice? safetyNotice;
  final String? runRecordReference;
  final String? serverId;
  final String? profileId;

  String? get profileContactKey => navivoxProfileContactKeyFromNullable(
    serverId: serverId,
    profileId: profileId,
  );
}

class NavivoxToolCall {
  const NavivoxToolCall({
    required this.name,
    required this.status,
    required this.summary,
    this.approval,
    this.artifacts = const [],
  });

  final String name;
  final String status;
  final String summary;
  final NavivoxToolApproval? approval;
  final List<NavivoxToolArtifact> artifacts;

  NavivoxToolCall copyWith({
    String? name,
    String? status,
    String? summary,
    NavivoxToolApproval? approval,
    List<NavivoxToolArtifact>? artifacts,
  }) {
    return NavivoxToolCall(
      name: name ?? this.name,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      approval: approval ?? this.approval,
      artifacts: artifacts ?? this.artifacts,
    );
  }
}

class NavivoxToolApproval {
  const NavivoxToolApproval({
    required this.id,
    required this.status,
    required this.prompt,
    this.risk,
  });

  final String id;
  final String status;
  final String prompt;
  final String? risk;
}

class NavivoxToolArtifact {
  const NavivoxToolArtifact({
    required this.id,
    required this.kind,
    required this.title,
    this.summary,
    this.ref,
  });

  final String id;
  final String kind;
  final String title;
  final String? summary;
  final String? ref;
}

class NavivoxSafetyNotice {
  const NavivoxSafetyNotice({
    required this.id,
    required this.message,
    this.severity,
    this.risk,
    this.approvalId,
    this.toolCallId,
  });

  final String id;
  final String message;
  final String? severity;
  final String? risk;
  final String? approvalId;
  final String? toolCallId;
}

class NavivoxVoiceMessage {
  const NavivoxVoiceMessage({
    required this.duration,
    required this.transcript,
    required this.confidence,
    this.voiceRunId,
    this.status,
  });

  final String? voiceRunId;
  final Duration duration;
  final String transcript;
  final double confidence;
  final NavivoxVoiceRunStatus? status;
}
