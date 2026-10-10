import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/enrollment/models/hermes_enrollment_payload.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/providers/app_router.dart';

import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

Finder key(String name) => find.byKey(ValueKey(name));

class _Rejected implements HermesApiStatusException {
  @override
  int get statusCode => 401;
  @override
  String toString() => 'private-auth-response-must-not-render';
}

void main() {
  for (final width in [390.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('public first-run direct retry at $width text $scale', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final requests = <String>[];
        var reject = true;
        var managementRequests = 0;
        final store = FakeHermesEndpointStore();
        HermesApiClient client(config) => HermesApiClient(
          config: config,
          get: (uri, _) async {
            requests.add('GET ${uri.path}');
            if (reject) throw _Rejected();
            return switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => jsonEncode({
                'schema_version': 1,
                'profile_context': {
                  'type': 'query',
                  'name': 'profile',
                  'required': true,
                  'default_profile_id': 'default',
                },
                'auth': {
                  'type': 'bearer',
                  'required': true,
                  'granted_scopes': ['sessions:read'],
                },
                'endpoints': {
                  'sessions': {'method': 'GET', 'path': '/api/sessions'},
                },
              }),
              '/api/sessions' => '{"data":[]}',
              _ => throw StateError('Unexpected Agent read'),
            };
          },
          post: (uri, _, _) async {
            requests.add('POST ${uri.path}');
            throw StateError('No mutation allowed');
          },
        );
        final channel = HermesApiChannel(clientBuilder: client);
        final directory = HermesGatewayDirectory(
          store: store,
          cache: FakeGatewayContactCache(),
          loader: HermesApiGatewaySummaryLoader(clientBuilder: client),
          activeChannel: channel,
        );
        final enrollment = HermesEnrollmentController(
          endpointStore: store,
          inspectEnrollment: ({required origin, required code}) async {
            managementRequests++;
            throw StateError('management unavailable');
          },
          exchangeEnrollment: ({required origin, required code}) async {
            managementRequests++;
            throw StateError('No exchange allowed');
          },
        );
        final container = ProviderContainer(
          overrides: [
            hermesChannelProvider.overrideWith((_) => channel),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesGatewayDirectoryProvider.overrideWith((_) => directory),
            hermesEnrollmentControllerProvider.overrideWith((_) => enrollment),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);
        // This deterministic controller is reused across independent route visits.
        final enrollmentLease = container.listen(
          hermesEnrollmentControllerProvider,
          (_, _) {},
        );
        addTearDown(enrollmentLease.close);
        final router = container.read(routerProvider);
        addTearDown(router.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(key('hermes-welcome'), findsOneWidget);
        expect(find.text('Welcome to Hermes Wing'), findsOneWidget);
        expect(key('mobile-shell-navigation-bar'), findsNothing);
        for (final entry in ['hermes-welcome-ssh', 'hermes-welcome-remote']) {
          await activate(tester, entry);
          final mode = entry.endsWith('ssh') ? 'ssh' : 'remote';
          expect(
            tester
                .widget<ChoiceChip>(key('hermes-connection-mode-$mode'))
                .selected,
            isTrue,
          );
          expect(store.saveCalls, isEmpty);
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(key('hermes-welcome'), findsOneWidget);
        }
        await activate(tester, 'hermes-enrollment-direct-connect');
        expect(
          tester
              .widget<ChoiceChip>(key('hermes-connection-mode-local'))
              .selected,
          isTrue,
        );
        expect(key('hermes-primary-connection-modes'), findsOneWidget);
        expect(requests, isEmpty);
        expect(managementRequests, 0);
        for (final mode in ['local', 'ssh', 'remote']) {
          await activate(tester, 'hermes-connection-mode-$mode');
          expect(
            tester
                .widget<ChoiceChip>(key('hermes-connection-mode-$mode'))
                .selected,
            isTrue,
          );
        }
        await activate(tester, 'hermes-remote-transport-vpn');
        expect(
          tester
              .widget<ChoiceChip>(key('hermes-connection-mode-remote'))
              .selected,
          isTrue,
        );
        await tester.enterText(
          key('hermes-base-url-field'),
          'https://example.invalid',
        );
        await activate(tester, 'hermes-connect-button');
        expect(channel.state.connectionFailureKind, isNotNull);
        expect(find.textContaining('private-auth-response'), findsNothing);
        expect(store.saveCalls, isEmpty);
        final failureRequests = requests.toList();
        reject = false;
        await tester.pump(const Duration(seconds: 2));
        expect(requests, failureRequests, reason: 'Retry is explicit');
        await activate(tester, 'hermes-connect-button');
        expect(store.saveCalls, hasLength(1));
        expect(store.saveCalls.single.wingLinkOrigin, isNull);
        expect(store.saveCalls.single.wingLinkToken, isNull);
        expect(directory.hasSavedGateways, isTrue);
        expect(router.routeInformationProvider.value.uri.path, '/hermes');
        expect(key('hermes-welcome'), findsNothing);
        expect(requests, contains('GET /v1/capabilities'));
        expect(requests, contains('GET /api/sessions'));
        expect(requests.every((r) => r.startsWith('GET ')), isTrue);
        expect(managementRequests, 0);

        router.go('/enroll');
        await tester.pumpAndSettle();
        await activate(tester, 'hermes-enrollment-direct-connect');
        expect(key('hermes-primary-connection-modes'), findsOneWidget);
        // Local now exposes its guide, not the Remote-only optional setup action.
        await activate(tester, 'hermes-connection-mode-remote');
        await activate(tester, 'hermes-optional-setup');
        await activate(tester, 'hermes-welcome-optional');
        await activate(tester, 'hermes-enrollment-pair-choice');
        expect(key('hermes-enrollment-type-link'), findsOneWidget);
        // Failed optional management is not a gate for returning to direct Agent.
        await enrollment.inspect(
          HermesEnrollmentPayload(
            origin: Uri.parse('https://management.example.invalid'),
            code: 'fixture-once',
          ),
        );
        await tester.pumpAndSettle();
        expect(key('hermes-enrollment-error'), findsOneWidget);
        await activate(tester, 'hermes-enrollment-manual-connect');
        expect(key('hermes-primary-connection-modes'), findsOneWidget);
        expect(managementRequests, 1);
        expect(store.saveCalls, hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}

Future<void> activate(WidgetTester tester, String name) async {
  await tester.ensureVisible(key(name));
  for (var i = 0; i < 120; i++) {
    var focused = false;
    FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
      if (e.widget.key == ValueKey(name)) focused = true;
      return !focused;
    });
    if (focused) {
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
  fail('Keyboard did not reach $name');
}
