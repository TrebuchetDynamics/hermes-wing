import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';

import 'local_serve_chat_fixture.dart';
import 'local_serve_read_journey.dart';

Future<Map<String, Object?>> runLocalServeChatJourney(
  WidgetTester tester,
) async {
  final fixture = LocalServeChatFixture();
  return runLocalServeReadJourney(
    tester,
    backend: fixture,
    afterConnected: (channel) async {
      Future<void> waitFor(bool Function() done) async {
        for (var i = 0; i < 150 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(done(), true, reason: 'Serve chat control did not settle');
      }

      Future<void> press(String key) async {
        final target = find.byKey(ValueKey(key));
        expect(target, findsOneWidget);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pump();
      }

      Future<void> send(String text) async {
        final field = find.byKey(const ValueKey('hermes-composer-field'));
        await tester.enterText(field, text);
        await tester.pump();
        await press('hermes-send-button');
      }

      fixture.denyTicket = true;
      await press('hermes-local-serve-chat');
      await waitFor(() => channel.state.errorMessage != null);
      expect(channel.state.serveChat, isNull);
      expect(fixture.count('prompt.submit'), 0);
      fixture.denyTicket = false;
      fixture.exclusive = false;
      await press('hermes-local-serve-chat');
      await waitFor(
        () =>
            fixture.count('gateway.capabilities') == 1 &&
            channel.state.errorMessage != null,
      );
      expect(channel.state.serveChat, isNull);
      fixture.exclusive = true;
      await press('hermes-local-serve-chat');
      await waitFor(() => channel.state.serveChat?.canSubmit == true);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('hermes-attachment-button')),
            )
            .onPressed,
        isNull,
      );
      final requests = <HermesApprovalRequest>[];
      final subscription = channel.approvalRequests.listen(requests.add);
      try {
        fixture.approval();
        await waitFor(
          () => find
              .byKey(const ValueKey('hermes-approval-banner'))
              .evaluate()
              .isNotEmpty,
        );
        final stale = requests.single;
        fixture.event('request.cancel', {'id': 'srq-fixture'});
        await waitFor(
          () => find
              .byKey(const ValueKey('hermes-approval-banner'))
              .evaluate()
              .isEmpty,
        );
        await tester.runAsync(
          () => expectLater(
            channel.respondToApproval(
              approvalId: stale.id,
              decision: HermesApprovalDecision.once,
              runId: stale.runId,
              origin: stale,
            ),
            throwsStateError,
          ),
        );
        expect(fixture.count('approval.respond'), 0);
        await send('deliberate production fixture');
        await waitFor(() => fixture.count('prompt.submit') == 1);
        fixture.event('message.delta', {'text': 'Ordered production '});
        fixture.event('message.delta', {'text': 'fixture'});
        fixture.event('tool.start', {
          'tool_id': 'tool-fixture',
          'name': 'synthetic',
        });
        fixture.event('tool.complete', {
          'tool_id': 'tool-fixture',
          'name': 'synthetic',
        });
        fixture.approval(id: 'queue-current', serverId: 'srq-current');
        await waitFor(
          () => find
              .byKey(const ValueKey('hermes-approval-once'))
              .evaluate()
              .isNotEmpty,
        );
        expect(find.text('Ordered production fixture'), findsWidgets);
        await press('hermes-approval-once');
        await waitFor(() => fixture.count('approval.respond') == 1);
        await press('hermes-composer-stop-chip');
        await waitFor(() => fixture.count('session.interrupt') == 1);
        expect(channel.state.serveChat!.running, true);
        expect(channel.state.serveChat!.stopRequested, true);
        fixture.event('message.complete', {
          'text': 'Authoritative stopped fixture',
          'status': 'interrupted',
        });
        await waitFor(() => channel.state.serveChat?.running == false);
        expect(find.text('Authoritative stopped fixture'), findsWidgets);
        await press('hermes-local-serve-chat');
        await waitFor(() => channel.state.serveChat?.canSubmit == true);
        fixture.dropSubmit = true;
        await send('uncertain production fixture');
        await waitFor(
          () => channel.state.serveChat?.needsReconciliation == true,
        );
        expect(channel.state.serveChat!.canSubmit, false);
        fixture.dropSubmit = false;
        await press('hermes-local-serve-chat');
        await waitFor(() => channel.state.serveChat?.canSubmit == true);
        expect(fixture.count('prompt.submit'), 2);
        expect(fixture.count('approval.respond'), 1);
        expect(fixture.count('session.interrupt'), 1);
        expect(tester.takeException(), isNull);

        return {
          'mutations': 4,
          'sends': fixture.count('prompt.submit'),
          'answers': fixture.count('approval.respond'),
          'stops': fixture.count('session.interrupt'),
          'rpc_requests': fixture.rpc.length,
          'tickets': fixture.minted,
          'chat_auth_denied': true,
          'chat_unsupported': true,
          'idle_withdrawal': true,
          'stale_answers': 0,
          'authoritative_stop': true,
          'uncertain_recovery_without_replay': true,
        };
      } finally {
        await tester.runAsync(subscription.cancel);
      }
    },
  );
}
