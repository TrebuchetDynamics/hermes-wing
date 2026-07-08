part of '../hermes_api_channel_test.dart';

void _hermesApiChannelDirectChatTests() {
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
}
