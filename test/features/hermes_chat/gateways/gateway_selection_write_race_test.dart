import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Exercise the real plugin boundary without adding a production storage seam.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_gateway_directory.dart';

const _selectionKey = 'flutter.wing.hermes.gateway_contact_selection.v1';
const _contact = GatewayContactId(gatewayId: 'alpha', profileId: 'default');

class _ParkedStore extends InMemorySharedPreferencesStore {
  _ParkedStore() : super.empty();
  Completer<void>? acquireGate;
  Completer<void>? writeGate;
  Completer<void> acquired = Completer<void>();
  final issued = Completer<void>();
  final selectedB = Completer<void>();
  int writes = 0;

  @override
  Future<Map<String, Object>> getAll() async {
    if (!acquired.isCompleted) acquired.complete();
    await acquireGate?.future;
    return super.getAll();
  }

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == _selectionKey) {
      writes++;
      final gate = writeGate;
      writeGate = null;
      if (gate != null) {
        if (!issued.isCompleted) issued.complete();
        await gate.future;
      }
    }
    final result = await super.setValue(type, key, value);
    if (key == _selectionKey &&
        (jsonDecode(value as String) as Map)['sessionId'] == 'B' &&
        !selectedB.isCompleted) {
      selectedB.complete();
    }
    return result;
  }

  Future<Map<String, Object?>?> pointer() async {
    final raw = (await super.getAll())[_selectionKey];
    return raw == null
        ? null
        : (jsonDecode(raw as String) as Map).cast<String, Object?>();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ParkedStore store;
  setUp(() {
    SharedPreferences.resetStatic();
    store = _ParkedStore();
    SharedPreferencesStorePlatform.instance = store;
  });
  tearDown(() => SharedPreferences.setMockInitialValues({}));

  test(
    'storage acquisition rechecks disposal/selection validity before write',
    () async {
      final gate = Completer<void>();
      store.acquireGate = gate;
      var valid = true;
      final save = GatewayContactCache().saveSelection(
        const GatewayContactSelection(contactId: _contact, sessionId: 'A'),
        canWrite: () => valid,
      );
      await store.acquired.future;
      valid = false;
      gate.complete();
      await save;
      expect(store.writes, 0);
      expect(await store.pointer(), isNull);
    },
  );

  for (final action in [
    'directory',
    'remove',
    'manual',
    'dispose-acquiring',
    'directory-acquiring',
    'remove-acquiring',
    'manual-acquiring',
  ]) {
    test('real delayed storage write cannot undo $action', () async {
      final channel = FakeHermesChannel.disconnected();
      final cache = GatewayContactCache();
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(id: 'alpha', baseUrl: 'https://alpha.example'),
        ],
        loader: FakeGatewaySummaryLoader({'alpha': gatewaySummary([])}),
        cache: cache,
        activeChannel: channel,
      );
      var disposed = false;
      addTearDown(() {
        if (!disposed) directory.dispose();
        channel.dispose();
      });
      await directory.start();
      final acquiring = action.endsWith('-acquiring');
      if (acquiring) {
        SharedPreferences.resetStatic();
        store.acquireGate = Completer<void>();
        store.acquired = Completer<void>();
      } else {
        store.writeGate = Completer<void>();
      }
      final writeRelease = acquiring ? store.acquireGate : store.writeGate;
      final activation = directory.activate(_contact);
      if (action == 'dispose-acquiring') {
        await store.acquired.future;
        directory.dispose();
        disposed = true;
        store.acquireGate!.complete();
        await activation;
        expect(store.writes, 0);
        expect(await store.pointer(), isNull);
        return;
      }
      await (acquiring ? store.acquired : store.issued).future;
      if (action.startsWith('manual')) {
        channel.replaceSessions(const [
          HermesSession(id: 'sess_1', source: 'test'),
          HermesSession(id: 'B', source: 'test'),
        ], activeSessionId: 'B');
        writeRelease!.complete();
        await activation;
        await store.selectedB.future;
        expect((await store.pointer())!['sessionId'], 'B');
        expect(channel.state.activeSessionId, 'B');
      } else {
        final navigation = action.startsWith('directory')
            ? directory.showDirectory()
            : directory.removeGateway('alpha');
        writeRelease!.complete();
        await activation;
        await navigation;
        expect(await store.pointer(), isNull);
        expect(directory.activeContactId, isNull);
      }
    });
  }
}
