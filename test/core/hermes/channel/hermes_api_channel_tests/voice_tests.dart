part of '../hermes_api_channel_test.dart';

void _hermesApiChannelVoiceTests() {
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
}
