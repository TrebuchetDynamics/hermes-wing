import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The installed plugin interface is used only by this isolated platform fake.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/session/hermes_session_pin_store.dart';

const _contact = GatewayContactId(gatewayId: 'alpha', profileId: 'default');
const _key = 'flutter.wing.hermes.pinned_sessions.v1';
const _deadline = Duration(seconds: 5);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferencesStorePlatform originalPlatform;
  late _DelayedPreferences preferences;

  setUp(() {
    originalPlatform = SharedPreferencesStorePlatform.instance;
    SharedPreferences.resetStatic();
    preferences = _DelayedPreferences();
    SharedPreferencesStorePlatform.instance = preferences;
  });

  tearDown(() {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  test(
    'pending toggle completes benignly after disposal during load',
    () async {
      final store = HermesSessionPinStore();
      var notifications = 0;
      store.addListener(() => notifications++);
      final loading = store.load();
      await preferences.readStarted.future.timeout(_deadline);
      final toggling = store.toggle(_contact, 'session-1');
      final completion = expectLater(toggling.timeout(_deadline), completes);
      store.dispose();
      preferences.read.complete({
        _key: [
          jsonEncode(['alpha', 'default', 'old']),
        ],
      });
      await loading.timeout(_deadline);
      await completion;
      expect(notifications, 0);
      expect(preferences.writes, isEmpty);
      expect(store.isPinned(_contact, 'session-1'), isFalse);
      expect(store.isPinned(_contact, 'old'), isFalse);
    },
  );

  test('load alone does not populate or notify after disposal', () async {
    final store = HermesSessionPinStore();
    var notifications = 0;
    store.addListener(() => notifications++);
    final loading = store.load();
    await preferences.readStarted.future.timeout(_deadline);
    store.dispose();
    preferences.read.complete({
      _key: [
        jsonEncode(['alpha', 'default', 'old']),
      ],
    });
    await loading.timeout(_deadline);
    expect(notifications, 0);
    expect(store.isPinned(_contact, 'old'), isFalse);
    expect(preferences.writes, isEmpty);
  });

  test(
    'toggle and load invoked after disposal do not access storage',
    () async {
      final store = HermesSessionPinStore();
      store.dispose();
      await store.toggle(_contact, 'session-1').timeout(_deadline);
      await store.load().timeout(_deadline);
      expect(preferences.reads, 0);
      expect(preferences.writes, isEmpty);
      expect(store.isPinned(_contact, 'session-1'), isFalse);
    },
  );

  test('active pending toggle persists only its owner and unpins', () async {
    final store = HermesSessionPinStore();
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications++);
    final loading = store.load();
    await preferences.readStarted.future.timeout(_deadline);
    final toggling = store.toggle(_contact, 'session-1');
    preferences.read.complete({});
    await loading.timeout(_deadline);
    await toggling.timeout(_deadline);
    expect(notifications, 2);
    expect(store.isPinned(_contact, 'session-1'), isTrue);
    expect(
      store.isPinned(
        const GatewayContactId(gatewayId: 'beta', profileId: 'default'),
        'session-1',
      ),
      isFalse,
    );
    expect(preferences.writes, hasLength(1));
    expect(preferences.writes.single.$1, _key);
    expect(preferences.writes.single.$2, [
      jsonEncode(['alpha', 'default', 'session-1']),
    ]);
    final restored = HermesSessionPinStore();
    addTearDown(restored.dispose);
    await restored.load().timeout(_deadline);
    expect(restored.isPinned(_contact, 'session-1'), isTrue);
    await store.toggle(_contact, 'session-1').timeout(_deadline);
    expect(store.isPinned(_contact, 'session-1'), isFalse);
    expect(preferences.writes.last.$1, _key);
    expect(preferences.writes.last.$2, isEmpty);
  });

  test('delayed read failure settles pending toggle after disposal', () async {
    final store = HermesSessionPinStore();
    final loading = store.load();
    await preferences.readStarted.future.timeout(_deadline);
    final toggling = store.toggle(_contact, 'session-1');
    final completion = expectLater(toggling.timeout(_deadline), completes);
    store.dispose();
    preferences.read.completeError(StateError('Synthetic preference failure'));
    await loading.timeout(_deadline);
    await completion;
    expect(preferences.reads, 1);
    expect(preferences.writes, isEmpty);
    expect(store.isPinned(_contact, 'session-1'), isFalse);
  });

  test('active store remains usable after delayed read failure', () async {
    final store = HermesSessionPinStore();
    addTearDown(store.dispose);
    final loading = store.load();
    await preferences.readStarted.future.timeout(_deadline);
    preferences.read.completeError(StateError('Synthetic preference failure'));
    await loading.timeout(_deadline);
    // The plugin retries initialization after failure; restore only its cache.
    SharedPreferences.resetStatic();
    preferences.read = Completer<Map<String, Object>>()..complete({});
    await store.toggle(_contact, 'session-1').timeout(_deadline);
    expect(store.isPinned(_contact, 'session-1'), isTrue);
    expect(preferences.writes, hasLength(1));
  });

  test('disposal while acquiring persistence prevents a new write', () async {
    final store = HermesSessionPinStore();
    var notifications = 0;
    store.addListener(() => notifications++);
    // No initial load: toggle reaches its separate persistence await.
    final toggling = store.toggle(_contact, 'session-1');
    await preferences.readStarted.future.timeout(_deadline);
    expect(notifications, 1);
    store.dispose();
    preferences.read.complete({});
    await toggling.timeout(_deadline);
    expect(notifications, 1);
    expect(preferences.writes, isEmpty);
  });

  test('already-started platform write may settle after disposal', () async {
    final store = HermesSessionPinStore();
    preferences.read.complete({});
    await store.load().timeout(_deadline);
    preferences.writeGate = Completer<bool>();
    final toggling = store.toggle(_contact, 'session-1');
    await preferences.writeStarted.future.timeout(_deadline);
    expect(preferences.writes, hasLength(1));
    store.dispose();
    preferences.writeGate!.complete(true);
    await toggling.timeout(_deadline);
    await store.toggle(_contact, 'session-2').timeout(_deadline);
    expect(preferences.writes, hasLength(1));
  });
}

class _DelayedPreferences extends InMemorySharedPreferencesStore {
  _DelayedPreferences() : super.empty();

  Completer<Map<String, Object>> read = Completer<Map<String, Object>>();
  final readStarted = Completer<void>();
  final writeStarted = Completer<void>();
  Completer<bool>? writeGate;
  int reads = 0;
  final writes = <(String, List<String>)>[];

  @override
  Future<Map<String, Object>> getAll() {
    reads++;
    if (!readStarted.isCompleted) readStarted.complete();
    return read.future;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    expect(valueType, 'StringList');
    writes.add((key, List<String>.from(value as List)));
    if (!writeStarted.isCompleted) writeStarted.complete();
    final gate = writeGate;
    if (gate != null) await gate.future;
    return super.setValue(valueType, key, value);
  }
}
