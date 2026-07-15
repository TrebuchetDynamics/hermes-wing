import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/l10n/app_localizations.dart';
import 'package:navivox/core/hermes/client/hermes_api_client.dart';
import 'package:navivox/features/enrollment/models/hermes_enrollment_payload.dart';
import 'package:navivox/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:navivox/features/enrollment/services/hermes_connect_intent_source.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/router/providers/app_router.dart';
import 'package:navivox/router/routes/app_routes.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';

const _secretToken = 'hop_super-secret-token-should-never-render';

const _validPayload =
    'navivox://connect?origin=https%3A%2F%2Fhermes.example&code=one-time';

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

class _FakeConnectIntentSource implements HermesConnectIntentSource {
  _FakeConnectIntentSource({this.initial});

  final String? initial;
  final _events = StreamController<String>.broadcast();

  @override
  Future<String?> initialPayload() async => initial;

  @override
  Stream<String> payloadEvents() => _events.stream;

  void emit(String payload) => _events.add(payload);

  void dispose() => unawaited(_events.close());
}

void main() {
  group('HermesEnrollmentController (fake inspect/exchange)', () {
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
      expect(controller.status, HermesEnrollmentStatus.failed);
      expect(controller.errorMessage, isNotNull);
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

      expect(controller.status, HermesEnrollmentStatus.failed);
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

    test('connectSavedEndpoint runs only after a successful save', () async {
      var connectCalls = 0;
      final store = FakeHermesEndpointStore();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        endpointStore: store,
        connectSavedEndpoint: () async {
          connectCalls++;
        },
      );
      addTearDown(controller.dispose);

      await controller.inspect(HermesEnrollmentPayload.parse(_validPayload));
      await controller.confirm();

      expect(connectCalls, 1);
    });
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

    bool anyTextContainsToken(WidgetTester tester) {
      final texts = tester.widgetList<Text>(find.byType(Text));
      for (final text in texts) {
        final data = text.data ?? text.textSpan?.toPlainText() ?? '';
        if (data.contains(_secretToken)) return true;
      }
      return false;
    }

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
      'confirm exchanges once, saves the token, redirects, and never renders it',
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
    });
  });
}
