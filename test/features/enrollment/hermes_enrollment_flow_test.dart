import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';
import 'package:wing/features/enrollment/models/hermes_enrollment_payload.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/enrollment/services/hermes_connect_intent_source.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/router/providers/app_router.dart';
import 'package:wing/router/routes/app_routes.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
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

class _FakeConnectIntentSource implements HermesConnectIntentSource {
  _FakeConnectIntentSource({
    this.initial,
    this.scanned,
    this.imported,
    this.scanThrowsOnce = false,
  });

  final String? initial;
  final String? scanned;
  final String? imported;
  final bool scanThrowsOnce;
  int scanCalls = 0;
  int importCalls = 0;
  final _events = StreamController<String>.broadcast();

  @override
  Future<String?> initialPayload() async => initial;

  @override
  Stream<String> payloadEvents() => _events.stream;

  @override
  Future<String?> importQrImage() async {
    importCalls++;
    return imported;
  }

  @override
  Future<String?> scanQrCode() async {
    scanCalls++;
    if (scanThrowsOnce && scanCalls == 1) {
      throw StateError('scanner launch failed');
    }
    return scanned;
  }

  void emit(String payload) => _events.add(payload);

  void dispose() => unawaited(_events.close());
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

  group('HermesEnrollmentScreen (widget flow)', () {
    Widget buildApp({
      required HermesEnrollmentController controller,
      required _FakeConnectIntentSource source,
      required FakeHermesEndpointStore store,
    }) {
      final container = ProviderContainer(
        overrides: [
          hermesEnrollmentControllerProvider.overrideWith((ref) => controller),
          hermesConnectIntentSourceProvider.overrideWithValue(source),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesChannelProvider.overrideWithValue(
            FakeHermesChannel.disconnected(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      router.go(AppRoutes.enroll);
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
    }

    bool anyTextContains(WidgetTester tester, String value) {
      final texts = tester.widgetList<Text>(find.byType(Text));
      for (final text in texts) {
        final data = text.data ?? text.textSpan?.toPlainText() ?? '';
        if (data.contains(value)) return true;
      }
      return false;
    }

    bool anyTextContainsToken(WidgetTester tester) =>
        anyTextContains(tester, _secretToken);

    testWidgets(
      'Android chooser actions are ordered, full width, and bounded',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final store = FakeHermesEndpointStore();
        final source = _FakeConnectIntentSource();
        addTearDown(source.dispose);
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
        );

        await tester.pumpWidget(
          buildApp(controller: controller, source: source, store: store),
        );
        await tester.pumpAndSettle();

        final paste = find.byKey(
          const ValueKey('hermes-enrollment-paste-link'),
        );
        final scan = find.byKey(const ValueKey('hermes-enrollment-scan-qr'));
        final manual = find.byKey(
          const ValueKey('hermes-enrollment-manual-connect'),
        );
        expect(find.text('Paste pairing link'), findsOneWidget);
        expect(find.text('Scan QR from another screen'), findsOneWidget);
        expect(find.text('Connect one profile manually'), findsOneWidget);
        expect(
          find.text(
            'If the link is on this phone, tap it or share it to Hermes Wing.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('This does not import Wing Link or other Hermes profiles.'),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(paste).dy,
          lessThan(tester.getTopLeft(scan).dy),
        );
        expect(
          tester.getTopLeft(scan).dy,
          lessThan(tester.getTopLeft(manual).dy),
        );
        for (final action in [paste, scan, manual]) {
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(action).width, greaterThan(300));
        }
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('clipboard is read only after Paste and inspected once', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var clipboardReads = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.getData') {
              clipboardReads++;
              return <String, Object?>{
                'text': 'Pair this phone:\n$_validPayload',
              };
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      var inspectCalls = 0;
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource();
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async {
          inspectCalls++;
          return _preview;
        },
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();
      expect(clipboardReads, 0);

      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-paste-link')),
      );
      await tester.pumpAndSettle();

      expect(clipboardReads, 1);
      expect(inspectCalls, 1);
      expect(controller.status, HermesEnrollmentStatus.ready);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'invalid pasted secrets are never retained in rendered errors',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        const rawSecret = 'pairing-code-must-not-render';
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'Clipboard.getData') {
                return <String, Object?>{
                  'text': 'wing://connect?origin=invalid&code=$rawSecret',
                };
              }
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null),
        );
        final store = FakeHermesEndpointStore();
        final source = _FakeConnectIntentSource();
        addTearDown(source.dispose);
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
        );

        await tester.pumpWidget(
          buildApp(controller: controller, source: source, store: store),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('hermes-enrollment-paste-link')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('hermes-enrollment-payload-error')),
          findsOneWidget,
        );
        expect(anyTextContains(tester, rawSecret), isFalse);
        expect(anyTextContains(tester, 'wing://connect'), isFalse);
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('empty clipboard shows inline recovery without clearing it', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final methods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            methods.add(call.method);
            if (call.method == 'Clipboard.getData') {
              return <String, Object?>{'text': '   '};
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource();
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-paste-link')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('The clipboard does not contain a pairing link.'),
        findsOneWidget,
      );
      expect(methods.where((method) => method.startsWith('Clipboard.')), [
        'Clipboard.getData',
      ]);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Android chooser remains usable at 200 percent text scale', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource();
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('hermes-enrollment-paste-link')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
        findsOneWidget,
      );
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'Linux chooser offers pairing, local setup, and manual actions',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final store = FakeHermesEndpointStore();
        final source = _FakeConnectIntentSource();
        addTearDown(source.dispose);
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
        );

        await tester.pumpWidget(
          buildApp(controller: controller, source: source, store: store),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('hermes-enrollment-local-setup')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('hermes-enrollment-paste-link')),
          findsOneWidget,
        );
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'desktop clipboard failure preserves paste and manual recovery',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'Clipboard.getData') {
                throw PlatformException(code: 'clipboard-unavailable');
              }
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null),
        );
        final store = FakeHermesEndpointStore();
        final source = _FakeConnectIntentSource(
          initial: 'wing://connect?code=missing-origin',
        );
        addTearDown(source.dispose);
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
        );

        await tester.pumpWidget(
          buildApp(controller: controller, source: source, store: store),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('hermes-enrollment-paste-another')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Paste another link'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('hermes-enrollment-scan-another')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('hermes-enrollment-import-qr-image')),
          findsNothing,
        );
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('non-Android failure offers usable setup actions', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(initial: _validPayload);
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async =>
            throw StateError('offline'),
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-enrollment-local-setup')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-scan-another')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-import-qr-image')),
        findsNothing,
      );
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('shared prose routes through explicit handoff extraction', (
      tester,
    ) async {
      var inspectCalls = 0;
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(
        initial: 'Shared from Android:\n$_validPayload',
      );
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async {
          inspectCalls++;
          return _preview;
        },
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(inspectCalls, 1);
      expect(controller.status, HermesEnrollmentStatus.ready);
    });

    testWidgets('explicit handoff preserves cleartext review before inspect', (
      tester,
    ) async {
      const cleartextCode = 'cleartext-code-must-not-render';
      var inspectCalls = 0;
      Uri? inspectedOrigin;
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(
        initial:
            'Shared link: wing://connect?origin=http%3A%2F%2Fhermes.example'
            '&code=$cleartextCode',
      );
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async {
          inspectCalls++;
          inspectedOrigin = origin;
          return _preview;
        },
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-enrollment-cleartext-warning')),
        findsOneWidget,
      );
      expect(inspectCalls, 0);
      expect(anyTextContains(tester, cleartextCode), isFalse);

      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-cleartext-confirm')),
      );
      await tester.pumpAndSettle();

      expect(inspectCalls, 1);
      expect(inspectedOrigin, Uri.parse('http://hermes.example'));
      expect(controller.status, HermesEnrollmentStatus.ready);
      expect(anyTextContains(tester, cleartextCode), isFalse);
    });

    testWidgets('scan QR opens pairing review', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(scanned: _validPayload);
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-enrollment-local-setup')),
        findsOneWidget,
      );
      expect(find.text('Install Hermes Agent on this phone'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hermes-enrollment-scan-qr')));
      await tester.pumpAndSettle();

      expect(source.scanCalls, 1);
      expect(controller.status, HermesEnrollmentStatus.ready);
      expect(find.text('hermes.example'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('scanner launch failure permits an immediate retry', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(
        scanned: _validPayload,
        scanThrowsOnce: true,
      );
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();
      final scanButton = find.byKey(
        const ValueKey('hermes-enrollment-scan-qr'),
      );
      await tester.tap(scanButton);
      await tester.pumpAndSettle();
      expect(source.scanCalls, 1);
      expect(tester.widget<FilledButton>(scanButton).onPressed, isNotNull);

      await tester.tap(scanButton);
      await tester.pumpAndSettle();
      expect(source.scanCalls, 2);
      expect(controller.status, HermesEnrollmentStatus.ready);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('chosen QR image opens pairing review', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(imported: _validPayload);
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-import-qr-image')),
      );
      await tester.pumpAndSettle();

      expect(source.importCalls, 1);
      expect(controller.status, HermesEnrollmentStatus.ready);
      expect(find.text('hermes.example'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('invalid pairing links offer manual gateway setup', (
      tester,
    ) async {
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(
        initial: 'wing://connect?code=missing-origin',
      );
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-enrollment-payload-error')),
        findsOneWidget,
      );
      expect(find.text('Pairing link couldn’t be opened'), findsOneWidget);
      expect(
        find.text('Paste another pairing link or scan a new QR code.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HermesChatScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hermes-base-url-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
        findsNothing,
      );

      final router = GoRouter.of(tester.element(find.byType(HermesChatScreen)));
      expect(
        router.canPop(),
        isTrue,
        reason: 'Android back must return to the enrollment chooser.',
      );
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('Connect to Hermes'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
        findsOneWidget,
      );
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('review and success remain usable at 200 percent text scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(
        initial:
            'wing://connect?origin=https%3A%2F%2Fhermes.example'
            '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time',
      );
      addTearDown(source.dispose);
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
            }) async {},
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final confirm = find.byKey(const ValueKey('hermes-enrollment-confirm'));
      expect(confirm, findsOneWidget);
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('hermes-enrollment-confirmed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-view-profiles')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-open-chat')),
        findsOneWidget,
      );
    });

    testWidgets(
      'review and persistent success show the nine-profile outcome securely',
      (tester) async {
        const rawCode = 'raw-pairing-code-must-not-render';
        var exchangeCalls = 0;
        final store = FakeHermesEndpointStore();
        final source = _FakeConnectIntentSource(
          initial:
              'wing://connect?origin=https%3A%2F%2Fhermes.example'
              '&control=https%3A%2F%2Fhermes.example%3A8654&code=$rawCode',
        );
        addTearDown(source.dispose);
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              const HermesEnrollmentPreview(
                label: 'BlueBlack',
                origin: 'https://hermes.example',
                scopes: ['Full Hermes access'],
                connectionCount: 9,
              ),
          exchangeEnrollment: ({required origin, required code}) async {
            exchangeCalls++;
            return _issuedBundleWithCount(9);
          },
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
        await tester.pumpWidget(
          buildApp(controller: controller, source: source, store: store),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Connect 9 Hermes profiles from BlueBlack?'),
          findsOneWidget,
        );
        expect(find.text('Profiles'), findsOneWidget);
        expect(find.text('9'), findsOneWidget);
        expect(find.text('Connect 9 profiles'), findsOneWidget);
        expect(exchangeCalls, 0);
        expect(anyTextContains(tester, rawCode), isFalse);
        expect(anyTextContainsToken(tester), isFalse);
        final semantics = tester.ensureSemantics();
        expect(find.bySemanticsLabel(RegExp(rawCode)), findsNothing);
        expect(find.bySemanticsLabel(RegExp(_secretToken)), findsNothing);
        semantics.dispose();

        await tester.tap(
          find.byKey(const ValueKey('hermes-enrollment-confirm')),
        );
        await tester.pumpAndSettle();

        expect(exchangeCalls, 1);
        expect(find.text('9 profiles connected'), findsOneWidget);
        expect(
          find.text('Wing Link is ready for profile and gateway management.'),
          findsOneWidget,
        );
        expect(find.text('View profiles'), findsOneWidget);
        expect(find.text('Open chat'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('hermes-enrollment-confirmed')),
          findsOneWidget,
        );
        expect(anyTextContains(tester, rawCode), isFalse);
        expect(anyTextContainsToken(tester), isFalse);

        final router = GoRouter.of(
          tester.element(
            find.byKey(const ValueKey('hermes-enrollment-confirmed')),
          ),
        );
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.enroll,
        );
        await tester.tap(
          find.byKey(const ValueKey('hermes-enrollment-view-profiles')),
        );
        await tester.pump();
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.profiles,
        );
        expect(controller.connectedProfileCount, isNull);
      },
    );

    testWidgets('loopback success shows honest Termux follow-up guidance', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource();
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async =>
            const HermesEnrollmentPreview(
              label: 'This phone',
              origin: 'http://127.0.0.1:8642',
              scopes: ['Full Hermes access'],
            ),
        exchangeEnrollment: ({required origin, required code}) async =>
            const HermesIssuedOperatorToken(
              token: _secretToken,
              label: 'This phone',
              credentialId: 'local_default',
            ),
        endpointStore: store,
      );
      await controller.inspect(
        HermesEnrollmentPayload(
          origin: Uri.parse('http://127.0.0.1:8642'),
          code: 'once',
        ),
      );
      await controller.confirm();

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(controller.confirmedLoopback, isTrue);
      expect(find.textContaining('run hermes setup in Termux'), findsOneWidget);
      expect(
        find.textContaining('retry the unchanged request'),
        findsOneWidget,
      );
      expect(find.textContaining('pair once more'), findsOneWidget);
      expect(anyTextContainsToken(tester), isFalse);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('desktop loopback success keeps platform-neutral guidance', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource();
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async =>
            const HermesEnrollmentPreview(
              label: 'This computer',
              origin: 'http://127.0.0.1:8642',
              scopes: ['Full Hermes access'],
            ),
        exchangeEnrollment: ({required origin, required code}) async =>
            const HermesIssuedOperatorToken(
              token: _secretToken,
              label: 'This computer',
              credentialId: 'local_default',
            ),
        endpointStore: store,
      );
      await controller.inspect(
        HermesEnrollmentPayload(
          origin: Uri.parse('http://127.0.0.1:8642'),
          code: 'once',
        ),
      );
      await controller.confirm();

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(controller.confirmedLoopback, isTrue);
      expect(find.textContaining('run hermes setup in Termux'), findsNothing);
      expect(
        find.text('Wing Link is ready for profile and gateway management.'),
        findsOneWidget,
      );
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('one-profile review and success use singular grammar', (
      tester,
    ) async {
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(initial: _validPayload);
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
      );
      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Connect 1 Hermes profile from Galaxy S24?'),
        findsOneWidget,
      );
      expect(find.text('Connect 1 profile'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hermes-enrollment-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('1 profile connected'), findsOneWidget);
      expect(find.text('1 profiles connected'), findsNothing);
      final router = GoRouter.of(
        tester.element(
          find.byKey(const ValueKey('hermes-enrollment-confirmed')),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-open-chat')),
      );
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.hermes);
      expect(controller.connectedProfileCount, isNull);
    });

    testWidgets(
      'shows scopes/expiry from inspection and does not exchange before confirm',
      (tester) async {
        var exchangeCalls = 0;
        final store = FakeHermesEndpointStore();
        final source = _FakeConnectIntentSource(initial: _validPayload);
        addTearDown(source.dispose);
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async {
            exchangeCalls++;
            return _issued;
          },
          endpointStore: store,
        );
        await tester.pumpWidget(
          buildApp(controller: controller, source: source, store: store),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('hermes-enrollment-host')),
          findsOneWidget,
        );
        expect(find.text('hermes.example'), findsOneWidget);
        expect(find.textContaining('chat:write'), findsOneWidget);
        expect(exchangeCalls, 0);
        expect(anyTextContainsToken(tester), isFalse);
      },
    );

    testWidgets(
      'review shows the payload host and warns when the server claims a '
      'different origin',
      (tester) async {
        final store = FakeHermesEndpointStore();
        final source = _FakeConnectIntentSource(initial: _validPayload);
        addTearDown(source.dispose);
        // Payload origin is hermes.example; a hostile pairing server echoes a
        // trusted-looking origin in its inspection response.
        const spoofedPreview = HermesEnrollmentPreview(
          label: 'Galaxy S24',
          origin: 'https://hermes.company.example',
          scopes: ['chat:write'],
        );
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              spoofedPreview,
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
        );
        await tester.pumpWidget(
          buildApp(controller: controller, source: source, store: store),
        );
        await tester.pumpAndSettle();

        // The host shown is the PAYLOAD origin (what gets saved/connected),
        // not the server's claimed origin.
        expect(find.text('hermes.example'), findsOneWidget);
        expect(find.text('hermes.company.example'), findsNothing);
        // And the mismatch is surfaced as an explicit warning.
        expect(
          find.byKey(const ValueKey('hermes-enrollment-origin-mismatch')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'confirm exchanges once, saves the token, and never renders it',
      (tester) async {
        var exchangeCalls = 0;
        final store = FakeHermesEndpointStore();
        final source = _FakeConnectIntentSource(initial: _validPayload);
        addTearDown(source.dispose);
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async {
            exchangeCalls++;
            return _issued;
          },
          endpointStore: store,
        );
        await tester.pumpWidget(
          buildApp(controller: controller, source: source, store: store),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('hermes-enrollment-confirm')),
        );
        await tester.pump();
        expect(anyTextContainsToken(tester), isFalse);
        await tester.pumpAndSettle();

        expect(exchangeCalls, 1);
        expect(store.saveCalls, hasLength(1));
        expect(store.saveCalls.single.apiKey, _secretToken);
        expect(anyTextContainsToken(tester), isFalse);
      },
    );

    testWidgets('cancel discards the code without contacting exchange', (
      tester,
    ) async {
      var exchangeCalls = 0;
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(initial: _validPayload);
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async {
          exchangeCalls++;
          return _issued;
        },
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hermes-enrollment-cancel')));
      await tester.pumpAndSettle();

      expect(exchangeCalls, 0);
      expect(store.saveCalls, isEmpty);
    });

    testWidgets(
      'desktop failure restores paste without Android scanner actions',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final store = FakeHermesEndpointStore();
        final source = _FakeConnectIntentSource(initial: _validPayload);
        addTearDown(source.dispose);
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              throw StateError('offline'),
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: store,
        );

        await tester.pumpWidget(
          buildApp(controller: controller, source: source, store: store),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('hermes-enrollment-paste-another')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('hermes-enrollment-scan-another')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('hermes-enrollment-import-qr-image')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
          findsOneWidget,
        );
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('expired recovery remains usable at 200 percent text scale', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.utc(2026, 8, 22, 12);
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(initial: _validPayload);
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        clock: () => now,
        inspectEnrollment: ({required origin, required code}) async =>
            HermesEnrollmentPreview(
              label: 'BlueBlack',
              origin: 'https://hermes.example',
              scopes: const ['Full Hermes access'],
              connectionCount: 9,
              expiresAt: now,
            ),
        exchangeEnrollment: ({required origin, required code}) async =>
            _issuedBundleWithCount(9),
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('hermes-enrollment-expired')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-paste-another')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-enrollment-scan-another')),
        findsOneWidget,
      );
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('countdown expires into actionable paste and scan recovery', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var now = DateTime.utc(2026, 8, 22, 12, 0, 1);
      var inspectCalls = 0;
      var clipboardReads = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.getData') {
              clipboardReads++;
              return <String, Object?>{'text': _validPayload};
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(
        initial: _validPayload,
        scanned: _validPayload,
      );
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        clock: () => now,
        inspectEnrollment: ({required origin, required code}) async {
          inspectCalls++;
          return HermesEnrollmentPreview(
            label: 'BlueBlack',
            origin: 'https://hermes.example',
            scopes: const ['Full Hermes access'],
            connectionCount: 9,
            expiresAt: DateTime.utc(2026, 8, 22, 12, 4 + inspectCalls),
          );
        },
        exchangeEnrollment: ({required origin, required code}) async =>
            _issuedBundleWithCount(9),
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('4:59'), findsOneWidget);
      now = DateTime.utc(2026, 8, 22, 12, 5);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('This pairing link expired'), findsOneWidget);
      expect(
        find.text(
          'Run wing-link pair again, then open the new link or scan its QR.',
        ),
        findsOneWidget,
      );
      expect(find.text('Paste another link'), findsOneWidget);
      expect(find.text('Scan another QR'), findsOneWidget);
      expect(anyTextContains(tester, 'one-time'), isFalse);

      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-paste-another')),
      );
      await tester.pump();
      await tester.pump();
      expect(clipboardReads, 1);
      expect(inspectCalls, 2);

      now = DateTime.utc(2026, 8, 22, 12, 6);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-scan-another')),
      );
      await tester.pump();
      await tester.pump();
      expect(source.scanCalls, 1);
      expect(inspectCalls, 3);
      controller.cancel();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('an expired/reused response fails closed with no save', (
      tester,
    ) async {
      final store = FakeHermesEndpointStore();
      final source = _FakeConnectIntentSource(initial: _validPayload);
      addTearDown(source.dispose);
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async {
          throw StateError('pairing code expired or already used');
        },
        endpointStore: store,
      );

      await tester.pumpWidget(
        buildApp(controller: controller, source: source, store: store),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hermes-enrollment-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hermes-enrollment-error')),
        findsOneWidget,
      );
      expect(store.saveCalls, isEmpty);
      expect(anyTextContainsToken(tester), isFalse);
      expect(
        anyTextContains(tester, 'pairing code expired or already used'),
        isFalse,
      );
    });
  });
}
