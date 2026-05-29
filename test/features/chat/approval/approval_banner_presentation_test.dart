import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/chat/approval/approval_banner_presentation.dart';

void main() {
  test('summarizes approval prompt actions and medium risk copy', () {
    final presentation = ApprovalBannerPresentation.fromRequest(
      const NavivoxApprovalRequest(
        id: 'ap-1',
        toolCallId: 'tc-1',
        prompt: 'Allow shell.run to delete /tmp/x?',
        risk: 'medium',
      ),
    );

    expect(presentation.title, 'Approval requested');
    expect(presentation.prompt, 'Allow shell.run to delete /tmp/x?');
    expect(presentation.denyLabel, 'Deny');
    expect(presentation.allowLabel, 'Allow');
    expect(presentation.riskLabel, 'Medium risk');
    expect(presentation.showRiskBadge, isTrue);
    expect(presentation.showHighRiskWarning, isFalse);
  });

  test('flags high-risk approvals for Adapter warning icon rendering', () {
    final presentation = ApprovalBannerPresentation.fromRequest(
      const NavivoxApprovalRequest(
        id: 'ap-high',
        toolCallId: 'tc-high',
        prompt: 'shell.run rm -rf /?',
        risk: ' HIGH ',
      ),
    );

    expect(presentation.riskLabel, 'High risk');
    expect(presentation.showRiskBadge, isTrue);
    expect(presentation.showHighRiskWarning, isTrue);
  });

  test('omits risk badge for unknown or missing risk values', () {
    final unknown = ApprovalBannerPresentation.fromRequest(
      const NavivoxApprovalRequest(
        id: 'ap-unknown',
        toolCallId: 'tc-unknown',
        prompt: 'shell.run ls?',
        risk: 'experimental',
      ),
    );
    final missing = ApprovalBannerPresentation.fromRequest(
      const NavivoxApprovalRequest(
        id: 'ap-missing',
        toolCallId: 'tc-missing',
        prompt: 'shell.run pwd?',
      ),
    );

    expect(unknown.riskLabel, isNull);
    expect(unknown.showRiskBadge, isFalse);
    expect(unknown.showHighRiskWarning, isFalse);
    expect(missing.riskLabel, isNull);
    expect(missing.showRiskBadge, isFalse);
    expect(missing.showHighRiskWarning, isFalse);
  });
}
