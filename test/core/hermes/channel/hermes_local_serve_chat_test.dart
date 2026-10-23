import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_web_read_client.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';

import '../../../../integration_test/support/local_serve_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';

void main() {
  late LocalServeChatFixture fixture;
  late HermesApiChannel channel;
  setUp(() async {
    fixture = LocalServeChatFixture();
    addTearDown(() => fixture.close());
    await fixture.start();
    channel = HermesApiChannel();
    addTearDown(() => channel.dispose());
    await channel.connectLocalServeReads(
      baseUrl: fixture.origin,
      credential: LocalServeReadFixture.token,
    );
  });
  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 40));

  test(
    'product authorization belongs to the authenticated live ticket only',
    () async {
      final reader = HermesWebReadClient.forLocalReads(
        origin: Uri.parse(fixture.origin),
        credential: LocalServeReadFixture.token,
        profile: 'default',
      );
      addTearDown(reader.disconnect);
      expect(
        reader.productAuthorization,
        HermesWebProductAuthorization.unsupportedAuthorization,
      );
      final lifecycle =
          await reader.connectLifecycleForProduct() as HermesWebLifecycle;
      expect(
        lifecycle.productAuthorization,
        HermesWebProductAuthorization.authenticatedTicket,
      );
      reader.closeLifecycle();
      expect(
        lifecycle.productAuthorization,
        HermesWebProductAuthorization.unsupportedAuthorization,
      );
    },
  );

  test(
    'submission timeout preserves uncertainty and explicit recovery never replays',
    () async {
      await channel.enableLocalServeChat();
      fixture.holdSubmit = true;
      await expectLater(
        channel.sendText('timeout fixture'),
        throwsA(isA<HermesWebReadException>()),
      );
      expect(channel.state.serveChat!.canSubmit, false);
      expect(channel.state.hasUnreconciledRun, true);
      fixture.submitHeld!.complete();
      fixture.holdSubmit = false;
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat!.canSubmit, true);
      expect(fixture.count('prompt.submit'), 1);
      expect(channel.state.activeMessages.single.text, 'timeout fixture');
    },
  );

  test(
    'ticket denial and exact negotiation leave reads intact and writes off',
    () async {
      fixture.denyTicket = true;
      await channel.enableLocalServeChat();
      expect(channel.state.isConnected, true);
      expect(channel.state.serveChat, isNull);
      await expectLater(channel.sendText('not sent'), throwsStateError);
      fixture.denyTicket = false;
      fixture.exclusive = false;
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat, isNull);
      expect(fixture.count('prompt.submit'), 0);
      fixture.exclusive = true;
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat!.canSubmit, true);
      expect(channel.state.canCreateSessions, false);
      expect(channel.state.canUpdateSessions, false);
    },
  );

  test(
    'intentional Send ordered stream tools exact approval and idle withdrawal',
    () async {
      final approvals = <HermesApprovalRequest>[];
      final withdrawn = <HermesApprovalRequest>[];
      channel.approvalRequests.listen(approvals.add);
      channel.invalidatedApprovals.listen(withdrawn.add);
      await channel.enableLocalServeChat();
      fixture.approval();
      await flush();
      final stale = approvals.single;
      fixture.event('request.cancel', {'id': 'srq-fixture'});
      await flush();
      expect(withdrawn, contains(same(stale)));
      await expectLater(
        channel.respondToApproval(
          approvalId: stale.id,
          decision: HermesApprovalDecision.once,
          runId: stale.runId,
          origin: stale,
        ),
        throwsStateError,
      );
      expect(fixture.count('approval.respond'), 0);
      await channel.sendText('deliberate fixture');
      fixture.event('message.delta', {'text': 'ordered '});
      fixture.event('message.delta', {'text': 'text'});
      fixture.event('tool.start', {
        'tool_id': 'tool-fixture',
        'name': 'synthetic',
      });
      fixture.event('tool.complete', {
        'tool_id': 'tool-fixture',
        'name': 'synthetic',
      });
      fixture.approval(id: 'queue-current', serverId: 'srq-current');
      await flush();
      expect(
        channel.state.activeMessages
            .where((m) => m.kind == HermesTurnKind.text)
            .last
            .text,
        'ordered text',
      );
      expect(channel.state.activeMessages.last.kind, HermesTurnKind.toolCall);
      final request = approvals.last;
      await expectLater(
        channel.respondToApproval(
          approvalId: request.id,
          decision: HermesApprovalDecision.always,
          runId: request.runId,
          origin: request,
        ),
        throwsStateError,
      );
      await channel.respondToApproval(
        approvalId: request.id,
        decision: HermesApprovalDecision.once,
        runId: request.runId,
        origin: request,
      );
      expect(fixture.count('prompt.submit'), 1);
      expect(fixture.count('approval.respond'), 1);
      final answer = fixture.rpc.last['params'] as Map;
      expect(answer, {
        'profile': 'default',
        'session_id': 'runtime-default-session',
        'request_id': 'queue-current',
        'choice': 'once',
        'all': false,
      });
    },
  );

  test(
    'Stop captured target receipt is not terminal and no duplicate Stop',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await channel.enableLocalServeChat();
      final prepared = channel.beginSessionHistoryExport();
      await prepared.collect();
      final pending = channel.beginSessionHistoryExport();
      await channel.sendText('fixture');
      expect(prepared.isCurrent, isFalse);
      expect(channel.canExportSessionHistory, isFalse);
      await expectLater(
        pending.collect(),
        throwsA(isA<HermesWebReadException>()),
      );
      final target = channel.activeTurnInterruptionTarget!;
      expect(await channel.stopTurn(target), true);
      expect(channel.state.serveChat!.stopRequested, true);
      expect(channel.state.serveChat!.running, true);
      expect(channel.state.serveChat!.canSubmit, false);
      expect(await channel.stopTurn(target), false);
      fixture.event('message.complete', {
        'text': 'Stopped fixture',
        'status': 'interrupted',
      });
      await flush();
      expect(channel.state.serveChat!.running, false);
      expect(
        prepared.isCurrent,
        isFalse,
        reason: 'Run completion cannot revive old bytes',
      );
      expect(pending.isCurrent, isFalse);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
      expect(fixture.count('session.interrupt'), 1);
      await channel.enableLocalServeChat();
      expect(channel.state.serveChat!.canSubmit, true);
      expect(fixture.count('prompt.submit'), 1);
    },
  );

  test(
    'local close and uncertain send require explicit reconciliation without replay',
    () async {
      await channel.enableLocalServeChat();
      fixture.dropSubmit = true;
      await expectLater(
        channel.sendText('uncertain fixture'),
        throwsA(isA<Exception>()),
      );
      await flush();
      expect(channel.state.hasUnreconciledRun, true);
      expect(channel.state.serveChat!.canSubmit, false);
      await channel.reconcileActiveSession();
      expect(fixture.minted, 1);
      fixture.dropSubmit = false;
      await channel.enableLocalServeChat();
      expect(fixture.minted, 2);
      expect(fixture.count('prompt.submit'), 1);
      expect(channel.state.activeMessages.single.text, 'uncertain fixture');
      await channel.sendText('new deliberate fixture');
      channel.cancelActiveTurn();
      await flush();
      expect(channel.state.serveChat!.running, true);
      expect(channel.state.serveChat!.canSubmit, false);
      expect(fixture.count('session.interrupt'), 0);
    },
  );

  test(
    'session owner replacement rejects late acceptance and stale Stop',
    () async {
      await channel.enableLocalServeChat();
      fixture.holdSubmit = true;
      final send = channel.sendText('held fixture');
      final rejected = expectLater(send, throwsA(isA<Exception>()));
      await flush();
      final target = channel.activeTurnInterruptionTarget!;
      await channel.selectProfile('demo');
      fixture.submitHeld!.complete();
      await rejected;
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.serveChat, isNull);
      expect(await channel.stopTurn(target), false);
      expect(fixture.count('session.interrupt'), 0);
      expect(fixture.count('prompt.submit'), 1);
    },
  );

  test(
    'RPC denial and gap retain explicit recovery, never another submission',
    () async {
      await channel.enableLocalServeChat();
      fixture.denySubmit = true;
      await expectLater(
        channel.sendText('denied fixture'),
        throwsA(isA<Exception>()),
      );
      expect(channel.state.serveChat!.canSubmit, false);
      fixture.denySubmit = false;
      await channel.enableLocalServeChat();
      await channel.sendText('new fixture');
      fixture.event('message.delta', {'text': 'gap'}, seq: 3);
      await flush();
      expect(channel.state.hasUnreconciledRun, true);
      expect(channel.state.activeMessages.last.text, 'new fixture');
      expect(fixture.count('prompt.submit'), 2);
    },
  );
}
