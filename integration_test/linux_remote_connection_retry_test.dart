import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/providers/app_router.dart';

import 'support/direct_first_run_native_fixture.dart';
import 'support/remote_connection_retry_native_fixture.dart';

Finder control(String name) => find.byKey(ValueKey(name));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [1280.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('GTK Remote auth/save retry $width text $scale', (
        tester,
      ) async {
        final root = Platform.environment['WING_RETRY_ROOT'];
        if (root == null ||
            Platform.environment['HOME'] != '$root/home' ||
            Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
            Platform.environment['WING_LIVE_AUTH'] != null ||
            Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
          throw StateError('Use the isolated Remote retry launcher');
        }
        final preferences = await SharedPreferences.getInstance();
        await preferences.clear();
        await binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => binding.setSurfaceSize(null));
        final fixture = RemoteConnectionRetryNativeFixture();
        final store = RetryNativeStore();
        final channel = RetryNativeChannel(fixture);
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
            throw StateError('Management forbidden');
          },
          exchangeEnrollment: ({required origin, required code}) async {
            managementAttempts++;
            throw StateError('Management forbidden');
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
        Future<void> reach(String name, {bool pending = false}) async {
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
              if (pending) {
                await tester.pump(const Duration(milliseconds: 100));
              } else {
                await tester.pumpAndSettle();
              }
              return;
            }
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            if (pending) {
              await tester.pump(const Duration(milliseconds: 100));
            } else {
              await tester.pumpAndSettle();
            }
          }
          fail('Keyboard did not reach $name');
        }

        Future<void> activate(String name) async {
          await reach(name);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
        }

        Future<void> edit(String name, String value) async {
          await reach(name);
          await tester.enterText(control(name), value);
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

        String draft(String key) =>
            tester.widget<TextField>(control(key)).controller!.text;
        const origin = DirectFirstRunNativeFixture.origin;
        const profile = DirectFirstRunNativeFixture.profile;
        const session = DirectFirstRunNativeFixture.session;
        expect(fixture.requests, isEmpty);
        expect(await store.loadProfiles(), isEmpty);
        await activate('gateway-contacts-add');
        await activate('hermes-connection-mode-remote');
        await edit('hermes-base-url-field', origin);
        await edit('hermes-profile-label-field', 'Synthetic retry host');
        fixture.deniedBootstrapStatus = 401;
        await activate('hermes-connect-button');
        expect(find.text('Hermes API rejected the API key.'), findsOneWidget);
        expect(find.textContaining('private-response'), findsNothing);
        expect(channel.connects, 1);
        expect(store.attempts, 0);
        final rejectedReads = List.of(fixture.requests);
        await tester.pump(const Duration(seconds: 2));
        await reach('hermes-connect-button');
        expect(fixture.requests, rejectedReads);
        await capture('auth');
        fixture.deniedBootstrapStatus = null;
        store.reject = true;
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(channel.connects, 2);
        expect(store.attempts, 1);
        expect(store.saveCalls, isEmpty);
        expect(channel.state.isConnected, true);
        final connectedOwner = (
          channel.state.connectedBaseUrl,
          channel.state.selectedProfileId,
          channel.state.activeSessionId,
        );
        expect(connectedOwner.$1, origin);
        expect(connectedOwner.$2, 'default');
        expect(connectedOwner.$3, session);
        expect(draft('hermes-base-url-field'), origin);
        expect(draft('hermes-profile-label-field'), 'Synthetic retry host');
        expect(control('hermes-connection-save-error'), findsOneWidget);
        expect(find.textContaining('private-storage-detail'), findsNothing);
        expect(find.textContaining('Your token is stored'), findsNothing);
        final readsBeforeIdle = List.of(fixture.requests);
        final disconnectsBeforeIdle = channel.disconnects;
        await tester.pump(const Duration(seconds: 2));
        expect(fixture.requests, readsBeforeIdle);
        expect(channel.connects, 2);
        expect(store.attempts, 1);
        expect(channel.disconnects, disconnectsBeforeIdle);
        expect((
          channel.state.connectedBaseUrl,
          channel.state.selectedProfileId,
          channel.state.activeSessionId,
        ), connectedOwner);
        await tester.ensureVisible(control('hermes-connection-save-error'));
        await tester.pumpAndSettle();
        await capture('uncertain');
        store.reject = false;
        await activate('hermes-connect-button');
        expect(channel.connects, 3);
        expect(store.attempts, 2);
        expect(store.saveCalls, hasLength(1));
        expect(store.saveCalls.single.baseUrl, origin);
        expect(store.saveCalls.single.apiKey, isNull);
        expect(store.saveCalls.single.wingLinkOrigin, isNull);
        expect(store.saveCalls.single.wingLinkToken, isNull);
        expect(control('hermes-connection-save-error'), findsNothing);
        await tester.pageBack();
        await tester.pumpAndSettle();
        final contact = directory.contacts.single;
        expect(contact.id.profileId, profile);
        await activate(
          'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}',
        );
        expect(channel.state.selectedProfileId, profile);
        expect(channel.state.activeSessionId, session);
        await capture('connected');
        // Both settlements are fenced against both a changed form and owner.
        final lateCases = <Map<String, Object>>[];
        await directory.showDirectory();
        await tester.pumpAndSettle();
        for (final reject in [false, true]) {
          for (final replacement in [false, true]) {
            await activate('hermes-connect-another-gateway');
            await activate('hermes-connection-mode-remote');
            await edit('hermes-base-url-field', origin);
            await edit('hermes-profile-label-field', 'Original draft');
            final gate = Completer<void>();
            store.gate = gate;
            store.reject = reject;
            final attempts = store.attempts;
            final connects = channel.connects;
            await reach('hermes-connect-button');
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pump(const Duration(milliseconds: 300));
            expect(store.attempts, attempts + 1);
            expect(channel.connects, connects + 1);
            expect(
              tester
                  .widget<FilledButton>(control('hermes-connect-button'))
                  .onPressed,
              isNull,
            );
            if (replacement) {
              await channel.connect(baseUrl: 'https://other.example.invalid');
              await channel.selectProfile(profile);
              await channel.selectSession(session);
              await tester.pump(const Duration(milliseconds: 300));
            } else {
              await reach('hermes-profile-label-field', pending: true);
              await tester.enterText(
                control('hermes-profile-label-field'),
                'Replacement draft',
              );
              await tester.pump(const Duration(milliseconds: 100));
            }
            final owner = (
              channel.state.connectedBaseUrl,
              channel.state.selectedProfileId,
              channel.state.activeSessionId,
            );
            final disconnects = channel.disconnects;
            final reads = List.of(fixture.requests);
            gate.complete();
            await tester.pumpAndSettle();
            expect(channel.state.isConnected, true);
            expect((
              channel.state.connectedBaseUrl,
              channel.state.selectedProfileId,
              channel.state.activeSessionId,
            ), owner);
            expect(channel.disconnects, disconnects);
            expect(fixture.requests, reads);
            expect(store.attempts, attempts + 1);
            expect(
              draft('hermes-profile-label-field'),
              replacement ? 'Original draft' : 'Replacement draft',
            );
            expect(control('hermes-connection-save-error'), findsNothing);
            expect(
              tester
                  .widget<FilledButton>(control('hermes-connect-button'))
                  .onPressed,
              isNotNull,
            );
            lateCases.add({
              'reject': reject,
              'replacement': replacement,
              'fenced': true,
            });
            await tester.pageBack();
            await directory.showDirectory();
            await tester.pumpAndSettle();
          }
        }
        expect(fixture.mutationAttempts, 0);
        expect(fixture.forbiddenReadAttempts, 0);
        expect(managementAttempts, 0);
        expect(tester.takeException(), isNull);
        final receipt = {
          'native_pid': pid,
          'width': width,
          'text_scale': scale,
          'public_entry': true,
          'denial_sanitized': true,
          'explicit_keyboard_retry': true,
          'connected_draft_retained': true,
          'auth_connects': 1,
          'auth_saves': 0,
          'auth_profile': connectedOwner.$2,
          'auth_session': connectedOwner.$3,
          'retry_connects': 1,
          'retry_saves': 1,
          'save_attempts': store.attempts,
          'save_commits': store.saveCalls.length,
          'profile': profile,
          'session': session,
          'late_cases': lateCases,
          'physical_keychain': 'NOT_CHECKED',
          'management_attempts': managementAttempts,
          'mutation_attempts': fixture.mutationAttempts,
          'forbidden_read_attempts': fixture.forbiddenReadAttempts,
          'requests': fixture.requests,
          'denied_reads': fixture.deniedReads,
        };
        final target = File('$root/cache/retry-$width-$scale.json');
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
