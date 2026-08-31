part of '../hermes_api_channel_test.dart';

void _hermesApiChannelDirectChatTests() {
  test('historical tool results stay out of the visible transcript', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              '''
{"object":"list","data":[
  {"id":"tool-1","session_id":"sess_1","role":"tool","content":"{\\"content\\":\\"1|internal\\",\\"total_lines\\":1}"},
  {"id":"assistant-1","session_id":"sess_1","role":"assistant","content":"Visible answer"}
]}
''',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);

    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    expect(channel.state.activeMessages.map((turn) => turn.text), [
      'Visible answer',
    ]);
  });

  test('sendText fails an SSE stream that stays open but idle', () async {
    final stream = StreamController<String>();
    addTearDown(stream.close);
    final channel = HermesApiChannel(
      streamIdleTimeout: const Duration(milliseconds: 20),
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
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText('idle stream');

    expect(channel.state.activeMessages.last.status, HermesTurnStatus.failed);
    expect(channel.state.errorMessage, contains('timed out'));
  });

  test('sendText safely inlines a text attachment', () async {
    Map<String, Object?>? requestBody;
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
          requestBody = jsonDecode(body) as Map<String, Object?>;
          return Stream.value('data: [DONE]\n\n');
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText(
      '',
      textAttachment: 'alpha\nbeta',
      attachmentName: 'notes<&.txt',
    );

    expect(requestBody, {
      'message': [
        {
          'type': 'input_text',
          'text':
              '<file name="notes&lt;&amp;.txt" mime="text/plain">\nalpha\nbeta\n</file>',
        },
      ],
    });
  });

  test('text attachment filename round-trips through history safely', () async {
    Map<String, Object?>? requestBody;
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
          requestBody = jsonDecode(body) as Map<String, Object?>;
          return Stream.value('data: [DONE]\n\n');
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText(
      '',
      textAttachment: 'private contents',
      attachmentName: '  ${List.filled(120, '&quot;').join()}\r\nsecret.md  ',
    );

    final content = (requestBody!['message'] as List<Object?>)
        .cast<Map<String, Object?>>()
        .single['text'];
    final restored = HermesMessage.fromJson({
      'id': 'restored',
      'session_id': 'sess_1',
      'role': 'user',
      'content': [
        {'type': 'input_text', 'text': content},
      ],
    });
    expect(restored.content, isEmpty);
    expect(restored.content, isNot(contains('private contents')));
    expect(restored.attachment?.kind, HermesAttachmentKind.file);
    expect(restored.attachment?.name, isNot(contains(RegExp(r'[\r\n]'))));
    expect(restored.attachment?.name.length, lessThanOrEqualTo(512));
  });

  test(
    'plain duplicate prose does not inherit optimistic attachment metadata',
    () async {
      var messageReads = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _sessionsFixture,
              '/api/sessions/sess_1/messages' =>
                messageReads++ == 0
                    ? _messagesFixture
                    : '''{"object":"list","data":[{"id":"msg_1","session_id":"sess_1","role":"user","content":"Hello"},{"id":"server-plain","session_id":"sess_1","role":"user","content":"Inspect"}]}''',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
          postStream: (uri, headers, body) => Stream.value('data: [DONE]\n\n'),
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText(
        'Inspect',
        imageDataUrl: 'data:image/png;base64,c2FmZQ==',
        attachmentName: 'photo.png',
      );

      final reconciled = channel.state.activeMessages.last;
      expect(reconciled.id, 'server-plain');
      expect(reconciled.text, 'Inspect');
      expect(reconciled.attachment, isNull);
    },
  );

  test('image reconciliation preserves the optimistic attachment name', () async {
    var messageReads = 0;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              messageReads++ == 0
                  ? _messagesFixture
                  : '''{"object":"list","data":[{"id":"msg_1","session_id":"sess_1","role":"user","content":"Hello"},{"id":"server-image","session_id":"sess_1","role":"user","content":[{"type":"input_text","text":"Inspect"},{"type":"input_image","image_url":"data:image/png;base64,secret"}]}]}''',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        postStream: (uri, headers, body) => Stream.value('data: [DONE]\n\n'),
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.sendText(
      'Inspect',
      imageDataUrl: 'data:image/png;base64,c2FmZQ==',
      attachmentName: 'photo.png',
    );

    final imageTurn = channel.state.activeMessages.last;
    expect(imageTurn.id, 'server-image');
    expect(imageTurn.text, 'Inspect');
    expect(imageTurn.attachment?.kind, HermesAttachmentKind.image);
    expect(imageTurn.attachment?.name, 'photo.png');
  });

  test('restores an image-only turn as a structured attachment', () async {
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' =>
              '''{"object":"list","data":[{"id":"server-image","session_id":"sess_1","role":"user","content":[{"type":"image_url","image_url":{"url":"data:image/png;base64,secret"}}]}]}''',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final imageTurn = channel.state.activeMessages.single;
    expect(imageTurn.text, isEmpty);
    expect(imageTurn.attachment?.kind, HermesAttachmentKind.image);
    expect(imageTurn.attachment?.name, 'attachment');
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
    'sendText fails a completed direct stream with no assistant reply',
    () async {
      var messagesRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => () {
              messagesRequests += 1;
              return _messagesFixture;
            }(),
            _ => throw StateError('unexpected GET $uri'),
          },
          postStream: (uri, headers, body) =>
              Stream<String>.fromIterable(const [
                'event: run.started\ndata: {}\n\n',
                'event: message.started\ndata: {}\n\n',
                'event: assistant.completed\ndata: {}\n\n',
                'event: run.completed\ndata: {}\n\n',
                'event: done\ndata: {}\n\n',
              ]),
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      await channel.sendText('empty completed reply');

      expect(messagesRequests, 2);
      expect(
        channel.state.errorMessage,
        'Hermes finished without an assistant reply.',
      );
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

  test(
    'sendText rejects a declared but ungranted chat scope before HTTP',
    () async {
      const capabilities = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "schema_version": 1,
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["chat:read"]},
  "features": {"session_chat_streaming": true},
  "endpoints": {
    "session_chat_stream": {
      "method": "POST",
      "path": "/api/sessions/{session_id}/chat/stream",
      "required_scopes": ["chat:write"]
    }
  }
}
''';
      var postStreamCalled = false;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => capabilities,
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
      addTearDown(channel.dispose);
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
