import '../../../../core/protocol/navivox_event.dart';

enum TranscriptSafetyNoticeTone { warning, approval }

class TranscriptSafetyNoticePresentation {
  const TranscriptSafetyNoticePresentation({
    required this.tone,
    required this.cardKeyValue,
    required this.title,
    required this.message,
    required this.severityLabel,
    required this.risk,
  });

  factory TranscriptSafetyNoticePresentation.fromNotice(
    NavivoxSafetyNotice notice, {
    required bool approval,
  }) {
    return TranscriptSafetyNoticePresentation(
      tone: approval
          ? TranscriptSafetyNoticeTone.approval
          : TranscriptSafetyNoticeTone.warning,
      cardKeyValue: approval ? 'approval-required-card' : 'safety-warning-card',
      title: approval ? 'Approval required' : 'Safety warning',
      message: notice.message,
      severityLabel: notice.severity,
      risk: notice.risk,
    );
  }

  final TranscriptSafetyNoticeTone tone;
  final String cardKeyValue;
  final String title;
  final String message;
  final String? severityLabel;
  final String? risk;

  bool get showSeverity =>
      tone == TranscriptSafetyNoticeTone.warning &&
      severityLabel?.isNotEmpty == true;

  bool get showRisk => risk?.isNotEmpty == true;
}
