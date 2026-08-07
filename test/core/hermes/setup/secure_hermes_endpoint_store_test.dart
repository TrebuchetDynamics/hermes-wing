import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';

/// Every value the store wrote to shared preferences, flattened for scanning.
Future<String> _preferenceDump() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getKeys().map((key) => '$key=${prefs.get(key)}').join('\n');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureHermesEndpointStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    store = SecureHermesEndpointStore();
  });

  group('credential placement', () {
    test('an API key never reaches shared preferences', () async {
      await store.save(
        baseUrl: 'https://hermes.example',
        apiKey: 'super-secret-token',
        label: 'Work',
      );

      expect(
        await _preferenceDump(),
        isNot(contains('super-secret-token')),
        reason: 'shared preferences is unencrypted on disk',
      );
    });

    test('the API key round-trips through secure storage', () async {
      await store.save(
        baseUrl: 'https://hermes.example',
        apiKey: 'super-secret-token',
      );

      final loaded = await store.load();

      expect(loaded?.apiKey, 'super-secret-token');
      expect(loaded?.baseUrl, 'https://hermes.example');
    });

    test('the Wing Link token is secure and round-trips separately', () async {
      await store.save(
        baseUrl: 'https://hermes.example:8642',
        apiKey: 'hermes-secret',
        wingLinkOrigin: 'https://hermes.example:8654',
        wingLinkToken: 'wing-link-secret',
        wingLinkPendingCredentialId: 'cred_pending',
      );

      final loaded = await store.load();

      expect(loaded?.wingLinkOrigin, 'https://hermes.example:8654');
      expect(loaded?.wingLinkToken, 'wing-link-secret');
      expect(loaded?.wingLinkPendingCredentialId, 'cred_pending');
      expect(await _preferenceDump(), isNot(contains('wing-link-secret')));
      expect(loaded?.apiKey, 'hermes-secret');

      await store.save(
        baseUrl: 'https://hermes.example:8642',
        apiKey: 'hermes-secret',
        wingLinkPendingCredentialId: '',
      );
      expect((await store.load())?.wingLinkPendingCredentialId, isNull);
      expect((await store.load())?.wingLinkToken, 'wing-link-secret');
    });

    test('saving without a credential leaves none behind', () async {
      await store.save(baseUrl: 'https://hermes.example', apiKey: 'first');
      await store.save(baseUrl: 'https://hermes.example', apiKey: null);

      final loaded = await store.load();

      expect(
        loaded?.apiKey,
        isNull,
        reason: 'a cleared credential must not resurrect',
      );
    });

    test('a blank credential is treated as absent, not stored', () async {
      await store.save(baseUrl: 'https://hermes.example', apiKey: 'first');
      await store.save(baseUrl: 'https://hermes.example', apiKey: '');

      expect((await store.load())?.apiKey, isNull);
    });
  });

  group('profiles', () {
    test('saved profiles round-trip with their metadata', () async {
      await store.save(
        baseUrl: 'https://a.example',
        apiKey: 'key-a',
        label: 'Alpha',
        profileId: 'a',
      );
      await store.save(
        baseUrl: 'https://b.example',
        apiKey: 'key-b',
        label: 'Beta',
        profileId: 'b',
      );

      final profiles = await store.loadProfiles();

      expect(profiles.map((p) => p.id), containsAll(['a', 'b']));
      expect(
        profiles.firstWhere((p) => p.id == 'a').apiKey,
        'key-a',
        reason: 'each profile keeps its own credential',
      );
      expect(profiles.firstWhere((p) => p.id == 'b').apiKey, 'key-b');
    });

    test('the origin is normalized before it is stored', () async {
      await store.save(
        baseUrl: 'https://hermes.example:8642/api/sessions?token=leaked',
        apiKey: 'key',
      );

      final loaded = await store.load();

      expect(loaded?.baseUrl, 'https://hermes.example:8642');
      expect(
        await _preferenceDump(),
        isNot(contains('leaked')),
        reason: 'query secrets must not survive normalization',
      );
    });

    test('re-saving the same origin updates rather than duplicates', () async {
      await store.save(
        baseUrl: 'https://a.example',
        apiKey: 'first',
        profileId: 'a',
      );
      await store.save(
        baseUrl: 'https://a.example',
        apiKey: 'second',
        profileId: 'a',
      );

      final profiles = await store.loadProfiles();

      expect(profiles, hasLength(1));
      expect(profiles.single.apiKey, 'second');
    });

    test('load returns the selected profile, not merely the first', () async {
      await store.save(baseUrl: 'https://a.example', profileId: 'a');
      await store.save(baseUrl: 'https://b.example', profileId: 'b');

      expect(
        (await store.load())?.id,
        'b',
        reason: 'the most recently saved profile is the selected one',
      );
    });
  });

  group('deletion', () {
    test('deleting a profile removes its stored credential', () async {
      await store.save(
        baseUrl: 'https://a.example',
        apiKey: 'key-a',
        profileId: 'a',
      );
      await store.save(
        baseUrl: 'https://b.example',
        apiKey: 'key-b',
        profileId: 'b',
      );

      await store.deleteProfile('a');

      final profiles = await store.loadProfiles();
      expect(profiles.map((p) => p.id), ['b']);
      expect(
        await const FlutterSecureStorage().read(
          key: 'wing.hermes.profile_api_key.a',
        ),
        isNull,
        reason: 'a deleted profile must not leave its key behind',
      );
    });

    test('deleting the selected profile promotes a survivor', () async {
      await store.save(baseUrl: 'https://a.example', profileId: 'a');
      await store.save(
        baseUrl: 'https://b.example',
        apiKey: 'key-b',
        profileId: 'b',
      );

      await store.deleteProfile('b');

      final loaded = await store.load();
      expect(loaded?.id, 'a');
      expect(loaded?.apiKey, isNull);
    });

    test('deleting the last profile leaves nothing loadable', () async {
      await store.save(
        baseUrl: 'https://a.example',
        apiKey: 'key-a',
        profileId: 'a',
      );

      await store.deleteProfile('a');

      expect(await store.loadProfiles(), isEmpty);
      expect(await store.load(), isNull);
    });

    test('clear drops the selected profile and its credential', () async {
      await store.save(
        baseUrl: 'https://a.example',
        apiKey: 'key-a',
        profileId: 'a',
      );

      await store.clear();

      expect(await store.load(), isNull);
      expect(await _preferenceDump(), isNot(contains('key-a')));
    });
  });

  group('legacy single-endpoint migration', () {
    test('a legacy base URL and key are adopted as one profile', () async {
      SharedPreferences.setMockInitialValues({
        'wing.hermes.base_url': 'https://legacy.example',
      });
      FlutterSecureStorage.setMockInitialValues({
        'wing.hermes.api_key': 'legacy-secret',
      });

      final profiles = await SecureHermesEndpointStore().loadProfiles();

      expect(profiles, hasLength(1));
      expect(profiles.single.baseUrl, 'https://legacy.example');
      expect(profiles.single.apiKey, 'legacy-secret');
    });

    test('modern profiles take precedence over the legacy entry', () async {
      await store.save(
        baseUrl: 'https://modern.example',
        apiKey: 'modern',
        profileId: 'modern',
      );

      final profiles = await store.loadProfiles();

      expect(profiles.map((p) => p.baseUrl), ['https://modern.example']);
    });

    test('no stored state loads nothing rather than failing', () async {
      expect(await store.loadProfiles(), isEmpty);
      expect(await store.load(), isNull);
    });
  });

  group('malformed stored state', () {
    test('unparseable profile metadata degrades to empty', () async {
      SharedPreferences.setMockInitialValues({
        'wing.hermes.profiles': 'not json at all',
      });

      expect(await SecureHermesEndpointStore().loadProfiles(), isEmpty);
    });

    test('profile rows missing an id or origin are discarded', () async {
      SharedPreferences.setMockInitialValues({
        'wing.hermes.profiles':
            '[{"id":"","baseUrl":"https://a.example"},'
            '{"id":"b","baseUrl":""},'
            '{"id":"c","baseUrl":"https://c.example"}]',
      });

      final profiles = await SecureHermesEndpointStore().loadProfiles();

      expect(profiles.map((p) => p.id), ['c']);
    });

    test('duplicate origins collapse to the first row', () async {
      SharedPreferences.setMockInitialValues({
        'wing.hermes.profiles':
            '[{"id":"a","baseUrl":"https://same.example"},'
            '{"id":"b","baseUrl":"https://same.example"}]',
      });

      final profiles = await SecureHermesEndpointStore().loadProfiles();

      expect(profiles.map((p) => p.id), ['a']);
    });
  });
}
