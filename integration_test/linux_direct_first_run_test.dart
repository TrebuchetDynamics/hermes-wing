import 'dart:async';
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

import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import 'support/direct_first_run_native_fixture.dart';

Finder control(String name) => find.byKey(ValueKey(name));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [1280.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('public GTK first-run width $width text $scale', (
        tester,
      ) async {
        final root = Platform.environment['WING_DIRECT_ROOT'];
        if (root == null ||
            Platform.environment['HOME'] != '$root/home' ||
            Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
            Platform.environment['WING_LIVE_AUTH'] != null ||
            Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
          throw StateError('Use the isolated direct first-run launcher');
        }
        // Real native preferences, in a fresh launcher-owned HOME only.
        final preferences = await SharedPreferences.getInstance();
        await preferences.clear();
        // Keep the real GTK view metrics so its engine receives valid frames.
        // The integration binding maps these logical layouts into that surface.
        await binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => binding.setSurfaceSize(null));
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

        await activate('gateway-contacts-add');
        // GoRouter does not mirror imperative pushes into route information.
        expect(control('hermes-primary-connection-modes'), findsOneWidget);
        for (final mode in ['local', 'ssh', 'remote']) {
          await activate('hermes-connection-mode-$mode');
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
          }
        }
        await activate('hermes-remote-transport-vpn');
        await tester.ensureVisible(control('hermes-primary-connection-modes'));
        await tester.pumpAndSettle();
        await capture('choices');
        expect(fixture.requests, isEmpty);
        await activate('hermes-optional-setup');
        expect(control('hermes-enrollment-direct-connect'), findsOneWidget);
        expect(control('hermes-enrollment-local-setup'), findsOneWidget);
        await activate('hermes-enrollment-pair-choice');
        expect(control('hermes-enrollment-type-link'), findsOneWidget);
        await activate('hermes-enrollment-manual-connect');
        expect(control('hermes-primary-connection-modes'), findsOneWidget);
        // Back through the actual production stack; no endpoint or domain mutation.
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/hermes');
        // Enrollment consumes Back once to return from pairing to its chooser.
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(control('gateway-contacts-add'), findsOneWidget);
        expect(store.saveCalls, isEmpty);
        expect(fixture.requests, isEmpty);

        await activate('gateway-contacts-add');
        await activate('hermes-connection-mode-remote');
        await reach('hermes-base-url-field');
        await tester.enterText(
          control('hermes-base-url-field'),
          DirectFirstRunNativeFixture.origin,
        );
        // A newer channel owner wins while the public form's bootstrap is pending.
        final gate = fixture.bootstrapGate = Completer<void>();
        await reach('hermes-connect-button');
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump(const Duration(milliseconds: 100));
        expect(channel.state.isConnected, false);
        await channel.connect(baseUrl: 'https://other.example.invalid');
        gate.complete();
        await tester.pumpAndSettle();
        expect(store.saveCalls, isEmpty);
        expect(channel.state.connectedBaseUrl, 'https://other.example.invalid');
        expect(channel.state.selectedProfileId, 'default');
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(store.saveCalls, isEmpty);
        await channel.disconnect();
        await tester.pumpAndSettle();

        await activate('gateway-contacts-add');
        await activate('hermes-connection-mode-remote');
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
        await capture('denied');
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
        expect(directory.hasSavedGateways, true);
        // The direct form saves but does not implicitly activate the directory.
        await tester.pageBack();
        await tester.pumpAndSettle();
        final contact = directory.contacts.single;
        expect(contact.id.profileId, DirectFirstRunNativeFixture.profile);
        final contactKey =
            'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}';
        // Public contact controls are used below; no pre-shell activation.
        await activate(contactKey);
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
        await capture('connected');
        expect(fixture.mutationAttempts, 0);
        expect(fixture.forbiddenReadAttempts, 0);
        expect(managementAttempts, 0);
        expect(tester.takeException(), isNull);
        final receipt = {
          'native_pid': pid,
          'width': width,
          'text_scale': scale,
          'public_entry': true,
          'keyboard_modes': ['local', 'ssh', 'remote', 'vpn'],
          'optional_pairing_reachable': true,
          'back_no_save': true,
          'pending_owner_fenced': true,
          'denial_sanitized': true,
          'explicit_keyboard_retry': true,
          'agent_only_save': true,
          'profile': channel.state.selectedProfileId,
          'session': channel.state.activeSessionId,
          'management_attempts': managementAttempts,
          'mutation_attempts': fixture.mutationAttempts,
          'forbidden_read_attempts': fixture.forbiddenReadAttempts,
          'requests': fixture.requests,
          'denied_reads': fixture.deniedReads,
        };
        final target = File('$root/cache/direct-$width-$scale.json');
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
