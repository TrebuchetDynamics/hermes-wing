import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'support/direct_first_run_native_fixture.dart';
import 'support/remote_connection_retry_native_fixture.dart';
import 'support/saved_endpoint_edit_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [1280.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('GTK saved endpoint repair $width text $scale', (
        tester,
      ) async {
        final root = Platform.environment['WING_SAVED_EDIT_ROOT'];
        if (root == null ||
            Platform.environment['HOME'] != '$root/home' ||
            Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
            Platform.environment['WING_LIVE_AUTH'] != null ||
            Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
          throw StateError('Use the isolated saved-edit launcher');
        }
        await (await SharedPreferences.getInstance()).clear();
        await binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => binding.setSurfaceSize(null));
        final fixture = SavedEndpointEditNativeFixture();
        await fixture.start();
        addTearDown(fixture.close);
        final activeFixture = RemoteConnectionRetryNativeFixture();
        final channel = RetryNativeChannel(activeFixture);
        await channel.connect(baseUrl: DirectFirstRunNativeFixture.origin);
        await channel.selectProfile(DirectFirstRunNativeFixture.profile);
        await channel.selectSession(DirectFirstRunNativeFixture.session);
        final initialReads = List.of(activeFixture.requests);
        final initialConnects = channel.connects;
        final initialDisconnects = channel.disconnects;
        final owner = channel.state;
        final store = SavedEditStore();
        final initialRows = await store.loadProfiles();
        final directory = HermesGatewayDirectory(
          store: store,
          cache: GatewayContactCache(),
          loader: SavedEditDirectoryLoader(),
          activeChannel: channel,
        );
        final container = ProviderContainer(
          overrides: [
            hermesChannelProvider.overrideWith((_) => channel),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesGatewayDirectoryProvider.overrideWith((_) => directory),
            hermesEndpointTestClientProvider.overrideWithValue(fixture.client),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const HermesChatScreen(initiallyEditingConnection: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Finder control(String key) => find.byKey(ValueKey(key));
        Future<void> reach(String key, {bool pending = false}) async {
          await tester.ensureVisible(control(key));
          for (var i = 0; i < 120; i++) {
            var focused = false;
            final context = FocusManager.instance.primaryFocus?.context;
            if (context?.widget.key == ValueKey(key)) focused = true;
            context?.visitAncestorElements((element) {
              if (element.widget.key == ValueKey(key)) focused = true;
              return !focused;
            });
            if (focused) return;
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            if (pending) {
              await tester.pump(const Duration(milliseconds: 100));
            } else {
              await tester.pumpAndSettle();
            }
          }
          fail('Keyboard did not reach $key');
        }

        Future<void> activate(String key, {bool pending = false}) async {
          await reach(key, pending: pending);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          if (pending) {
            await tester.pump(const Duration(milliseconds: 100));
          } else {
            await tester.pumpAndSettle();
          }
        }

        Future<void> edit(String key, String value) async {
          await reach(key);
          await tester.enterText(control(key), value);
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

        void unchanged({bool saved = false}) {
          expect(channel.state.connectedBaseUrl, owner.connectedBaseUrl);
          expect(channel.state.selectedProfileId, owner.selectedProfileId);
          expect(channel.state.activeSessionId, owner.activeSessionId);
          expect(channel.connects, initialConnects);
          expect(channel.disconnects, initialDisconnects);
          expect(activeFixture.requests, initialReads);
          expect(activeFixture.mutationAttempts, 0);
          expect(activeFixture.forbiddenReadAttempts, 0);
          expect(fixture.forbidden, 0);
          expect(store.saveCalls.length, saved ? 1 : 0);
          expect(store.saveAllCalls, isEmpty);
          expect(store.deleteProfileCalls, isEmpty);
          expect(store.clearCalls, 0);
        }

        const entry = 'hermes-endpoint-profile-edit-original';
        await activate(entry);
        await edit('hermes-saved-edit-url', fixture.origin);
        await activate('hermes-saved-edit-cancel');
        expect(await store.loadProfiles(), initialRows);
        expect(fixture.requests, isEmpty);
        unchanged();
        await activate(entry);
        await edit('hermes-saved-edit-url', fixture.origin);
        fixture.status = 403;
        await activate('hermes-saved-edit-test');
        expect(find.textContaining('denied this credential'), findsOneWidget);
        expect(find.textContaining('private-response'), findsNothing);
        unchanged();
        expect(fixture.requests, hasLength(1));
        await reach('hermes-saved-edit-test');
        await capture('denied');
        await tester.pump(const Duration(seconds: 2));
        expect(fixture.requests, hasLength(1));
        fixture.status = 200;
        await activate('hermes-saved-edit-test');
        expect(
          find.textContaining('Supported Agent discovery responded'),
          findsOneWidget,
        );
        unchanged();
        expect(fixture.requests, hasLength(2));
        await reach('hermes-saved-edit-save');
        await capture('success');
        final gate = Completer<void>();
        fixture.gate = gate;
        fixture.status = 500;
        await activate('hermes-saved-edit-test', pending: true);
        await activate('hermes-saved-edit-cancel-test', pending: true);
        gate.complete();
        await tester.pumpAndSettle();
        expect(find.textContaining('could not be verified'), findsNothing);
        expect(
          find.textContaining('Supported Agent discovery responded'),
          findsNothing,
        );
        unchanged();
        expect(fixture.requests, hasLength(3));
        // Native settling can outlast the transient persistence snackbar.
        await activate('hermes-saved-edit-save', pending: true);
        await tester.pump(const Duration(milliseconds: 300));
        unchanged(saved: true);
        expect(
          find.text(
            'Saved connection updated. The active conversation is unchanged.',
          ),
          findsOneWidget,
        );
        expect(control('hermes-saved-edit-dialog'), findsNothing);
        await tester.pumpAndSettle();
        final rows = await store.loadProfiles();
        expect(rows, hasLength(2));
        expect(
          rows.singleWhere((row) => row.id == 'original').baseUrl,
          fixture.origin,
        );
        expect(
          rows.singleWhere((row) => row.id == 'peer').baseUrl,
          initialRows.last.baseUrl,
        );
        expect(rows.every((row) => row.label == 'Shared name'), true);
        expect(store.saveCalls.single.id, 'original');
        await activate(entry);
        expect(
          tester
              .widget<TextField>(control('hermes-saved-edit-key'))
              .controller!
              .text,
          isEmpty,
        );
        await reach('hermes-saved-edit-cancel');
        await capture('reopened');
        await activate('hermes-saved-edit-cancel');
        unchanged(saved: true);
        expect(tester.takeException(), isNull);
        final receipt = {
          'native_pid': pid,
          'width': width,
          'text_scale': scale,
          'public_entry': true,
          'keyboard_retry': true,
          'cancel_no_mutation': true,
          'pending_cancel_fenced': true,
          'exact_id_peer_preserved': true,
          'reopened_key_blank': true,
          'owner_unchanged': true,
          'physical_keychain': 'NOT_CHECKED',
          'connect_delta': channel.connects - initialConnects,
          'disconnect_delta': channel.disconnects - initialDisconnects,
          'mutation_attempts':
              activeFixture.mutationAttempts + fixture.forbidden,
          'active_read_delta':
              activeFixture.requests.length - initialReads.length,
          'save_commits': store.saveCalls.length,
          'requests': fixture.requests,
        };
        final path = '$root/cache/saved-edit-$width-$scale.json';
        File('$path.tmp').writeAsStringSync(jsonEncode(receipt));
        File('$path.tmp').renameSync(path);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
