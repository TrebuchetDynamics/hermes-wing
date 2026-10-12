import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';
import 'package:wing/features/enrollment/models/hermes_enrollment_payload.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';

import '../hermes_chat/support/fake_hermes_endpoint_store.dart';

const _secretToken = 'hop_super-secret-token-should-never-render';

const _validPayload =
    'wing://connect?origin=https%3A%2F%2Fhermes.example&code=one-time';

const _preview = HermesEnrollmentPreview(
  label: 'Galaxy S24',
  origin: 'https://hermes.example',
  scopes: ['chat:write', 'profiles:read'],
);

const _issued = HermesIssuedOperatorToken(
  token: _secretToken,
  label: 'Galaxy S24',
  credentialId: 'hoc_1',
);

HermesIssuedOperatorToken _issuedBundleWithCount(int count) =>
    HermesIssuedOperatorToken(
      token: _secretToken,
      label: 'BlueBlack',
      credentialId: 'hoc_default',
      wingLinkOrigin: 'https://hermes.example:8654',
      wingLinkToken: 'wing-link-secret',
      wingLinkCredentialId: 'cred_bundle',
      connections: [
        for (var index = 0; index < count; index++)
          HermesIssuedConnection(
            origin: 'https://hermes.example/p/profile-$index',
            token: 'profile-$index-secret',
            label: 'BlueBlack · profile-$index',
            profileId: 'profile-$index',
            credentialId: 'hoc_profile_$index',
          ),
      ],
    );

const _issuedBundle = HermesIssuedOperatorToken(
  token: _secretToken,
  label: 'BlueBlack',
  credentialId: 'hoc_default',
  wingLinkOrigin: 'https://hermes.example:8654',
  wingLinkToken: 'wing-link-secret',
  wingLinkCredentialId: 'cred_bundle',
  connections: [
    HermesIssuedConnection(
      origin: 'https://hermes.example/p/default',
      token: 'default-secret',
      label: 'BlueBlack · default',
      profileId: 'default',
      credentialId: 'hoc_default',
    ),
    HermesIssuedConnection(
      origin: 'https://hermes.example/p/sidon',
      token: 'sidon-secret',
      label: 'BlueBlack · sidon',
      profileId: 'sidon',
      credentialId: 'hoc_sidon',
    ),
  ],
);

class _BlockingEnrollmentStore extends FakeHermesEndpointStore {
  _BlockingEnrollmentStore({super.profiles});

  Completer<void>? loadBlock;
  Completer<void>? firstSaveBlock;
  final loadStarted = Completer<void>();
  final firstSavePersisted = Completer<void>();

  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async {
    if (!loadStarted.isCompleted) loadStarted.complete();
    await loadBlock?.future;
    return super.loadProfiles();
  }

  @override
  Future<void> saveAll(List<HermesEndpointConfig> profiles) async {
    await super.saveAll(profiles);
    if (!firstSavePersisted.isCompleted) {
      firstSavePersisted.complete();
      await firstSaveBlock?.future;
    }
  }
}

void main() {
  group('HermesEnrollmentController (fake inspect/exchange)', () {
    test('rejects a changed host identity before exchange', () async {
      var exchangeCalls = 0;
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async =>
            HermesEnrollmentPreview(
              label: 'Host',
              origin: origin.toString(),
              scopes: const ['health:read'],
              hostFingerprint:
                  'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
              protocolGeneration: 2,
            ),
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          return _issued;
        },
        endpointStore: FakeHermesEndpointStore(),
      );
      addTearDown(controller.dispose);

      await controller.inspect(
        HermesEnrollmentPayload(
          origin: Uri.parse('https://hermes.example'),
          code: 'once',
          wingLinkOrigin: Uri.parse('https://hermes.example:8654'),
          wingLinkHostFingerprint:
              'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
          protocolGeneration: 2,
        ),
      );
      await controller.confirm();

      expect(controller.status, HermesEnrollmentStatus.inspectionFailed);
      expect(exchangeCalls, 0);
    });

    test(
      'generation 2 broker inspect and exchange use pinned transport seams',
      () async {
        var ordinaryInspect = 0;
        var ordinaryExchange = 0;
        var pinnedInspect = 0;
        var pinnedExchange = 0;
        const fingerprint =
            'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async {
            ordinaryInspect++;
            return _preview;
          },
          exchangeEnrollment: ({required origin, required code}) async {
            ordinaryExchange++;
            return _issued;
          },
          inspectPinnedEnrollment:
              ({
                required origin,
                required code,
                required hostFingerprint,
              }) async {
                pinnedInspect++;
                expect(hostFingerprint, fingerprint);
                return HermesEnrollmentPreview(
                  label: 'Pinned host',
                  origin: 'http://192.0.2.1:18642',
                  scopes: const ['health:read'],
                  hostFingerprint: fingerprint,
                  protocolGeneration: 2,
                );
              },
          exchangePinnedEnrollment:
              ({
                required origin,
                required code,
                required hostFingerprint,
              }) async {
                pinnedExchange++;
                expect(hostFingerprint, fingerprint);
                return const HermesIssuedOperatorToken(
                  token: _secretToken,
                  label: 'Pinned host',
                  credentialId: 'hermes_credential',
                  wingLinkOrigin: 'https://192.0.2.1:18654',
                  wingLinkToken: 'wing-link-secret',
                  wingLinkCredentialId: 'cred_phone',
                  hostFingerprint: fingerprint,
                  protocolGeneration: 2,
                  deviceId: 'cred_phone',
                  deviceScopes: ['health.read'],
                );
              },
          acknowledgeWingLinkCredential:
              ({
                required origin,
                required token,
                required credentialId,
                required hostFingerprint,
              }) async {},
          endpointStore: FakeHermesEndpointStore(),
        );
        addTearDown(controller.dispose);
        await controller.inspect(
          HermesEnrollmentPayload(
            origin: Uri.parse('http://192.0.2.1:18642'),
            brokerOrigin: Uri.parse('https://192.0.2.1:40000'),
            code: 'once',
            wingLinkOrigin: Uri.parse('https://192.0.2.1:18654'),
            wingLinkHostFingerprint: fingerprint,
            protocolGeneration: 2,
          ),
        );
        await controller.confirm();
        expect((pinnedInspect, pinnedExchange), (1, 1));
        expect((ordinaryInspect, ordinaryExchange), (0, 0));
        expect(controller.status, HermesEnrollmentStatus.confirmed);
      },
    );

    test('countdown is derived from the injected clock', () async {
      var now = DateTime.utc(2026, 8, 22, 12, 0, 1);
      final controller = HermesEnrollmentController(
        clock: () => now,
        inspectEnrollment: ({required origin, required code}) async =>
            HermesEnrollmentPreview(
              label: 'BlueBlack',
              origin: 'https://hermes.example',
              scopes: const ['Full Hermes access'],
              expiresAt: DateTime.utc(2026, 8, 22, 12, 5),
            ),
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: FakeHermesEndpointStore(),
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));

      expect(controller.remainingTime, const Duration(minutes: 4, seconds: 59));
      now = DateTime.utc(2026, 8, 22, 12, 3, 30);
      expect(controller.remainingTime, const Duration(minutes: 1, seconds: 30));
    });

    test('expiry immediately before confirm prevents exchange', () async {
      var now = DateTime.utc(2026, 8, 22, 12);
      var exchangeCalls = 0;
      final controller = HermesEnrollmentController(
        clock: () => now,
        inspectEnrollment: ({required origin, required code}) async =>
            HermesEnrollmentPreview(
              label: 'BlueBlack',
              origin: 'https://hermes.example',
              scopes: const ['Full Hermes access'],
              expiresAt: DateTime.utc(2026, 8, 22, 12, 1),
            ),
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          return _issued;
        },
        endpointStore: FakeHermesEndpointStore(),
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      now = DateTime.utc(2026, 8, 22, 12, 1);
      await controller.confirm();

      expect(controller.status, HermesEnrollmentStatus.expired);
      expect(exchangeCalls, 0);
      now = DateTime.utc(2026, 8, 22, 12);
      await controller.confirm();
      expect(exchangeCalls, 0, reason: 'the one-time code must stay cleared');
    });

    testWidgets('expiry does not abort an exchange already confirming', (
      tester,
    ) async {
      var now = DateTime.utc(2026, 8, 22, 12);
      var exchangeCalls = 0;
      final exchange = Completer<HermesIssuedOperatorToken>();
      final controller = HermesEnrollmentController(
        clock: () => now,
        inspectEnrollment: ({required origin, required code}) async =>
            HermesEnrollmentPreview(
              label: 'BlueBlack',
              origin: 'https://hermes.example',
              scopes: const ['Full Hermes access'],
              expiresAt: DateTime.utc(2026, 8, 22, 12, 1),
            ),
        exchangeEnrollment: ({required origin, required code}) {
          exchangeCalls++;
          return exchange.future;
        },
        endpointStore: FakeHermesEndpointStore(),
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      final confirmation = controller.confirm();
      expect(controller.status, HermesEnrollmentStatus.confirming);
      expect(exchangeCalls, 1);

      now = DateTime.utc(2026, 8, 22, 12, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(controller.status, HermesEnrollmentStatus.confirming);

      exchange.complete(_issued);
      await confirmation;
      expect(controller.status, HermesEnrollmentStatus.confirmed);
    });

    testWidgets('dispose prevents a pending inspection from starting a timer', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 8, 22, 12);
      final inspection = Completer<HermesEnrollmentPreview>();
      final controller = HermesEnrollmentController(
        clock: () => now,
        inspectEnrollment: ({required origin, required code}) =>
            inspection.future,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: FakeHermesEndpointStore(),
      );

      final pending = controller.inspect(
        HermesEnrollmentPayload.parse(_validPayload),
      );
      controller.dispose();
      inspection.complete(
        HermesEnrollmentPreview(
          label: 'BlueBlack',
          origin: 'https://hermes.example',
          scopes: const ['Full Hermes access'],
          expiresAt: now.add(const Duration(minutes: 5)),
        ),
      );
      await pending;
      await tester.pump(const Duration(seconds: 2));
    });

    test('does not exchange before confirm', () async {
      var inspectCalls = 0;
      var exchangeCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async {
          inspectCalls++;
          return _preview;
        },
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          return _issued;
        },
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));

      expect(inspectCalls, 1);
      expect(exchangeCalls, 0);
      expect(controller.status, HermesEnrollmentStatus.ready);
      expect(store.saveCalls, isEmpty);
    });

    test('confirm exchanges exactly once and saves the token', () async {
      var exchangeCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          return _issued;
        },
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      // A double confirm (e.g. a fast double tap) must still exchange once.
      await Future.wait([controller.confirm(), controller.confirm()]);

      expect(exchangeCalls, 1);
      expect(controller.status, HermesEnrollmentStatus.confirmed);
      expect(store.saveCalls, hasLength(1));
      expect(store.saveCalls.single.apiKey, _secretToken);
      expect(store.saveCalls.single.baseUrl, 'https://hermes.example');
      expect(store.saveCalls.single.label, 'Galaxy S24');
      expect(store.saveCalls.single.displayLabel, 'Galaxy S24');
    });

    test(
      'legacy enrollment persists through the production store as default',
      () async {
        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        final store = SecureHermesEndpointStore();
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
        );
        addTearDown(controller.dispose);

        await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
        await controller.confirm();

        expect(controller.status, HermesEnrollmentStatus.confirmed);
        final saved = await store.loadProfiles();
        expect(saved, hasLength(1));
        expect(
          saved.single.id,
          hermesEndpointIdForBaseUrl('https://hermes.example'),
        );
        expect(saved.single.baseUrl, 'https://hermes.example');
        expect(saved.single.apiKey, _secretToken);
      },
    );

    test(
      'one Wing Link exchange replaces the legacy endpoint with every profile',
      () async {
        const legacy = HermesEndpointConfig(
          id: 'legacy',
          baseUrl: 'https://hermes.example',
          apiKey: 'legacy-secret',
          label: 'BlueBlack',
        );
        final store = FakeHermesEndpointStore(
          initial: legacy,
          profiles: const [legacy],
        );
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              const HermesEnrollmentPreview(
                label: 'Galaxy S24',
                origin: 'https://hermes.example',
                scopes: ['chat:write', 'profiles:read'],
                connectionCount: 2,
              ),
          exchangeEnrollment: ({required origin, required code}) async =>
              _issuedBundle,
          verifyEnrollment:
              ({
                required hermesOrigin,
                required hermesToken,
                required wingLinkOrigin,
                required wingLinkToken,
              }) async {},
          acknowledgeWingLinkCredential:
              ({
                required origin,
                required token,
                required credentialId,
                required hostFingerprint,
              }) async {},
          endpointStore: store,
        );
        addTearDown(controller.dispose);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
          ),
        );
        await controller.confirm();

        expect(controller.status, HermesEnrollmentStatus.confirmed);
        final profiles = await store.loadProfiles();
        expect(profiles, hasLength(2));
        expect(
          profiles.map((profile) => profile.baseUrl),
          containsAll([
            'https://hermes.example/p/default',
            'https://hermes.example/p/sidon',
          ]),
        );
        expect(
          profiles.map((profile) => profile.displayLabel),
          containsAll(['BlueBlack · default', 'BlueBlack · sidon']),
        );
      },
    );

    test('a named profile cannot claim the unprefixed Hermes origin', () async {
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async =>
            const HermesIssuedOperatorToken(
              token: _secretToken,
              connections: [
                HermesIssuedConnection(
                  origin: 'https://hermes.example',
                  token: 'sidon-secret',
                  label: 'Sidon',
                  profileId: 'sidon',
                  credentialId: 'hoc_sidon',
                ),
              ],
            ),
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      await controller.confirm();

      expect(controller.status, HermesEnrollmentStatus.exchangeFailed);
      expect(store.saveAllCalls, isEmpty);
    });

    test(
      'a duplicate profile bundle fails before verification or persistence',
      () async {
        var verifyCalls = 0;
        final store = FakeHermesEndpointStore();
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              const HermesIssuedOperatorToken(
                token: _secretToken,
                wingLinkOrigin: 'https://hermes.example:8654',
                wingLinkToken: 'wlc-control-secret',
                wingLinkCredentialId: 'cred_123',
                connections: [
                  HermesIssuedConnection(
                    origin: 'https://hermes.example/p/sidon',
                    token: 'first',
                    label: 'Sidon',
                    profileId: 'sidon',
                    credentialId: 'hoc_first',
                  ),
                  HermesIssuedConnection(
                    origin: 'https://hermes.example/p/sidon/',
                    token: 'second',
                    label: 'Sidon duplicate',
                    profileId: 'sidon',
                    credentialId: 'hoc_second',
                  ),
                ],
              ),
          verifyEnrollment:
              ({
                required hermesOrigin,
                required hermesToken,
                required wingLinkOrigin,
                required wingLinkToken,
              }) async {
                verifyCalls++;
              },
          endpointStore: store,
        );
        addTearDown(controller.dispose);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
          ),
        );
        await controller.confirm();

        expect(controller.status, HermesEnrollmentStatus.exchangeFailed);
        expect(
          verifyCalls,
          0,
          reason: 'all rows validate before any network verification',
        );
        expect(store.saveAllCalls, isEmpty);
      },
    );

    test(
      'bundle count mismatch fails before verification or persistence',
      () async {
        var verifyCalls = 0;
        var acknowledgeCalls = 0;
        var connectCalls = 0;
        final store = FakeHermesEndpointStore();
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              const HermesEnrollmentPreview(
                label: 'BlueBlack',
                origin: 'https://hermes.example',
                scopes: ['Full Hermes access'],
                connectionCount: 2,
              ),
          exchangeEnrollment: ({required origin, required code}) async =>
              _issuedBundleWithCount(3),
          verifyEnrollment:
              ({
                required hermesOrigin,
                required hermesToken,
                required wingLinkOrigin,
                required wingLinkToken,
              }) async {
                verifyCalls++;
              },
          acknowledgeWingLinkCredential:
              ({
                required origin,
                required token,
                required credentialId,
                required hostFingerprint,
              }) async {
                acknowledgeCalls++;
              },
          endpointStore: store,
          connectSavedEndpoint: (_) async {
            connectCalls++;
          },
        );
        addTearDown(controller.dispose);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
          ),
        );
        await controller.confirm();

        expect(controller.status, HermesEnrollmentStatus.exchangeFailed);
        expect(verifyCalls, 0);
        expect(store.saveAllCalls, isEmpty);
        expect(acknowledgeCalls, 0);
        expect(connectCalls, 0);
      },
    );

    test(
      'legacy exchange is accepted only for a one-connection preview',
      () async {
        final store = FakeHermesEndpointStore();
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              const HermesEnrollmentPreview(
                label: 'BlueBlack',
                origin: 'https://hermes.example',
                scopes: ['Full Hermes access'],
                connectionCount: 2,
              ),
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
        );
        addTearDown(controller.dispose);

        await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
        await controller.confirm();

        expect(controller.status, HermesEnrollmentStatus.exchangeFailed);
        expect(store.saveAllCalls, isEmpty);
      },
    );

    test('invalid direct preview count fails before exchange', () async {
      var exchangeCalls = 0;
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async =>
            const HermesEnrollmentPreview(
              label: 'BlueBlack',
              origin: 'https://hermes.example',
              scopes: ['Full Hermes access'],
              connectionCount: 101,
            ),
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          return _issuedBundleWithCount(100);
        },
        endpointStore: FakeHermesEndpointStore(),
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));

      expect(controller.status, HermesEnrollmentStatus.inspectionFailed);
      await controller.confirm();
      expect(exchangeCalls, 0);
    });

    test('hostile labels are bounded before review and persistence', () async {
      final store = FakeHermesEndpointStore();
      final preview = HermesEnrollmentPreview(
        label: 'Trusted\u202e\u2028\n${List.filled(100, 'x').join()}',
        origin: 'https://hermes.example',
        scopes: const ['chat:write'],
      );
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      final reviewedLabel = controller.preview!.label;
      expect(reviewedLabel.runes, hasLength(80));
      expect(reviewedLabel, isNot(contains('\u202e')));
      expect(reviewedLabel, isNot(contains('\u2028')));
      expect(reviewedLabel, isNot(contains('\n')));

      await controller.confirm();

      expect(store.saveCalls.single.label, reviewedLabel);
    });

    test(
      'CLI broker exchanges the token but saves the Hermes origin',
      () async {
        final contactedOrigins = <Uri>[];
        final store = FakeHermesEndpointStore();
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async {
            contactedOrigins.add(origin);
            return _preview;
          },
          exchangeEnrollment: ({required origin, required code}) async {
            contactedOrigins.add(origin);
            return _issued;
          },
          endpointStore: store,
        );
        addTearDown(controller.dispose);

        final payload = HermesEnrollmentPayload.parse(
          'wing://connect?origin=https%3A%2F%2Fhermes.example'
          '&broker=https%3A%2F%2Fhermes.example%3A45123&code=one-time',
        );
        await controller.inspect(payload);
        await controller.confirm();

        expect(
          contactedOrigins,
          everyElement(Uri.parse('https://hermes.example:45123')),
        );
        expect(store.saveCalls.single.baseUrl, 'https://hermes.example');
        expect(store.saveCalls.single.apiKey, _secretToken);
      },
    );

    test(
      'bundle saves and acknowledges before connecting its imported ID',
      () async {
        final events = <String>[];
        final store = FakeHermesEndpointStore(
          onSaveAll: () => events.add('committed'),
        );
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              const HermesIssuedOperatorToken(
                token: _secretToken,
                wingLinkOrigin: 'https://hermes.example:8654',
                wingLinkToken: 'wlc-control-secret',
                wingLinkCredentialId: 'cred_123',
              ),
          verifyEnrollment:
              ({
                required hermesOrigin,
                required hermesToken,
                required wingLinkOrigin,
                required wingLinkToken,
              }) async {
                events.add('verified');
              },
          acknowledgeWingLinkCredential:
              ({
                required origin,
                required token,
                required credentialId,
                required hostFingerprint,
              }) async {
                events.add('$origin|$token|$credentialId');
              },
          endpointStore: store,
          connectSavedEndpoint: (gatewayId) async {
            events.add('connected:$gatewayId');
          },
        );
        addTearDown(controller.dispose);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
          ),
        );
        await controller.confirm();

        expect(events, [
          'verified',
          'committed',
          'https://hermes.example:8654|wlc-control-secret|cred_123',
          'committed',
          'connected:${hermesEndpointIdForBaseUrl('https://hermes.example')}',
        ]);
        expect(controller.status, HermesEnrollmentStatus.confirmed);
        expect(store.saveAllCalls, hasLength(2));
        expect(store.saveAllCalls.first, hasLength(1));
        expect(
          store.saveAllCalls.first.single.wingLinkOrigin,
          'https://hermes.example:8654',
        );
        expect(
          store.saveAllCalls.first.single.wingLinkToken,
          'wlc-control-secret',
        );
        expect(
          store.saveAllCalls.first.single.wingLinkPendingCredentialId,
          'cred_123',
        );
        expect(
          store.saveAllCalls.last.single.wingLinkPendingCredentialId,
          isNull,
          reason: 'successful acknowledgment must clear durable pending state',
        );
      },
    );

    test(
      'activation failure preserves the committed enrollment outcome',
      () async {
        final activatedIds = <String>[];
        HermesEnrollmentStatus? statusDuringActivation;
        int? countDuringActivation;
        final store = FakeHermesEndpointStore();
        late final HermesEnrollmentController controller;
        controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              const HermesEnrollmentPreview(
                label: 'BlueBlack',
                origin: 'https://hermes.example',
                scopes: ['Full Hermes access'],
                connectionCount: 9,
              ),
          exchangeEnrollment: ({required origin, required code}) async =>
              _issuedBundleWithCount(9),
          verifyEnrollment:
              ({
                required hermesOrigin,
                required hermesToken,
                required wingLinkOrigin,
                required wingLinkToken,
              }) async {},
          acknowledgeWingLinkCredential:
              ({
                required origin,
                required token,
                required credentialId,
                required hostFingerprint,
              }) async {},
          endpointStore: store,
          connectSavedEndpoint: (gatewayId) async {
            statusDuringActivation = controller.status;
            countDuringActivation = controller.connectedProfileCount;
            activatedIds.add(gatewayId);
            throw StateError('gateway reload failed');
          },
        );
        addTearDown(controller.dispose);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
          ),
        );
        await controller.confirm();

        expect(activatedIds, [
          hermesEndpointIdForBaseUrl('https://hermes.example/p/profile-0'),
        ]);
        expect(statusDuringActivation, HermesEnrollmentStatus.confirmed);
        expect(countDuringActivation, 9);
        expect(controller.status, HermesEnrollmentStatus.confirmed);
        expect(controller.connectedProfileCount, 9);
        expect(controller.errorMessage, isNull);
      },
    );

    test(
      'retains the connected profile count only after commit and acknowledgment',
      () async {
        final acknowledgment = Completer<void>();
        var acknowledgmentStarted = false;
        final store = FakeHermesEndpointStore();
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              const HermesEnrollmentPreview(
                label: 'BlueBlack',
                origin: 'https://hermes.example',
                scopes: ['Full Hermes access'],
                connectionCount: 9,
              ),
          exchangeEnrollment: ({required origin, required code}) async =>
              _issuedBundleWithCount(9),
          verifyEnrollment:
              ({
                required hermesOrigin,
                required hermesToken,
                required wingLinkOrigin,
                required wingLinkToken,
              }) async {},
          acknowledgeWingLinkCredential:
              ({
                required origin,
                required token,
                required credentialId,
                required hostFingerprint,
              }) {
                acknowledgmentStarted = true;
                return acknowledgment.future;
              },
          endpointStore: store,
        );
        addTearDown(controller.dispose);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
          ),
        );
        expect(controller.preview!.connectionCount, 9);
        expect(controller.connectedProfileCount, isNull);

        final confirmation = controller.confirm();
        while (!acknowledgmentStarted) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(store.saveAllCalls, hasLength(1));
        expect(controller.connectedProfileCount, isNull);

        acknowledgment.complete();
        await confirmation;

        expect(controller.status, HermesEnrollmentStatus.confirmed);
        expect(controller.connectedProfileCount, 9);
        controller.clearConfirmed();
        expect(controller.status, HermesEnrollmentStatus.idle);
        expect(controller.connectedProfileCount, isNull);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=another-time',
          ),
        );
        await controller.confirm();
        expect(controller.connectedProfileCount, 9);
        controller.cancel();
        expect(controller.status, HermesEnrollmentStatus.idle);
        expect(controller.connectedProfileCount, isNull);
      },
    );

    test(
      'acknowledgment failure retains the complete pending bundle for recovery',
      () async {
        var activationCalls = 0;
        final store = FakeHermesEndpointStore();
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              const HermesEnrollmentPreview(
                label: 'BlueBlack',
                origin: 'https://hermes.example',
                scopes: ['Full Hermes access'],
                connectionCount: 9,
              ),
          exchangeEnrollment: ({required origin, required code}) async =>
              _issuedBundleWithCount(9),
          verifyEnrollment:
              ({
                required hermesOrigin,
                required hermesToken,
                required wingLinkOrigin,
                required wingLinkToken,
              }) async {},
          acknowledgeWingLinkCredential:
              ({
                required origin,
                required token,
                required credentialId,
                required hostFingerprint,
              }) async {
                throw StateError('ack response lost');
              },
          endpointStore: store,
          connectSavedEndpoint: (_) async {
            activationCalls++;
          },
        );
        addTearDown(controller.dispose);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
          ),
        );
        await controller.confirm();

        expect(controller.status, HermesEnrollmentStatus.exchangeFailed);
        expect(controller.connectedProfileCount, isNull);
        expect(activationCalls, 0);
        expect(store.saveAllCalls, hasLength(1));
        final retained = await store.loadProfiles();
        expect(retained, hasLength(9));
        expect(
          retained.map((profile) => profile.id),
          containsAll([
            for (var index = 0; index < 9; index++)
              hermesEndpointIdForBaseUrl(
                'https://hermes.example/p/profile-$index',
              ),
          ]),
        );
        expect(
          retained.every(
            (profile) =>
                profile.wingLinkOrigin == 'https://hermes.example:8654' &&
                profile.wingLinkToken == 'wing-link-secret' &&
                profile.wingLinkPendingCredentialId == 'cred_bundle',
          ),
          isTrue,
          reason: 'response-loss recovery needs every pending credential',
        );
      },
    );

    test('failed enrollment never connects an imported gateway', () async {
      var verifyCalls = 0;
      var connectCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async =>
            const HermesEnrollmentPreview(
              label: 'BlueBlack',
              origin: 'https://hermes.example',
              scopes: ['Full Hermes access'],
              connectionCount: 9,
            ),
        exchangeEnrollment: ({required origin, required code}) async =>
            _issuedBundleWithCount(9),
        verifyEnrollment:
            ({
              required hermesOrigin,
              required hermesToken,
              required wingLinkOrigin,
              required wingLinkToken,
            }) async {
              verifyCalls++;
              if (verifyCalls == 9) throw StateError('verification failed');
            },
        endpointStore: store,
        connectSavedEndpoint: (_) async {
          connectCalls++;
        },
      );
      addTearDown(controller.dispose);

      await controller.inspect(
        HermesEnrollmentPayload.parse(
          'wing://connect?origin=https%3A%2F%2Fhermes.example'
          '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
        ),
      );
      await controller.confirm();

      expect(verifyCalls, 9);
      expect(controller.status, HermesEnrollmentStatus.exchangeFailed);
      expect(controller.connectedProfileCount, isNull);
      expect(store.saveAllCalls, isEmpty);
      expect(connectCalls, 0);
    });

    test('confirm before a successful inspection is a no-op', () async {
      var exchangeCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          return _issued;
        },
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.confirm();

      expect(exchangeCalls, 0);
      expect(store.saveCalls, isEmpty);
      expect(controller.status, HermesEnrollmentStatus.idle);
    });

    test('an expired or reused code fails closed and writes nothing', () async {
      var exchangeCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          throw StateError('pairing code expired or already used');
        },
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      await controller.confirm();

      expect(exchangeCalls, 1);
      expect(controller.status, HermesEnrollmentStatus.exchangeFailed);
      expect(controller.errorMessage, isNull);
      expect(store.saveCalls, isEmpty);

      // Retrying confirm after a failure must not attempt a second
      // exchange: the server-side pairing code is single-use.
      await controller.confirm();
      expect(exchangeCalls, 1);
    });

    test('an inspection failure never reaches exchange', () async {
      var exchangeCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async {
          throw StateError('pairing code not found');
        },
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          return _issued;
        },
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));

      expect(controller.status, HermesEnrollmentStatus.inspectionFailed);
      expect(exchangeCalls, 0);
      expect(store.saveCalls, isEmpty);
    });

    test('cancel discards the code without contacting exchange', () async {
      var exchangeCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          return _issued;
        },
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      controller.cancel();
      // A confirm() arriving after cancel (e.g. a queued tap) must not
      // resurrect the discarded code.
      await controller.confirm();

      expect(exchangeCalls, 0);
      expect(store.saveCalls, isEmpty);
      expect(controller.status, HermesEnrollmentStatus.idle);
      expect(controller.preview, isNull);
    });

    test('a new inspection is ignored while confirmation is active', () async {
      final exchange = Completer<HermesIssuedOperatorToken>();
      var inspectCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async {
          inspectCalls++;
          return _preview;
        },
        exchangeEnrollment: ({required origin, required code}) =>
            exchange.future,
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      final confirmation = controller.confirm();
      await Future<void>.delayed(Duration.zero);
      await controller.inspect(
        HermesEnrollmentPayload.parse(
          'wing://connect?origin=https%3A%2F%2Fhermes.example&code=new-code',
        ),
      );

      expect(inspectCalls, 1);
      expect(controller.status, HermesEnrollmentStatus.confirming);
      exchange.complete(_issued);
      await confirmation;
      expect(controller.status, HermesEnrollmentStatus.confirmed);
    });

    test('cancel during verification never persists or acknowledges', () async {
      final verification = Completer<void>();
      var verifyStarted = false;
      var acknowledgeCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async =>
            const HermesEnrollmentPreview(
              label: 'BlueBlack',
              origin: 'https://hermes.example',
              scopes: ['Full Hermes access'],
              connectionCount: 2,
            ),
        exchangeEnrollment: ({required origin, required code}) async =>
            _issuedBundle,
        verifyEnrollment:
            ({
              required hermesOrigin,
              required hermesToken,
              required wingLinkOrigin,
              required wingLinkToken,
            }) {
              verifyStarted = true;
              return verification.future;
            },
        acknowledgeWingLinkCredential:
            ({
              required origin,
              required token,
              required credentialId,
              required hostFingerprint,
            }) async {
              acknowledgeCalls++;
            },
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(
        HermesEnrollmentPayload.parse(
          'wing://connect?origin=https%3A%2F%2Fhermes.example'
          '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
        ),
      );
      final confirmation = controller.confirm();
      while (!verifyStarted) {
        await Future<void>.delayed(Duration.zero);
      }
      controller.cancel();
      verification.complete();
      await confirmation;

      expect(controller.status, HermesEnrollmentStatus.idle);
      expect(store.saveAllCalls, isEmpty);
      expect(acknowledgeCalls, 0);
    });

    test('cancel during profile load never persists or acknowledges', () async {
      final loadBlock = Completer<void>();
      var acknowledgeCalls = 0;
      final store = _BlockingEnrollmentStore()..loadBlock = loadBlock;
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async =>
            const HermesEnrollmentPreview(
              label: 'BlueBlack',
              origin: 'https://hermes.example',
              scopes: ['Full Hermes access'],
              connectionCount: 2,
            ),
        exchangeEnrollment: ({required origin, required code}) async =>
            _issuedBundle,
        verifyEnrollment:
            ({
              required hermesOrigin,
              required hermesToken,
              required wingLinkOrigin,
              required wingLinkToken,
            }) async {},
        acknowledgeWingLinkCredential:
            ({
              required origin,
              required token,
              required credentialId,
              required hostFingerprint,
            }) async {
              acknowledgeCalls++;
            },
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(
        HermesEnrollmentPayload.parse(
          'wing://connect?origin=https%3A%2F%2Fhermes.example'
          '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
        ),
      );
      final confirmation = controller.confirm();
      await store.loadStarted.future;
      controller.cancel();
      loadBlock.complete();
      await confirmation;

      expect(controller.status, HermesEnrollmentStatus.idle);
      expect(store.saveAllCalls, isEmpty);
      expect(acknowledgeCalls, 0);
    });

    test(
      'cancel during the first save restores the exact existing snapshot',
      () async {
        const existingSnapshot = [
          HermesEndpointConfig(
            id: 'existing-a',
            baseUrl: 'https://a.example',
            apiKey: 'a-secret',
            label: 'Alpha',
          ),
          HermesEndpointConfig(
            id: 'existing-b',
            baseUrl: 'https://b.example',
            apiKey: 'b-secret',
            label: 'Beta',
            wingLinkOrigin: 'https://b.example:8654',
            wingLinkToken: 'existing-wing-secret',
          ),
        ];
        final firstSaveBlock = Completer<void>();
        var acknowledgeCalls = 0;
        var activationCalls = 0;
        final store = _BlockingEnrollmentStore(profiles: existingSnapshot)
          ..firstSaveBlock = firstSaveBlock;
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              const HermesEnrollmentPreview(
                label: 'BlueBlack',
                origin: 'https://hermes.example',
                scopes: ['Full Hermes access'],
                connectionCount: 2,
              ),
          exchangeEnrollment: ({required origin, required code}) async =>
              _issuedBundle,
          verifyEnrollment:
              ({
                required hermesOrigin,
                required hermesToken,
                required wingLinkOrigin,
                required wingLinkToken,
              }) async {},
          acknowledgeWingLinkCredential:
              ({
                required origin,
                required token,
                required credentialId,
                required hostFingerprint,
              }) async {
                acknowledgeCalls++;
              },
          endpointStore: store,
          connectSavedEndpoint: (_) async {
            activationCalls++;
          },
        );
        addTearDown(controller.dispose);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
          ),
        );
        final confirmation = controller.confirm();
        await store.firstSavePersisted.future;
        controller.cancel();
        firstSaveBlock.complete();
        await confirmation;

        expect(controller.status, HermesEnrollmentStatus.idle);
        expect(await store.loadProfiles(), existingSnapshot);
        expect(store.saveAllCalls, hasLength(2));
        expect(store.saveAllCalls.last, existingSnapshot);
        expect(acknowledgeCalls, 0);
        expect(activationCalls, 0);
      },
    );

    test(
      'cancel after acknowledgment starts still finalizes pending credentials',
      () async {
        final acknowledgeStarted = Completer<void>();
        final acknowledgeBlock = Completer<void>();
        var activationCalls = 0;
        final store = FakeHermesEndpointStore();
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              const HermesEnrollmentPreview(
                label: 'BlueBlack',
                origin: 'https://hermes.example',
                scopes: ['Full Hermes access'],
                connectionCount: 2,
              ),
          exchangeEnrollment: ({required origin, required code}) async =>
              _issuedBundle,
          verifyEnrollment:
              ({
                required hermesOrigin,
                required hermesToken,
                required wingLinkOrigin,
                required wingLinkToken,
              }) async {},
          acknowledgeWingLinkCredential:
              ({
                required origin,
                required token,
                required credentialId,
                required hostFingerprint,
              }) async {
                acknowledgeStarted.complete();
                await acknowledgeBlock.future;
              },
          endpointStore: store,
          connectSavedEndpoint: (_) async {
            activationCalls++;
          },
        );
        addTearDown(controller.dispose);

        await controller.inspect(
          HermesEnrollmentPayload.parse(
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
          ),
        );
        final confirmation = controller.confirm();
        await acknowledgeStarted.future;
        controller.cancel();
        acknowledgeBlock.complete();
        await confirmation;

        expect(controller.status, HermesEnrollmentStatus.idle);
        expect(activationCalls, 0);
        final saved = await store.loadProfiles();
        expect(saved, hasLength(2));
        expect(
          saved.every((profile) => profile.wingLinkPendingCredentialId == null),
          isTrue,
        );
      },
    );

    test('cancel during exchange does not save a stale token', () async {
      final exchange = Completer<HermesIssuedOperatorToken>();
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) =>
            exchange.future,
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      final confirmation = controller.confirm();
      await Future<void>.delayed(Duration.zero);
      controller.cancel();
      exchange.complete(_issued);
      await confirmation;

      expect(store.saveCalls, isEmpty);
      expect(controller.status, HermesEnrollmentStatus.idle);
    });

    test(
      'successful enrollment appends and reloads without deletion',
      () async {
        var reloadCalls = 0;
        final store = FakeHermesEndpointStore(
          initial: const HermesEndpointConfig(
            id: 'a',
            label: 'Alpha',
            baseUrl: 'https://a.example',
            apiKey: 'a-secret',
          ),
        );
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
          connectSavedEndpoint: (_) async {
            reloadCalls++;
          },
        );
        addTearDown(controller.dispose);

        await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
        await controller.confirm();

        expect(await store.loadProfiles(), hasLength(2));
        expect(reloadCalls, 1);
        expect(store.deleteProfileCalls, isEmpty);
      },
    );

    test('updating a gateway preserves every unrelated gateway', () async {
      final store = FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(
            id: 'existing',
            label: 'Old label',
            baseUrl: 'https://hermes.example',
            apiKey: 'old-key',
          ),
          HermesEndpointConfig(
            id: 'unrelated',
            label: 'Unrelated',
            baseUrl: 'https://other.example',
            apiKey: 'other-key',
          ),
        ],
      );
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      await controller.confirm();

      final profiles = await store.loadProfiles();
      expect(profiles, hasLength(2));
      expect(
        profiles
            .singleWhere(
              (profile) => profile.baseUrl == 'https://hermes.example',
            )
            .apiKey,
        _secretToken,
      );
      final unrelated = profiles.singleWhere(
        (profile) => profile.id == 'unrelated',
      );
      expect(unrelated.baseUrl, 'https://other.example');
      expect(unrelated.label, 'Unrelated');
      expect(unrelated.apiKey, 'other-key');
      expect(store.deleteProfileCalls, isEmpty);
      expect(store.clearCalls, 0);
    });

    test(
      'same-named profiles from different gateways remain distinct',
      () async {
        final store = FakeHermesEndpointStore(
          profiles: const [
            HermesEndpointConfig(
              id: 'default',
              label: 'Other default',
              baseUrl: 'https://other.example',
              apiKey: 'other-key',
            ),
          ],
        );
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
        );
        addTearDown(controller.dispose);

        await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
        await controller.confirm();

        final profiles = await store.loadProfiles();
        expect(
          profiles.map((profile) => profile.baseUrl),
          containsAll(['https://hermes.example', 'https://other.example']),
        );
        expect(profiles.map((profile) => profile.id).toSet(), hasLength(2));
      },
    );
  });
}
