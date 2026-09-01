part of '../hermes_api_channel_test.dart';

void _hermesApiChannelSessionMutationTests() {
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
    'selectSession keeps a direct chat stream active in the background',
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
      stream.emit(
        'event: assistant.delta\ndata: {"delta":"Background reply"}\n\n',
      );
      await pumpEventQueue();
      stream.emit('event: assistant.completed\ndata: {}\n\n');
      await pumpEventQueue();

      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.activeMessages.single.text, 'From two');
      expect(
        channel.state.messages['sess_1']!.last.status,
        HermesTurnStatus.completed,
      );
      expect(channel.state.messages['sess_1']!.last.text, 'Background reply');
      expect(sendDone.isCompleted, isTrue);
    },
  );

  test(
    'reopening a streaming session preserves its live local transcript',
    () async {
      final stream = _ManualStringStream();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _twoSessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/sess_2/messages' =>
              '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"From two"}]}',
            _ => throw StateError('unexpected GET $uri'),
          },
          postStream: (uri, headers, body) => stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('keep this turn');
      await pumpEventQueue();
      stream.emit('event: assistant.delta\ndata: {"delta":"Partial"}\n\n');
      await pumpEventQueue();
      await channel.selectSession('sess_2');
      await channel.selectSession('sess_1');

      expect(channel.state.activeMessages.map((turn) => turn.text), [
        'Hello',
        'keep this turn',
        'Partial',
      ]);
      expect(
        channel.state.activeMessages.last.status,
        HermesTurnStatus.streaming,
      );

      stream.emit('event: assistant.completed\ndata: {}\n\n');
      await pumpEventQueue();
      await send;
    },
  );

  test(
    'background stream failure stays attached to its original session',
    () async {
      final stream = _ManualStringStream();
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async => switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _twoSessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/sess_2/messages' =>
              '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"From two"}]}',
            _ => throw StateError('unexpected GET $uri'),
          },
          postStream: (uri, headers, body) => stream,
        ),
      );
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final send = channel.sendText('background failure');
      await pumpEventQueue();
      await channel.selectSession('sess_2');
      stream.emit('event: assistant.failed\ndata: {}\n\n');
      await pumpEventQueue();
      await send;

      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.errorMessage, isNull);
      expect(
        channel.state.messages['sess_1']?.last.status,
        HermesTurnStatus.failed,
      );
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
    'latest session selection wins when an older history load finishes later',
    () async {
      final staleHistory = Completer<String>();
      var sessionOneHistoryRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _twoSessionsFixture,
              '/api/sessions/sess_1/messages' =>
                sessionOneHistoryRequests++ == 0
                    ? _messagesFixture
                    : staleHistory.future,
              '/api/sessions/sess_2/messages' =>
                '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"Latest"}]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final olderSelection = channel.selectSession('sess_1');
      await channel.selectSession('sess_2');
      expect(channel.state.activeSessionId, 'sess_2');

      staleHistory.complete(_messagesFixture);
      await olderSelection;
      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.activeMessages.single.text, 'Latest');
    },
  );

  test(
    'stale session history failures do not escape after a newer selection',
    () async {
      final staleFailure = Completer<String>();
      unawaited(staleFailure.future.catchError((_) => ''));
      var sessionOneHistoryRequests = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => _capabilitiesFixture,
              '/api/sessions' => _twoSessionsFixture,
              '/api/sessions/sess_1/messages' =>
                sessionOneHistoryRequests++ == 0
                    ? _messagesFixture
                    : staleFailure.future,
              '/api/sessions/sess_2/messages' =>
                '{"object":"list","session_id":"sess_2","data":[{"id":"msg_9","session_id":"sess_2","role":"assistant","content":"Latest"}]}',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://127.0.0.1:8642');

      final olderSelection = channel.selectSession('sess_1');
      await channel.selectSession('sess_2');
      staleFailure.completeError(StateError('stale history failed'));

      await expectLater(olderSelection, completes);
      expect(channel.state.activeSessionId, 'sess_2');
      expect(channel.state.activeMessages.single.text, 'Latest');
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

  test('mutable session calls require every declared write scope', () async {
    const capabilities = '''
{
  "object": "hermes.api_server.capabilities",
  "platform": "hermes-agent",
  "model": "hermes-agent",
  "schema_version": 1,
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["sessions:read"]},
  "features": {},
  "endpoints": {
    "session_create": {"method": "POST", "path": "/api/sessions", "required_scopes": ["sessions:write"]},
    "session_update": {"method": "PATCH", "path": "/api/sessions/{session_id}", "required_scopes": ["sessions:write"]},
    "session_delete": {"method": "DELETE", "path": "/api/sessions/{session_id}", "required_scopes": ["sessions:write"]},
    "session_fork": {"method": "POST", "path": "/api/sessions/{session_id}/fork", "required_scopes": ["sessions:write"]}
  }
}
''';
    var posted = false;
    var patched = false;
    var deleted = false;
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
    addTearDown(channel.dispose);
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
  });

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

  test('stale delete cleanup cannot clear a reconnected delete guard', () async {
    final firstDeleteStarted = Completer<void>();
    final releaseFirstDelete = Completer<void>();
    final secondDeleteStarted = Completer<void>();
    final releaseSecondDelete = Completer<void>();
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
          } else if (deleteCount == 2) {
            secondDeleteStarted.complete();
            await releaseSecondDelete.future;
          } else {
            throw StateError('duplicate reached server');
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

    final currentDelete = channel.deleteSession('sess_1');
    await secondDeleteStarted.future;
    releaseFirstDelete.complete();
    await firstDelete;
    await expectLater(channel.deleteSession('sess_1'), throwsStateError);

    expect(deleteCount, 2);
    releaseSecondDelete.complete();
    await currentDelete;
    expect(channel.state.sessions, isEmpty);
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

  test('forkSession rejects an active reply before HTTP', () async {
    final stream = _ManualStringStream();
    var forkPosts = 0;
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
        post: (uri, headers, body) async {
          forkPosts += 1;
          return '{}';
        },
        postStream: (uri, headers, body) => stream,
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    unawaited(channel.sendText('still running'));
    await pumpEventQueue();
    expect(channel.state.isSessionStreaming('sess_1'), isTrue);

    await expectLater(channel.forkSession('sess_1'), throwsStateError);

    expect(forkPosts, 0);
    stream.emit(
      'event: done\ndata: {"session_id":"sess_1","content":"done"}\n\n',
    );
    await pumpEventQueue();
  });

  test('forkSession blocks duplicate in-flight branches before HTTP', () async {
    final firstPostStarted = Completer<void>();
    final releaseFirstPost = Completer<void>();
    var forkPosts = 0;
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
            '/api/sessions/fork_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          forkPosts += 1;
          if (forkPosts == 1) {
            firstPostStarted.complete();
            await releaseFirstPost.future;
          } else {
            throw StateError('duplicate reached server');
          }
          return '{"object":"hermes.session","session":{"id":"fork_1","source":"api_server","title":"Fork","parent_session_id":"sess_1"}}';
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final first = channel.forkSession('sess_1');
    await firstPostStarted.future;
    await expectLater(channel.forkSession('sess_1'), throwsStateError);

    expect(forkPosts, 1);
    releaseFirstPost.complete();
    await first;
    expect(channel.state.activeSession?.parentSessionId, 'sess_1');
  });

  test('stale branch cleanup cannot clear a reconnected branch guard', () async {
    final firstPostStarted = Completer<void>();
    final releaseFirstPost = Completer<void>();
    final secondPostStarted = Completer<void>();
    final releaseSecondPost = Completer<void>();
    var forkPosts = 0;
    var nextForkId = 0;
    final channel = HermesApiChannel(
      sessionIdFactory: () => 'fork_${++nextForkId}',
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _capabilitiesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/sessions/fork_2/messages' => _messagesFixture,
            _ => throw StateError('unexpected GET $uri'),
          };
        },
        post: (uri, headers, body) async {
          forkPosts += 1;
          if (forkPosts == 1) {
            firstPostStarted.complete();
            await releaseFirstPost.future;
            return '{"object":"hermes.session","session":{"id":"fork_1","source":"api_server","parent_session_id":"sess_1"}}';
          }
          if (forkPosts == 2) {
            secondPostStarted.complete();
            await releaseSecondPost.future;
            return '{"object":"hermes.session","session":{"id":"fork_2","source":"api_server","parent_session_id":"sess_1"}}';
          }
          throw StateError('duplicate reached server');
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    final stale = channel.forkSession('sess_1');
    await firstPostStarted.future;
    await channel.disconnect();
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    final current = channel.forkSession('sess_1');
    await secondPostStarted.future;

    releaseFirstPost.complete();
    await stale;
    await expectLater(channel.forkSession('sess_1'), throwsStateError);
    expect(forkPosts, 2);

    releaseSecondPost.complete();
    await current;
    expect(channel.state.activeSessionId, 'fork_2');
  });

  test('forkSession derives the accepted child run guard', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_fork',
          sessionId: 'fork_1',
          baseUrl: 'http://127.0.0.1:8642',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    final channel = HermesApiChannel(
      detachedRunStore: store,
      sessionIdFactory: () => 'fork_1',
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _capabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/api/sessions/fork_1/messages' =>
            '{"object":"list","session_id":"fork_1","data":[]}',
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async =>
            '{"object":"hermes.session","session":{"id":"fork_1","source":"api_server","title":"Recovered fork","parent_session_id":"sess_1"}}',
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.forkSession('sess_1');

    expect(channel.state.activeSessionId, 'fork_1');
    expect(channel.state.hasUnreconciledRun, isTrue);
  });

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
    'forkSession keeps the accepted child when history refresh fails',
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

      await channel.forkSession('sess_1');

      expect(channel.state.sessions.map((s) => s.id), ['sess_1', 'fork_1']);
      expect(channel.state.activeSessionId, 'fork_1');
      expect(channel.state.activeSession?.parentSessionId, 'sess_1');
      expect(channel.state.activeMessages.single.text, 'Hello');
      expect(channel.state.messages.containsKey('fork_1'), isTrue);
    },
  );

  test('createSession derives the accepted session run guard', () async {
    final store = _MemoryDetachedRunStore()
      ..leases = [
        HermesDetachedRunLease(
          runId: 'run_child',
          sessionId: 'navi-test-2',
          baseUrl: 'http://127.0.0.1:8642',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    final channel = HermesApiChannel(
      detachedRunStore: store,
      sessionIdFactory: () => 'navi-test-2',
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async => switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => _capabilitiesFixture,
          '/api/sessions' => _sessionsFixture,
          '/api/sessions/sess_1/messages' => _messagesFixture,
          '/api/sessions/navi-test-2/messages' =>
            '{"object":"list","session_id":"navi-test-2","data":[]}',
          _ => throw StateError('unexpected GET $uri'),
        },
        post: (uri, headers, body) async =>
            '{"object":"hermes.session","session":{"id":"navi-test-2","source":"api_server","title":"Recovered child"}}',
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');

    await channel.createSession(title: 'Recovered child');

    expect(channel.state.activeSessionId, 'navi-test-2');
    expect(channel.state.hasUnreconciledRun, isTrue);
  });

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
}
