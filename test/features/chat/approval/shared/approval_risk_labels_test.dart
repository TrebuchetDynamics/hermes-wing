import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/approval/shared/approval_risk_labels.dart';

void main() {
  test('normalizes known approval risk wire values into display labels', () {
    expect(ApprovalRiskLabels.fromWireValue('high'), ApprovalRiskLabels.high);
    expect(ApprovalRiskLabels.fromWireValue(' MEDIUM '), ApprovalRiskLabels.medium);
    expect(ApprovalRiskLabels.fromWireValue('Low'), ApprovalRiskLabels.low);
  });

  test('omits unknown approval risk wire values', () {
    expect(ApprovalRiskLabels.fromWireValue('experimental'), isNull);
    expect(ApprovalRiskLabels.fromWireValue(null), isNull);
  });

  test('shows warning icon only for high-risk labels', () {
    expect(ApprovalRiskLabels.showsWarningIcon(ApprovalRiskLabels.high), isTrue);
    expect(ApprovalRiskLabels.showsWarningIcon(ApprovalRiskLabels.medium), isFalse);
    expect(ApprovalRiskLabels.showsWarningIcon(null), isFalse);
  });
}
