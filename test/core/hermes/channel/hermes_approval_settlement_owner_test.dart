import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';

class _Answer {
  final started = Completer<void>();
  final release = Completer<void>();
}

class _Harness {
  _Harness() {
    channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => jsonEncode({
            'object': 'hermes.api_server.capabilities',
            'platform': 'hermes-agent',
            'model': 'hermes-agent',
            'features': {
              'run_submission': true,
              'run_status': true,
              'run_events_sse': true,
              'run_approval_response': true,
            },
            'endpoints': {
              'runs': {'method': 'POST', 'path': '/v1/runs'},
              'run_status': {'method': 'GET', 'path': '/v1/runs/{run_id}'},
              'run_events': {
                'method': 'GET',
                'path': '/v1/runs/{run_id}/events',
              },
              'run_approval': {
                'method': 'POST',
                'path': '/v1/runs/{run_id}/approval',
              },
            },
          }),
          '/api/sessions' => '{"data":[{"id":"sess_1","source":"api_server"}]}',
          '/api/sessions/sess_1/messages' =>
            '{"object":"list","session_id":"sess_1","data":[]}',
          '/v1/runs/run_1' =>
            '{"run_id":"run_1","session_id":"sess_1","status":"completed"}',
          _ => throw StateError('unexpected deterministic GET'),
        },
        post: (uri, headers, body) async {
          if (uri.path == '/v1/runs') {
            return '{"run_id":"run_1","session_id":"sess_1","status":"queued"}';
          }
          expect(uri.path, '/v1/runs/run_1/approval');
          posts.add((uri, jsonDecode(body) as Map<String, Object?>));
          final gate = answers.removeAt(0);
          gate.started.complete();
          await gate.release.future;
          return '{}';
        },
        getStream: (uri, headers) {
          final controller = StreamController<String>();
          streams.add(controller);
          streamStarted.complete();
          return controller.stream;
        },
      ),
    );
    channel.approvalRequests.listen(requests.add);
  }

  late final HermesApiChannel channel;
  final requests = <HermesApprovalRequest>[];
  final posts = <(Uri, Map<String, Object?>)>[];
  final answers = <_Answer>[];
  final streams = <StreamController<String>>[];
  Completer<void> streamStarted = Completer<void>();

  Future<void> connect(String baseUrl) async {
    await channel.connect(baseUrl: baseUrl, deferSessionSelection: true);
    expect(
      channel.state.status,
      HermesConnectionStatus.connected,
      reason: channel.state.errorMessage,
    );
    await channel.selectSession('sess_1');
    expect(channel.state.activeSessionId, 'sess_1');
  }

  Future<void> start() async {
    streamStarted = Completer<void>();
    final send = channel.sendText('Synthetic approval settlement control');
    await Future.any([
      streamStarted.future,
      send.then<void>((_) => throw StateError('Run ended before opening SSE')),
    ]).timeout(const Duration(seconds: 5));
    streams.last.add(
      'event: approval.request\ndata: ${jsonEncode({
        'request_id': 'request_1',
        'run_id': 'run_1',
        'session_id': 'sess_1',
        'choices': ['once', 'deny'],
      })}\n\n',
    );
    await pumpEventQueue();
    expect(requests.last.id, 'request_1');
  }

  Future<void> respond(HermesApprovalRequest origin) =>
      channel.respondToApproval(
        approvalId: origin.id,
        runId: origin.runId,
        origin: origin,
        decision: HermesApprovalDecision.once,
      );

  Future<void> dispose() async {
    channel.dispose();
    for (final stream in streams) {
      await stream.close();
    }
  }
}

void main() {
  test(
    'bootstrap without a session fails instead of waiting for SSE',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await expectLater(h.start(), throwsStateError);
      expect(h.streams, isEmpty);
      expect(h.posts, isEmpty);
    },
  );

  test(
    'current owner failure permits only an explicit correlated retry',
    () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.connect('http://127.0.0.1:8642');
      await h.start();
      final origin = h.requests.last;
      final failedGate = _Answer();
      h.answers.add(failedGate);
      final failed = h.respond(origin);
      final failure = expectLater(failed, throwsStateError);
      await failedGate.started.future;
      await expectLater(h.respond(origin), throwsStateError);
      expect(h.posts, hasLength(1));
      failedGate.release.completeError(StateError('synthetic retry control'));
      await failure;
      expect(
        h.channel.state.errorMessage,
        contains('Could not answer approval'),
      );
      await pumpEventQueue();
      expect(h.posts, hasLength(1), reason: 'failure must not replay the POST');

      final retryGate = _Answer();
      h.answers.add(retryGate);
      final retry = h.respond(origin);
      await retryGate.started.future;
      await expectLater(h.respond(origin), throwsStateError);
      retryGate.release.complete();
      await retry;
      await expectLater(h.respond(origin), throwsStateError);
      expect(h.posts, hasLength(2));
      expect(
        h.posts.map((p) => p.$2),
        everyElement({'request_id': 'request_1', 'choice': 'once'}),
      );
    },
  );

  for (final fails in [false, true]) {
    test('dispose retires delayed approval failure=$fails', () async {
      final h = _Harness();
      await h.connect('http://127.0.0.1:8642');
      await h.start();
      final gate = _Answer();
      h.answers.add(gate);
      final answer = h.respond(h.requests.last);
      await gate.started.future;
      await h.dispose();
      final state = h.channel.state;
      if (fails) {
        gate.release.completeError(StateError('retired synthetic failure'));
      } else {
        gate.release.complete();
      }
      await answer;
      expect(identical(h.channel.state, state), isTrue);
      expect(h.posts, hasLength(1));
    });
  }

  for (final replacedOrigin in [false, true]) {
    for (final fails in [false, true]) {
      for (final newerInFlight in [false, true]) {
        test('retired $fails settlement preserves replacement admission '
            'origin=$replacedOrigin busy=$newerInFlight', () async {
          final h = _Harness();
          addTearDown(h.dispose);
          await h.connect('http://127.0.0.1:8642');
          await h.start();
          final oldOrigin = h.requests.last;
          final oldGate = _Answer();
          h.answers.add(oldGate);
          Object? oldError;
          final old = h.respond(oldOrigin).catchError((Object error) {
            oldError = error;
          });
          await oldGate.started.future;
          await h.channel.disconnect();
          await h.connect(
            replacedOrigin ? 'http://127.0.0.1:8643' : 'http://127.0.0.1:8642',
          );
          await h.start();
          final currentOrigin = h.requests.last;
          expect(
            currentOrigin.connectionGeneration,
            isNot(oldOrigin.connectionGeneration),
          );
          await expectLater(h.respond(oldOrigin), throwsStateError);
          final currentGate = _Answer();
          h.answers.add(currentGate);
          Future<void>? current;
          if (newerInFlight) {
            current = h.respond(currentOrigin);
            await currentGate.started.future;
          }
          if (fails) {
            oldGate.release.completeError(
              StateError('retired synthetic failure'),
            );
          } else {
            oldGate.release.complete();
          }
          // Obsolete errors are not failures of the replacement context.
          await old;
          expect(h.channel.state.errorMessage, isNull);
          if (newerInFlight) {
            await expectLater(h.respond(currentOrigin), throwsStateError);
            expect(h.posts, hasLength(2));
          } else {
            Object? currentError;
            current = h.respond(currentOrigin).catchError((Object error) {
              currentError = error;
            });
            await pumpEventQueue();
            expect(
              currentError,
              isNull,
              reason: 'retired success must not erase replacement mapping',
            );
            expect(currentGate.started.isCompleted, isTrue);
          }
          currentGate.release.complete();
          await current;
          await expectLater(h.respond(currentOrigin), throwsStateError);
          expect(h.posts, hasLength(2));
          expect(
            h.posts.map((p) => p.$2),
            everyElement({'request_id': 'request_1', 'choice': 'once'}),
          );
          expect(h.posts.last.$1.port, replacedOrigin ? 8643 : 8642);
          expect(oldError, isNull);
        });
      }
    }
  }
}
