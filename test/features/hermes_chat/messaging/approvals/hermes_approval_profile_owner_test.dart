import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/messaging/approvals/hermes_approval_queue.dart';

import '../../support/fake_hermes_channel.dart';

void main() {
  test(
    'same session ID in another profile cannot expose or resolve old approval',
    () async {
      final channel = FakeHermesChannel(selectedProfileId: 'alpha');
      addTearDown(channel.dispose);
      final queue = HermesApprovalQueue(
        channel: () => channel,
        onResolveError: (e) => fail('$e'),
      );
      addTearDown(queue.dispose);
      const old = HermesApprovalRequest(
        id: 'synthetic-approval',
        toolCallId: 'synthetic-call',
        prompt: 'Synthetic approval',
        sessionId: 'sess_1',
        profileId: 'alpha',
        runId: 'synthetic-run',
      );
      queue.add(old);
      expect(queue.activeFor('sess_1'), [old]);
      await channel.selectProfile('beta');
      expect(channel.state.activeSessionId, 'sess_1');
      expect(queue.activeFor('sess_1'), isEmpty);
      await queue.resolve(HermesApprovalDecision.once, old);
      expect(channel.respondToApprovalCalls, isEmpty);
      expect(queue.answeringId, isNull);
      const current = HermesApprovalRequest(
        id: 'synthetic-current',
        toolCallId: 'synthetic-current-call',
        prompt: 'Synthetic current approval',
        sessionId: 'sess_1',
        profileId: 'beta',
        runId: 'synthetic-current-run',
      );
      queue.add(current);
      expect(queue.activeFor('sess_1'), [current]);
      await queue.resolve(HermesApprovalDecision.once, current);
      expect(
        channel.respondToApprovalCalls.single['approvalId'],
        'synthetic-current',
      );
      expect(
        channel.respondToApprovalCalls.single['runId'],
        'synthetic-current-run',
      );
      expect(channel.stopActiveTurnCalls, 0);
      expect(channel.sentImageDataUrls, isEmpty);
    },
  );
}
