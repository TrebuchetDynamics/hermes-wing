import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/providers/app_router.dart';

import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import 'support/direct_first_run_native_fixture.dart';

Finder control(String name) => find.byKey(ValueKey(name));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final phase = Platform.environment['WING_WELCOME_PHASE'];
  if (!{'write', 'verify'}.contains(phase)) throw StateError('Phase required');
  for (final width in phase == 'verify' ? [390.0] : [1280.0, 390.0]) {
    for (final scale in phase == 'verify' ? [2.0] : [1.0, 2.0]) {
      testWidgets('public GTK welcome recovery $phase width $width text $scale', (
        tester,
      ) async {
        final root = Platform.environment['WING_WELCOME_ROOT'];
        if (root == null ||
            Platform.environment['HOME'] != '$root/home' ||
            Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
            Platform.environment['WING_LIVE_AUTH'] != null ||
            Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
          throw StateError('Use the isolated welcome recovery launcher');
        }
        // Real native preferences, in a fresh launcher-owned HOME only.
        final preferences = await SharedPreferences.getInstance();
        if (phase == 'write') await preferences.clear();
        // Keep the real GTK view metrics so its engine receives valid frames.
        // The integration binding maps these logical layouts into that surface.
        await binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => binding.setSurfaceSize(null));
        final fixture = DirectFirstRunNativeFixture();
        final savedFile = File('$root/cache/synthetic-endpoint.json');
        final saved = phase == 'verify'
            ? jsonDecode(savedFile.readAsStringSync()) as Map<String, dynamic>
            : null;
        final store = FakeHermesEndpointStore(
          initial: saved == null
              ? null
              : HermesEndpointConfig(
                  baseUrl: saved['baseUrl'] as String,
                  id: saved['id'] as String,
                ),
        );
        final channel = HermesApiChannel(clientBuilder: fixture.client);
        final cache = GatewayContactCache();

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
            gatewayContactCacheProvider.overrideWithValue(cache),
            hermesGatewaySummaryLoaderProvider.overrideWithValue(
              HermesApiGatewaySummaryLoader(clientBuilder: fixture.client),
            ),
            hermesEnrollmentControllerProvider.overrideWith((_) => enrollment),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);
        final directory = container.read(hermesGatewayDirectoryProvider);
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
        if (phase == 'verify') {
          for (var i = 0; i < 50 && !channel.state.isConnected; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          await tester.pumpAndSettle();
        }
        expect(tester.getSize(find.byType(MaterialApp)).width, width);
        if (phase == 'write') {
          expect(await store.loadProfiles(), isEmpty);
          expect(await cache.loadSelection(), isNull);
          expect(fixture.requests, isEmpty);
        }

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

        Future<void> capture(String name) async {
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            final result = await Process.run('/usr/bin/import', [
              '-window',
              'root',
              '$root/cache/$name-$width-$scale.png',
            ]);
            expect(result.exitCode, 0);
          });
        }

        var retryAdmissions = 0;
        if (phase == 'write') {
          expect(control('hermes-welcome'), findsOneWidget);
          expect(find.text('Welcome to Hermes Wing'), findsOneWidget);
          expect(control('mobile-shell-navigation-bar'), findsNothing);
          await capture('welcome');
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
              expect(
                find.textContaining('Start the fixed tunnel outside Wing'),
                findsOneWidget,
              );
              await tester.ensureVisible(
                control('hermes-primary-connection-modes'),
              );
              await capture('ssh');
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
              FocusManager.instance.primaryFocus?.context
                  ?.visitAncestorElements((element) {
                    if (element.widget is BackButton) reachedBack = true;
                    return !reachedBack;
                  });
              if (reachedBack) break;
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pumpAndSettle();
            }
            expect(reachedBack, true);
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
          expect(
            fixture.requests,
            deniedRequests,
            reason: 'Focus is not retry',
          );
          await capture('denied');
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          retryAdmissions = store.saveCalls.length;
          expect(retryAdmissions, 1);
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
          savedFile.writeAsStringSync(
            jsonEncode({'baseUrl': config.baseUrl, 'id': config.id}),
          );
        } else {
          // Fresh GTK process/channel/directory/router; only the synthetic
          // endpoint fixture and real isolated native preferences survive.
          expect(store.saveCalls, isEmpty);
          expect(control('hermes-welcome'), findsNothing);
        }
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
        await capture(phase == 'write' ? 'connected' : 'restored');
        expect(fixture.mutationAttempts, 0);
        expect(fixture.forbiddenReadAttempts, 0);
        expect(managementAttempts, 0);
        expect(tester.takeException(), isNull);
        final receipt = {
          'phase': phase,
          'native_pid': pid,
          'width': width,
          'text_scale': scale,
          'public_entry': true,
          'keyboard_modes': phase == 'write'
              ? ['local', 'ssh', 'remote', 'vpn']
              : [],
          'back_no_save': phase == 'write',
          'denial_sanitized': phase == 'write',
          'explicit_keyboard_retry': phase == 'write',
          'retry_admissions': retryAdmissions,
          'save_calls': store.saveCalls.length,
          'saved_owner_restored': phase == 'verify',
          'endpoint_storage': 'SYNTHETIC_FIXTURE_NOT_KEYCHAIN',
          'canonical_route': router.routeInformationProvider.value.uri.path,
          'profile': channel.state.selectedProfileId,
          'session': channel.state.activeSessionId,
          'management_attempts': managementAttempts,
          'mutation_attempts': fixture.mutationAttempts,
          'forbidden_read_attempts': fixture.forbiddenReadAttempts,
          'requests': fixture.requests,
          'denied_reads': fixture.deniedReads,
        };
        final target = File('$root/cache/welcome-$phase-$width-$scale.json');
        File('${target.path}.tmp').writeAsStringSync(jsonEncode(receipt));
        File('${target.path}.tmp').renameSync(target.path);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
