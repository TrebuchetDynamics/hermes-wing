import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/core/hermes/channel/hermes_api_channel.dart';
import 'package:navivox/core/hermes/hermes_api.dart';
import 'package:navivox/core/hermes/models/hermes_chat_turn.dart';
import 'package:navivox/core/protocol/voice/models/navivox_voice_run.dart';

void main() {
  test(
    'connect selects the first existing session and loads its messages',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );

      await channel.connect(baseUrl: 'http://127.0.0.1:8642', apiKey: 'key');

      expect(channel.state.status, HermesConnectionStatus.connected);
      expect(channel.state.sessions.single.id, 'sess_1');
      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
    },
  );

  test('connect loads read-only Hermes catalog when advertised', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _catalogCapabilitiesFixture,
            '/v1/models' => _modelsFixture,
            '/v1/skills' => _skillsFixture,
            '/v1/toolsets' => _toolsetsFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.models, ['hermes-agent']);
    expect(channel.state.skills, ['ascii-art', 'github']);
    expect(channel.state.enabledToolsets, ['default']);
  });

  test('connect loads read-only Hermes jobs when advertised', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _jobsCapabilitiesFixture,
            '/api/jobs' => _jobsFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.jobs.single.id, 'job_1');
    expect(channel.state.jobs.single.displayName, 'Morning check');
  });

  test('connect loads detailed Hermes health when advertised', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _healthCapabilitiesFixture,
            '/health/detailed' =>
              '{"status":"ok","platform":"hermes-agent","version":"0.16.0","gateway_state":"running","active_agents":0}',
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.detailedHealth?.version, '0.16.0');
    expect(channel.state.detailedHealth?.gatewayState, 'running');
    expect(channel.state.detailedHealth?.activeAgents, 0);
  });

  test('connect creates a session with a generated id when none exist', () async {
    final posts = <String, Map<String, Object?>>{};
    final channel = HermesApiChannel(
      sessionIdFactory: () => 'navi-test-1',
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _sessionCreateCapabilitiesFixture,
            '/api/sessions' => '{"object":"list","data":[]}',
            '/api/sessions/navi-test-1/messages' =>
              '{"object":"list","session_id":"navi-test-1","data":[]}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = {};
          return '{"object":"hermes.session","session":{"id":"navi-test-1","source":"api_server"}}';
        },
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.status, HermesConnectionStatus.connected);
    expect(channel.state.activeSessionId, 'navi-test-1');
    expect(posts.keys, ['/api/sessions']);
  });

  test(
    'connect stays sessionless when create is absent and none exist',
    () async {
      final posts = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _chatOnlyCapabilitiesFixture,
              '/api/sessions' => '{"object":"list","data":[]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            posts.add(uri.path);
            return '{}';
          },
        ),
      );

      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      expect(channel.state.status, HermesConnectionStatus.connected);
      expect(channel.state.sessions, isEmpty);
      expect(channel.state.activeSessionId, isNull);
      expect(channel.state.messages, isEmpty);
      expect(posts, isEmpty);
    },
  );

  test('connect surfaces a bounded error without throwing', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => throw StateError('offline'),
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.status, HermesConnectionStatus.error);
    expect(channel.state.errorMessage, contains('offline'));
  });

  test('connect redacts and bounds secret-looking stored errors', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => throw StateError(
          '401 unauthorized for Bearer secret-api-key token=secret-token '
          'Basic secret-basic Cookie: sid=secret-cookie; '
          'https://user:secret-pass@example.test/path '
          'sk-1234567890abcdef '
          'ghp_'
          'abcdefghijklmnopqrstuvwxyz123456 '
          'xoxb-'
          '123456789012-abcdefabcdefabcdef '
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signaturevalue '
          '${List.filled(30, 'verbose').join(' ')} tail-marker',
        ),
      ),
    );

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.status, HermesConnectionStatus.error);
    expect(channel.state.errorMessage, contains('401 unauthorized'));
    expect(channel.state.errorMessage, contains('Bearer [redacted]'));
    expect(channel.state.errorMessage, contains('Basic [redacted]'));
    expect(channel.state.errorMessage, contains('Cookie: [redacted]'));
    expect(channel.state.errorMessage, contains('https://[redacted]@'));
    expect(channel.state.errorMessage, contains('sk-[redacted]'));
    expect(channel.state.errorMessage, contains('ghp_[redacted]'));
    expect(channel.state.errorMessage, contains('xox-[redacted]'));
    expect(channel.state.errorMessage, contains('[redacted-jwt]'));
    expect(channel.state.errorMessage, isNot(contains('secret-api-key')));
    expect(channel.state.errorMessage, isNot(contains('secret-token')));
    expect(channel.state.errorMessage, isNot(contains('secret-basic')));
    expect(channel.state.errorMessage, isNot(contains('secret-cookie')));
    expect(channel.state.errorMessage, isNot(contains('secret-pass')));
    expect(channel.state.errorMessage, isNot(contains('tail-marker')));
    expect(channel.state.errorMessage!.length, lessThanOrEqualTo(241));
  });

  test('connect reports invalid Hermes base URLs without HTTP', () async {
    var clientBuilt = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) {
        clientBuilt = true;
        return HermesApiClient(config: config);
      },
    );

    await channel.connect(baseUrl: '   ');

    expect(clientBuilt, isFalse);
    expect(channel.state.status, HermesConnectionStatus.error);
    expect(channel.state.errorMessage, contains('baseUrl'));
    expect(channel.state.sessions, isEmpty);
  });

  test('failed reconnect clears stale endpoint session data', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          if (config.baseUri.port == 8643) throw StateError('offline');
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    expect(channel.state.activeMessages.single.text, 'Hello');

    await channel.connect(baseUrl: 'http://127.0.0.1:8643');

    expect(channel.state.status, HermesConnectionStatus.error);
    expect(channel.state.errorMessage, contains('offline'));
    expect(channel.state.sessions, isEmpty);
    expect(channel.state.messages, isEmpty);
    expect(channel.state.activeSessionId, isNull);
  });

  test('stale connect results cannot overwrite a newer connection', () async {
    final firstHealthStarted = Completer<void>();
    final releaseFirstHealth = Completer<void>();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          final staleConnection = config.baseUri.port == 8642;
          if (staleConnection && uri.path == '/health') {
            firstHealthStarted.complete();
            await releaseFirstHealth.future;
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' =>
              staleConnection
                  ? _sessionsFixture
                  : '{"object":"list","data":[{"id":"fresh","source":"api_server","title":"Fresh"}]}',
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/fresh/messages' =>
              '{"object":"list","session_id":"fresh","data":[{"id":"msg_fresh","session_id":"fresh","role":"assistant","content":"Fresh connection"}]}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    final staleConnect = channel.connect(baseUrl: 'http://127.0.0.1:8642');
    await firstHealthStarted.future;
    await channel.connect(baseUrl: 'http://127.0.0.1:8643');
    releaseFirstHealth.complete();
    await staleConnect;

    expect(channel.state.status, HermesConnectionStatus.connected);
    expect(channel.state.activeSessionId, 'fresh');
    expect(channel.state.activeMessages.single.text, 'Fresh connection');
  });

  test(
    'sendText appends the user turn, streams assistant deltas, then reconciles with server history',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) {
            expect(uri.path, '/api/sessions/sess_1/chat/stream');
            return Stream.fromIterable([
              'event: assistant.delta\ndata: {"delta":"Hi"}\n\n',
              'event: assistant.delta\ndata: {"delta":" there"}\n\ndata: [DONE]\n\n',
            ]);
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      var streamingSeen = false;
      channel.addListener(() {
        final last = channel.state.activeMessages.lastOrNull;
        if (last?.status == HermesTurnStatus.streaming) streamingSeen = true;
      });

      await channel.sendText('Hello');

      expect(streamingSeen, isTrue);
      expect(messagesRequests, 2);
      final turns = channel.state.activeMessages;
      expect(turns.map((t) => t.text), ['Hello', 'Hi there']);
      expect(turns.last.author, HermesTurnAuthor.assistant);
      expect(turns.last.status, HermesTurnStatus.completed);
    },
  );

  test('sendText accepts text/content delta aliases on delta events', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        postStream: (uri, headers, body) => Stream.fromIterable([
          'event: assistant.delta\ndata: {"content":"Hi"}\n\n',
          'event: assistant.delta\ndata: {"text":" there"}\n\n',
          'event: done\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('alias test');

    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'alias test',
      'Hi there',
    ]);
    expect(
      channel.state.activeMessages.last.status,
      HermesTurnStatus.completed,
    );
  });

  test(
    'sendText completes and reconciles when done sentinel arrives without stream close',
    () async {
      var messagesRequests = 0;
      final stream = StreamController<String>();
      addTearDown(stream.close);
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => stream.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('done sentinel');
      await pumpEventQueue();
      stream.add('event: assistant.delta\ndata: {"delta":"local"}\n\n');
      stream.add('data: [DONE]\n\n');
      await send;
      stream.add('event: assistant.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hi there',
      ]);
    },
  );

  test(
    'sendText fails a direct chat stream that closes before a terminal event',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0) ? _messagesFixture : _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => Stream<String>.fromIterable(
            const ['event: assistant.delta\ndata: {"delta":"partial"}\n\n'],
          ),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('closed stream');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'closed stream',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText keeps a closed direct chat stream failed when history has only old assistant replies',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => Stream<String>.fromIterable(
            const ['event: assistant.delta\ndata: {"delta":"partial"}\n\n'],
          ),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      messagesRequests = 1;

      await channel.sendText('closed stream');

      expect(messagesRequests, 1);
      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hi there',
        'closed stream',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText does not recover a closed direct chat stream from an old duplicate user turn',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ >= 0) ? _duplicateMessagesFixture : '',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => Stream<String>.fromIterable(
            const ['event: assistant.delta\ndata: {"delta":"partial"}\n\n'],
          ),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('Hello again');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hello again',
        'Old answer',
        'Hello again',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText does not recover a closed stream from a later-turn assistant reply',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _interleavedLaterReplyMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => Stream<String>.fromIterable(
            const ['event: assistant.delta\ndata: {"delta":"partial"}\n\n'],
          ),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('closed stream');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'closed stream',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText recovers a closed direct chat stream from server history',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => Stream<String>.fromIterable(
            const ['event: assistant.delta\ndata: {"delta":"partial"}\n\n'],
          ),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('closed stream');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hi there',
      ]);
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.completed,
      );
    },
  );

  test(
    'sendText keeps the partial assistant turn failed when the stream drops',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0) ? _messagesFixture : _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) async* {
            yield 'event: assistant.delta\ndata: {"delta":"partial"}\n\n';
            throw StateError('stream dropped');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('Hello again');

      expect(messagesRequests, 2);
      final turns = channel.state.activeMessages;
      expect(turns.map((t) => t.text), ['Hello', 'Hello again', 'partial']);
      expect(turns.last.author, HermesTurnAuthor.assistant);
      expect(turns.last.status, HermesTurnStatus.failed);
      expect(channel.state.errorMessage, contains('stream dropped'));
    },
  );

  test(
    'sendText does not recover a dropped direct chat stream from an old duplicate user turn',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ >= 0) ? _duplicateMessagesFixture : '',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) async* {
            yield 'event: assistant.delta\ndata: {"delta":"partial"}\n\n';
            throw StateError('stream dropped');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('Hello again');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('stream dropped'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hello again',
        'Old answer',
        'Hello again',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText does not recover a dropped direct stream from a later-turn assistant reply',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _interleavedLaterReplyMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) async* {
            yield 'event: assistant.delta\ndata: {"delta":"partial"}\n\n';
            throw StateError('stream dropped');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('closed stream');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('stream dropped'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'closed stream',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText recovers a dropped direct chat stream from server history',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) async* {
            yield 'event: assistant.delta\ndata: {"delta":"partial"}\n\n';
            throw StateError('stream dropped');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('Hello again');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hi there',
      ]);
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.completed,
      );
    },
  );

  test(
    'sendText rejects when no supported chat transport is advertised',
    () async {
      var postStreamCalled = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _noChatCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) {
            postStreamCalled = true;
            return const Stream.empty();
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('hello?'), throwsStateError);

      expect(postStreamCalled, isFalse);
      expect(channel.state.activeMessages.map((turn) => turn.text), ['Hello']);
    },
  );

  test('sendText rejects blank messages before touching Hermes', () async {
    var postStreamCalled = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        postStream: (uri, headers, body) {
          postStreamCalled = true;
          return const Stream.empty();
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.sendText('   '), throwsArgumentError);

    expect(postStreamCalled, isFalse);
    expect(channel.state.activeMessages.map((turn) => turn.text), ['Hello']);
  });

  test('sendText rejects direct concurrent sends while streaming', () async {
    final stream = _ManualStringStream();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        postStream: (uri, headers, body) => stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final firstSend = channel.sendText('first');
    await pumpEventQueue();

    await expectLater(channel.sendText('second'), throwsStateError);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'first',
      '',
    ]);

    channel.cancelActiveTurn();
    await firstSend;
  });

  test(
    'stop during pending run submission prevents late stream attach',
    () async {
      final startRunStarted = Completer<void>();
      final releaseStartRun = Completer<void>();
      var runEventsOpened = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            if (!startRunStarted.isCompleted) startRunStarted.complete();
            await releaseStartRun.future;
            return '{"object":"hermes.run","run":{"id":"late_run","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) {
            runEventsOpened = true;
            return Stream<String>.fromIterable([
              'event: message.delta\ndata: {"delta":"late"}\n\n',
              'data: [DONE]\n\n',
            ]);
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('stop me');
      await startRunStarted.future;
      channel.stopActiveTurn();
      releaseStartRun.complete();
      await send;

      expect(runEventsOpened, isFalse);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'stop me',
        'Stopped.',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
      await expectLater(
        channel.respondToApproval(
          approvalId: 'appr_1',
          decision: HermesApprovalDecision.once,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'stop during pending run submission ignores late submission failure',
    () async {
      final startRunStarted = Completer<void>();
      final releaseStartRun = Completer<void>();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            if (!startRunStarted.isCompleted) startRunStarted.complete();
            await releaseStartRun.future;
            throw StateError('late run submit failed');
          },
          getStream: (uri, headers) => throw StateError('should not attach'),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('stop failing submit');
      await startRunStarted.future;
      channel.stopActiveTurn();
      releaseStartRun.complete();
      await send;

      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'stop failing submit',
        'Stopped.',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test('stale stopped run cleanup cannot clear a newer active run', () async {
    var nextRun = 1;
    final stops = <String>[];
    final streams = <String, _ManualStringStream>{};
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          if (uri.path == '/v1/runs') {
            final runId = 'run_${nextRun++}';
            return '{"object":"hermes.run","run":{"id":"$runId","session_id":"sess_1"}}';
          }
          if (uri.path.endsWith('/stop')) {
            stops.add(uri.path);
            return '{}';
          }
          throw StateError('unexpected POST $uri');
        },
        getStream: (uri, headers) {
          final runId = uri.pathSegments[2];
          return streams.putIfAbsent(runId, _ManualStringStream.new);
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final firstSend = channel.sendText('first');
    await pumpEventQueue();
    channel.stopActiveTurn();

    final secondSend = channel.sendText('second');
    await pumpEventQueue();
    channel.stopActiveTurn();

    await firstSend;
    await secondSend;
    expect(stops, ['/v1/runs/run_1/stop', '/v1/runs/run_2/stop']);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'first',
      'Stopped.',
      'second',
      'Stopped.',
    ]);
  });

  test('sendText rejects direct sends while run submission is pending', () async {
    final startRunStarted = Completer<void>();
    final releaseStartRun = Completer<void>();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs');
          if (!startRunStarted.isCompleted) startRunStarted.complete();
          await releaseStartRun.future;
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => const Stream<String>.empty(),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final firstSend = channel.sendText('first');
    await startRunStarted.future;

    await expectLater(channel.sendText('second'), throwsStateError);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'first',
      '',
    ]);

    releaseStartRun.complete();
    await firstSend;
  });

  test(
    'sendText marks local assistant failed when run event stream fails to open',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => throw StateError('events offline'),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('open events'), throwsStateError);

      expect(
        channel.state.errorMessage,
        contains('Hermes run event stream failed to open'),
      );
      expect(channel.state.errorMessage, contains('events offline'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'open events',
        '',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText fails a run stream that closes before a terminal event',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => Stream<String>.fromIterable(const [
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('dropped run');

      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'dropped run',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test('sendText fails when a run stream emits an error event', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs');
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => Stream<String>.fromIterable(const [
          'event: message.delta\ndata: {"delta":"partial"}\n\n',
          'event: error\ndata: {"error":{"code":"upstream","message":"token=secret-stream-error"}}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('errored run');

    expect(
      channel.state.errorMessage,
      contains('Hermes stream reported an error'),
    );
    expect(channel.state.errorMessage, contains('upstream: token=[redacted]'));
    expect(channel.state.errorMessage, isNot(contains('secret-stream-error')));
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'errored run',
      'partial',
    ]);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test('sendText fails when a run stream emits message.error', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs');
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => Stream<String>.fromIterable(const [
          'event: message.delta\ndata: {"delta":"partial"}\n\n',
          'event: message.error\ndata: upstream token=secret-message-error\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('message errored run');

    expect(
      channel.state.errorMessage,
      contains('Hermes stream reported an error'),
    );
    expect(channel.state.errorMessage, contains('token=[redacted]'));
    expect(channel.state.errorMessage, isNot(contains('secret-message-error')));
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'message errored run',
      'partial',
    ]);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test('sendText recovers a closed run stream from server history', () async {
    var messagesRequests = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs');
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) => Stream<String>.fromIterable(const [
          'event: message.delta\ndata: {"delta":"partial"}\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('dropped run');

    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'Hi there',
    ]);
    expect(
      channel.state.activeMessages.last.status,
      HermesTurnStatus.completed,
    );
  });

  test(
    'sendText does not recover a closed run stream from an old duplicate user turn',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ >= 0) ? _duplicateMessagesFixture : '',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => Stream<String>.fromIterable(const [
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('Hello again');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hello again',
        'Old answer',
        'Hello again',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText does not recover a closed run stream from a later-turn assistant reply',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _interleavedLaterReplyMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => Stream<String>.fromIterable(const [
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('closed stream');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('closed before a terminal'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'closed stream',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText keeps a dropped run stream failed when history has only old assistant replies',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ >= 0) ? _reconciledMessagesFixture : '',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) async* {
            yield 'event: message.delta\ndata: {"delta":"partial"}\n\n';
            throw StateError('run events dropped');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('dropped run');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('run events dropped'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hi there',
        'dropped run',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText does not recover a dropped run stream from a later-turn assistant reply',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _interleavedLaterReplyMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) async* {
            yield 'event: message.delta\ndata: {"delta":"partial"}\n\n';
            throw StateError('run events dropped');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('closed stream');

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, contains('run events dropped'));
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'closed stream',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test('sendText recovers a dropped run stream from server history', () async {
    var messagesRequests = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs');
          return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
        },
        getStream: (uri, headers) async* {
          yield 'event: message.delta\ndata: {"delta":"partial"}\n\n';
          throw StateError('run events dropped');
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('dropped run');

    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'Hi there',
    ]);
    expect(
      channel.state.activeMessages.last.status,
      HermesTurnStatus.completed,
    );
  });

  test(
    'sendText marks the local assistant turn failed when run submission is rejected',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            throw StateError('401 unauthorized');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('needs auth'), throwsStateError);

      final turns = channel.state.activeMessages;
      expect(turns.map((t) => t.text), ['Hello', 'needs auth', '']);
      expect(turns.last.author, HermesTurnAuthor.assistant);
      expect(turns.last.status, HermesTurnStatus.failed);
      expect(channel.state.errorMessage, contains('401 unauthorized'));
    },
  );

  test(
    'sendText redacts bearer and secret values from stored errors',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async => throw StateError(
            '403 forbidden for Bearer secret-stream-key api_key=secret-api-key',
          ),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.sendText('needs auth'), throwsStateError);

      expect(channel.state.errorMessage, contains('403 forbidden'));
      expect(channel.state.errorMessage, contains('Bearer [redacted]'));
      expect(channel.state.errorMessage, isNot(contains('secret-stream-key')));
      expect(channel.state.errorMessage, isNot(contains('secret-api-key')));
    },
  );

  test(
    'disconnect cancels an active stream and ignores stale deltas',
    () async {
      final stream = StreamController<String>();
      addTearDown(stream.close);
      final sendDone = Completer<void>();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => stream.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      unawaited(channel.sendText('long run').whenComplete(sendDone.complete));
      await pumpEventQueue();
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.streaming,
      );

      await channel.disconnect();
      stream.add('event: assistant.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(channel.state.status, HermesConnectionStatus.disconnected);
      expect(channel.state.messages, isEmpty);
      expect(sendDone.isCompleted, isTrue);
    },
  );

  test(
    'selectSession cancels an active stream before switching sessions',
    () async {
      final stream = _ManualStringStream();
      final sendDone = Completer<void>();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _twoSessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/sess_2/messages' =>
                '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"From two"}]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      unawaited(channel.sendText('long run').whenComplete(sendDone.complete));
      await pumpEventQueue();
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.streaming,
      );

      await channel.selectSession('sess_2');
      stream.emit('event: assistant.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.activeMessages.single.text, 'From two');
      expect(
        channel.state.messages['sess_1']!.last.status,
        HermesTurnStatus.failed,
      );
      expect(channel.state.messages['sess_1']!.last.text, 'Stopped.');
      expect(sendDone.isCompleted, isTrue);
    },
  );

  test(
    'selectSession rejects unknown sessions before fetching history',
    () async {
      var fetchedMissingHistory = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/missing/messages' => () {
                fetchedMissingHistory = true;
                return '{"object":"list","data":[]}';
              }(),
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.selectSession('missing'), throwsStateError);

      expect(fetchedMissingHistory, isFalse);
      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
    },
  );

  test(
    'selectSession leaves the active session unchanged when message load fails',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _twoSessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/sess_2/messages' => throw StateError(
                'session history unavailable',
              ),
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.selectSession('sess_2'), throwsStateError);

      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
    },
  );

  test(
    'selectSession switches the active session and loads its messages',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _twoSessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/sess_2/messages' =>
                '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"From two"}]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      expect(channel.state.activeSessionId, 'sess_1');

      await channel.selectSession('sess_2');

      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.activeMessages.single.text, 'From two');
    },
  );

  test(
    'renameSession patches the server and replaces the local session row',
    () async {
      final patches = <String, Map<String, Object?>>{};
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          patch: (uri, headers, body) async {
            patches[uri.path] = jsonDecode(body) as Map<String, Object?>;
            return '{"object":"hermes.session","session":{"id":"sess_1","source":"api_server","title":"Renamed"}}';
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.renameSession(sessionId: 'sess_1', title: ' Renamed ');

      expect(patches['/api/sessions/sess_1'], {'title': 'Renamed'});
      expect(channel.state.sessions.single.title, 'Renamed');
      expect(channel.state.activeSession?.title, 'Renamed');
    },
  );

  test('renameSession rejects a blank title before PATCH', () async {
    var patched = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        patch: (uri, headers, body) async {
          patched = true;
          return '{}';
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(
      channel.renameSession(sessionId: 'sess_1', title: '   '),
      throwsArgumentError,
    );
    expect(patched, isFalse);
  });

  test(
    'mutable session calls reject when endpoints are not advertised',
    () async {
      var posted = false;
      var patched = false;
      var deleted = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _noChatCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            posted = true;
            return '{}';
          },
          patch: (uri, headers, body) async {
            patched = true;
            return '{}';
          },
          delete: (uri, headers) async {
            deleted = true;
            return '{}';
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.createSession(), throwsStateError);
      await expectLater(
        channel.renameSession(sessionId: 'sess_1', title: 'Renamed'),
        throwsStateError,
      );
      await expectLater(channel.deleteSession('sess_1'), throwsStateError);
      await expectLater(channel.forkSession('sess_1'), throwsStateError);

      expect(posted, isFalse);
      expect(patched, isFalse);
      expect(deleted, isFalse);
      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
    },
  );

  test('mutable session calls reject unknown sessions before HTTP', () async {
    var posted = false;
    var patched = false;
    var deleted = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posted = true;
          return '{}';
        },
        patch: (uri, headers, body) async {
          patched = true;
          return '{}';
        },
        delete: (uri, headers) async {
          deleted = true;
          return '{}';
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(
      channel.renameSession(sessionId: 'missing', title: 'Renamed'),
      throwsStateError,
    );
    await expectLater(channel.deleteSession('missing'), throwsStateError);
    await expectLater(channel.forkSession('missing'), throwsStateError);

    expect(posted, isFalse);
    expect(patched, isFalse);
    expect(deleted, isFalse);
    expect(channel.state.activeSessionId, 'sess_1');
    expect(channel.state.activeMessages.single.text, 'Hello');
  });

  test(
    'deleteSession removes the active session and selects the next one',
    () async {
      final deletes = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _twoSessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/sess_2/messages' =>
                '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"From two"}]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          delete: (uri, headers) async {
            deletes.add(uri.path);
            return '{"object":"hermes.session.deleted","id":"sess_1","deleted":true}';
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.deleteSession('sess_1');

      expect(deletes, ['/api/sessions/sess_1']);
      expect(channel.state.sessions.map((s) => s.id), ['sess_2']);
      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.activeMessages.single.text, 'From two');
    },
  );

  test(
    'deleteSession cancels active stream before removing active session',
    () async {
      final stream = _ManualStringStream();
      final sendDone = Completer<void>();
      final deletes = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _twoSessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/sess_2/messages' =>
                '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"From two"}]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => stream,
          delete: (uri, headers) async {
            deletes.add(uri.path);
            return '{"object":"hermes.session.deleted","id":"sess_1","deleted":true}';
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      unawaited(
        channel
            .sendText('deleted while streaming')
            .whenComplete(sendDone.complete),
      );
      await pumpEventQueue();
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.streaming,
      );

      await channel.deleteSession('sess_1');
      stream.emit('event: assistant.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(deletes, ['/api/sessions/sess_1']);
      expect(channel.state.sessions.map((s) => s.id), ['sess_2']);
      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.activeMessages.single.text, 'From two');
      expect(channel.state.messages.containsKey('sess_1'), isFalse);
      expect(sendDone.isCompleted, isTrue);
    },
  );

  test('disconnect clears pending delete in-progress guard', () async {
    final firstDeleteStarted = Completer<void>();
    final releaseFirstDelete = Completer<void>();
    var deleteCount = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        delete: (uri, headers) async {
          deleteCount += 1;
          if (deleteCount == 1) {
            firstDeleteStarted.complete();
            await releaseFirstDelete.future;
          }
          return '{"object":"hermes.session.deleted","id":"sess_1","deleted":true}';
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final firstDelete = channel.deleteSession('sess_1');
    await firstDeleteStarted.future;
    await channel.disconnect();
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.deleteSession('sess_1');
    releaseFirstDelete.complete();
    await firstDelete;

    expect(deleteCount, 2);
    expect(channel.state.status, HermesConnectionStatus.connected);
  });

  test(
    'deleteSession leaves local state alone when the server fails',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          delete: (uri, headers) async => throw StateError('delete failed'),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.deleteSession('sess_1'), throwsStateError);

      expect(channel.state.sessions.single.id, 'sess_1');
      expect(channel.state.activeSessionId, 'sess_1');
    },
  );

  test('forkSession creates and selects a copied child session', () async {
    final posts = <String, Map<String, Object?>>{};
    final channel = HermesApiChannel(
      sessionIdFactory: () => 'fork_1',
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/fork_1/messages' =>
              '{"object":"list","session_id":"fork_1","data":[{"id":"msg_f","session_id":"fork_1","role":"assistant","content":"Forked history"}]}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return '{"object":"hermes.session","session":{"id":"fork_1","source":"api_server","title":"Fork","parent_session_id":"sess_1"}}';
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.forkSession('sess_1', title: 'Fork');

    expect(posts['/api/sessions/sess_1/fork'], {
      'id': 'fork_1',
      'title': 'Fork',
    });
    expect(channel.state.sessions.map((s) => s.id), ['sess_1', 'fork_1']);
    expect(channel.state.activeSessionId, 'fork_1');
    expect(channel.state.activeSession?.parentSessionId, 'sess_1');
    expect(channel.state.activeMessages.single.text, 'Forked history');
  });

  test('forkSession leaves local state alone when the server fails', () async {
    final channel = HermesApiChannel(
      sessionIdFactory: () => 'fork_1',
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async => throw StateError('fork failed'),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await expectLater(channel.forkSession('sess_1'), throwsStateError);

    expect(channel.state.sessions.map((s) => s.id), ['sess_1']);
    expect(channel.state.activeSessionId, 'sess_1');
  });

  test(
    'forkSession leaves local state alone when forked history fails to load',
    () async {
      final channel = HermesApiChannel(
        sessionIdFactory: () => 'fork_1',
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/fork_1/messages' => throw StateError(
                'history failed',
              ),
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async =>
              '{"object":"hermes.session","session":{"id":"fork_1","source":"api_server","title":"Fork","parent_session_id":"sess_1"}}',
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(channel.forkSession('sess_1'), throwsStateError);

      expect(channel.state.sessions.map((s) => s.id), ['sess_1']);
      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
      expect(channel.state.messages.containsKey('fork_1'), isFalse);
    },
  );

  test('createSession creates and selects a new session', () async {
    final posts = <String, Map<String, Object?>>{};
    final channel = HermesApiChannel(
      sessionIdFactory: () => 'navi-test-2',
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/navi-test-2/messages' =>
              '{"object":"list","session_id":"navi-test-2","data":[]}',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return '{"object":"hermes.session","session":{"id":"navi-test-2","source":"api_server","title":"New chat"}}';
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.createSession(title: 'New chat');

    expect(posts['/api/sessions'], {'id': 'navi-test-2', 'title': 'New chat'});
    expect(channel.state.activeSessionId, 'navi-test-2');
    expect(channel.state.sessions.map((s) => s.id), ['sess_1', 'navi-test-2']);
    expect(channel.state.activeMessages, isEmpty);
  });

  test(
    'createSession leaves local state alone when new history fails to load',
    () async {
      final channel = HermesApiChannel(
        sessionIdFactory: () => 'navi-test-2',
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/navi-test-2/messages' => throw StateError(
                'history failed',
              ),
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async =>
              '{"object":"hermes.session","session":{"id":"navi-test-2","source":"api_server","title":"New chat"}}',
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await expectLater(
        channel.createSession(title: 'New chat'),
        throwsStateError,
      );

      expect(channel.state.sessions.map((s) => s.id), ['sess_1']);
      expect(channel.state.activeSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
      expect(channel.state.messages.containsKey('navi-test-2'), isFalse);
    },
  );

  test(
    'pending createSession cannot repopulate state after disconnect',
    () async {
      final createStarted = Completer<void>();
      final releaseCreate = Completer<void>();
      final channel = HermesApiChannel(
        sessionIdFactory: () => 'navi-slow',
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/navi-slow/messages' =>
                '{"object":"list","session_id":"navi-slow","data":[]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            createStarted.complete();
            await releaseCreate.future;
            return '{"object":"hermes.session","session":{"id":"navi-slow","source":"api_server","title":"Slow"}}';
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final create = channel.createSession(title: 'Slow');
      await createStarted.future;
      await channel.disconnect();
      releaseCreate.complete();
      await create;

      expect(channel.state.status, HermesConnectionStatus.disconnected);
      expect(channel.state.sessions, isEmpty);
      expect(channel.state.messages, isEmpty);
    },
  );

  test(
    'continuous voice: stage then submit sends the transcript as a Hermes text turn',
    () async {
      final sentMessages = <String>[];
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) {
            sentMessages.add((jsonDecode(body) as Map)['message'] as String);
            return Stream.fromIterable(['data: [DONE]\n\n']);
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final voiceRunId = channel.startVoiceRun();
      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.recording,
      );

      channel.stageVoiceRunTranscript(
        voiceRunId: voiceRunId,
        transcript: 'turn the lights on',
        duration: const Duration(seconds: 2),
        confidence: 0.9,
      );
      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.pendingSend,
      );

      channel.submitVoiceRun(voiceRunId);
      await pumpEventQueue();

      expect(sentMessages, ['turn the lights on']);
      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.completed,
      );
      // Reconciled with server-confirmed history after the streamed turn.
      expect(channel.state.activeMessages.map((t) => t.text), [
        'Hello',
        'Hi there',
      ]);
    },
  );

  test(
    'voice submit fails locally for blank transcripts before HTTP',
    () async {
      var postStreamCalled = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) {
            postStreamCalled = true;
            return const Stream.empty();
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final voiceRunId = channel.startVoiceRun();
      channel.stageVoiceRunTranscript(
        voiceRunId: voiceRunId,
        transcript: '   ',
        duration: const Duration(milliseconds: 500),
        confidence: 0.1,
      );

      channel.submitVoiceRun(voiceRunId);
      await pumpEventQueue();

      final run = channel.state.voiceRuns[voiceRunId]!;
      expect(run.status, NavivoxVoiceRunStatus.failed);
      expect(run.reason, 'Hermes voice transcript was empty.');
      expect(postStreamCalled, isFalse);
      expect(channel.state.activeMessages.map((turn) => turn.text), ['Hello']);
    },
  );

  test('voice submit fails locally when no Hermes session is active', () async {
    final channel = HermesApiChannel();
    final voiceRunId = channel.startVoiceRun();
    channel.stageVoiceRunTranscript(
      voiceRunId: voiceRunId,
      transcript: 'voice without a session',
      duration: const Duration(seconds: 1),
      confidence: 0.8,
    );

    channel.submitVoiceRun(voiceRunId);
    await pumpEventQueue();

    final run = channel.state.voiceRuns[voiceRunId]!;
    expect(run.status, NavivoxVoiceRunStatus.failed);
    expect(run.reason, 'Hermes channel is not connected to a session.');
    expect(run.sessionId, isNull);
    expect(channel.state.messages, isEmpty);
  });

  test(
    'voice submit fails locally when no supported chat transport is advertised',
    () async {
      var postStreamCalled = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _noChatCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) {
            postStreamCalled = true;
            return const Stream.empty();
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final voiceRunId = channel.startVoiceRun();
      channel.stageVoiceRunTranscript(
        voiceRunId: voiceRunId,
        transcript: 'voice without transport',
        duration: const Duration(seconds: 1),
        confidence: 0.8,
      );

      channel.submitVoiceRun(voiceRunId);
      await pumpEventQueue();

      final run = channel.state.voiceRuns[voiceRunId]!;
      expect(run.status, NavivoxVoiceRunStatus.failed);
      expect(run.reason, contains('supported chat transport'));
      expect(run.sessionId, isNull);
      expect(postStreamCalled, isFalse);
      expect(channel.state.activeMessages.map((turn) => turn.text), ['Hello']);
    },
  );

  test('voice submit fails when Hermes produces no assistant reply', () async {
    var messagesRequests = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        postStream: (uri, headers, body) {
          messagesRequests += 1;
          return Stream.fromIterable(['data: [DONE]\n\n']);
        },
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final voiceRunId = channel.startVoiceRun();
    channel.stageVoiceRunTranscript(
      voiceRunId: voiceRunId,
      transcript: 'voice with no reply',
      duration: const Duration(seconds: 1),
      confidence: 0.8,
    );

    channel.submitVoiceRun(voiceRunId);
    await pumpEventQueue();

    final run = channel.state.voiceRuns[voiceRunId]!;
    expect(messagesRequests, 1);
    expect(run.status, NavivoxVoiceRunStatus.failed);
    expect(run.reason, 'Hermes voice turn did not complete.');
  });

  test(
    'voice submit fails instead of completing if the session changes mid-turn',
    () async {
      final stream = _ManualStringStream();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _twoSessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              '/api/sessions/sess_2/messages' =>
                '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"From two"}]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final voiceRunId = channel.startVoiceRun();
      channel.stageVoiceRunTranscript(
        voiceRunId: voiceRunId,
        transcript: 'voice before switch',
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      );

      channel.submitVoiceRun(voiceRunId);
      await pumpEventQueue();
      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.submitted,
      );

      await channel.selectSession('sess_2');
      await pumpEventQueue();

      final run = channel.state.voiceRuns[voiceRunId];
      expect(run?.status, NavivoxVoiceRunStatus.failed);
      expect(run?.reason, 'Hermes voice turn did not complete.');
      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.activeMessages.single.text, 'From two');
    },
  );

  test(
    'cancelled voice run ignores late transcript staging and submit',
    () async {
      var postStreamCalled = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) {
            postStreamCalled = true;
            return const Stream<String>.empty();
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final voiceRunId = channel.startVoiceRun();
      channel.cancelVoiceRun(voiceRunId, reason: 'user cancelled');

      channel.stageVoiceRunTranscript(
        voiceRunId: voiceRunId,
        transcript: 'late transcript',
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      );
      channel.submitVoiceRun(voiceRunId);
      await pumpEventQueue();

      final run = channel.state.voiceRuns[voiceRunId];
      expect(run?.status, NavivoxVoiceRunStatus.cancelled);
      expect(run?.reason, 'user cancelled');
      expect(run?.transcript, isNull);
      expect(postStreamCalled, isFalse);
    },
  );

  test(
    'cancelled voice run is not overwritten by late send completion',
    () async {
      final stream = _ManualStringStream();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final voiceRunId = channel.startVoiceRun();
      channel.stageVoiceRunTranscript(
        voiceRunId: voiceRunId,
        transcript: 'cancel after submit',
        duration: const Duration(seconds: 1),
        confidence: 0.9,
      );

      channel.submitVoiceRun(voiceRunId);
      await pumpEventQueue();
      channel.cancelVoiceRun(voiceRunId, reason: 'user cancelled');
      stream.emit('data: [DONE]\n\n');
      await pumpEventQueue();

      final run = channel.state.voiceRuns[voiceRunId];
      expect(run?.status, NavivoxVoiceRunStatus.cancelled);
      expect(run?.reason, 'user cancelled');
    },
  );

  test('terminal voice run ignores late cancel and fail calls', () async {
    var messagesRequests = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        postStream: (uri, headers, body) =>
            Stream.fromIterable(['data: [DONE]\n\n']),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final voiceRunId = channel.startVoiceRun();
    channel.stageVoiceRunTranscript(
      voiceRunId: voiceRunId,
      transcript: 'done voice run',
      duration: const Duration(seconds: 1),
      confidence: 0.8,
    );

    channel.submitVoiceRun(voiceRunId);
    await pumpEventQueue();
    expect(
      channel.state.voiceRuns[voiceRunId]?.status,
      NavivoxVoiceRunStatus.completed,
    );

    channel.cancelVoiceRun(voiceRunId, reason: 'late cancel');
    channel.failVoiceRun(voiceRunId, reason: 'late failure');

    final run = channel.state.voiceRuns[voiceRunId];
    expect(run?.status, NavivoxVoiceRunStatus.completed);
    expect(run?.reason, isNull);
  });

  test(
    'cancelVoiceRun marks the run cancelled without sending anything',
    () async {
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) =>
              throw StateError('should not send while cancelling'),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final voiceRunId = channel.startVoiceRun();
      channel.cancelVoiceRun(voiceRunId, reason: 'user cancelled');

      expect(
        channel.state.voiceRuns[voiceRunId]?.status,
        NavivoxVoiceRunStatus.cancelled,
      );
      expect(channel.state.activeVoiceRun, isNull);
    },
  );

  test(
    'dispose cancels an active run stream and completes pending send',
    () async {
      final stream = _ManualStringStream();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) => stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('keep going');
      await pumpEventQueue();
      expect(stream.cancelCount, 0);

      channel.dispose();
      await send;
      stream.emit('event: message.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(stream.cancelCount, 1);
    },
  );

  test(
    'disconnect while run submission later fails keeps disconnected state empty',
    () async {
      final startRunStarted = Completer<void>();
      final releaseStartRun = Completer<void>();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            startRunStarted.complete();
            await releaseStartRun.future;
            throw StateError('late run submit failed');
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('slow run');
      await startRunStarted.future;
      await channel.disconnect();
      releaseStartRun.complete();
      await send;

      expect(channel.state.status, HermesConnectionStatus.disconnected);
      expect(channel.state.messages, isEmpty);
      expect(channel.state.errorMessage, isNull);
    },
  );

  test(
    'disconnect while run submission is pending prevents late run stream attach',
    () async {
      final startRunStarted = Completer<void>();
      final releaseStartRun = Completer<void>();
      final sendDone = Completer<void>();
      final stream = _ManualStringStream();
      var runEventsOpened = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            expect(uri.path, '/v1/runs');
            if (!startRunStarted.isCompleted) startRunStarted.complete();
            await releaseStartRun.future;
            return '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}';
          },
          getStream: (uri, headers) {
            runEventsOpened = true;
            return stream;
          },
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      unawaited(channel.sendText('slow run').whenComplete(sendDone.complete));
      await startRunStarted.future;
      await channel.disconnect();
      releaseStartRun.complete();
      await sendDone.future;
      stream.emit('event: message.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(runEventsOpened, isFalse);
      expect(channel.state.status, HermesConnectionStatus.disconnected);
      expect(channel.state.messages, isEmpty);
    },
  );

  test(
    'stale run submission cannot attach a run id to a newer connection',
    () async {
      final startRunStarted = Completer<void>();
      final releaseStartRun = Completer<void>();
      final sendDone = Completer<void>();
      final approvalPosts = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            if (uri.path == '/v1/runs') {
              if (config.baseUri.port == 8642) {
                if (!startRunStarted.isCompleted) startRunStarted.complete();
                await releaseStartRun.future;
                return '{"object":"hermes.run","run":{"id":"old_run","session_id":"sess_1"}}';
              }
              return '{"object":"hermes.run","run":{"id":"new_run","session_id":"sess_1"}}';
            }
            approvalPosts.add(uri.path);
            return '{}';
          },
          getStream: (uri, headers) => const Stream<String>.empty(),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      unawaited(channel.sendText('slow run').whenComplete(sendDone.complete));
      await startRunStarted.future;
      await channel.connect(baseUrl: 'http://127.0.0.1:8643');
      releaseStartRun.complete();
      await sendDone.future;

      await expectLater(
        channel.respondToApproval(
          approvalId: 'appr_1',
          decision: HermesApprovalDecision.once,
        ),
        throwsA(isA<StateError>()),
      );
      expect(approvalPosts, isEmpty);
      expect(
        channel.state.errorMessage,
        'Could not answer approval: active run is no longer available.',
      );
    },
  );

  test(
    'sendText uses run transport when advertised: streams deltas, surfaces an approval, then reconciles',
    () async {
      final approvals = <NavivoxApprovalRequest>[];
      var messagesRequests = 0;
      final posts = <String, Map<String, Object?>>{};
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) {
            expect(uri.path, '/v1/runs/run_1/events');
            return Stream.fromIterable([
              'event: message.delta\ndata: {"delta":"Hi"}\n\n',
              'event: approval.request\ndata: {"approval_id":"appr_1","prompt":"Run rm -rf?","risk":"high"}\n\n',
              'event: run.completed\ndata: {}\n\ndata: [DONE]\n\n',
            ]);
          },
        ),
      );
      channel.approvalRequests.listen(approvals.add);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('rm the temp dir');

      expect(posts['/v1/runs'], {
        'session_id': 'sess_1',
        'message': 'rm the temp dir',
      });
      expect(approvals, hasLength(1));
      expect(approvals.single.id, 'appr_1');
      expect(approvals.single.prompt, 'Run rm -rf?');
      expect(approvals.single.risk, 'high');
      // Reconciled with server-confirmed history after the run completed.
      expect(channel.state.activeMessages.map((t) => t.text), [
        'Hello',
        'Hi there',
      ]);
    },
  );

  test('sendText accepts approval id aliases from run events', () async {
    final approvals = <NavivoxApprovalRequest>[];
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => Stream.fromIterable([
          'event: approval.request\ndata: {"id":"appr_alias","toolCallId":"tool_alias","prompt":"Approve alias?"}\n\n',
          'event: run.completed\ndata: {}\n\ndata: [DONE]\n\n',
        ]),
      ),
    );
    channel.approvalRequests.listen(approvals.add);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('needs approval');

    expect(approvals, hasLength(1));
    expect(approvals.single.id, 'appr_alias');
    expect(approvals.single.toolCallId, 'tool_alias');
    expect(approvals.single.prompt, 'Approve alias?');
    expect(channel.state.errorMessage, isNull);
  });

  test('sendText fails locally for malformed approval requests', () async {
    final approvals = <NavivoxApprovalRequest>[];
    final stream = _ManualStringStream();
    final sendDone = Completer<void>();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream,
      ),
    );
    channel.approvalRequests.listen(approvals.add);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    unawaited(
      channel.sendText('needs approval').whenComplete(sendDone.complete),
    );
    await pumpEventQueue();
    stream.emit('event: approval.request\ndata: {"prompt":"Approve?"}\n\n');
    await pumpEventQueue();

    expect(sendDone.isCompleted, isTrue);
    expect(approvals, isEmpty);
    expect(
      channel.state.errorMessage,
      'Hermes approval request was missing an approval id.',
    );
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'needs approval',
      '',
    ]);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test(
    'sendText completes and reconciles when run completed arrives without stream close',
    () async {
      var messagesRequests = 0;
      final stream = StreamController<String>();
      addTearDown(stream.close);
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => stream.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('finish run');
      await pumpEventQueue();
      stream.add('event: message.delta\ndata: {"delta":"local"}\n\n');
      stream.add('event: run.completed\ndata: {}\n\n');
      await send;
      stream.add('event: message.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'Hi there',
      ]);
    },
  );

  test(
    'sendText keeps streamed assistant when server history is stale',
    () async {
      var messagesRequests = 0;
      final stream = StreamController<String>();
      addTearDown(stream.close);
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0) ? _messagesFixture : _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => stream.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('finish run');
      await pumpEventQueue();
      stream.add('event: message.delta\ndata: {"delta":"local reply"}\n\n');
      stream.add('event: run.completed\ndata: {}\n\n');
      await send;

      expect(messagesRequests, 2);
      expect(channel.state.errorMessage, isNull);
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'finish run',
        'local reply',
      ]);
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.completed,
      );
    },
  );

  test('sendText ignores stream errors after terminal success', () async {
    var messagesRequests = 0;
    final stream = StreamController<String>();
    addTearDown(stream.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final send = channel.sendText('finish run');
    await pumpEventQueue();
    stream.add('event: message.delta\ndata: {"delta":"local"}\n\n');
    stream.add('event: run.completed\ndata: {}\n\n');
    stream.addError(StateError('late stream drop'));
    await send;
    await pumpEventQueue();

    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'Hi there',
    ]);
  });

  test('sendText treats assistant completed as terminal success', () async {
    var messagesRequests = 0;
    final stream = StreamController<String>();
    addTearDown(stream.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final send = channel.sendText('finish assistant');
    await pumpEventQueue();
    stream.add('event: message.delta\ndata: {"delta":"local"}\n\n');
    stream.add('event: assistant.completed\ndata: {}\n\n');
    await send;
    stream.add('event: message.delta\ndata: {"delta":"late"}\n\n');
    await pumpEventQueue();

    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'Hi there',
    ]);
  });

  test('sendText treats message completed as terminal success', () async {
    var messagesRequests = 0;
    final stream = StreamController<String>();
    addTearDown(stream.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              (messagesRequests++ == 0)
                  ? _messagesFixture
                  : _reconciledMessagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final send = channel.sendText('finish message');
    await pumpEventQueue();
    stream.add('event: message.delta\ndata: {"delta":"local"}\n\n');
    stream.add('event: message.completed\ndata: {}\n\n');
    await send;

    expect(messagesRequests, 2);
    expect(channel.state.errorMessage, isNull);
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'Hi there',
    ]);
  });

  test(
    'sendText completes when a terminal run cancelled event arrives without stream close',
    () async {
      final stream = _ManualStringStream();
      final sendDone = Completer<void>();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      unawaited(channel.sendText('cancel run').whenComplete(sendDone.complete));
      await pumpEventQueue();
      stream.emit('event: run.cancelled\ndata: {}\n\n');
      await pumpEventQueue();

      expect(sendDone.isCompleted, isTrue);
      stream.emit('event: message.delta\ndata: {"delta":"late"}\n\n');
      await pumpEventQueue();

      expect(channel.state.errorMessage, 'Hermes run was cancelled.');
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'cancel run',
        '',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test('sendText treats message failed as terminal failure', () async {
    final stream = _ManualStringStream();
    final sendDone = Completer<void>();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    unawaited(channel.sendText('fail message').whenComplete(sendDone.complete));
    await pumpEventQueue();
    stream.emit('event: message.failed\ndata: {}\n\n');
    await pumpEventQueue();

    expect(sendDone.isCompleted, isTrue);
    expect(channel.state.errorMessage, 'Hermes run failed.');
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'fail message',
      '',
    ]);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test('sendText treats assistant failed as terminal failure', () async {
    final stream = _ManualStringStream();
    final sendDone = Completer<void>();
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    unawaited(
      channel.sendText('fail assistant').whenComplete(sendDone.complete),
    );
    await pumpEventQueue();
    stream.emit('event: message.delta\ndata: {"delta":"partial"}\n\n');
    await pumpEventQueue();
    stream.emit('event: assistant.failed\ndata: {}\n\n');
    await pumpEventQueue();

    expect(sendDone.isCompleted, isTrue);
    stream.emit('event: message.delta\ndata: {"delta":"late"}\n\n');
    await pumpEventQueue();

    expect(channel.state.errorMessage, 'Hermes run failed.');
    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Hello',
      'fail assistant',
      'partial',
    ]);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
  });

  test(
    'sendText keeps local failed assistant turn when run failed event arrives',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => Stream.fromIterable([
            'event: message.delta\ndata: {"delta":"partial"}\n\n',
            'event: run.failed\ndata: {}\n\ndata: [DONE]\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('fail the run');

      expect(messagesRequests, 1);
      expect(channel.state.errorMessage, 'Hermes run failed.');
      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'fail the run',
        'partial',
      ]);
      expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    },
  );

  test(
    'sendText via run transport tracks tool events by call id instead of duplicating turns',
    () async {
      var messagesRequests = 0;
      final states = <HermesChannelState>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => Stream.fromIterable([
            'event: tool.started\ndata: {"tool":"bash","preview":"ls -la"}\n\n',
            'event: message.delta\ndata: {"delta":"Looking"}\n\n',
            'event: tool.completed\ndata: {"tool":"bash","result_text":"file1"}\n\n',
            'event: message.delta\ndata: {"delta":" done"}\n\ndata: [DONE]\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      channel.addListener(() => states.add(channel.state));

      await channel.sendText('list the files');

      // Snapshot from mid-run, before reconciliation replaces the transcript
      // with server-confirmed history: exactly one tool-call turn (not two),
      // updated in place from `running` to `completed`, ordered before the
      // streaming assistant reply.
      final duringRun = states.lastWhere(
        (s) => s.activeMessages.any((t) => t.kind == HermesTurnKind.toolCall),
      );
      final turns = duringRun.activeMessages;
      expect(
        turns.where((t) => t.kind == HermesTurnKind.toolCall),
        hasLength(1),
      );
      final toolTurn = turns.firstWhere(
        (t) => t.kind == HermesTurnKind.toolCall,
      );
      final toolIndex = turns.indexOf(toolTurn);
      final assistantIndex = turns.indexWhere(
        (t) => t.author == HermesTurnAuthor.assistant,
      );
      expect(toolIndex, lessThan(assistantIndex));
      expect(toolTurn.toolCall?.name, 'bash');
      expect(toolTurn.toolCall?.status, 'completed');
      expect(toolTurn.toolCall?.result, 'file1');
    },
  );

  test('sendText via run transport updates tool progress in place', () async {
    final states = <HermesChannelState>[];
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => Stream.fromIterable([
          'event: tool.started\ndata: {"tool":"bash","tool_call_id":"call_1","preview":"starting"}\n\n',
          'event: tool.progress\ndata: {"tool":"bash","tool_call_id":"call_1","preview":"halfway"}\n\n',
          'event: message.delta\ndata: {"delta":"done"}\n\ndata: [DONE]\n\n',
        ]),
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    channel.addListener(() => states.add(channel.state));

    await channel.sendText('track progress');

    final progressState = states.lastWhere(
      (s) => s.activeMessages.any(
        (turn) =>
            turn.kind == HermesTurnKind.toolCall &&
            turn.toolCall?.preview == 'halfway',
      ),
    );
    final toolTurns = progressState.activeMessages
        .where((turn) => turn.kind == HermesTurnKind.toolCall)
        .toList(growable: false);
    expect(toolTurns, hasLength(1));
    expect(toolTurns.single.toolCall?.name, 'bash');
    expect(toolTurns.single.toolCall?.status, 'running');
    expect(toolTurns.single.toolCall?.preview, 'halfway');
  });

  test(
    'sendText via run transport keeps same-name tool calls separate by event call id',
    () async {
      var messagesRequests = 0;
      final states = <HermesChannelState>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                (messagesRequests++ == 0)
                    ? _messagesFixture
                    : _reconciledMessagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => Stream.fromIterable([
            'event: tool.started\ndata: {"tool":"bash","tool_call_id":"call_a","preview":"ls"}\n\n',
            'event: tool.started\ndata: {"tool":"bash","tool_call_id":"call_b","preview":"pwd"}\n\n',
            'event: tool.completed\ndata: {"tool":"bash","tool_call_id":"call_a","result_text":"file1"}\n\n',
            'event: tool.completed\ndata: {"tool":"bash","tool_call_id":"call_b","result_text":"/tmp"}\n\n',
            'event: message.delta\ndata: {"delta":"done"}\n\ndata: [DONE]\n\n',
          ]),
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      channel.addListener(() => states.add(channel.state));

      await channel.sendText('run two commands');

      final duringRun = states.lastWhere(
        (s) =>
            s.activeMessages
                .where((t) => t.kind == HermesTurnKind.toolCall)
                .length ==
            2,
      );
      final toolTurns = duringRun.activeMessages
          .where((t) => t.kind == HermesTurnKind.toolCall)
          .toList(growable: false);
      expect(toolTurns, hasLength(2));
      expect(toolTurns.map((turn) => turn.toolCall?.name), ['bash', 'bash']);
      expect(toolTurns.map((turn) => turn.toolCall?.status), [
        'completed',
        'completed',
      ]);
      expect(toolTurns.map((turn) => turn.toolCall?.result), ['file1', '/tmp']);
    },
  );

  test(
    'respondToApproval rejects locally when approval endpoint is absent',
    () async {
      final posts = <String>[];
      final openRunEvents = StreamController<String>();
      addTearDown(openRunEvents.close);
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsWithoutStopCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            posts.add(uri.path);
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              _ => '{}',
            };
          },
          getStream: (uri, headers) => openRunEvents.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      unawaited(channel.sendText('do the risky thing'));
      await pumpEventQueue();

      await expectLater(
        channel.respondToApproval(
          approvalId: 'appr_1',
          decision: HermesApprovalDecision.once,
        ),
        throwsStateError,
      );

      expect(posts, ['/v1/runs']);
      expect(
        channel.state.errorMessage,
        contains('did not advertise approval responses'),
      );
    },
  );

  test('respondToApproval rejects blank approval ids before POST', () async {
    final posts = <String>[];
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts.add(uri.path);
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('do the risky thing'));
    await pumpEventQueue();

    await expectLater(
      channel.respondToApproval(
        approvalId: '   ',
        decision: HermesApprovalDecision.once,
      ),
      throwsStateError,
    );

    expect(posts, ['/v1/runs']);
    expect(channel.state.errorMessage, contains('approval id is missing'));
  });

  test('respondToApproval trims approval ids before POST', () async {
    final posts = <String, Map<String, Object?>>{};
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('do the risky thing'));
    await pumpEventQueue();

    await channel.respondToApproval(
      approvalId: '  appr_1  ',
      decision: HermesApprovalDecision.once,
    );

    expect(posts['/v1/runs/run_1/approval'], {
      'approval_id': 'appr_1',
      'decision': 'once',
    });
  });

  test('respondToApproval answers the active run', () async {
    final posts = <String, Map<String, Object?>>{};
    // Left open deliberately: the run is still active awaiting the
    // operator's approval decision when respondToApproval is called.
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('do the risky thing'));
    await pumpEventQueue();
    openRunEvents.add(
      'event: approval.request\ndata: {"approval_id":"appr_1"}\n\n',
    );
    await pumpEventQueue();

    await channel.respondToApproval(
      approvalId: 'appr_1',
      decision: HermesApprovalDecision.always,
    );

    expect(posts['/v1/runs/run_1/approval'], {
      'approval_id': 'appr_1',
      'decision': 'always',
    });
  });

  test(
    'respondToApproval ignores failures after the active run is gone',
    () async {
      final openRunEvents = StreamController<String>();
      final approvalStarted = Completer<void>();
      final releaseApproval = Completer<void>();
      addTearDown(openRunEvents.close);
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              '/v1/runs/run_1/approval' => () async {
                approvalStarted.complete();
                await releaseApproval.future;
                throw StateError('approval failed after disconnect');
              }(),
              _ => '{}',
            };
          },
          getStream: (uri, headers) => openRunEvents.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      unawaited(channel.sendText('do the risky thing'));
      await pumpEventQueue();
      openRunEvents.add(
        'event: approval.request\ndata: {"approval_id":"appr_1"}\n\n',
      );
      await pumpEventQueue();

      final response = channel.respondToApproval(
        approvalId: 'appr_1',
        decision: HermesApprovalDecision.once,
      );
      await approvalStarted.future;
      await channel.disconnect();
      releaseApproval.complete();
      await response;

      expect(channel.state.status, HermesConnectionStatus.disconnected);
      expect(channel.state.errorMessage, isNull);
    },
  );

  test('respondToApproval surfaces approval response failures', () async {
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            '/v1/runs/run_1/approval' => throw StateError('approval failed'),
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    unawaited(channel.sendText('do the risky thing'));
    await pumpEventQueue();
    openRunEvents.add(
      'event: approval.request\ndata: {"approval_id":"appr_1"}\n\n',
    );
    await pumpEventQueue();

    await expectLater(
      channel.respondToApproval(
        approvalId: 'appr_1',
        decision: HermesApprovalDecision.once,
      ),
      throwsA(isA<StateError>()),
    );

    expect(channel.state.errorMessage, contains('Could not answer approval'));
    expect(channel.state.errorMessage, contains('approval failed'));
  });

  test(
    'stopActiveTurn swallows server stop failure after clearing the active run',
    () async {
      final stopRequests = <String>[];
      final openRunEvents = StreamController<String>();
      addTearDown(openRunEvents.close);
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _runsCapableCapabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' => _messagesFixture,
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          post: (uri, headers, body) async {
            return switch (uri.path) {
              '/v1/runs' =>
                '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
              '/v1/runs/run_1/stop' => throw StateError(
                (stopRequests..add(uri.path)).join(','),
              ),
              _ => '{}',
            };
          },
          getStream: (uri, headers) => openRunEvents.stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');
      unawaited(channel.sendText('keep going forever'));
      await pumpEventQueue();

      channel.stopActiveTurn();
      channel.stopActiveTurn();
      await pumpEventQueue();

      expect(stopRequests, ['/v1/runs/run_1/stop']);
    },
  );

  test('stopActiveTurn stays local when run stop is not advertised', () async {
    final posts = <String>[];
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsWithoutStopCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts.add(uri.path);
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final sendFuture = channel.sendText('keep going forever');
    await pumpEventQueue();

    channel.stopActiveTurn();
    await sendFuture;
    await pumpEventQueue();

    expect(posts, ['/v1/runs']);
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    expect(channel.state.activeMessages.last.text, 'Stopped.');
  });

  test('stopActiveTurn stops the active run on the server', () async {
    final posts = <String, Map<String, Object?>>{};
    // Left open deliberately: simulates a long-running turn that only stops
    // because the operator calls stopActiveTurn, not because the stream ends.
    final openRunEvents = StreamController<String>();
    addTearDown(openRunEvents.close);
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _runsCapableCapabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          posts[uri.path] = jsonDecode(body) as Map<String, Object?>;
          return switch (uri.path) {
            '/v1/runs' =>
              '{"object":"hermes.run","run":{"id":"run_1","session_id":"sess_1"}}',
            _ => '{}',
          };
        },
        getStream: (uri, headers) => openRunEvents.stream,
      ),
    );
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final sendFuture = channel.sendText('keep going forever');
    await pumpEventQueue();

    channel.stopActiveTurn();
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    expect(channel.state.activeMessages.last.text, 'Stopped.');
    await sendFuture;
    await pumpEventQueue();

    expect(posts['/v1/runs/run_1/stop'], <String, Object?>{});
    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    expect(channel.state.activeMessages.last.text, 'Stopped.');
  });
}

const _capabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_create": {"method": "POST", "path": "/api/sessions"},
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"},
    "session_update": {"method": "PATCH", "path": "/api/sessions/{session_id}"},
    "session_delete": {"method": "DELETE", "path": "/api/sessions/{session_id}"},
    "session_fork": {"method": "POST", "path": "/api/sessions/{session_id}/fork"}
  }
}
''';

const _chatOnlyCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"}
  }
}
''';

const _sessionCreateCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_create": {"method": "POST", "path": "/api/sessions"},
    "session_chat_stream": {"method": "POST", "path": "/api/sessions/{session_id}/chat/stream"}
  }
}
''';

const _noChatCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {},
  "endpoints": {}
}
''';

const _catalogCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {},
  "endpoints": {
    "models": {"method": "GET", "path": "/v1/models"},
    "skills": {"method": "GET", "path": "/v1/skills"},
    "toolsets": {"method": "GET", "path": "/v1/toolsets"}
  }
}
''';

const _jobsCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {"jobs_admin": false},
  "endpoints": {
    "jobs": {"method": "GET", "path": "/api/jobs"}
  }
}
''';

const _healthCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {},
  "endpoints": {
    "health_detailed": {"method": "GET", "path": "/health/detailed"}
  }
}
''';

const _runsWithoutStopCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "run_submission": true,
    "run_events_sse": true
  },
  "endpoints": {
    "runs": {"method": "POST", "path": "/v1/runs"},
    "run_events": {"method": "GET", "path": "/v1/runs/{run_id}/events"}
  }
}
''';

const _runsCapableCapabilitiesFixture = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "auth": {"type": "bearer", "required": true},
  "features": {
    "session_chat_streaming": true,
    "run_submission": true,
    "run_status": true,
    "run_events_sse": true,
    "run_stop": true,
    "run_approval_response": true,
    "tool_progress_events": true
  },
  "endpoints": {
    "runs": {"method": "POST", "path": "/v1/runs"},
    "run_status": {"method": "GET", "path": "/v1/runs/{run_id}"},
    "run_events": {"method": "GET", "path": "/v1/runs/{run_id}/events"},
    "run_approval": {"method": "POST", "path": "/v1/runs/{run_id}/approval"},
    "run_stop": {"method": "POST", "path": "/v1/runs/{run_id}/stop"}
  }
}
''';

const _modelsFixture = '''
{
  "object": "list",
  "data": [
    {"id": "hermes-agent", "owned_by": "hermes"}
  ]
}
''';

const _skillsFixture = '''
{
  "object": "list",
  "data": [
    {"name": "ascii-art", "description": "ASCII art generation", "category": "creative"},
    {"name": "github", "description": "GitHub workflow skill", "category": "github"}
  ]
}
''';

const _toolsetsFixture = '''
{
  "object": "list",
  "platform": "api_server",
  "data": [
    {"name": "default", "label": "Default Tools", "enabled": true, "configured": true, "tools": ["read_file"]},
    {"name": "web", "label": "Web Tools", "enabled": false, "configured": true, "tools": ["web_search"]}
  ]
}
''';

const _jobsFixture = '''
{
  "jobs": [
    {"id": "job_1", "name": "Morning check", "enabled": true, "schedule_display": "Daily"}
  ]
}
''';

class _ManualStringStream extends Stream<String> {
  void Function(String)? _onData;

  int cancelCount = 0;

  void emit(String value) => _onData?.call(value);

  @override
  StreamSubscription<String> listen(
    void Function(String event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _onData = onData;
    return _ManualStringSubscription(this);
  }
}

class _ManualStringSubscription implements StreamSubscription<String> {
  _ManualStringSubscription(this._stream);

  final _ManualStringStream _stream;
  bool _paused = false;

  @override
  Future<void> cancel() async {
    _stream.cancelCount += 1;
    // Intentionally keep callbacks installed so tests can simulate stale events
    // that arrive after channel-side cancellation.
  }

  @override
  void onData(void Function(String data)? handleData) {
    _stream._onData = handleData;
  }

  @override
  void onError(Function? handleError) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void pause([Future<void>? resumeSignal]) {
    _paused = true;
    resumeSignal?.whenComplete(resume);
  }

  @override
  void resume() {
    _paused = false;
  }

  @override
  bool get isPaused => _paused;

  @override
  Future<E> asFuture<E>([E? futureValue]) async => futureValue as E;
}

const _sessionsFixture = '''
{
  "object": "list",
  "data": [
    {"id": "sess_1", "source": "api_server", "title": "Demo", "message_count": 1}
  ]
}
''';

const _messagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"}
  ]
}
''';

const _twoSessionsFixture = '''
{
  "object": "list",
  "data": [
    {"id": "sess_1", "source": "api_server", "title": "One", "message_count": 1},
    {"id": "sess_2", "source": "api_server", "title": "Two", "message_count": 1}
  ]
}
''';

const _reconciledMessagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"},
    {"id": "msg_2", "session_id": "sess_1", "role": "assistant", "content": "Hi there"}
  ]
}
''';

const _duplicateMessagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"},
    {"id": "msg_2", "session_id": "sess_1", "role": "user", "content": "Hello again"},
    {"id": "msg_3", "session_id": "sess_1", "role": "assistant", "content": "Old answer"}
  ]
}
''';

const _interleavedLaterReplyMessagesFixture = '''
{
  "object": "list",
  "session_id": "sess_1",
  "data": [
    {"id": "msg_1", "session_id": "sess_1", "role": "user", "content": "Hello"},
    {"id": "msg_2", "session_id": "sess_1", "role": "user", "content": "closed stream"},
    {"id": "msg_3", "session_id": "sess_1", "role": "user", "content": "newer question"},
    {"id": "msg_4", "session_id": "sess_1", "role": "assistant", "content": "newer answer"}
  ]
}
''';
