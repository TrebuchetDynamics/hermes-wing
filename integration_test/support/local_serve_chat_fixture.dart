import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'local_serve_read_fixture.dart';

/// Deterministic wire fixture, not an Agent authentication/inference substitute.
class LocalServeChatFixture extends LocalServeReadFixture {
  final sockets = <WebSocket>[];
  final rpc = <Map<String, dynamic>>[];
  final tickets = <String>{};
  int minted = 0, sequence = 0;
  bool denyTicket = false,
      exclusive = true,
      dropSubmit = false,
      denySubmit = false;
  bool holdSubmit = false;
  bool running = false, denyHistory = false, dropStop = false;
  Completer<void>? holdHistory;
  Completer<void>? submitHeld;
  String? resumedProfile;
  final canonical = <Map<String, Object>>[];
  int count(String method) => rpc.where((r) => r['method'] == method).length;

  @override
  Future<bool> handleExtra(HttpRequest request) async {
    if (request.uri.path == '/api/auth/ws-ticket') {
      if (denyTicket ||
          request.method != 'POST' ||
          request.headers.value('Authorization') !=
              'Bearer ${LocalServeReadFixture.token}') {
        request.response.statusCode = 401;
      } else {
        final ticket = 'synthetic-ticket-${++minted}';
        tickets.add(ticket);
        request.response.write(
          jsonEncode({'ticket': ticket, 'ttl_seconds': 30}),
        );
      }
      await request.response.close();
      return true;
    }
    if (request.uri.path != '/api/ws') return false;
    final protocols =
        request.headers
            .value('Sec-WebSocket-Protocol')
            ?.split(',')
            .map((s) => s.trim())
            .toList() ??
        [];
    final ticketProtocols = protocols
        .where((s) => s.startsWith('hermes-gateway-ticket.'))
        .toList();
    if (request.uri.hasQuery ||
        !protocols.contains('hermes-gateway-v1') ||
        ticketProtocols.length != 1 ||
        !tickets.remove(
          ticketProtocols.single.substring('hermes-gateway-ticket.'.length),
        )) {
      request.response.statusCode = 403;
      await request.response.close();
      return true;
    }
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
            'replay_epoch': 'fixture-epoch',
          },
        },
      }),
    );
    var profile = 'default';
    var stored = 'default-session';
    ws.listen((raw) async {
      final frame = jsonDecode(raw as String) as Map<String, dynamic>;
      if (frame['method'] == null) return;
      rpc.add(frame);
      final params = frame['params'] as Map;
      final method = frame['method'];
      Map<String, Object?> result;
      switch (method) {
        case 'gateway.capabilities':
          result = {'per_session_exclusive_submit': exclusive};
        case 'client.capabilities':
          result = {
            'server_requests': ['approval'],
            'declines_not_shown': true,
          };
        case 'session.resume':
          profile = params['profile'] as String;
          stored = params['session_id'] as String;
          result = {
            'session_id': 'runtime-$stored',
            'stored_session_id': stored,
            'info': {'profile_name': resumedProfile ?? profile},
            'running': running,
          };
        case 'session.history':
          if (denyHistory) {
            ws.add(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': frame['id'],
                'error': {'code': 4001, 'message': 'Denied'},
              }),
            );
            return;
          }
          await holdHistory?.future;
          result = {'count': canonical.length, 'messages': canonical};
        case 'session.events.since':
          result = {
            'epoch': 'fixture-epoch',
            'latest_seq': sequence,
            'events': [],
            'count': 0,
            'truncated': false,
            'open_requests': [],
          };
        case 'prompt.submit':
          if (params['profile'] != profile ||
              params['session_id'] != 'runtime-$stored') {
            throw StateError('Fixture rejected retargeted send.');
          }
          if (denySubmit) {
            ws.add(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': frame['id'],
                'error': {'code': 4001, 'message': 'Denied'},
              }),
            );
            return;
          }
          canonical.add({
            'role': 'user',
            'text': params['text'] as String,
            'row_id': canonical.length + 1,
          });
          if (dropSubmit) {
            await ws.close();
            return;
          }
          if (holdSubmit) {
            submitHeld ??= Completer<void>();
            await submitHeld!.future;
          }
          result = {'status': 'streaming'};
        case 'approval.respond':
          result = {'resolved': 1};
        case 'session.interrupt':
          if (dropStop) {
            await ws.close();
            return;
          }
          result = {'status': 'interrupted'};
        default:
          ws.add(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': frame['id'],
              'error': {'code': -32601, 'message': 'Unsupported'},
            }),
          );
          return;
      }
      ws.add(
        jsonEncode({'jsonrpc': '2.0', 'id': frame['id'], 'result': result}),
      );
    });
    return true;
  }

  void event(
    String type,
    Map<String, Object?> payload, {
    String session = 'default-session',
    int? seq,
  }) {
    final next = seq ?? ++sequence;
    sockets.last.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'method': 'event',
        'params': {
          'type': type,
          'session_id': 'runtime-$session',
          'seq': next,
          'payload': payload,
        },
      }),
    );
  }

  void approval({
    String id = 'queue-fixture',
    String serverId = 'srq-fixture',
    String session = 'default-session',
  }) {
    sockets.last.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': serverId,
        'method': 'approval',
        'params': {
          'session_id': 'runtime-$session',
          'request_id': id,
          'command': 'synthetic bounded operation',
          'description': 'Approve fixture operation',
          'choices': ['once', 'deny'],
        },
      }),
    );
  }

  @override
  Future<void> close() async {
    if (submitHeld != null && !submitHeld!.isCompleted) submitHeld!.complete();
    for (final ws in sockets) {
      await ws.close();
    }
    await super.close();
  }
}
