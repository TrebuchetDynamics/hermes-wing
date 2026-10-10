import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';

/// Owned loopback HTTP/SSE authority. Persisted bytes are synthetic fixture
/// history, never an Agent store, credentials or client-side domain fallback.
class IntegratedDailyRestartFixture {
  static const profile = 'synthetic-qa';
  static const session = 'synthetic-off-page';
  final String root;
  final String phase;
  IntegratedDailyRestartFixture(this.root, this.phase);
  late HttpServer server;
  late String origin;
  final requests = <Map<String, Object?>>[];
  final mutations = <Map<String, Object?>>[];
  final history = <Map<String, Object?>>[];
  final statuses = <String, String>{};
  final streams = <String, HttpResponse>{};
  bool modelSelected = false;
  int submits = 0;
  bool holdStop = true;
  Completer<void>? stopGate;
  bool failHistory = false;

  Future<void> start() async {
    final file = File('$root/cache/backend.json');
    if (phase == 'verify') {
      final saved = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      history.addAll(
        (saved['history'] as List).cast<Map>().map(
          (r) => r.cast<String, Object?>(),
        ),
      );
      submits = saved['submits'] as int;
      statuses.addAll((saved['statuses'] as Map).cast<String, String>());
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        saved['port'] as int,
      );
    } else {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    }
    origin = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      try {
        await handle(request);
      } catch (_) {
        request.response.statusCode = 500;
        request.response.write('{"error":"Synthetic fixture failure"}');
        await request.response.close();
      }
    });
  }

  void save() => File('$root/cache/backend.json').writeAsStringSync(
    jsonEncode({
      'port': server.port,
      'history': history,
      'submits': submits,
      'statuses': statuses,
    }),
  );

  Map<String, Object?> row(String id) => {
    'id': id,
    'title': id == session
        ? 'Synthetic off-page conversation'
        : 'Synthetic first page',
    'source': 'api_server',
    'profile_id': profile,
    if (id == session && submits > 0) ...{
      'model': 'synthetic/model',
      'has_model_config': true,
    },
  };

  Future<void> json(HttpRequest req, Object value, {int status = 200}) async {
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(value));
    await req.response.close();
  }

  Future<void> handle(HttpRequest req) async {
    final path = req.uri.path;
    final owner = req.uri.queryParameters['profile'];
    if (req.headers.value('Authorization') != null || requests.length >= 256) {
      return json(req, {'error': 'Synthetic authority rejected'}, status: 403);
    }
    requests.add({
      'method': req.method,
      'path': path,
      'profile': owner,
      'query': req.uri.queryParameters,
    });
    if (path == '/health') return json(req, {'status': 'ok'});
    if (path == '/v1/capabilities') {
      return json(req, {
        'schema_version': 1,
        'profile_context': {
          'type': 'query',
          'name': 'profile',
          'required': true,
          'default_profile_id': 'default',
        },
        'auth': {
          'type': 'bearer',
          'required': false,
          'granted_scopes': [
            'profiles:read',
            'sessions:read',
            'runs:write',
            'models:write',
          ],
        },
        'features': {
          for (final key in [
            'run_submission',
            'run_events_sse',
            'run_status',
            'run_stop',
            'run_approval_response',
            'model_options',
            'session_model_lock',
          ])
            key: true,
        },
        'endpoints': {
          for (final entry in {
            'profiles': ['GET', '/api/profiles'],
            'sessions': ['GET', '/api/sessions'],
            'session': ['GET', '/api/sessions/{session_id}'],
            'session_messages': ['GET', '/api/sessions/{session_id}/messages'],
            'model_options': ['GET', '/api/model/options'],
            'session_model_lock': ['POST', '/api/sessions/{session_id}/model'],
            'runs': ['POST', '/v1/runs'],
            'run_events': ['GET', '/v1/runs/{run_id}/events'],
            'run_status': ['GET', '/v1/runs/{run_id}'],
            'run_approval': ['POST', '/v1/runs/{run_id}/approval'],
            'run_stop': ['POST', '/v1/runs/{run_id}/stop'],
          }.entries)
            entry.key: {
              'method': entry.value[0],
              'path': entry.value[1],
              'profile_scoped': entry.key != 'profiles',
              'required_scopes': [if (entry.key == 'profiles') 'profiles:read'],
            },
        },
      });
    }
    if (path == '/api/profiles') {
      return json(req, {
        'data': [
          {'id': profile, 'name': 'Synthetic QA'},
        ],
      });
    }
    if (!{'default', profile}.contains(owner)) {
      return json(req, {'error': 'Synthetic wrong profile'}, status: 403);
    }
    if (req.method == 'GET') {
      if (path == '/api/sessions') {
        final more =
            (int.tryParse(req.uri.queryParameters['offset'] ?? '0') ?? 0) > 0;
        requests.last['returned_ids'] = [more ? session : 'synthetic-first'];
        return json(req, {
          'data': [row(more ? session : 'synthetic-first')],
          'limit': 1,
          'offset': more ? 1 : 0,
          'has_more': !more,
        });
      }
      for (final id in [session, 'synthetic-first']) {
        if (path == '/api/sessions/$id') {
          return json(req, {'object': 'hermes.session', 'session': row(id)});
        }
        if (path == '/api/sessions/$id/messages') {
          if (failHistory) {
            return json(req, {
              'error': 'Synthetic canonical history unavailable',
            }, status: 503);
          }
          return json(req, {
            'object': 'list',
            'session_id': id,
            'data': id == session ? history : [],
          });
        }
      }
      if (path == '/api/model/options') {
        return json(req, {
          'provider': 'other',
          'model': 'other/model',
          'providers': [
            {
              'slug': 'synthetic',
              'label': 'Synthetic fixture',
              'authenticated': true,
              'models': ['synthetic/model'],
            },
          ],
        });
      }
      final match = RegExp(
        r'^/v1/runs/(run_[1-3])(/events)?$',
      ).firstMatch(path);
      if (match != null) {
        final run = match[1]!;
        final payload = {
          'run_id': run,
          'session_id': session,
          'profile_id': profile,
          'status': statuses[run],
        };
        if (match[2] == null) return json(req, payload);
        req.response.headers.contentType = ContentType('text', 'event-stream');
        req.response.headers.set('Cache-Control', 'no-store');
        req.response.bufferOutput = false;
        streams[run] = req.response;
        event(run, 'message.delta', {'delta': 'Synthetic active work'});
        if (run == 'run_1') {
          event(run, 'approval.request', {
            'request_id': 'approval_run_1',
            'description': 'Synthetic harmless approval',
            'choices': ['once', 'deny'],
          });
        } else if (run == 'run_3') {
          await complete(run);
          return;
        }
        await req.response.flush();
        return;
      }
    }
    final body = req.method == 'POST'
        ? jsonDecode(await utf8.decoder.bind(req).join())
              as Map<String, dynamic>
        : <String, dynamic>{};
    mutations.add({
      'method': req.method,
      'path': path,
      'profile': owner,
      'body': body,
    });
    if (owner != profile) {
      return json(req, {
        'error': 'Synthetic wrong mutation owner',
      }, status: 403);
    }
    if (path == '/api/sessions/$session/model' &&
        body['provider'] == 'synthetic' &&
        body['model'] == 'synthetic/model') {
      modelSelected = true;
      return json(req, {
        'session_id': session,
        'runtime': {
          'provider': 'synthetic',
          'model': 'synthetic/model',
          'model_lock': 'accepted',
          'route_source': 'session',
        },
      });
    }
    if (path == '/v1/runs' &&
        body['session_id'] == session &&
        modelSelected &&
        submits < 3) {
      final run = 'run_${++submits}';
      statuses[run] = 'running';
      history.add({
        'id': 'user_$run',
        'session_id': session,
        'role': 'user',
        'content': body['message'],
      });
      return json(req, {
        'run_id': run,
        'session_id': session,
        'status': 'queued',
      }, status: 202);
    }
    if (path == '/v1/runs/run_1/approval' &&
        body['request_id'] == 'approval_run_1' &&
        body['choice'] == 'once') {
      await json(req, {'run_id': 'run_1', 'choice': 'once'});
      await complete('run_1');
      return;
    }
    if (path == '/v1/runs/run_2/stop') {
      statuses['run_2'] = 'stopping';
      await streams.remove('run_2')?.close();
      if (holdStop) {
        stopGate = Completer<void>();
        await stopGate!.future;
      }
      return json(req, {'run_id': 'run_2', 'status': 'stopping'});
    }
    return json(req, {'error': 'Forbidden synthetic mutation'}, status: 403);
  }

  void event(String run, String name, Map<String, Object?> data) {
    streams[run]?.write(
      'event: $name\ndata: ${jsonEncode({'run_id': run, 'session_id': session, 'profile_id': profile, ...data})}\n\n',
    );
  }

  Future<void> complete(String run) async {
    statuses[run] = 'completed';
    history.add({
      'id': 'canonical_$run',
      'session_id': session,
      'role': 'assistant',
      'content': 'Synthetic canonical reply $run',
    });
    event(run, 'run.completed', {'status': 'completed'});
    await streams.remove(run)?.close();
  }

  void cancel() {
    statuses['run_2'] = 'cancelled';
    history.add({
      'id': 'canonical_run_2',
      'session_id': session,
      'role': 'assistant',
      'content': 'Synthetic canonical stopped outcome',
    });
  }

  Future<void> dispose() async {
    stopGate?.complete();
    await server.close(force: true);
  }
}

class IntegratedDailyEndpointStore extends EmptyHermesEndpointStore {
  const IntegratedDailyEndpointStore(this.origin);
  final String origin;
  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async => [
    HermesEndpointConfig(
      id: 'integrated-fixture',
      label: 'Synthetic direct Agent',
      baseUrl: origin,
    ),
  ];
}
