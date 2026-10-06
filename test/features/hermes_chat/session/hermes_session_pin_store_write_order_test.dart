import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Only this isolated fake uses the installed plugin platform interface.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/session/hermes_session_pin_store.dart';

const _alpha = GatewayContactId(gatewayId: 'alpha', profileId: 'default');
const _beta = GatewayContactId(gatewayId: 'beta', profileId: 'default');
const _profile = GatewayContactId(gatewayId: 'alpha', profileId: 'other');
const _deadline = Duration(seconds: 5);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferencesStorePlatform originalPlatform;
  late _CommitPreferences backend;

  setUp(() {
    originalPlatform = SharedPreferencesStorePlatform.instance;
    SharedPreferences.resetStatic();
    backend = _CommitPreferences();
    SharedPreferencesStorePlatform.instance = backend;
  });

  tearDown(() {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  Future<HermesSessionPinStore> loaded() async {
    final store = HermesSessionPinStore();
    addTearDown(store.dispose);
    await store.load().timeout(_deadline);
    return store;
  }

  Future<HermesSessionPinStore> fresh() async {
    // A new store alone would read the plugin's optimistic cache, not commits.
    SharedPreferences.resetStatic();
    return loaded();
  }

  Future<void> finishLatestBeforeOlderIfOverlapping() async {
    // Event-queue barrier lets all admitted microtasks reach platform dispatch.
    // No elapsed-time delay controls commit order; only explicit gates do.
    await Future<void>(() {}).timeout(_deadline);
    if (backend.writes.length > 1) {
      backend.writes.last.gate.complete(true);
      await backend.writes.last.settled.future.timeout(_deadline);
      backend.writes.first.gate.complete(true);
    } else {
      backend.writes.first.gate.complete(true);
      await backend.waitForWrites(2);
      backend.writes.last.gate.complete(true);
    }
  }

  test('latest unpin survives an older delayed pin commit', () async {
    final store = await loaded();
    var notifications = 0;
    store.addListener(() => notifications++);
    final pin = store.toggle(_alpha, 'session-1');
    await backend.waitForWrites(1);
    final unpin = store.toggle(_alpha, 'session-1');
    await Future<void>(() {}).timeout(_deadline);
    expect(store.isPinned(_alpha, 'session-1'), isFalse);
    expect(notifications, 2);
    await finishLatestBeforeOlderIfOverlapping();
    await Future.wait([pin, unpin]).timeout(_deadline);
    final restored = await fresh();
    expect(restored.isPinned(_alpha, 'session-1'), isFalse);
    expect(backend.maxActive, 1);
  });

  test(
    'latest distinct session and contact choices survive delayed commit',
    () async {
      final store = await loaded();
      final first = store.toggle(_alpha, 'session-1');
      await backend.waitForWrites(1);
      final changes = [
        store.toggle(_alpha, 'session-2'),
        store.toggle(_beta, 'session-1'),
        store.toggle(_profile, 'session-1'),
        store.toggle(_alpha, 'session-1'),
      ];
      await Future<void>(() {}).timeout(_deadline);
      expect(store.isPinned(_alpha, 'session-1'), isFalse);
      expect(store.isPinned(_alpha, 'session-2'), isTrue);
      expect(store.isPinned(_beta, 'session-1'), isTrue);
      expect(store.isPinned(_profile, 'session-1'), isTrue);
      expect(backend.writes, hasLength(1));
      backend.writes.first.gate.complete(true);
      await backend.waitForWrites(2);
      backend.writes.last.gate.complete(true);
      await Future.wait([first, ...changes]).timeout(_deadline);
      final restored = await fresh();
      expect(restored.isPinned(_alpha, 'session-1'), isFalse);
      expect(restored.isPinned(_alpha, 'session-2'), isTrue);
      expect(restored.isPinned(_beta, 'session-1'), isTrue);
      expect(restored.isPinned(_profile, 'session-1'), isTrue);
      expect(restored.isPinned(_beta, 'session-2'), isFalse);
      expect(backend.maxActive, 1);
      expect(backend.writes, hasLength(2));
    },
  );

  for (final rejected in [false, true]) {
    test(
      '${rejected ? 'rejected' : 'false'} commit releases waiting deliberate choice',
      () async {
        final store = await loaded();
        final first = store.toggle(_alpha, 'session-1');
        await backend.waitForWrites(1);
        final waiting = store.toggle(_alpha, 'session-1');
        await Future<void>(() {}).timeout(_deadline);
        expect(store.isPinned(_alpha, 'session-1'), isFalse);
        expect(backend.writes, hasLength(1));
        if (rejected) {
          backend.writes.first.gate.completeError(
            StateError('Synthetic failure'),
          );
        } else {
          backend.writes.first.gate.complete(false);
        }
        await backend.waitForWrites(2);
        backend.writes.last.gate.complete(true);
        await Future.wait([first, waiting]).timeout(_deadline);
        final restored = await fresh();
        expect(restored.isPinned(_alpha, 'session-1'), isFalse);
        expect(backend.writes, hasLength(2));
        expect(backend.maxActive, 1);
      },
    );

    test(
      '${rejected ? 'rejected' : 'false'} commit does not poison later intent or retry',
      () async {
        final store = await loaded();
        final first = store.toggle(_alpha, 'session-1');
        await backend.waitForWrites(1);
        if (rejected) {
          backend.writes.first.gate.completeError(
            StateError('Synthetic failure'),
          );
        } else {
          backend.writes.first.gate.complete(false);
        }
        await first.timeout(_deadline);
        await Future<void>(() {}).timeout(_deadline);
        expect(backend.writes, hasLength(1));
        expect(store.isPinned(_alpha, 'session-1'), isTrue);
        final next = store.toggle(_alpha, 'session-2');
        await backend.waitForWrites(2);
        backend.writes.last.gate.complete(true);
        await next.timeout(_deadline);
        final restored = await fresh();
        expect(restored.isPinned(_alpha, 'session-1'), isTrue);
        expect(restored.isPinned(_alpha, 'session-2'), isTrue);
        expect(backend.maxActive, 1);
      },
    );
  }

  test(
    'disposal drops waiting intent but allows started commit to settle',
    () async {
      final store = HermesSessionPinStore();
      await store.load().timeout(_deadline);
      var notifications = 0;
      store.addListener(() => notifications++);
      final started = store.toggle(_alpha, 'session-1');
      await backend.waitForWrites(1);
      final waiting = store.toggle(_alpha, 'session-2');
      await Future<void>(() {}).timeout(_deadline);
      expect(notifications, 2);
      expect(backend.writes, hasLength(1));
      store.dispose();
      backend.writes.first.gate.complete(true);
      await Future.wait([started, waiting]).timeout(_deadline);
      await store.toggle(_alpha, 'session-3').timeout(_deadline);
      await store.load().timeout(_deadline);
      expect(backend.writes, hasLength(1));
      expect(notifications, 2);
      final restored = await fresh();
      expect(restored.isPinned(_alpha, 'session-1'), isTrue);
      expect(restored.isPinned(_alpha, 'session-2'), isFalse);
    },
  );
}

class _Commit {
  final gate = Completer<bool>();
  final settled = Completer<void>();
}

class _CommitPreferences extends InMemorySharedPreferencesStore {
  _CommitPreferences() : super.empty();

  final writes = <_Commit>[];
  final _admissions = <int, Completer<void>>{};
  int active = 0;
  int maxActive = 0;

  Future<void> waitForWrites(int count) {
    if (writes.length >= count) return Future<void>.value();
    return (_admissions[count] ??= Completer<void>()).future.timeout(_deadline);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    expect(valueType, 'StringList');
    expect(key, 'flutter.wing.hermes.pinned_sessions.v1');
    final snapshot = List<String>.from(value as List);
    final commit = _Commit();
    writes.add(commit);
    active++;
    if (active > maxActive) maxActive = active;
    _admissions.remove(writes.length)?.complete();
    try {
      final successful = await commit.gate.future.timeout(_deadline);
      if (!successful) return false;
      return await super.setValue(valueType, key, snapshot);
    } finally {
      active--;
      commit.settled.complete();
    }
  }
}
