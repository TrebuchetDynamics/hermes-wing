import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

class _QueuedProfileChannel extends FakeHermesChannel {
  _QueuedProfileChannel() : super(status: HermesConnectionStatus.disconnected);

  final slowStarted = Completer<void>();
  final releaseSlow = Completer<void>();

  @override
  Future<void> selectProfile(
    String profileId, {
    bool allowDiscovered = false,
  }) async {
    if (profileId == 'slow') {
      if (!slowStarted.isCompleted) slowStarted.complete();
      await releaseSlow.future;
    }
    await super.selectProfile(profileId, allowDiscovered: allowDiscovered);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'refresh resumes a securely stored pending Wing Link acknowledgment',
    () async {
      var acknowledged = false;
      const origin = 'http://127.0.0.1:8654';
      final config = HermesEndpointConfig(
        id: 'pending',
        baseUrl: origin,
        apiKey: 'hermes-token',
        wingLinkOrigin: origin,
        wingLinkToken: 'wlc-token',
        wingLinkPendingCredentialId: 'cred_pending',
      );
      final store = FakeHermesEndpointStore(
        initial: config,
        profiles: [config],
      );
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({
          'pending': gatewaySummary(['default']),
        }),
        activeChannel: channel,
        pendingCredentialRecovery: (candidate) async {
          expect(candidate.wingLinkToken, 'wlc-token');
          expect(candidate.wingLinkPendingCredentialId, 'cred_pending');
          acknowledged = true;
          return true;
        },
      );
      addTearDown(directory.dispose);

      await directory.refresh();

      expect(acknowledged, isTrue);
      expect(store.saveCalls.single.wingLinkPendingCredentialId, '');
    },
  );

  test('Wing Link credentials do not manufacture profile contacts', () async {
    const config = HermesEndpointConfig(
      id: 'home',
      label: 'Home',
      baseUrl: 'https://home.example',
      wingLinkOrigin: 'https://home.example:8654',
      wingLinkToken: 'control-token',
    );
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = HermesGatewayDirectory(
      store: FakeHermesEndpointStore(profiles: const [config]),
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({
        'home': const GatewaySummary(
          profiles: [],
          sessionsByProfile: {},
          unscopedSessions: [],
          profileContextAvailable: true,
        ),
      }),
      activeChannel: channel,
    );
    addTearDown(directory.dispose);

    await directory.refresh();

    expect(directory.contacts, hasLength(1));
    expect(directory.contacts.single.id.profileId, 'default');
    expect(directory.contacts.single.gatewayLabel, 'Home');
    expect(directory.contacts.single.profileName, 'Endpoint contact');
    expect(directory.contacts.single.isFallbackProfile, isTrue);
    expect(
      directory.contacts.any((contact) => contact.id.profileId == 'link'),
      isFalse,
    );
  });

  final enrollmentBoundaryCases =
      <({String name, HermesEndpointConfig candidate})>[
        (
          name:
              'managed profile enrollment rejects a different Hermes authority',
          candidate: const HermesEndpointConfig(
            id: 'candidate',
            baseUrl: 'https://other.example:8642/p/link',
            apiKey: 'candidate-key',
            wingLinkOrigin: 'https://control.example:8654',
          ),
        ),
        (
          name:
              'managed profile enrollment rejects a different Wing Link authority',
          candidate: const HermesEndpointConfig(
            id: 'candidate',
            baseUrl: 'https://hermes.example:8642/p/link',
            apiKey: 'candidate-key',
            wingLinkOrigin: 'https://other-control.example:8654',
          ),
        ),
        (
          name:
              'managed profile enrollment rejects a blank endpoint credential',
          candidate: const HermesEndpointConfig(
            id: 'candidate',
            baseUrl: 'https://hermes.example:8642/p/link',
            apiKey: '   ',
            wingLinkOrigin: 'https://control.example:8654',
          ),
        ),
      ];

  for (final boundaryCase in enrollmentBoundaryCases) {
    test(boundaryCase.name, () async {
      const source = HermesEndpointConfig(
        id: 'source',
        baseUrl: 'https://hermes.example:8642/p/default',
        apiKey: 'source-key',
        wingLinkOrigin: 'https://control.example:8654',
      );
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final directory = HermesGatewayDirectory(
        store: FakeHermesEndpointStore(
          profiles: [source, boundaryCase.candidate],
        ),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({
          'source': gatewaySummary(['default']),
          'candidate': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      addTearDown(directory.dispose);
      await directory.refresh();

      expect(
        directory.enrolledGatewayIdForManagedProfile(
          sourceGatewayId: 'source',
          profileId: 'link',
        ),
        isNull,
      );
    });
  }

  test('profile-prefixed endpoints keep distinct contact identities', () async {
    const config = HermesEndpointConfig(
      id: 'sidon-endpoint',
      label: 'BlueBlack · sidon',
      baseUrl: 'https://home.example/p/sidon',
    );
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = HermesGatewayDirectory(
      store: FakeHermesEndpointStore(profiles: const [config]),
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({
        'sidon-endpoint': const GatewaySummary(
          profiles: [],
          sessionsByProfile: {},
          unscopedSessions: [],
        ),
      }),
      activeChannel: channel,
    );
    addTearDown(directory.dispose);

    await directory.refresh();

    expect(directory.contacts.single.id.profileId, 'sidon');
    expect(directory.contacts.single.gatewayLabel, 'BlueBlack');
    expect(directory.contacts.single.profileName, 'sidon');
  });

  test(
    'API summary loader does not probe profiles without profiles read scope',
    () async {
      final requestedPaths = <String>[];
      final loader = HermesApiGatewaySummaryLoader(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            requestedPaths.add(uri.path);
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' =>
                '''
{
  "schema_version": 1,
  "profile_context": {"type": "query", "name": "profile", "required": true, "default_profile_id": "default"},
  "auth": {"type": "bearer", "required": true, "granted_scopes": []},
  "endpoints": {
    "profiles": {
      "method": "GET",
      "path": "/api/profiles",
      "required_scopes": ["profiles:read"]
    }
  }
}
''',
              '/api/sessions' => () {
                expect(uri.queryParameters['profile'], 'default');
                return '{"object":"list","data":[]}';
              }(),
              '/api/profiles' => throw StateError('must not be requested'),
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );

      final summary = await loader.load(
        const HermesEndpointConfig(
          id: 'scoped',
          baseUrl: 'https://scoped.example',
          apiKey: 'secret',
        ),
      );

      expect(requestedPaths, isNot(contains('/api/profiles')));
      expect(summary.profiles, isEmpty);
      expect(summary.sessionsByProfile, isEmpty);
      expect(summary.profileContextAvailable, isTrue);
    },
  );

  test(
    'API summary loader never infers profile session query context',
    () async {
      final requestedUris = <Uri>[];
      final loader = HermesApiGatewaySummaryLoader(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            requestedUris.add(uri);
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' =>
                '''
{
  "schema_version": 1,
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["profiles:read"]},
  "endpoints": {
    "profiles": {
      "method": "GET",
      "path": "/api/profiles",
      "required_scopes": ["profiles:read"]
    }
  }
}
''',
              '/api/profiles' => throw StateError(
                'profiles must not be requested without query context',
              ),
              '/api/sessions' =>
                '''
{"object":"list","data":[{"id":"unscoped","source":"api"}]}
''',
              _ => throw StateError('unexpected GET $uri'),
            };
          },
        ),
      );

      final summary = await loader.load(
        const HermesEndpointConfig(
          id: 'no-context',
          baseUrl: 'https://no-context.example',
        ),
      );

      expect(summary.profiles, isEmpty);
      expect(summary.sessionsByProfile, isEmpty);
      expect(summary.unscopedSessions.single.id, 'unscoped');
      expect(requestedUris.any((uri) => uri.path == '/api/profiles'), isFalse);
      expect(
        requestedUris.any(
          (uri) =>
              uri.path == '/api/sessions' &&
              uri.queryParameters.containsKey('profile'),
        ),
        isFalse,
      );
    },
  );

  test('API summary loader uses an exact declared profile context', () async {
    final requestedUris = <Uri>[];
    final loader = HermesApiGatewaySummaryLoader(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          requestedUris.add(uri);
          return switch (uri.path) {
            '/health' => '{"status":"ok"}',
            '/v1/capabilities' =>
              '''
{
  "schema_version": 1,
  "profile_context": {
    "type": "query",
    "name": "profile",
    "required": true,
    "default_profile_id": "default"
  },
  "auth": {"type": "bearer", "required": true, "granted_scopes": ["profiles:read"]},
  "endpoints": {
    "profiles": {
      "method": "GET",
      "path": "/api/profiles",
      "required_scopes": ["profiles:read"]
    }
  }
}
''',
            '/api/profiles' =>
              '''
{"object":"list","data":[{"id":"coder","name":"Coder","revision":"p1"}]}
''',
            '/api/sessions' =>
              '''
{"object":"list","data":[{"id":"session-1","source":"api"}]}
''',
            _ => throw StateError('unexpected GET $uri'),
          };
        },
      ),
    );

    final summary = await loader.load(
      const HermesEndpointConfig(
        id: 'scoped-context',
        baseUrl: 'https://scoped-context.example',
      ),
    );

    expect(summary.sessionsByProfile['coder']?.single.id, 'session-1');
    expect(
      requestedUris.any(
        (uri) =>
            uri.path == '/api/sessions' &&
            uri.queryParameters['profile'] == 'coder',
      ),
      isTrue,
    );
  });

  test('activate connects the gateway, profile, and latest session', () async {
    final channel = FakeHermesChannel.disconnected();
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'beta',
          baseUrl: 'https://beta.example',
          apiKey: 'beta-secret',
        ),
      ],
      loader: FakeGatewaySummaryLoader(const {
        'beta': GatewaySummary(
          profileContextAvailable: true,
          profiles: [
            HermesProfile(
              id: 'agent-2',
              displayName: 'Agent 2',
              revision: 'r2',
            ),
          ],
          sessionsByProfile: {
            'agent-2': [HermesSession(id: 'sess_1', source: 'test')],
          },
        ),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await directory.activate(
      const GatewayContactId(gatewayId: 'beta', profileId: 'agent-2'),
    );

    expect(channel.connectCalls.single.baseUrl, 'https://beta.example');
    expect(channel.connectCalls.single.apiKey, 'beta-secret');
    expect(channel.selectProfileCalls, ['agent-2']);
    expect(channel.selectSessionCalls, ['sess_1']);
    expect(
      directory.activeContactId,
      const GatewayContactId(gatewayId: 'beta', profileId: 'agent-2'),
    );
  });

  test('activateGateway connects the gateway default profile', () async {
    final channel = FakeHermesChannel.disconnected();
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'alpha', baseUrl: 'https://alpha.example'),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['coder', 'default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await directory.activateGateway('alpha');

    expect(channel.connectCalls.single.baseUrl, 'https://alpha.example');
    expect(channel.selectProfileCalls, ['default']);
    expect(directory.activeContactId?.gatewayId, 'alpha');
  });

  test(
    'same-gateway profile selection keeps directory state synchronized',
    () async {
      final channel = FakeHermesChannel.disconnected();
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(id: 'alpha', baseUrl: 'https://alpha.example'),
        ],
        loader: FakeGatewaySummaryLoader({
          'alpha': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('alpha');
      await channel.createProfile(name: 'New Agent');

      await directory.selectProfileOnActiveGateway('new-agent');

      expect(channel.disconnectCalls, 0);
      expect(channel.selectProfileCalls, ['default', 'new-agent']);
      expect(
        directory.activeContactId,
        const GatewayContactId(gatewayId: 'alpha', profileId: 'new-agent'),
      );
      expect(
        directory.contacts.any(
          (contact) =>
              contact.id.profileId == 'new-agent' &&
              contact.profileName == 'New Agent',
        ),
        isTrue,
      );
    },
  );

  test('same-gateway profile selections are serialized', () async {
    final channel = _QueuedProfileChannel();
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'alpha', baseUrl: 'https://alpha.example'),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    await directory.activateGateway('alpha');
    await channel.createProfile(name: 'slow');
    await channel.createProfile(name: 'fast');

    final slow = directory.selectProfileOnActiveGateway('slow');
    await channel.slowStarted.future;
    final fast = directory.selectProfileOnActiveGateway('fast');
    channel.releaseSlow.complete();
    await Future.wait([slow, fast]);

    expect(channel.state.selectedProfileId, 'fast');
    expect(
      directory.activeContactId,
      const GatewayContactId(gatewayId: 'alpha', profileId: 'fast'),
    );
    expect(channel.disconnectCalls, 0);
  });

  test('fallback contact skips profile selection', () async {
    final channel = FakeHermesChannel.disconnected();
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'legacy', baseUrl: 'https://legacy'),
      ],
      loader: FakeGatewaySummaryLoader(const {
        'legacy': GatewaySummary(
          profiles: [],
          sessionsByProfile: {},
          unscopedSessions: [],
        ),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await directory.activate(
      const GatewayContactId(gatewayId: 'legacy', profileId: 'default'),
    );

    expect(channel.selectProfileCalls, isEmpty);
  });

  test('activation exposes the selected contact while connecting', () async {
    final gate = Completer<void>();
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
      connectGate: () => gate.future,
    );
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'legacy', baseUrl: 'https://legacy'),
      ],
      loader: FakeGatewaySummaryLoader(const {
        'legacy': GatewaySummary(
          profiles: [],
          sessionsByProfile: {},
          unscopedSessions: [],
        ),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    const id = GatewayContactId(gatewayId: 'legacy', profileId: 'default');

    final activation = directory.activate(id);
    while (channel.connectCalls.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(directory.activeContactId, id);
    gate.complete();
    await activation;
  });

  test('second activation disconnects previous channel first', () async {
    final channel = FakeHermesChannel.disconnected();
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'a', baseUrl: 'https://a'),
        HermesEndpointConfig(id: 'b', baseUrl: 'https://b'),
      ],
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
        'b': gatewaySummary(['b1']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await directory.activate(
      const GatewayContactId(gatewayId: 'a', profileId: 'a1'),
    );
    await directory.activate(
      const GatewayContactId(gatewayId: 'b', profileId: 'b1'),
    );

    expect(channel.disconnectCalls, 1);
    expect(channel.connectCalls, hasLength(2));
  });

  test('rename and reconnect update one gateway only', () async {
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(id: 'a', label: 'Alpha', baseUrl: 'https://a'),
        HermesEndpointConfig(id: 'b', label: 'Beta', baseUrl: 'https://b'),
      ],
    );
    final loader = FakeGatewaySummaryLoader({
      'a': gatewaySummary(['a1']),
      'b': gatewaySummary(['b1']),
    });
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: loader,
      activeChannel: FakeHermesChannel.disconnected(),
    );
    await directory.refresh();

    await directory.renameGateway('a', 'Work');
    await directory.reconnectGateway('a');

    expect(store.saveCalls.single.id, 'a');
    expect(store.saveCalls.single.label, 'Work');
    expect(loader.calls.where((id) => id == 'a'), hasLength(2));
    expect(loader.calls.where((id) => id == 'b'), hasLength(1));
  });

  test(
    'update connection sanitizes the origin and preserves a hidden credential',
    () async {
      final store = FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(
            id: 'a',
            label: 'Alpha',
            baseUrl: 'https://old.example',
            apiKey: 'sentinel-secret',
          ),
        ],
      );
      final loader = FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      });
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: loader,
        activeChannel: FakeHermesChannel.disconnected(),
      );
      await directory.refresh();

      await directory.updateGatewayConnection(
        'a',
        baseUrl: 'https://new.example/private?token=discarded',
      );

      expect(store.saveCalls.single.baseUrl, 'https://new.example');
      expect(store.saveCalls.single.apiKey, 'sentinel-secret');
      expect(directory.gateways.single.baseUrl, 'https://new.example');
      expect(
        directory.contacts.map((contact) => contact.toJson()).toString(),
        isNot(contains('sentinel-secret')),
      );
      expect(loader.calls, ['a', 'a']);
    },
  );

  test(
    'update connection can explicitly remove the saved credential',
    () async {
      final store = FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(
            id: 'a',
            baseUrl: 'https://a.example',
            apiKey: 'sentinel-secret',
          ),
        ],
      );
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({
          'a': gatewaySummary(['a1']),
        }),
        activeChannel: FakeHermesChannel.disconnected(),
      );
      await directory.refresh();

      await directory.updateGatewayConnection(
        'a',
        baseUrl: 'https://a.example',
        clearApiKey: true,
      );

      expect(store.saveCalls.single.apiKey, isNull);
    },
  );

  test(
    'active and duplicate gateway connection updates fail before persistence',
    () async {
      final store = FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(id: 'a', baseUrl: 'https://a.example'),
          HermesEndpointConfig(id: 'b', baseUrl: 'https://b.example'),
        ],
      );
      final channel = FakeHermesChannel.disconnected();
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({
          'a': gatewaySummary(['a1']),
          'b': gatewaySummary(['b1']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activate(
        const GatewayContactId(gatewayId: 'a', profileId: 'a1'),
      );

      await expectLater(
        directory.updateGatewayConnection(
          'a',
          baseUrl: 'https://changed.example',
        ),
        throwsStateError,
      );
      await expectLater(
        directory.updateGatewayConnection(
          'b',
          baseUrl: 'https://a.example/path',
        ),
        throwsStateError,
      );

      expect(store.saveCalls, isEmpty);
    },
  );

  test('remove gateway clears only its contacts and credential', () async {
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(id: 'a', baseUrl: 'https://a'),
        HermesEndpointConfig(id: 'b', baseUrl: 'https://b'),
      ],
    );
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
        'b': gatewaySummary(['b1']),
      }),
      activeChannel: FakeHermesChannel.disconnected(),
    );
    await directory.refresh();

    await directory.removeGateway('a');

    expect(store.deleteProfileCalls, ['a']);
    expect(directory.contacts.every((c) => c.id.gatewayId != 'a'), isTrue);
    expect(directory.contacts.any((c) => c.id.gatewayId == 'b'), isTrue);
  });

  test('remove gateway discards an in-flight refresh result', () async {
    final gate = Completer<void>();
    final cache = FakeGatewayContactCache();
    final loader = FakeGatewaySummaryLoader({
      'a': gatewaySummary(['a1']),
    }, gate: gate);
    final directory = directoryFor(
      configs: const [HermesEndpointConfig(id: 'a', baseUrl: 'https://a')],
      cache: cache,
      loader: loader,
    );

    final refresh = directory.refresh();
    while (loader.calls.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await directory.removeGateway('a');
    gate.complete();
    await refresh;

    expect(directory.hasSavedGateways, isFalse);
    expect(directory.contacts, isEmpty);
    expect(directory.gateways, isEmpty);
    expect(cache.stored, isEmpty);
  });

  test('merges profiles from every gateway without exposing keys', () async {
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'a',
          label: 'Alpha',
          baseUrl: 'https://a',
          apiKey: 'secret-a',
        ),
        HermesEndpointConfig(
          id: 'b',
          label: 'Beta',
          baseUrl: 'https://b',
          apiKey: 'secret-b',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1', 'a2', 'a3']),
        'b': gatewaySummary(['b1', 'b2']),
      }),
    );

    await directory.refresh();

    expect(directory.contacts, hasLength(5));
    expect(directory.contacts.map((c) => c.id.gatewayId).toSet(), {'a', 'b'});
    expect(
      directory.contacts.map((c) => c.toJson()).toString(),
      isNot(contains('secret-')),
    );
  });

  test('offline refresh retains cached contacts and healthy results', () async {
    const cached = GatewayContact(
      id: GatewayContactId(gatewayId: 'a', profileId: 'a1'),
      gatewayLabel: 'Alpha',
      profileName: 'A1',
      sessionCount: 0,
      availability: GatewayAvailability.offline,
    );
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'a', label: 'Alpha', baseUrl: 'https://a'),
        HermesEndpointConfig(id: 'b', label: 'Beta', baseUrl: 'https://b'),
      ],
      cache: FakeGatewayContactCache(const [cached]),
      loader: FakeGatewaySummaryLoader({
        'a': StateError('offline'),
        'b': gatewaySummary(['b1']),
      }),
    );

    await directory.start();

    expect(
      directory.contacts
          .where((c) => c.id.gatewayId == 'a')
          .single
          .availability,
      GatewayAvailability.offline,
    );
    expect(
      directory.contacts
          .where((c) => c.id.gatewayId == 'b')
          .single
          .availability,
      GatewayAvailability.online,
    );
  });

  test(
    'authentication failure is isolated without exposing its error',
    () async {
      const cached = GatewayContact(
        id: GatewayContactId(gatewayId: 'a', profileId: 'a1'),
        gatewayLabel: 'Alpha',
        profileName: 'A1',
        sessionCount: 0,
        availability: GatewayAvailability.online,
      );
      final directory = directoryFor(
        configs: const [HermesEndpointConfig(id: 'a', baseUrl: 'https://a')],
        cache: FakeGatewayContactCache(const [cached]),
        loader: FakeGatewaySummaryLoader({
          'a': StateError('HTTP 401 Bearer secret-sentinel'),
        }),
      );

      await directory.start();

      expect(
        directory.contacts.single.availability,
        GatewayAvailability.authenticationFailed,
      );
      expect(
        directory.contacts.single.toJson().toString(),
        isNot(contains('secret-sentinel')),
      );
    },
  );

  test('stale refresh cannot overwrite newer contacts', () async {
    final loader = _SequencedGatewaySummaryLoader();
    final directory = directoryFor(
      configs: const [HermesEndpointConfig(id: 'a', baseUrl: 'https://a')],
      loader: loader,
    );

    final staleRefresh = directory.refresh();
    while (loader.calls < 1) {
      await Future<void>.delayed(Duration.zero);
    }
    await directory.refresh();
    loader.first.complete(gatewaySummary(['old']));
    await staleRefresh;

    expect(directory.contacts.single.id.profileId, 'new');
  });

  test(
    'reconnect during refresh does not leave stale global progress',
    () async {
      final loader = _SequencedGatewaySummaryLoader();
      final directory = directoryFor(
        configs: const [HermesEndpointConfig(id: 'a', baseUrl: 'https://a')],
        loader: loader,
      );

      final refresh = directory.refresh();
      while (loader.calls < 1) {
        await Future<void>.delayed(Duration.zero);
      }
      await directory.reconnectGateway('a');
      loader.first.complete(gatewaySummary(['old']));
      await refresh;

      expect(directory.refreshing, isFalse);
      expect(directory.contacts.single.id.profileId, 'new');
    },
  );

  test('refreshes at most three gateways concurrently', () async {
    final gate = Completer<void>();
    final loader = FakeGatewaySummaryLoader({
      for (final id in ['a', 'b', 'c', 'd', 'e']) id: gatewaySummary([id]),
    }, gate: gate);
    final directory = directoryFor(
      configs: [
        for (final id in ['a', 'b', 'c', 'd', 'e'])
          HermesEndpointConfig(id: id, label: id, baseUrl: 'https://$id'),
      ],
      loader: loader,
    );

    final refresh = directory.refresh();
    while (loader.maxActive < 3) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(loader.maxActive, 3);
    gate.complete();
    await refresh;
    expect(loader.maxActive, 3);
  });

  test('foreground timer stops refreshing while paused', () async {
    final timers = <_FakeTimer>[];
    final loader = FakeGatewaySummaryLoader({
      'a': gatewaySummary(['a1']),
    });
    final directory = HermesGatewayDirectory(
      store: FakeHermesEndpointStore(
        profiles: const [HermesEndpointConfig(id: 'a', baseUrl: 'https://a')],
      ),
      cache: FakeGatewayContactCache(),
      loader: loader,
      activeChannel: FakeHermesChannel.disconnected(),
      periodicTimer: (duration, callback) {
        final timer = _FakeTimer(callback);
        timers.add(timer);
        return timer;
      },
    );
    addTearDown(directory.dispose);

    await directory.start();
    await directory.start();
    directory.didChangeAppLifecycleState(AppLifecycleState.resumed);
    directory.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);

    expect(timers, hasLength(1));
    final callsBeforeTick = loader.calls.length;
    timers.single.elapse();
    await Future<void>.delayed(Duration.zero);
    expect(loader.calls, hasLength(callsBeforeTick + 1));

    directory.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(timers.single.isActive, isFalse);
    final callsBeforePausedInterval = loader.calls.length;
    timers.single.elapse();
    await Future<void>.delayed(Duration.zero);
    expect(loader.calls, hasLength(callsBeforePausedInterval));
  });

  test('profile-less gateway produces one default contact', () async {
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'legacy',
          label: 'Legacy',
          baseUrl: 'https://legacy',
        ),
      ],
      loader: FakeGatewaySummaryLoader(const {
        'legacy': GatewaySummary(
          profiles: [],
          sessionsByProfile: {},
          unscopedSessions: [],
        ),
      }),
    );

    await directory.refresh();

    expect(directory.contacts.single.isFallbackProfile, isTrue);
    expect(directory.contacts.single.id.profileId, 'default');
  });

  test(
    'a failed saved-gateway read leaves the directory refreshable',
    () async {
      final cache = FakeGatewayContactCache([
        GatewayContact(
          id: const GatewayContactId(gatewayId: 'a', profileId: 'a1'),
          gatewayLabel: 'A',
          profileName: 'A1',
          sessionCount: 0,
          availability: GatewayAvailability.online,
          lastRefreshedAt: DateTime.utc(2026, 7, 16),
        ),
      ]);
      final directory = HermesGatewayDirectory(
        store: _ThrowingHermesEndpointStore(),
        cache: cache,
        loader: FakeGatewaySummaryLoader(const {}),
        activeChannel: FakeHermesChannel.disconnected(),
        now: () => DateTime.utc(2026, 7, 16),
      );

      await directory.refresh();

      expect(directory.refreshing, isFalse);
      expect(
        directory.contacts.map((contact) => contact.availability),
        everyElement(GatewayAvailability.offline),
      );
    },
  );

  test('a failed contact cache write still ends the refresh', () async {
    var notifications = 0;
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'a', label: 'A', baseUrl: 'https://a.example'),
      ],
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      }),
      cache: _ThrowingGatewayContactCache(),
    );
    directory.addListener(() => notifications++);

    await directory.refresh();

    expect(directory.refreshing, isFalse);
    expect(notifications, greaterThan(0));
  });

  test(
    'a discarded periodic refresh never escapes as an uncaught error',
    () async {
      final timers = <_FakeTimer>[];
      final directory = HermesGatewayDirectory(
        store: _ThrowingHermesEndpointStore(),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader(const {}),
        activeChannel: FakeHermesChannel.disconnected(),
        now: () => DateTime.utc(2026, 7, 16),
        periodicTimer: (duration, callback) {
          final timer = _FakeTimer(callback);
          timers.add(timer);
          return timer;
        },
      );

      await directory.start();
      directory.didChangeAppLifecycleState(AppLifecycleState.resumed);
      timers.single.elapse();
      await Future<void>.delayed(Duration.zero);

      expect(directory.refreshing, isFalse);
      directory.dispose();
    },
  );

  test('a failed cache write cannot break reconnect or rename', () async {
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'a', label: 'A', baseUrl: 'https://a.example'),
      ],
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      }),
      cache: _ThrowingGatewayContactCache(),
    );
    await directory.refresh();

    await directory.reconnectGateway('a');
    await directory.renameGateway('a', 'Work');

    expect(directory.contacts.single.availability, GatewayAvailability.online);
    expect(directory.contacts.single.gatewayLabel, 'Work');
  });

  test('a failed cache write cannot break an updated connection', () async {
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'a', label: 'A', baseUrl: 'https://a.example'),
      ],
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      }),
      cache: _ThrowingGatewayContactCache(),
    );
    await directory.refresh();

    await directory.updateGatewayConnection('a', baseUrl: 'https://b.example');

    expect(directory.gateways.single.baseUrl, 'https://b.example');
  });

  test('a failed cache cleanup cannot strand a removed gateway', () async {
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'a', label: 'A', baseUrl: 'https://a.example'),
      ],
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      }),
      cache: _ThrowingGatewayContactCache(),
    );
    await directory.refresh();

    await directory.removeGateway('a');

    expect(directory.contacts, isEmpty);
    expect(directory.gateways, isEmpty);
  });

  test('reconnecting an unsaved gateway still reports it lost', () async {
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'a', label: 'A', baseUrl: 'https://a.example'),
      ],
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      }),
    );
    await directory.refresh();

    await expectLater(directory.reconnectGateway('gone'), throwsStateError);
  });
}

class _ThrowingHermesEndpointStore implements HermesEndpointStore {
  @override
  Future<HermesEndpointConfig?> load() async => null;

  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async =>
      throw StateError('secure storage unavailable');

  @override
  Future<void> saveAll(List<HermesEndpointConfig> profiles) async {}

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
  }) async {}

  @override
  Future<void> deleteProfile(String profileId) async {}

  @override
  Future<void> clear() async {}
}

class _ThrowingGatewayContactCache extends FakeGatewayContactCache {
  @override
  Future<void> save(List<GatewayContact> contacts) async =>
      throw StateError('contact cache unavailable');

  @override
  Future<void> removeGateway(String gatewayId) async =>
      throw StateError('contact cache unavailable');
}

class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function(Timer) _callback;
  var _active = true;

  void elapse() {
    if (_active) _callback(this);
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;

  @override
  void cancel() => _active = false;
}

class _SequencedGatewaySummaryLoader implements GatewaySummaryLoader {
  final first = Completer<GatewaySummary>();
  int calls = 0;

  @override
  Future<GatewaySummary> load(HermesEndpointConfig config) {
    calls++;
    return calls == 1 ? first.future : Future.value(gatewaySummary(['new']));
  }
}
