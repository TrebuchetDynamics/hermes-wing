import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
