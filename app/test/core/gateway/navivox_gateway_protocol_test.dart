import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_client.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';

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
      config
          .memoryOverviewUri(serverId: 'local', profileId: 'mineru')
          .toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/memory/overview?server_id=local&profile_id=mineru',
    );
    expect(
      config
          .memorySearchUri(
            serverId: 'local',
            profileId: 'mineru',
            query: 'agent memory',
            type: NavivoxMemoryType.memoryItems,
            limit: 10,
          )
          .toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/memory/search?server_id=local&profile_id=mineru&q=agent+memory&type=memory_items&limit=10',
    );
    expect(
      config
          .memoryDetailUri(
            serverId: 'local',
            profileId: 'mineru',
            id: 'mem-1',
            type: NavivoxMemoryType.memoryItems,
          )
          .toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/memory/detail?server_id=local&profile_id=mineru&id=mem-1&type=memory_items',
    );
    expect(
      config.memoryActionUri.toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/memory/action',
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
    'client decodes authenticated memory overview with safe DB label',
    () async {
      final seen = <Uri, Map<String, String>>{};
      final client = NavivoxGatewayClient(
        config: NavivoxGatewayConfig.fromBaseUrl(
          'http://127.0.0.1:8765',
          token: 'nvbx_test_token',
        ),
        get: (uri, headers) async {
          seen[uri] = headers;
          return jsonEncode({
            'profile_id': 'mineru',
            'workspace_id': 'gormes',
            'database_path': '/home/xel/.gormes/profiles/mineru/memory.db',
            'health': 'active',
            'last_updated_at': '2026-05-21T15:28:18.000Z',
            'counts': {
              'turns': 120,
              'memory_items': 12,
              'observations': 34,
              'conclusions': 5,
              'session_summaries': 7,
              'entities': 18,
              'relationships': 21,
            },
          });
        },
      );

      final overview = await client.memoryOverview(
        serverId: 'local',
        profileId: 'mineru',
      );

      expect(overview.profileId, 'mineru');
      expect(overview.workspaceId, 'gormes');
      expect(overview.health, NavivoxMemoryHealth.active);
      expect(overview.totalTurns, 120);
      expect(overview.activeMemoryItems, 12);
      expect(overview.databaseLabel, '~/.gormes/profiles/mineru/memory.db');
      expect(overview.databaseLabel, isNot(contains('/home/xel')));
      expect(
        seen.keys.single.toString(),
        'http://127.0.0.1:8765/v1/navivox/memory/overview?server_id=local&profile_id=mineru',
      );
      expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
    },
  );

  test('client decodes authenticated memory search results', () async {
    final seen = <Uri, Map<String, String>>{};
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      get: (uri, headers) async {
        seen[uri] = headers;
        return jsonEncode({
          'items': [
            {
              'id': 'mem-1',
              'type': 'memory_items',
              'snippet': 'Mineru uses Goncho memory for workspace recall.',
              'timestamp': '2026-05-21T15:30:00Z',
              'session_id': 's-1',
              'peer_id': 'mineru',
              'status': 'current',
              'tags': ['workspace', 'recall'],
              'score': 0.92,
            },
          ],
          'next_page_token': 'cursor-2',
        });
      },
    );

    final result = await client.memorySearch(
      serverId: 'local',
      profileId: 'mineru',
      query: 'Goncho memory',
      type: NavivoxMemoryType.memoryItems,
      limit: 10,
    );

    expect(result.items, hasLength(1));
    expect(result.items.single.id, 'mem-1');
    expect(result.items.single.type, NavivoxMemoryType.memoryItems);
    expect(result.items.single.snippet, contains('Goncho memory'));
    expect(result.items.single.tags, ['workspace', 'recall']);
    expect(result.nextPageToken, 'cursor-2');
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/memory/search?server_id=local&profile_id=mineru&q=Goncho+memory&type=memory_items&limit=10',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
  });

  test('client decodes authenticated memory detail safely', () async {
    final seen = <Uri, Map<String, String>>{};
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      get: (uri, headers) async {
        seen[uri] = headers;
        return jsonEncode({
          'id': 'mem-1',
          'type': 'memory_items',
          'content': 'Mineru uses Goncho memory for workspace recall.',
          'source': 'goncho_memory_items',
          'session_id': 's-1',
          'peer_id': 'mineru',
          'created_at': '2026-05-21T15:30:00Z',
          'status': 'current',
          'tags': ['workspace'],
          'provenance': 'derived from reviewed session s-1',
          'linked_entities': ['Mineru', 'Goncho'],
          'linked_relationships': ['Mineru RELATED_TO Goncho'],
        });
      },
    );

    final detail = await client.memoryDetail(
      serverId: 'local',
      profileId: 'mineru',
      id: 'mem-1',
      type: NavivoxMemoryType.memoryItems,
    );

    expect(detail.id, 'mem-1');
    expect(detail.type, NavivoxMemoryType.memoryItems);
    expect(detail.content, contains('workspace recall'));
    expect(detail.provenance, contains('reviewed session'));
    expect(detail.linkedEntities, ['Mineru', 'Goncho']);
    expect(detail.linkedRelationships, ['Mineru RELATED_TO Goncho']);
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/memory/detail?server_id=local&profile_id=mineru&id=mem-1&type=memory_items',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
  });

  test('client sends authenticated memory management actions safely', () async {
    final seen = <Uri, Map<String, String>>{};
    final bodies = <Map<String, Object?>>[];
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      post: (uri, headers, body) async {
        seen[uri] = headers;
        bodies.add(Map<String, Object?>.from(jsonDecode(body) as Map));
        return jsonEncode({
          'accepted': true,
          'action': 'add_correction',
          'message': 'Correction added without mutating raw memory.',
          'raw_source_preserved': true,
        });
      },
    );

    final result = await client.memoryAction(
      serverId: 'local',
      profileId: 'mineru',
      id: 'mem-1',
      type: NavivoxMemoryType.memoryItems,
      action: NavivoxMemoryActionType.addCorrection,
      correction: 'Use Mineru profile memory only.',
    );

    expect(result.accepted, isTrue);
    expect(result.action, NavivoxMemoryActionType.addCorrection);
    expect(result.rawSourcePreserved, isTrue);
    expect(result.message, 'Correction added without mutating raw memory.');
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/memory/action',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
    expect(seen.values.single['Content-Type'], 'application/json');
    expect(bodies.single, {
      'server_id': 'local',
      'profile_id': 'mineru',
      'id': 'mem-1',
      'type': 'memory_items',
      'action': 'add_correction',
      'correction': 'Use Mineru profile memory only.',
    });
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
