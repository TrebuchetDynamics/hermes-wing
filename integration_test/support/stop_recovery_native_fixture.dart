import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';

import '../../test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart'
    as reference;

/// Synthetic HTTP/SSE seams; no sockets, credentials, Agent or provider.
class StopRecoveryNativeFixture {
  final reads = <String>[];
  final mutations = <String>[];
  final streams = <StreamController<String>>[];
  final terminal = <String>{};
  String outcome = 'stopping';
  bool failStop = false;
  bool failStatus = false;
  bool failHistory = false;
  bool wrongRun = false;
  Completer<void>? stopGate;
  int submits = 0;
  late final channel = HermesApiChannel(clientBuilder: client);

  HermesApiClient client(HermesApiConfig config) => HermesApiClient(
    config: config,
    get: (uri, headers) async {
      reads.add(uri.path);
      if (uri.path == '/health') return '{"status":"ok"}';
      if (uri.path == '/v1/capabilities') {
        return jsonEncode({
          'object': 'hermes.api_server.capabilities',
          'schema_version': 1,
          'features': {
            'run_submission': true,
            'run_events_sse': true,
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
            'run_events': {'method': 'GET', 'path': '/v1/runs/{run_id}/events'},
            'run_status': {'method': 'GET', 'path': '/v1/runs/{run_id}'},
            'run_stop': {'method': 'POST', 'path': '/v1/runs/{run_id}/stop'},
          },
        });
      }
      if (uri.path == '/api/sessions') {
        return jsonEncode({
          'data': [
            {'id': reference.session, 'title': 'Synthetic Stop recovery'},
          ],
        });
      }
      if (uri.path == '/api/sessions/${reference.session}/messages') {
        if (failHistory) throw StateError('Synthetic history read failure');
        return jsonEncode({
          'object': 'list',
          'session_id': reference.session,
          'data': terminal.isEmpty
              ? []
              : [
                  {
                    'id': 'canonical-stop',
                    'session_id': reference.session,
                    'role': 'assistant',
                    'content': 'Synthetic canonical Stop outcome',
                  },
                ],
        });
      }
      if (RegExp(r'^/v1/runs/run_[1-5]$').hasMatch(uri.path)) {
        if (failStatus) throw StateError('Synthetic status read failure');
        final run = uri.path.split('/').last;
        return jsonEncode({
          'run_id': wrongRun ? 'foreign' : run,
          'session_id': reference.session,
          'status': terminal.contains(run) ? 'cancelled' : outcome,
        });
      }
      throw StateError('Forbidden synthetic read');
    },
    post: (uri, headers, body) async {
      mutations.add(uri.path);
      if (uri.path == '/v1/runs') {
        submits++;
        return jsonEncode({
          'run_id': 'run_$submits',
          'session_id': reference.session,
        });
      }
      if (!RegExp(r'^/v1/runs/run_[1-5]/stop$').hasMatch(uri.path)) {
        throw StateError('Forbidden synthetic mutation');
      }
      final gate = stopGate;
      stopGate = null;
      final fail = failStop;
      await gate?.future;
      if (fail) throw StateError('Synthetic Stop failure');
      return jsonEncode({
        'run_id': uri.path.split('/')[3],
        'status': 'stopping',
      });
    },
    getStream: (uri, headers) {
      reads.add(uri.path);
      final stream = StreamController<String>();
      streams.add(stream);
      return stream.stream;
    },
  );

  Future<void> prelude() async {
    await pumpEventQueue();
    streams.last.add(
      'event: message.delta\ndata: {"delta":"Synthetic active work"}\n\n',
    );
    await pumpEventQueue();
  }

  Future<void> dispose() async {
    channel.dispose();
    for (final stream in streams) {
      await stream.close();
    }
  }
}
