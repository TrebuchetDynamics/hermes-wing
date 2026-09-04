part of '../hermes_api_channel_test.dart';

void _hermesApiChannelLifecycleRaceTests() {
  for (final resource in ['providers', 'models', 'options', 'health']) {
    test('$resource newest overlapping read owns inventory', () async {
      final pending = Completer<String>();
      var defer = false;
      final path = switch (resource) {
        'providers' => '/api/providers',
        'models' => '/api/models',
        'options' => '/api/model/options',
        _ => '/health/detailed',
      };
      final payload = switch (resource) {
        'providers' => _providersFixtureBody(),
        'models' => _modelsInventoryBody,
        'options' =>
          '{"provider":"synthetic","model":"current","providers":[]}',
        _ => '{"status":"ok","platform":"synthetic"}',
      };
      final capabilities =
          jsonDecode(_providerModelCapabilitiesFixture) as Map<String, dynamic>;
      (capabilities['endpoints'] as Map).addAll(<String, dynamic>{
        'model_options': {'method': 'GET', 'path': '/api/model/options'},
        'health_detailed': {'method': 'GET', 'path': '/health/detailed'},
      });
      final channel = await _connectedProviderModelChannel(
        capabilities: jsonEncode(capabilities),
        get: (uri) async {
          if (uri.path == '/health/detailed' && path != uri.path) {
            return '{"status":"ok"}';
          }
          if (uri.path != path) return null;
          if (defer) {
            defer = false;
            return pending.future;
          }
          return payload;
        },
      );
      Future<void> load() => switch (resource) {
        'providers' => channel.loadProviders(),
        'models' => channel.loadModels(),
        'options' => channel.loadModelOptions(),
        _ => channel.loadDetailedHealth(),
      };
      Object? inventory() => switch (resource) {
        'providers' => channel.state.providers,
        'models' => channel.state.modelInventory,
        'options' => channel.state.modelOptions,
        _ => channel.state.detailedHealth,
      };
      defer = true;
      final old = load();
      await pumpEventQueue();
      await load();
      final current = inventory();
      pending.complete(payload);
      await old;
      expect(identical(inventory(), current), isTrue);
    });
  }
  for (final failure in [false, true]) {
    test(
      'model assignment ${failure ? 'conflict' : 'success'} cannot cross profile roundtrip',
      () async {
        final pending = Completer<String>();
        var inventoryReads = 0;
        final channel = await _connectedProviderModelChannel(
          capabilities: _providerModelCapabilitiesFixture,
          get: (uri) async {
            if (uri.path != '/api/models') return null;
            inventoryReads++;
            return _modelsInventoryBody;
          },
          put: (uri, body) => pending.future,
        );
        final assignment = channel.assignModel(
          scope: 'primary',
          provider: 'openai',
          model: 'new-model',
          revision: 'mrev-1',
        );
        final done = assignment.catchError((Object _) {});
        await pumpEventQueue();
        await channel.selectProfile('coder');
        await channel.selectProfile('default');
        if (failure) {
          pending.completeError(const _TestHermesStatusException(412));
        } else {
          pending.complete(
            '{"active":{"provider":"openai","model":"new-model"},"revision":"mrev-2"}',
          );
        }
        await done;
        expect(channel.state.modelInventory, isNull);
        expect(inventoryReads, 0);
      },
    );
  }
  test('foreground history refresh cannot cross profile roundtrip', () async {
    final pending = Completer<String>();
    var defer = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          if (defer && uri.path.endsWith('/messages')) {
            defer = false;
            return pending.future;
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _profileCapabilitiesFixture,
            '/api/profiles' => _profilesFixture,
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            _ => throw StateError('unexpected route'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    defer = true;
    final refresh = channel.reconcileActiveSession();
    await pumpEventQueue();
    await channel.selectProfile('coder');
    await channel.selectProfile('default');
    final currentIds = channel.state.activeMessages
        .map((turn) => turn.id)
        .toList();
    pending.complete(_reconciledMessagesFixture);
    await refresh;
    expect(channel.state.activeMessages.map((turn) => turn.id), currentIds);
  });
  for (final resource in ['jobs', 'tools']) {
    for (final transition in ['refresh', 'profile', 'roundtrip', 'reconnect']) {
      for (final fails in [false, true]) {
        test(
          '$resource discards stale $transition ${fails ? 'failure' : 'success'}',
          () async {
            final pending = Completer<String>();
            var defer = false;
            final channel = HermesApiChannel(
              clientBuilder: (config) => HermesApiClient(
                config: config,
                get: (uri, headers) async {
                  if (defer &&
                      uri.path ==
                          (resource == 'jobs' ? '/api/jobs' : '/v1/skills')) {
                    defer = false;
                    return pending.future;
                  }
                  return switch (uri.path) {
                    '/health' => '{"status":"ok"}',
                    '/v1/capabilities' => _resourceRaceCapabilities(),
                    '/api/profiles' => _profilesFixture,
                    '/api/sessions' => _sessionsFixture,
                    '/api/sessions/sess_1/messages' => _messagesFixture,
                    '/api/jobs' => _jobsFixtureUpdated,
                    '/v1/skills' => '{"data":[{"name":"current"}]}',
                    '/v1/toolsets' => _toolsetsFixture,
                    _ => throw StateError('unexpected route'),
                  };
                },
              ),
            );
            addTearDown(channel.dispose);
            await channel.connect(baseUrl: 'http://127.0.0.1:8642');
            expect(
              channel.state.capabilities,
              isNotNull,
              reason: channel.state.errorMessage,
            );
            defer = true;
            final old = resource == 'jobs'
                ? channel.loadJobs()
                : channel.loadToolInventory();
            final oldDone = old.catchError((Object _) {});
            await pumpEventQueue();
            if (transition == 'profile' || transition == 'roundtrip') {
              await channel.selectProfile('coder');
            }
            if (transition == 'roundtrip') {
              await channel.selectProfile('default');
            }
            if (transition == 'reconnect') {
              await channel.connect(baseUrl: 'http://127.0.0.1:8642');
            }
            if (resource == 'jobs') {
              await channel.loadJobs();
            } else {
              await channel.loadToolInventory();
            }
            if (fails) {
              pending.completeError(StateError('obsolete inventory'));
            } else {
              pending.complete(
                resource == 'jobs' ? _jobsFixture : _skillsFixture,
              );
            }
            await oldDone;
            expect(channel.state.jobs.single.id, 'job_2');
            expect(channel.state.skills, ['current']);
            expect(channel.state.optionalResourceErrors, isEmpty);
          },
        );
      }
    }
  }
  test('concurrent optional inventory errors remain independent', () async {
    final skills = Completer<String>();
    var refreshing = false;
    final channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          if (refreshing && uri.path == '/v1/skills') return skills.future;
          if (refreshing && uri.path == '/api/jobs') {
            throw StateError('jobs unavailable');
          }
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' => _resourceRaceCapabilities(),
            '/api/sessions' => _sessionsFixture,
            '/api/sessions/sess_1/messages' => _messagesFixture,
            '/api/jobs' => _jobsFixture,
            '/v1/skills' => _skillsFixture,
            '/v1/toolsets' => _toolsetsFixture,
            _ => throw StateError('unexpected route'),
          };
        },
      ),
    );
    addTearDown(channel.dispose);
    await channel.connect(baseUrl: 'http://127.0.0.1:8642');
    refreshing = true;
    final tools = channel.loadToolInventory();
    await expectLater(channel.loadJobs(), throwsStateError);
    skills.completeError(StateError('skills unavailable'));
    await tools;
    expect(
      channel.state.optionalResourceErrors.keys,
      containsAll([HermesOptionalResource.jobs, HermesOptionalResource.skills]),
    );
  });
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
}

String _resourceRaceCapabilities() {
  final result =
      jsonDecode(_profileCapabilitiesFixture) as Map<String, dynamic>;
  final jobs = jsonDecode(_jobsCapabilitiesFixture) as Map<String, dynamic>;
  final catalog =
      jsonDecode(_catalogCapabilitiesFixture) as Map<String, dynamic>;
  (result['auth']['granted_scopes'] as List).addAll([
    'tasks:read',
    'skills:read',
    'tools:read',
  ]);
  (result['endpoints'] as Map).addAll(jobs['endpoints'] as Map);
  (result['endpoints'] as Map).addAll(<String, dynamic>{
    'skills': catalog['endpoints']['skills'],
    'toolsets': catalog['endpoints']['toolsets'],
  });
  return jsonEncode(result);
}
