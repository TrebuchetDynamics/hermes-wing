import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../../features/hermes_chat/support/fake_hermes_channel.dart';
import '../../../features/hermes_chat/support/fake_hermes_gateway_directory.dart';

const _bundle = 'wing.hermes.endpoint_bundle.v1';
const _metadata = 'wing.hermes.profiles';
const _tokenSlot = 'wing.hermes.profile_wing_link_token.first';
const _row = {
  'id': 'first',
  'baseUrl': 'https://agent.example.invalid/p/shared',
  'label': 'Saved',
  'apiKey': 'synthetic-agent',
  'wingLinkOrigin': 'https://control.example.invalid',
  'wingLinkToken': 'synthetic-control',
  'wingLinkPendingCredentialId': 'pending',
  'wingLinkHostFingerprint': 'synthetic-pin',
  'wingLinkDeviceId': 'device',
};

class _ObservedStorage extends FlutterSecureStorage {
  final reads = <String>[];
  bool failWrite = false;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    reads.add(key);
    if (key.contains('wing_link_token')) {
      throw StateError('Retired credential must not be read');
    }
    return super.read(key: key);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    if (failWrite) throw StateError('synthetic persistence failure');
    return super.write(key: key, value: value);
  }
}

Future<List<dynamic>> _rawRows() async =>
    jsonDecode((await const FlutterSecureStorage().read(key: _bundle))!)
        as List;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'directory startup, rename and edit preserve inert raw records without management traffic',
    () async {
      SharedPreferences.setMockInitialValues({});
      final other = {
        'id': 'other',
        'baseUrl': 'https://other.example.invalid',
        'apiKey': 'synthetic-other',
        'wingLinkDeviceId': 'other-device',
      };
      final initial = jsonEncode([_row, other]);
      FlutterSecureStorage.setMockInitialValues({
        _bundle: initial,
        _tokenSlot: 'synthetic-separate-control',
      });
      final storage = _ObservedStorage();
      final store = SecureHermesEndpointStore(secureStorage: storage);
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        activeChannel: channel,
        loader: FakeGatewaySummaryLoader({
          'first': gatewaySummary(['shared']),
          'other': gatewaySummary(['default']),
        }),
      );
      addTearDown(directory.dispose);
      var networkClients = 0;
      await HttpOverrides.runZoned(
        () async {
          await directory.start();
          await directory.reconnectGateway('first');
          expect(
            await const FlutterSecureStorage().read(key: _bundle),
            initial,
          );
          await directory.activateGateway('other');
          final owner = directory.activeContactId;
          final session = channel.state.activeSessionId;
          await directory.renameGateway('first', 'Renamed');
          await directory.updateGatewayConnection(
            'first',
            baseUrl: _row['baseUrl']!,
          );
          final raw = (await _rawRows()).first as Map;
          expect(raw, {..._row, 'label': 'Renamed'});
          expect((await _rawRows()).last, other);
          expect(directory.activeContactId, owner);
          expect(channel.state.activeSessionId, session);
          expect(channel.connectCalls.single.apiKey, 'synthetic-other');
          expect(channel.createSessionCalls, isEmpty);
          expect(channel.sentVoiceTranscripts, isEmpty);
          storage.failWrite = true;
          await expectLater(
            directory.renameGateway('first', 'Rejected'),
            throwsStateError,
          );
          expect(directory.configForGateway('first')!.label, 'Renamed');
          expect((await _rawRows()).first, raw);
          storage.failWrite = false;
        },
        createHttpClient: (_) {
          networkClients++;
          throw StateError('Unexpected management traffic');
        },
      );
      expect(networkClients, 0);
      expect(storage.reads, isNot(contains(_tokenSlot)));
      expect(
        await const FlutterSecureStorage().read(key: _tokenSlot),
        'synthetic-separate-control',
      );
      expect(
        (await SecureHermesEndpointStore().loadProfiles()).first.apiKey,
        'synthetic-agent',
      );
    },
  );

  test(
    'missing Agent credential never adopts a raw management credential',
    () async {
      SharedPreferences.setMockInitialValues({});
      final raw = jsonEncode([
        {..._row}..remove('apiKey'),
      ]);
      FlutterSecureStorage.setMockInitialValues({
        _bundle: raw,
        _tokenSlot: 'synthetic-control',
      });
      final storage = _ObservedStorage();
      final loaded = await SecureHermesEndpointStore(
        secureStorage: storage,
      ).load();
      expect(loaded!.apiKey, isNull);
      expect(loaded.baseUrl, _row['baseUrl']);
      expect(await const FlutterSecureStorage().read(key: _bundle), raw);
      expect(storage.reads, isNot(contains(_tokenSlot)));
    },
  );

  test(
    'unreadable historical records cannot be overwritten by a save',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({_bundle: 'unreadable'});
      await expectLater(
        SecureHermesEndpointStore().saveAll(const []),
        throwsFormatException,
      );
      expect(
        await const FlutterSecureStorage().read(key: _bundle),
        'unreadable',
      );
    },
  );

  for (final legacyPreferences in [false, true]) {
    test(
      'raw legacy roundtrip, failure and scoped deletion: preferences=$legacyPreferences',
      () async {
        final rawMetadata = jsonEncode([
          {..._row}
            ..remove('apiKey')
            ..remove('wingLinkToken')
            ..remove('wingLinkHostFingerprint'),
        ]);
        SharedPreferences.setMockInitialValues({_metadata: rawMetadata});
        final other = {
          'id': 'other',
          'baseUrl': 'https://other.example.invalid',
          'apiKey': 'synthetic-other',
          'wingLinkDeviceId': 'other-device',
        };
        FlutterSecureStorage.setMockInitialValues({
          if (!legacyPreferences) _bundle: jsonEncode([_row, other]),
          'wing.hermes.profile_api_key.first': 'synthetic-agent',
          _tokenSlot: 'synthetic-separate-control',
        });
        final storage = _ObservedStorage();
        final store = SecureHermesEndpointStore(secureStorage: storage);
        final loaded = await store.loadProfiles();
        expect(loaded.first.id, 'first');
        expect(loaded.first.baseUrl, _row['baseUrl']);
        expect(loaded.first.apiKey, 'synthetic-agent');
        expect(storage.reads, isNot(contains(_tokenSlot)));
        expect(
          (await SharedPreferences.getInstance()).getString(_metadata),
          rawMetadata,
        );

        storage.failWrite = true;
        final before = await const FlutterSecureStorage().read(key: _bundle);
        await expectLater(store.saveAll(loaded), throwsStateError);
        expect(await const FlutterSecureStorage().read(key: _bundle), before);
        expect(
          (await SharedPreferences.getInstance()).getString(_metadata),
          rawMetadata,
        );
        expect(
          await const FlutterSecureStorage().read(key: _tokenSlot),
          'synthetic-separate-control',
        );
        expect(
          (await SecureHermesEndpointStore().loadProfiles()).first.apiKey,
          'synthetic-agent',
        );
        storage.failWrite = false;
        await store.save(
          profileId: 'first',
          baseUrl: loaded.first.baseUrl,
          apiKey: loaded.first.apiKey,
          label: 'Renamed',
        );
        final raw = (await _rawRows()).first as Map;
        for (final key in _row.keys.where(
          (key) => key.startsWith('wingLink'),
        )) {
          if (legacyPreferences &&
              (key == 'wingLinkToken' || key == 'wingLinkHostFingerprint')) {
            continue;
          }
          expect(raw[key], _row[key], reason: key);
        }
        expect(raw['label'], 'Renamed');
        expect(raw['apiKey'], 'synthetic-agent');
        expect(
          jsonDecode(
            (await SharedPreferences.getInstance()).getString(_metadata)!,
          ).first,
          {
            ...(jsonDecode(rawMetadata) as List).first as Map,
            'label': 'Renamed',
          },
        );
        expect(
          await const FlutterSecureStorage().read(key: _tokenSlot),
          'synthetic-separate-control',
        );
        expect(
          jsonDecode(
            (await SharedPreferences.getInstance()).getString(_metadata)!,
          ).first['wingLinkDeviceId'],
          'device',
        );
        expect(
          (await SharedPreferences.getInstance()).getString(_metadata),
          isNot(contains('synthetic-control')),
        );
        final restarted = SecureHermesEndpointStore(secureStorage: storage);
        await restarted.saveAll(await restarted.loadProfiles());
        expect((await _rawRows()).first, raw);
        if (!legacyPreferences) expect((await _rawRows()).last, other);
        await restarted.deleteProfile('first');
        expect(
          await const FlutterSecureStorage().read(key: _tokenSlot),
          'synthetic-separate-control',
        );
        if (!legacyPreferences) expect((await _rawRows()).single, other);
        expect(storage.reads, isNot(contains(_tokenSlot)));
      },
    );
  }
  test('changed Agent origin never inherits its saved credential', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      _bundle: jsonEncode([_row]),
    });
    await SecureHermesEndpointStore().save(
      profileId: 'first',
      baseUrl: 'https://replacement.example.invalid',
      label: 'Saved',
    );
    expect((await SecureHermesEndpointStore().load())!.apiKey, isNull);
    expect((await _rawRows()).single['wingLinkToken'], isNull);
  });
}
