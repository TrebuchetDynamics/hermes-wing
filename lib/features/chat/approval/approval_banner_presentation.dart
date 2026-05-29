import '../../../core/channel/navivox_channel.dart';

class ApprovalBannerPresentation {
  const ApprovalBannerPresentation({
    required this.title,
    required this.prompt,
    required this.denyLabel,
    required this.allowLabel,
    required this.riskLabel,
  });

  factory ApprovalBannerPresentation.fromRequest(
    NavivoxApprovalRequest request,
  ) {
    return ApprovalBannerPresentation(
      title: 'Approval requested',
      prompt: request.prompt,
      denyLabel: 'Deny',
      allowLabel: 'Allow',
      riskLabel: riskLabelFor(request.risk),
    );
  }

  final String title;
  final String prompt;
  final String denyLabel;
  final String allowLabel;
  final String? riskLabel;

  bool get showRiskBadge => riskLabel != null;

  bool get showHighRiskWarning => riskLabel == 'High risk';

  static String? riskLabelFor(String? risk) {
    switch (risk?.trim().toLowerCase()) {
      case 'high':
        return 'High risk';
      case 'medium':
        return 'Medium risk';
      case 'low':
        return 'Low risk';
      default:
        return null;
    }
  }
}
