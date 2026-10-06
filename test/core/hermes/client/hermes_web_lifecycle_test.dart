import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_web_read_client.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';

// Deterministic wire behavior only, not native generation or live approvals.
class LifecycleFixture {
  late HttpServer server;
  final sockets = <WebSocket>[];
  final requests = <Map<String, dynamic>>[];
  int tickets = 0, sequence = 0;
  String epoch = 'fixture-epoch';
  bool truncate = false, dropSubmit = false, delaySubmit = false;
  int resolved = 1;
  List<Map<String, Object>> history = [];
  Map<String, dynamic>? held;
  List<Map<String, Object>> open = [];
  List<Map<String, Object>> replay = [];
  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/api/auth/ws-ticket') {
        tickets++;
        request.response.write(
          jsonEncode({'ticket': 'fixture-$tickets', 'ttl_seconds': 30}),
        );
        await request.response.close();
        return;
      }
      expect(request.uri.query, isEmpty);
      final ws = await WebSocketTransformer.upgrade(
        request,
        protocolSelector: (_) => 'hermes-gateway-v1',
      );
      sockets.add(ws);
      ws.add(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'event',
          'params': {
            'type': 'gateway.ready',
            'payload': {
              'change_events': true,
              'heartbeat': true,
              'replay_epoch': epoch,
            },
          },
        }),
      );
      ws.listen((raw) {
        final rpc = jsonDecode(raw as String) as Map<String, dynamic>;
        if (rpc['method'] == null) {
          return; // typed unsupported server-request reply
        }
        requests.add(rpc);
        final params = rpc['params'] as Map;
        final method = rpc['method'];
        if (method != 'client.capabilities') {
          expect(params['profile'], 'default');
        }
        Map<String, Object?> result;
        switch (method) {
          case 'client.capabilities':
            result = {'ok': true};
          case 'session.create':
          case 'session.resume':
            result = {
              'session_id': 'runtime-fixture',
              'stored_session_id': 'stored-fixture',
              'info': {'profile_name': 'default'},
              'messages': [],
              'message_count': history.length,
            };
          case 'session.history':
            result = {'count': history.length, 'messages': history};
          case 'session.events.since':
            result = {
              'events': replay,
              'count': replay.length,
              'epoch': epoch,
              'truncated': truncate,
              'latest_seq': sequence,
              'open_requests': open,
            };
          case 'prompt.submit':
            if (dropSubmit) {
              unawaited(ws.close());
              return;
            }
            if (delaySubmit) {
              held = rpc;
              return;
            }
            result = {'status': 'streaming'};
          case 'session.interrupt':
            result = {'status': 'interrupted'};
          case 'approval.respond':
            expect(params['all'], false);
            expect(params['choice'], isIn(['once', 'deny']));
            result = {'resolved': resolved};
          default:
            throw StateError('Unexpected fixture method');
        }
        reply(ws, rpc, result);
      });
    });
  }

  void reply(WebSocket ws, Map rpc, Map result) =>
      ws.add(jsonEncode({'jsonrpc': '2.0', 'id': rpc['id'], 'result': result}));
  HermesWebReadClient client() => HermesWebReadClient.forQualification(
    origin: Uri.parse('http://127.0.0.1:${server.port}'),
    credential: 'fixture-owned-auth',
    profile: 'default',
    timeout: const Duration(seconds: 2),
  );
  void event(
    String type,
    Map<String, Object> payload, {
    String session = 'runtime-fixture',
    String? profile,
    int? seq,
  }) {
    sockets.last.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'method': 'event',
        'params': {
          'type': type,
          'session_id': session,
          'seq': seq ?? ++sequence,
          'profile': ?profile,
          'payload': payload,
        },
      }),
    );
  }

  void approval({
    String session = 'runtime-fixture',
    String id = 'queue-fixture',
  }) {
    sockets.last.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'method': 'approval',
        'id': 'srq-fixture',
        'params': {'session_id': session, 'request_id': id},
      }),
    );
  }

  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 30));
  Future<void> close() async {
    for (final ws in sockets) {
      await ws.close();
    }
    await server.close(force: true);
  }
}

void main() {
  late LifecycleFixture fixture;
  late HermesWebReadClient client;
  late HermesWebLifecycle adapter;
  setUp(() async {
    fixture = LifecycleFixture();
    await fixture.start();
    client = fixture.client();
    adapter = await client.connectLifecycleForQualification();
    await adapter.createSession();
  });
  tearDown(() async {
    client.disconnect();
    await fixture.close();
  });

  test(
    'acceptance, streamed shared turns, completion and canonical replacement',
    () async {
      expect(adapter.runtimeSessionId, isNot(adapter.storedSessionId));
      expect(
        adapter.productAuthorization,
        HermesWebProductAuthorization.unsupportedAuthorization,
      );
      await adapter.submitText('Deterministic user fixture');
      expect(adapter.submission, HermesWebSubmission.accepted);
      expect(
        adapter.turns.where((t) => t.author == HermesTurnAuthor.assistant),
        isEmpty,
      );
      fixture.event('message.delta', {'text': 'synthetic chunk'});
      fixture.event('reasoning.delta', {'text': 'synthetic reasoning'});
      fixture.event('tool.start', {
        'tool_id': 'fixture-tool',
        'name': 'fixture',
      });
      fixture.event('tool.complete', {
        'tool_id': 'fixture-tool',
        'name': 'fixture',
      });
      await fixture.flush();
      expect(
        adapter.turns.any(
          (t) =>
              t.kind == HermesTurnKind.toolCall &&
              t.toolCall?.status == 'completed',
        ),
        true,
      );
      expect(
        adapter.turns.any(
          (t) =>
              t.text == 'synthetic chunk' &&
              t.status == HermesTurnStatus.streaming,
        ),
        true,
      );
      fixture.event('message.complete', {
        'text': 'synthetic final',
        'status': 'complete',
      });
      await fixture.flush();
      expect(adapter.submission, HermesWebSubmission.terminal);
      expect(adapter.canSubmit, false);
      fixture.history = [
        {'role': 'user', 'text': 'Deterministic user fixture', 'row_id': 1},
        {'role': 'assistant', 'text': 'canonical fixture', 'row_id': 2},
      ];
      await adapter.reconcileActiveSession();
      expect(adapter.turns.map((t) => t.id), ['row-1', 'row-2']);
      expect(adapter.turns.last.text, 'canonical fixture');
      expect(adapter.canSubmit, true);
    },
  );

  test('wrong session/profile and duplicate events cannot append', () async {
    await adapter.submitText('Fixture');
    fixture.event(
      'message.delta',
      {'text': 'wrong'},
      session: 'other-runtime',
      seq: 1,
    );
    fixture.event(
      'message.delta',
      {'text': 'wrong'},
      profile: 'other-profile',
      seq: 1,
    );
    fixture.event('message.delta', {'text': 'one'}, seq: 1);
    fixture.event('message.delta', {'text': 'duplicate'}, seq: 1);
    await fixture.flush();
    expect(adapter.turns.last.text, 'one');
  });

  test(
    'approval exact correlation, least privilege and authoritative outcome',
    () async {
      fixture.approval(session: 'other-runtime');
      await fixture.flush();
      expect(adapter.approvalRequestIds, isEmpty);
      fixture.approval();
      await fixture.flush();
      expect(adapter.approvalRequestIds, {'queue-fixture'});
      await expectLater(
        adapter.respondToApproval('wrong', HermesWebApprovalChoice.once),
        throwsA(isA<HermesWebReadException>()),
      );
      fixture.resolved = 0;
      await expectLater(
        adapter.respondToApproval(
          'queue-fixture',
          HermesWebApprovalChoice.deny,
        ),
        throwsA(isA<HermesWebReadException>()),
      );
      expect(adapter.approvalRequestIds, {'queue-fixture'});
      fixture.resolved = 1;
      await adapter.respondToApproval(
        'queue-fixture',
        HermesWebApprovalChoice.once,
      );
      expect(adapter.approvalRequestIds, isEmpty);
      final params = fixture.requests.last['params'] as Map;
      expect(params['session_id'], 'runtime-fixture');
      expect(params['request_id'], 'queue-fixture');
    },
  );

  test(
    'interrupt racing completion does not manufacture completion or send again',
    () async {
      await adapter.submitText('Fixture');
      expect(await adapter.interrupt(), true);
      expect(adapter.submission, HermesWebSubmission.accepted);
      fixture.event('message.delta', {'text': 'late cancel chunk'});
      await fixture.flush();
      expect(adapter.turns.length, 1);
      fixture.event('message.complete', {
        'text': 'partial fixture',
        'status': 'interrupted',
      });
      await fixture.flush();
      expect(adapter.turns.last.status, HermesTurnStatus.failed);
      expect(adapter.canSubmit, false);
      expect(
        fixture.requests.where((r) => r['method'] == 'prompt.submit').length,
        1,
      );
    },
  );

  test('completion before delayed acknowledgment remains terminal', () async {
    fixture.delaySubmit = true;
    final send = adapter.submitText('Fixture');
    await fixture.flush();
    fixture.event('message.complete', {
      'text': 'fixture',
      'status': 'complete',
    });
    await fixture.flush();
    fixture.reply(fixture.sockets.last, fixture.held!, {'status': 'streaming'});
    await send;
    expect(adapter.submission, HermesWebSubmission.terminal);
  });

  test(
    'uncertain submission reconnect gets fresh ticket, canonical state, no mutation replay',
    () async {
      fixture.dropSubmit = true;
      await expectLater(
        adapter.submitText('Fixture'),
        throwsA(isA<HermesWebReadException>()),
      );
      expect(adapter.submission, HermesWebSubmission.uncertain);
      final checkpoint = adapter.recovery;
      final replacement = await client.connectLifecycleForQualification();
      await replacement.recover(checkpoint);
      expect(fixture.tickets, 2);
      expect(replacement.submission, HermesWebSubmission.uncertain);
      expect(replacement.canSubmit, false);
      expect(
        fixture.requests.where((r) => r['method'] == 'prompt.submit').length,
        1,
      );
    },
  );

  test(
    'changed epoch and truncated replay use canonical history only',
    () async {
      final checkpoint = adapter.recovery;
      fixture.history = [
        {'role': 'assistant', 'text': 'Canonical fixture', 'row_id': 9},
      ];
      fixture.epoch = 'replacement-epoch';
      fixture.truncate = true;
      final replacement = await client.connectLifecycleForQualification();
      await replacement.recover(checkpoint);
      expect(replacement.turns.single.id, 'row-9');
      expect(
        fixture.requests.where((r) => r['method'] == 'prompt.submit'),
        isEmpty,
      );
    },
  );

  test(
    'session switch invalidates pending acceptance and old approvals',
    () async {
      fixture.approval();
      await fixture.flush();
      fixture.delaySubmit = true;
      final sending = adapter.submitText('Fixture');
      final rejection = expectLater(
        sending,
        throwsA(isA<HermesWebReadException>()),
      );
      await fixture.flush();
      await adapter.resumeSession('stored-fixture');
      fixture.reply(fixture.sockets.last, fixture.held!, {
        'status': 'streaming',
      });
      await rejection;
      expect(adapter.approvalRequestIds, isEmpty);
      expect(adapter.turns, isEmpty);
    },
  );

  test(
    'sequence gap requires reconciliation rather than partial projection',
    () async {
      await adapter.submitText('Fixture');
      fixture.event('message.delta', {'text': 'missing prefix'}, seq: 3);
      await fixture.flush();
      expect(adapter.needsReconciliation, true);
      expect(adapter.turns.length, 1);
    },
  );

  test('recovery checkpoint cannot cross origin or profile', () async {
    final checkpoint = adapter.recovery;
    for (final wrong in [
      HermesWebRecovery(
        profile: 'other',
        origin: checkpoint.origin,
        runtimeSessionId: checkpoint.runtimeSessionId,
        storedSessionId: checkpoint.storedSessionId,
        epoch: checkpoint.epoch,
        sequence: 0,
        uncertain: false,
      ),
      HermesWebRecovery(
        profile: checkpoint.profile,
        origin: Uri.parse('http://127.0.0.1:1'),
        runtimeSessionId: checkpoint.runtimeSessionId,
        storedSessionId: checkpoint.storedSessionId,
        epoch: checkpoint.epoch,
        sequence: 0,
        uncertain: false,
      ),
    ]) {
      await expectLater(
        adapter.recover(wrong),
        throwsA(isA<HermesWebReadException>()),
      );
    }
    expect(
      fixture.requests.where((r) => r['method'] == 'session.resume'),
      isEmpty,
    );
  });

  test(
    'canonical recovery rehydrates correlated open approval requests',
    () async {
      fixture.open = [
        {
          'id': 'srq-replay',
          'method': 'approval',
          'params': {
            'session_id': 'runtime-fixture',
            'request_id': 'queue-replay',
          },
        },
      ];
      await adapter.reconcileActiveSession();
      expect(adapter.approvalRequestIds, {'queue-replay'});
      await adapter.respondToApproval(
        'queue-replay',
        HermesWebApprovalChoice.deny,
      );
      expect(adapter.approvalRequestIds, isEmpty);
    },
  );

  test(
    'changed replay epoch stays fail closed and duplicate replay is malformed',
    () async {
      fixture.epoch = 'different-from-ready';
      await adapter.reconcileActiveSession();
      expect(adapter.needsReconciliation, true);
      expect(adapter.canSubmit, false);
      fixture.sequence = 1;
      fixture.replay = [
        {
          'type': 'message.delta',
          'session_id': 'runtime-fixture',
          'seq': 1,
          'payload': {'text': 'fixture'},
        },
        {
          'type': 'message.delta',
          'session_id': 'runtime-fixture',
          'seq': 1,
          'payload': {'text': 'duplicate'},
        },
      ];
      await expectLater(
        adapter.reconcileActiveSession(),
        throwsA(isA<HermesWebReadException>()),
      );
      expect(adapter.canSubmit, false);
    },
  );
}
