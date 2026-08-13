import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/messaging/approvals/hermes_approval_queue.dart';

void main() {
  test('messaging approvals package owns the approval queue', () {
    expect(HermesApprovalQueue, isNotNull);
  });
}
