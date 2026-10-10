import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/providers/app_router.dart';

import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../../../integration_test/support/direct_first_run_native_fixture.dart';

Finder control(String name) => find.byKey(ValueKey(name));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [1280.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('welcome keyboard recovery width $width text $scale', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = DirectFirstRunNativeFixture();
        final store = FakeHermesEndpointStore();
        final channel = HermesApiChannel(clientBuilder: fixture.client);
        final cache = GatewayContactCache();
        final directory = HermesGatewayDirectory(
          store: store,
          cache: cache,
          loader: HermesApiGatewaySummaryLoader(clientBuilder: fixture.client),
          activeChannel: channel,
        );
        var managementAttempts = 0;
        final enrollment = HermesEnrollmentController(
          endpointStore: store,
          inspectEnrollment: ({required origin, required code}) async {
            managementAttempts++;
            throw StateError('Management forbidden in direct qualification');
          },
          exchangeEnrollment: ({required origin, required code}) async {
            managementAttempts++;
            throw StateError('Management forbidden in direct qualification');
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
        expect(tester.getSize(find.byType(MaterialApp)).width, width);
        expect(await store.loadProfiles(), isEmpty);
        expect(await cache.loadSelection(), isNull);
        expect(fixture.requests, isEmpty);

        Future<void> reach(String name) async {
          await tester.ensureVisible(control(name));
          for (var i = 0; i < 120; i++) {
            var focused = false;
            final context = FocusManager.instance.primaryFocus?.context;
            if (context?.widget.key == ValueKey(name)) focused = true;
            context?.visitAncestorElements((element) {
              if (element.widget.key == ValueKey(name)) focused = true;
              return !focused;
            });
            if (focused) {
              await tester.ensureVisible(control(name));
              await tester.pumpAndSettle();
              return;
            }
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
          }
          fail('Keyboard did not reach $name');
        }

        Future<void> activate(String name) async {
          await reach(name);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
        }

        expect(control('hermes-welcome'), findsOneWidget);
        expect(find.text('Welcome to Hermes Wing'), findsOneWidget);
        expect(control('mobile-shell-navigation-bar'), findsNothing);
        for (final mode in ['local', 'ssh', 'remote']) {
          await activate(switch (mode) {
            'local' => 'hermes-enrollment-direct-connect',
            'ssh' => 'hermes-welcome-ssh',
            _ => 'hermes-welcome-remote',
          });
          expect(
            tester
                .widget<ChoiceChip>(control('hermes-connection-mode-$mode'))
                .selected,
            true,
          );
          if (mode == 'ssh') {
            for (final field in [
              'host',
              'ssh-port',
              'username',
              'password',
              'agent-port',
              'agent-token',
            ]) {
              expect(control('managed-ssh-$field'), findsOneWidget);
            }
            for (final secret in ['password', 'agent-token']) {
              expect(
                tester
                    .widget<TextField>(
                      find.descendant(
                        of: control('managed-ssh-$secret'),
                        matching: find.byType(TextField),
                      ),
                    )
                    .obscureText,
                isTrue,
              );
            }
            await reach('managed-ssh-host');
            expect(fixture.requests, isEmpty);
            expect(store.saveCalls, isEmpty);
            await tester.ensureVisible(
              control('hermes-primary-connection-modes'),
            );
          }
          if (mode == 'remote') {
            await activate('hermes-remote-transport-vpn');
            await tester.enterText(
              control('hermes-base-url-field'),
              DirectFirstRunNativeFixture.origin,
            );
          }
          // Public Back is keyboard-activated, not a programmatic route reset.
          final back = find.byType(BackButton);
          await tester.ensureVisible(back);
          var reachedBack = false;
          for (var i = 0; i < 120; i++) {
            FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
              element,
            ) {
              if (element.widget is BackButton) reachedBack = true;
              return !reachedBack;
            });
            if (reachedBack) break;
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
          }

          expect(reachedBack, true, reason: 'Back unreachable from $mode');
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(control('hermes-welcome'), findsOneWidget);
          expect(store.saveCalls, isEmpty);
          expect(fixture.requests, isEmpty);
        }
        await activate('hermes-welcome-remote');
        await reach('hermes-base-url-field');
        await tester.enterText(
          control('hermes-base-url-field'),
          DirectFirstRunNativeFixture.origin,
        );
        fixture.deniedBootstrapStatus = 401;
        await activate('hermes-connect-button');
        expect(channel.state.connectionFailureKind, isNotNull);
        expect(
          find.textContaining('private-response-must-not-render'),
          findsNothing,
        );
        expect(store.saveCalls, isEmpty);
        final deniedRequests = List.of(fixture.requests);
        fixture.deniedBootstrapStatus = null;
        await tester.pump(const Duration(seconds: 2));
        expect(fixture.requests, deniedRequests);
        await reach('hermes-connect-button');
        expect(fixture.requests, deniedRequests, reason: 'Focus is not retry');
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(store.saveCalls, hasLength(1));
        expect(
          store.saveCalls.single.baseUrl,
          DirectFirstRunNativeFixture.origin,
        );
        expect(store.saveCalls.single.apiKey, isNull);
        expect(store.saveCalls.single.wingLinkOrigin, isNull);
        expect(store.saveCalls.single.wingLinkToken, isNull);
        expect(router.routeInformationProvider.value.uri.path, '/hermes');
        expect(control('hermes-welcome'), findsNothing);
        final contact = directory.contacts.single;
        await activate(
          'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}',
        );
        final config = store.saveCalls.single;
        expect(config.id, isNotNull);
        expect(
          channel.state.connectedBaseUrl,
          DirectFirstRunNativeFixture.origin,
        );
        expect(
          channel.state.selectedProfileId,
          DirectFirstRunNativeFixture.profile,
        );
        expect(
          channel.state.activeSessionId,
          DirectFirstRunNativeFixture.session,
        );
        expect(
          find.text('Synthetic history synthetic-history'),
          findsOneWidget,
        );
        expect(router.routeInformationProvider.value.uri.path, '/hermes');
        final selection = await cache.loadSelection();
        expect(selection, isNotNull);
        expect(
          selection!.contactId.profileId,
          DirectFirstRunNativeFixture.profile,
        );
        expect(selection.sessionId, DirectFirstRunNativeFixture.session);
        expect(fixture.mutationAttempts, 0);
        expect(fixture.forbiddenReadAttempts, 0);
        expect(managementAttempts, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
