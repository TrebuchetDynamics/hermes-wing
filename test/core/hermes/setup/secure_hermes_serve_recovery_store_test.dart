import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_web_reads.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final row = <String, Object>{
    'version': 1,
    'origin': 'http://127.0.0.1:8765',
    'profile': 'demo',
    'stored': 'stored-fixture',
    'runtime': 'runtime-fixture',
    'epoch': 'fixture',
    'sequence': 9,
    'uncertain': true,
    'credential': 'synthetic-owner',
  };
  test(
    'exact pointer roundtrip preserves unrelated and legacy secure slots',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        SecureHermesServeRecoveryStore.key: jsonEncode(row),
        'inert-fixture-legacy': 'synthetic-inert',
      });
      final store = SecureHermesServeRecoveryStore();
      final selection = (await store.load())!;
      expect(selection.checkpoint.sequence, 9);
      expect(selection.checkpoint.runtimeSessionId, 'runtime-fixture');
      expect(selection.checkpoint.storedSessionId, 'stored-fixture');
      expect(selection.credential, 'synthetic-owner');
      await store.save(selection);
      expect((await store.load())!.checkpoint.profile, 'demo');
      await store.clear();
      expect(await store.load(), isNull);
      expect(
        await const FlutterSecureStorage().read(key: 'inert-fixture-legacy'),
        'synthetic-inert',
      );
    },
  );
  test(
    'malformed owner/remote origin fails closed without deleting the pointer',
    () async {
      for (final entry in <Map<String, Object>>[
        {'origin': 'http://example.invalid'},
        {'origin': 'http://127.0.0.1?credential=synthetic'},
        {'profile': ' demo'},
        {'stored': '../other'},
        {'sequence': -1},
        {'uncertain': 'true'},
        {'version': 2},
      ]) {
        final encoded = jsonEncode({...row, ...entry});
        FlutterSecureStorage.setMockInitialValues({
          SecureHermesServeRecoveryStore.key: encoded,
        });
        await expectLater(
          SecureHermesServeRecoveryStore().load(),
          throwsA(isA<HermesWebReadException>()),
        );
        expect(
          await const FlutterSecureStorage().read(
            key: SecureHermesServeRecoveryStore.key,
          ),
          encoded,
        );
      }
    },
  );
}
