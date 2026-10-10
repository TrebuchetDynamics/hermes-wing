import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';

import '../../test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart'
    as reference;

/// Deterministic transport seam only: no Agent, sockets, credentials or tools.
class TranscriptRecoveryNativeFixture {
  final history = reference.ReconnectFixture();
  final decisions = <Map<String, Object?>>[];
  final mutations = <String>[];
  final reads = <String>[];
  final streams = <StreamController<String>>[];
  bool canonical = false;
  final completedRuns = <String>{};
  bool failNext = false;
  Completer<void>? gate;
  late final channel = HermesApiChannel(
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, headers) async {
        reads.add(uri.path);
        history.canonical = canonical;

        return switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => jsonEncode({
            'object': 'hermes.api_server.capabilities',
            'schema_version': 1,
            'features': {
              'run_submission': true,
              'run_events_sse': true,
              'run_approval_response': true,
              'run_status': true,
              'run_stop': true,
            },
            'endpoints': {
              'sessions': {'method': 'GET', 'path': '/api/sessions'},
              'session_messages': {
                'method': 'GET',
                'path': '/api/sessions/{session_id}/messages',
              },
              'runs': {'method': 'POST', 'path': '/v1/runs'},
              'run_events': {
                'method': 'GET',
                'path': '/v1/runs/{run_id}/events',
              },
              'run_status': {'method': 'GET', 'path': '/v1/runs/{run_id}'},
              'run_approval': {
                'method': 'POST',
                'path': '/v1/runs/{run_id}/approval',
              },
              'run_stop': {'method': 'POST', 'path': '/v1/runs/{run_id}/stop'},
            },
          }),
          '/api/sessions' => jsonEncode({
            'data': [
              {
                'id': reference.session,
                'source': 'synthetic',
                'title': 'Synthetic recovery',
              },
            ],
          }),
          '/api/sessions/${reference.session}/messages' => jsonEncode({
            'object': 'list',
            'session_id': reference.session,
            'data': canonical ? history.history : [],
          }),
          '/v1/runs/run_1' => jsonEncode({
            'run_id': 'run_1',
            'session_id': reference.session,
            'status': canonical ? 'completed' : 'running',
          }),
          final path when RegExp(r'^/v1/runs/run_[2-5]$').hasMatch(path) =>
            jsonEncode({
              'run_id': path.split('/').last,
              'session_id': reference.session,
              'status': completedRuns.contains(path.split('/').last)
                  ? 'completed'
                  : 'running',
            }),
          _ => throw StateError('Unexpected synthetic read'),
        };
      },
      post: (uri, headers, body) async {
        mutations.add(uri.path);
        if (uri.path == '/v1/runs') {
          return jsonEncode({
            'run_id': 'run_${streams.length + 1}',
            'session_id': reference.session,
          });
        }
        if (!uri.path.endsWith('/approval')) {
          throw StateError('Forbidden synthetic mutation');
        }
        decisions.add({
          'path': uri.path,
          ...jsonDecode(body) as Map<String, dynamic>,
        });
        final pending = gate;
        gate = null;
        final fail = failNext;
        failNext = false;
        await pending?.future;
        if (fail) throw StateError('Synthetic approval failure');
        return '{}';
      },
      getStream: (uri, headers) {
        final stream = StreamController<String>();
        streams.add(stream);
        return stream.stream;
      },
    ),
  );

  void event(String name, Map<String, Object?> data) =>
      streams.last.add('event: $name\ndata: ${jsonEncode(data)}\n\n');

  Future<void> prelude() async {
    await pumpEventQueue();
    event('message.delta', {'delta': reference.commentary});
    for (final tool in ['read_file', 'web_search']) {
      event('tool.started', {'tool': tool, 'tool_call_id': tool});
      event('tool.completed', {
        'tool': tool,
        'tool_call_id': tool,
        'result_text': reference.hidden,
      });
    }
    event('approval.request', {
      'run_id': 'run_${streams.length}',
      'request_id': 'request_${streams.length}',
      'session_id': reference.session,
      'description': 'Synthetic pending approval',
      'choices': ['once', 'deny'],
    });
    await pumpEventQueue();
  }

  Future<void> complete() async {
    completedRuns.add('run_${streams.length}');
    event('run.completed', {
      'run_id': 'run_${streams.length}',
      'session_id': reference.session,
      'status': 'completed',
    });
    await pumpEventQueue();
  }

  Future<void> dispose() async {
    channel.dispose();
    await history.dispose();
    for (final stream in streams) {
      await stream.close();
    }
  }
}
