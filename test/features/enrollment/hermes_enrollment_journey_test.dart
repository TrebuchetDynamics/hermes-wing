import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/wing_link/wing_link_http.dart';
import 'package:wing/features/enrollment/models/hermes_enrollment_payload.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/enrollment/widgets/enrollment_readiness.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_endpoint_store.dart';

final _payload = HermesEnrollmentPayload(
  origin: Uri.parse('https://hermes.example'),
  code: 'fixture-once',
);
const _preview = HermesEnrollmentPreview(
  label: 'Fixture host',
  origin: 'https://hermes.example',
  scopes: [],
);
const _issued = HermesIssuedOperatorToken(
  token: 'fixture-only',
  label: 'Fixture host',
  credentialId: 'fixture-device',
);

void main() {
  test(
    'failed activation retries saved connection without exchanging or saving again',
    () async {
      final store = FakeHermesEndpointStore();
      var exchanges = 0;
      var connections = 0;
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async {
          exchanges++;
          return _issued;
        },
        connectSavedEndpoint: (_) async {
          if (++connections == 1) throw StateError('offline');
        },
        endpointStore: store,
      );
      addTearDown(controller.dispose);
      await controller.inspect(_payload);
      await controller.confirm();
      expect(controller.status, HermesEnrollmentStatus.confirmed);
      expect(controller.connection, HermesEnrollmentConnection.failed);
      final saves = store.saveCalls.length;
      await controller.connectSaved();
      expect(controller.connection, HermesEnrollmentConnection.connected);
      expect(connections, 2);
      expect(exchanges, 1);
      expect(store.saveCalls.length, saves);
    },
  );

  test(
    'late connection completion cannot restore a cancelled enrollment outcome',
    () async {
      final gate = Completer<void>();
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async => _preview,
        exchangeEnrollment: ({required origin, required code}) async => _issued,
        connectSavedEndpoint: (_) => gate.future,
        endpointStore: FakeHermesEndpointStore(),
      );
      addTearDown(controller.dispose);
      await controller.inspect(_payload);
      final confirmation = controller.confirm();
      while (controller.connection != HermesEnrollmentConnection.connecting) {
        await Future<void>.delayed(Duration.zero);
      }
      controller.cancel();
      gate.complete();
      await confirmation;
      expect(controller.connection, HermesEnrollmentConnection.unchecked);
      expect(controller.connectedGatewayId, isNull);
    },
  );

  for (final entry in <Object, HermesEnrollmentFailure>{
    const HandshakeException('fixture detail must not render'):
        HermesEnrollmentFailure.tls,
    const SocketException('fixture detail must not render'):
        HermesEnrollmentFailure.network,
    TimeoutException('fixture detail must not render'):
        HermesEnrollmentFailure.timeout,
    const WingLinkHttpException(403): HermesEnrollmentFailure.rejected,
    const WingLinkHttpException(410): HermesEnrollmentFailure.expired,
    const WingLinkHttpException(426): HermesEnrollmentFailure.unsupported,
    const FormatException('fixture detail must not render'):
        HermesEnrollmentFailure.invalidResponse,
  }.entries) {
    test('inspection exposes bounded ${entry.value.name} diagnosis', () async {
      var exchanged = false;
      final controller = HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) async =>
            throw entry.key,
        exchangeEnrollment: ({required origin, required code}) async {
          exchanged = true;
          return _issued;
        },
        endpointStore: FakeHermesEndpointStore(),
      );
      addTearDown(controller.dispose);
      await controller.inspect(_payload);
      await controller.confirm();
      expect(controller.failure, entry.value);
      expect(controller.errorMessage, isNull);
      expect(exchanged, isFalse);
    });
  }

  for (final scenario in [
    (
      origin: 'https://other.example',
      advertised: true,
      model: 'ok',
      expected: 'Model readiness is not reported for this profile',
    ),
    (
      origin: 'https://hermes.example',
      advertised: false,
      model: 'ok',
      expected: 'Model readiness is not reported for this profile',
    ),
    (
      origin: 'https://hermes.example',
      advertised: true,
      model: 'ok',
      expected: 'Agent reports a configured model for this profile',
    ),
    (
      origin: 'https://hermes.example',
      advertised: true,
      model: 'degraded',
      expected: 'Agent reports that a model needs configuration',
    ),
  ]) {
    testWidgets(
      'readiness respects identity, capability and model state: $scenario',
      (tester) async {
        final controller = HermesEnrollmentController(
          inspectEnrollment: ({required origin, required code}) async =>
              _preview,
          exchangeEnrollment: ({required origin, required code}) async =>
              _issued,
          endpointStore: FakeHermesEndpointStore(),
        );
        addTearDown(controller.dispose);
        await controller.inspect(_payload);
        await controller.confirm();
        final state = HermesChannelState(
          status: HermesConnectionStatus.connected,
          connectedBaseUrl: scenario.origin,
          capabilities: HermesCapabilityDocument.fromJson({
            'schema_version': 1,
            'auth': {
              'type': 'bearer',
              'granted_scopes': ['health:read'],
            },
            'endpoints': {
              if (scenario.advertised)
                'health_detailed': {
                  'method': 'GET',
                  'path': '/health/detailed',
                  'required_scopes': ['health:read'],
                },
            },
          }),
          detailedHealth: HermesHealthStatus(
            status: 'ok',
            platform: 'fixture',
            readiness: HermesGatewayReadiness(
              status: 'ok',
              checks: [
                HermesGatewayReadinessCheck(
                  id: 'model',
                  status: scenario.model,
                ),
              ],
            ),
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [hermesChannelStateProvider.overrideWithValue(state)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: EnrollmentReadiness(controller: controller)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(scenario.expected), findsOneWidget);
        expect(find.textContaining('fixture-only'), findsNothing);
      },
    );
  }
}
