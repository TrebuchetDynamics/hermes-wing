import '../../../../core/protocol/navivox_event.dart';

enum TranscriptToolCallStatusTone { active, success, failure, neutral }

class TranscriptToolArtifactPresentation {
  const TranscriptToolArtifactPresentation({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    required this.ref,
  });

  factory TranscriptToolArtifactPresentation.fromArtifact(
    NavivoxToolArtifact artifact,
  ) {
    return TranscriptToolArtifactPresentation(
      id: artifact.id,
      kind: artifact.kind,
      title: artifact.title,
      summary: artifact.summary,
      ref: artifact.ref,
    );
  }

  final String id;
  final String kind;
  final String title;
  final String? summary;
  final String? ref;

  bool get showSummary => summary?.isNotEmpty == true;
  bool get showRef => ref?.isNotEmpty == true;
}

class TranscriptToolCallPresentation {
  const TranscriptToolCallPresentation({
    required this.name,
    required this.statusLabel,
    required this.statusTone,
    required this.summary,
    required this.approvalLabel,
    required this.approvalPrompt,
    required this.approvalRisk,
    required this.artifacts,
  });

  factory TranscriptToolCallPresentation.fromToolCall(
    NavivoxToolCall toolCall,
  ) {
    return TranscriptToolCallPresentation(
      name: toolCall.name,
      statusLabel: toolCall.status,
      statusTone: statusToneFor(toolCall.status),
      summary: toolCall.summary,
      approvalLabel: toolCall.approval == null ? null : 'Approval required',
      approvalPrompt: toolCall.approval?.prompt,
      approvalRisk: toolCall.approval?.risk,
      artifacts: [
        for (final artifact in toolCall.artifacts)
          TranscriptToolArtifactPresentation.fromArtifact(artifact),
      ],
    );
  }

  final String name;
  final String statusLabel;
  final TranscriptToolCallStatusTone statusTone;
  final String summary;
  final String? approvalLabel;
  final String? approvalPrompt;
  final String? approvalRisk;
  final List<TranscriptToolArtifactPresentation> artifacts;

  bool get showSummary => summary.isNotEmpty;
  bool get showApproval => approvalLabel?.isNotEmpty == true;

  static TranscriptToolCallStatusTone statusToneFor(String status) {
    return switch (status) {
      'started' || 'updated' => TranscriptToolCallStatusTone.active,
      'finished' || 'completed' => TranscriptToolCallStatusTone.success,
      'failed' => TranscriptToolCallStatusTone.failure,
      _ => TranscriptToolCallStatusTone.neutral,
    };
  }
}
