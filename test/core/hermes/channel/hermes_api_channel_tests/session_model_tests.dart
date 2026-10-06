part of '../hermes_api_channel_test.dart';

void _hermesApiChannelSessionModelTests() {
  String capabilities({bool granted = true}) {
    final value =
        jsonDecode(_providerModelCapabilitiesFixture) as Map<String, dynamic>;
    (value['endpoints'] as Map).addAll(<String, dynamic>{
      'model_options': {'method': 'GET', 'path': '/api/model/options'},
      'session_model_lock': {
        'method': 'POST',
        'path': '/api/sessions/{session_id}/model',
        'profile_scoped': true,
        'required_scopes': [granted ? 'models:write' : 'missing:grant'],
      },
    });
    return jsonEncode(value);
  }

  for (final accepted in [true, false]) {
    test(
      'session model ${accepted ? 'confirmation' : 'rejection'} is profile scoped and authoritative',
      () async {
        final requests = <Uri>[];
        final bodies = <Object?>[];
        final channel = await _connectedProviderModelChannel(
          capabilities: capabilities(),
          requests: requests,
          post: (uri, body) async {
            bodies.add(jsonDecode(body));
            return jsonEncode({
              'session_id': 'sess_1',
              'runtime': {
                'provider': 'synthetic',
                'model': 'raw/model-99',
                'model_lock': accepted ? 'accepted' : '',
              },
            });
          },
        );
        final mutation = channel.lockSessionModel(
          sessionId: 'sess_1',
          provider: 'synthetic',
          model: 'raw/model-99',
        );
        if (accepted) {
          await mutation;
          expect(
            channel.state.sessionModelLocks['sess_1']!.model,
            'raw/model-99',
          );
        } else {
          await expectLater(mutation, throwsStateError);
          expect(channel.state.sessionModelLocks, isEmpty);
        }
        expect(requests.single.path, '/api/sessions/sess_1/model');
        expect(requests.single.queryParameters['profile'], 'default');
        expect(bodies.single, {
          'provider': 'synthetic',
          'model': 'raw/model-99',
        });
      },
    );
  }
  test(
    'missing exact grant and unavailable session reject before session-model I/O',
    () async {
      var posts = 0;
      for (final granted in [false, true]) {
        final channel = await _connectedProviderModelChannel(
          capabilities: capabilities(granted: granted),
          post: (_, _) async {
            posts++;
            return '{}';
          },
        );
        await expectLater(
          channel.lockSessionModel(
            sessionId: granted ? 'unavailable' : 'sess_1',
            provider: 'synthetic',
            model: 'raw/model-99',
          ),
          throwsStateError,
        );
      }
      expect(posts, 0);
    },
  );
  test(
    'late confirmed lock cannot cross profile roundtrip or reconnect generation',
    () async {
      for (final reconnect in [false, true]) {
        final pending = Completer<String>();
        final channel = await _connectedProviderModelChannel(
          capabilities: capabilities(),
          post: (_, _) => pending.future,
        );
        final mutation = channel.lockSessionModel(
          sessionId: 'sess_1',
          provider: 'synthetic',
          model: 'raw/model-99',
        );
        await pumpEventQueue();
        if (reconnect) {
          await channel.disconnect();
          await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        } else {
          await channel.selectProfile('coder');
          await channel.selectProfile('default');
        }
        pending.complete(
          '{"session_id":"sess_1","runtime":{"provider":"synthetic","model":"raw/model-99","model_lock":"accepted"}}',
        );
        await mutation;
        expect(channel.state.sessionModelLocks, isEmpty);
      }
    },
  );
}
