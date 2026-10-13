import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SecureHermesEndpointStore store;
  const original = HermesEndpointConfig(
    id: 'first',
    label: 'Shared',
    baseUrl: 'https://first.example.invalid/p/shared',
  );
  const other = HermesEndpointConfig(
    id: 'second',
    label: 'Shared',
    baseUrl: 'https://second.example.invalid/p/shared',
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    store = SecureHermesEndpointStore();
    await store.saveAll([original, other]);
  });
  test(
    'exact ID editing retains Agent identity and isolates unrelated rows',
    () async {
      await store.save(
        profileId: 'first',
        baseUrl: original.baseUrl,
        label: original.label,
        apiKey: 'synthetic-agent',
      );

      expect((await store.load())!.apiKey, 'synthetic-agent');
      await store.save(
        profileId: 'first',
        baseUrl: 'https://new.example.invalid/p/shared',
        label: original.label,
        apiKey: 'synthetic-new-agent',
      );
      final rows = await store.loadProfiles();
      final row = rows.singleWhere((row) => row.id == 'first');
      expect(row.apiKey, 'synthetic-new-agent');

      expect(
        rows.singleWhere((row) => row.id == 'second').baseUrl,
        other.baseUrl,
      );
    },
  );
  test(
    'collision with another saved origin fails without deleting either row',
    () async {
      await expectLater(
        store.save(profileId: 'first', baseUrl: other.baseUrl),
        throwsStateError,
      );
      final rows = await store.loadProfiles();
      expect(rows, hasLength(2));
      expect(
        rows.singleWhere((row) => row.id == 'first').baseUrl,
        original.baseUrl,
      );
      expect(
        rows.singleWhere((row) => row.id == 'second').baseUrl,
        other.baseUrl,
      );
    },
  );
}
