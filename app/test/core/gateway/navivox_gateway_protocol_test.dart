import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_client.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';

void main() {
  test('constructs HTTP and WebSocket URLs from one base URL', () {
    final config = NavivoxGatewayConfig.fromBaseUrl(
      'https://gromit.tailnet.test:8765',
      token: 'nvbx_test_token',
    );

    expect(
      config.healthUri.toString(),
      'https://gromit.tailnet.test:8765/healthz',
    );
    expect(
      config.statusUri.toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/status',
    );
    expect(
      config.turnUri.toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/turn',
    );
    expect(
      config.profileContactsUri.toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/profile-contacts',
    );
    expect(
      config.streamUri.toString(),
      'wss://gromit.tailnet.test:8765/v1/navivox/stream',
    );
    expect(config.headers, {'Authorization': 'Bearer nvbx_test_token'});
  });

  test('builds typed gateway messages', () {
    final start = NavivoxGatewayMessage.startTurn(
      requestId: 'req-1',
      sessionId: 's-1',
      text: 'hello',
    );
    expect(start.body['type'], 'start_turn');
    expect(start.body['request_id'], 'req-1');
    expect(start.body['session_id'], 's-1');
    expect(start.body['text'], 'hello');

    final ping = NavivoxGatewayMessage.ping(requestId: 'req-ping');
    expect(jsonEncode(ping.body), '{"type":"ping","request_id":"req-ping"}');
  });

  test('parses typed gateway events', () {
    final event = NavivoxGatewayEvent.fromJson({
      'type': 'tool_call_finished',
      'request_id': 'req-2',
      'session_id': 's-2',
      'tool_name': 'read_file',
      'tool_call_id': 'tool-1',
      'status': 'ok',
    });

    expect(event.type, 'tool_call_finished');
    expect(event.requestId, 'req-2');
    expect(event.sessionId, 's-2');
    expect(event.toolName, 'read_file');
    expect(event.toolCallId, 'tool-1');
    expect(event.status, 'ok');
    expect(event.isError, isFalse);
  });

  test('parses safety and approval event fields', () {
    final warning = NavivoxGatewayEvent.fromJson({
      'type': 'safety_warning',
      'request_id': 'req-safe',
      'session_id': 's-safe',
      'safety_id': 'safe-1',
      'severity': 'high',
      'message': 'Shell command wants to modify files',
      'risk': 'Writes may change the workspace',
    });
    expect(warning.safetyId, 'safe-1');
    expect(warning.severity, 'high');
    expect(warning.message, 'Shell command wants to modify files');
    expect(warning.risk, 'Writes may change the workspace');

    final approval = NavivoxGatewayEvent.fromJson({
      'type': 'approval_required',
      'request_id': 'req-safe',
      'session_id': 's-safe',
      'approval_id': 'approval-1',
      'tool_call_id': 'call-shell',
      'message': 'Approve shell.run?',
      'risk': 'Command can edit files',
    });
    expect(approval.approvalId, 'approval-1');
    expect(approval.toolCallId, 'call-shell');
    expect(approval.message, 'Approve shell.run?');
    expect(approval.risk, 'Command can edit files');
  });

  test('client sends auth headers and decodes status capabilities', () async {
    final seen = <Uri, Map<String, String>>{};
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      get: (uri, headers) async {
        seen[uri] = headers;
        return jsonEncode({
          'enabled': true,
          'protocol_version': 'navivox.v1',
          'websocket_protocols': ['navivox.v1', 'gormes.navivox.v1'],
          'capabilities': ['profile_contacts', 'stream_turns', 'turn_control'],
        });
      },
    );

    final status = await client.gatewayStatus();

    expect(status.enabled, isTrue);
    expect(status.protocolVersion, 'navivox.v1');
    expect(status.websocketProtocols, ['navivox.v1', 'gormes.navivox.v1']);
    expect(status.supports('profile_contacts'), isTrue);
    expect(status.supports('turn_control'), isTrue);
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/status',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
  });

  test(
    'client decodes WebSocket event stream and exposes bounded backoff',
    () async {
      final client = NavivoxGatewayClient(
        config: NavivoxGatewayConfig.fromBaseUrl('http://127.0.0.1:8765'),
      );
      final stream = Stream<dynamic>.fromIterable([
        '{"type":"pong","request_id":"req-ping"}',
        {'type': 'error', 'code': 'bad_request', 'message': 'Invalid JSON'},
      ]);

      final events = await client.decodeEvents(stream).toList();

      expect(events.first.type, 'pong');
      expect(events.first.requestId, 'req-ping');
      expect(events.last.isError, isTrue);
      expect(events.last.code, 'bad_request');
      expect(client.reconnectDelay(0), const Duration(milliseconds: 250));
      expect(client.reconnectDelay(10), const Duration(seconds: 16));
    },
  );
}
