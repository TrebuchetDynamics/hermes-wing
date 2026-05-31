abstract final class ApprovalRiskLabels {
  static const high = 'High risk';
  static const medium = 'Medium risk';
  static const low = 'Low risk';

  static String? fromWireValue(Object? value) {
    if (value is! String) return null;
    switch (value.trim().toLowerCase()) {
      case 'high':
        return high;
      case 'medium':
        return medium;
      case 'low':
        return low;
      default:
        return null;
    }
  }

  static bool showsWarningIcon(String? label) => label == high;
}
