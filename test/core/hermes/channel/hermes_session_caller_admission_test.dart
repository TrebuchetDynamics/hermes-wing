import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/hermes_api.dart';

const capabilities = '''
{"object":"hermes.api_server.capabilities","platform":"test","model":"test",
 "features":{"session_chat_streaming":true},
 "endpoints":{"session_create":{"method":"POST","path":"/api/sessions"},
 "session_chat_stream":{"method":"POST","path":"/api/sessions/{session_id}/chat/stream"},
 "session_messages":{"method":"GET","path":"/api/sessions/{session_id}/messages"}}}
''';
const inventory =
    '''{"data":[{"id":"synthetic-active","source":"test"},{"id":"synthetic-other","source":"test"}]}''';

void main() {
  for (final action in ['open', 'create']) {
    for (final phase in [
      'before',
      'clearing',
      'response',
      'rejection',
      'history',
    ]) {
      if (action == 'open' && (phase == 'history' || phase == 'clearing')) {
        continue;
      }
      test(
        '$action caller admission at $phase rejects stale result and cache',
        () async {
          final started = Completer<void>();
          final gate = Completer<String>();
          var alive = true;
          final requests = <String>[];
          final channel = HermesApiChannel(
            sessionIdFactory: () => 'synthetic-created',
            clientBuilder: (config) => HermesApiClient(
              config: config,
              get: (uri, headers) async {
                requests.add('GET ${uri.path}');
                final delayed =
                    action == 'open' &&
                        uri.path == '/api/sessions/synthetic-other/messages' ||
                    action == 'create' &&
                        phase == 'history' &&
                        uri.path == '/api/sessions/synthetic-created/messages';
                if (delayed) {
                  started.complete();
                  return gate.future;
                }
                return switch (uri.path) {
                  '/health' => '{"status":"ok"}',
                  '/v1/capabilities' => capabilities,
                  '/api/sessions' => inventory,
                  _ => jsonEncode({
                    'object': 'list',
                    'session_id': uri.pathSegments[2],
                    'data': [],
                  }),
                };
              },
              post: (uri, headers, body) async {
                requests.add('POST ${uri.path}');
                if (phase != 'history') {
                  started.complete();
                  return gate.future;
                }
                return '{"session":{"id":"synthetic-created","source":"test"}}';
              },
            ),
          );
          addTearDown(channel.dispose);
          await channel.connect(baseUrl: 'http://127.0.0.1:8642');
          final initial = channel.state.activeSessionId;
          requests.clear();
          if (phase == 'clearing') {
            channel.addListener(() {
              if (channel.state.activeSessionId == null) alive = false;
            });
          }
          if (phase == 'before') alive = false;
          final future = action == 'open'
              ? channel.selectSession('synthetic-other', canAccept: () => alive)
              : channel.createSession(canAccept: () => alive);
          if (phase == 'before' || phase == 'clearing') {
            await future;
            expect(requests, isEmpty);
            expect(
              channel.state.activeSessionId,
              phase == 'before' ? initial : isNull,
            );
            return;
          }
          await started.future;
          alive = false;
          if (phase == 'rejection') {
            gate.completeError(StateError('synthetic failure'));
            if (action == 'create') {
              await expectLater(future, throwsStateError);
            } else {
              await future;
            }
          } else {
            gate.complete(
              action == 'create' && phase != 'history'
                  ? jsonEncode({
                      'session': {'id': 'synthetic-created', 'source': 'test'},
                    })
                  : jsonEncode({
                      'object': 'list',
                      'session_id': action == 'open'
                          ? 'synthetic-other'
                          : 'synthetic-created',
                      'data': [],
                      'pagination': {
                        'limit': 1,
                        'offset': 40,
                        'order': 'latest',
                      },
                    }),
            );
            await future;
          }
          expect(
            channel.state.activeSessionId,
            action == 'open' ? initial : isNull,
          );
          expect(
            channel.state.sessions.any((s) => s.id == 'synthetic-created'),
            isFalse,
          );
          expect(channel.state.messages['synthetic-created'], isNull);
          expect(channel.state.messages['synthetic-other'], isNull);
          expect(
            channel.state.messageHistoryNextOffsets['synthetic-other'],
            isNull,
          );
          expect(
            channel.state.messageHistoryNextOffsets['synthetic-created'],
            isNull,
          );
          expect(
            requests.where((r) => r.startsWith('POST')),
            action == 'create' ? ['POST /api/sessions'] : isEmpty,
          );
        },
      );
    }
  }
}
