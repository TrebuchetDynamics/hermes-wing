import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'support/direct_first_run_native_fixture.dart';
import 'support/remote_connection_retry_native_fixture.dart';
import 'support/saved_endpoint_edit_native_fixture.dart';
import 'support/saved_endpoint_storage_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real Linux storage across native restart', (tester) async {
    final root = Platform.environment['WING_STORAGE_ROOT'];
    final phase = Platform.environment['WING_STORAGE_PHASE'];
    if (root == null ||
        !['write', 'verify'].contains(phase) ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
        !(Platform.environment['DBUS_SESSION_BUS_ADDRESS'] ?? '').startsWith(
          'unix:path=$root/runtime/bus',
        ) ||
        Platform.environment['WING_LIVE_AUTH'] != null) {
      throw StateError('Use the isolated real-storage launcher');
    }
    const secure = FlutterSecureStorage();
    final store = SecureHermesEndpointStore();
    final prefs = await SharedPreferences.getInstance();
    final cases = [
      for (final width in [1280.0, 390.0])
        for (final scale in [1.0, 2.0]) (width, scale),
    ];
    final markers = <String, String>{};
    if (phase == 'write') {
      storageCheck(
        (await store.loadProfiles()).isEmpty,
        'State not disposable',
      );
      for (var i = 0; i < cases.length; i++) {
        markers['original-$i'] = storageMarker();
        markers['peer-$i'] = storageMarker();
        markers['replacement-$i'] = storageMarker();
      }
      await secure.write(
        key: 'wing.qa.storage.witness',
        value: jsonEncode(markers),
      );
      await store.saveAll([
        for (var i = 0; i < cases.length; i++) ...[
          HermesEndpointConfig(
            id: 'original-$i',
            label: 'Shared name',
            baseUrl: 'http://127.0.0.1:${41000 + i}',
            apiKey: markers['original-$i'],
          ),
          HermesEndpointConfig(
            id: 'peer-$i',
            label: 'Shared name',
            baseUrl: 'http://127.0.0.1:${42000 + i}',
            apiKey: markers['peer-$i'],
          ),
        ],
      ]);
    } else {
      final witness = await secure.read(key: 'wing.qa.storage.witness');
      storageCheck(witness != null, 'Secure witness missing after restart');
      markers.addAll(Map<String, String>.from(jsonDecode(witness!) as Map));
    }
    final fixture = RemoteConnectionRetryNativeFixture();
    final channel = RetryNativeChannel(fixture);
    await channel.connect(baseUrl: DirectFirstRunNativeFixture.origin);
    await channel.selectProfile(DirectFirstRunNativeFixture.profile);
    await channel.selectSession(DirectFirstRunNativeFixture.session);
    final initialReads = fixture.requests.length;
    final initialConnects = channel.connects;
    final initialDisconnects = channel.disconnects;
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
        hermesVoiceCaptureServiceProvider.overrideWithValue(null),
        hermesTextToSpeechServiceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() => binding.setSurfaceSize(null));
    Finder control(String key) => find.byKey(ValueKey(key));
    Future<void> reach(String key) async {
      await tester.ensureVisible(control(key));
      for (var i = 0; i < 160; i++) {
        var focused = false;
        final context = FocusManager.instance.primaryFocus?.context;
        if (context?.widget.key == ValueKey(key)) focused = true;
        context?.visitAncestorElements((element) {
          if (element.widget.key == ValueKey(key)) focused = true;
          return !focused;
        });
        if (focused) return;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      throw StateError('Keyboard did not reach public action');
    }

    Future<void> activate(String key) async {
      await reach(key);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
    }

    Future<void> edit(String key, String value) async {
      await reach(key);
      await tester.enterText(control(key), value);
      await tester.pumpAndSettle();
    }

    Future<void> canonical(int index, bool repaired) async {
      final rows = await store.loadProfiles();
      storageCheck(rows.length == 8, 'Saved row count changed');
      final original = rows.singleWhere((r) => r.id == 'original-$index');
      final peer = rows.singleWhere((r) => r.id == 'peer-$index');
      storageCheck(
        original.baseUrl ==
            'http://127.0.0.1:${(repaired ? 43000 : 41000) + index}',
        'Exact edited origin not retained',
      );
      storageCheck(
        original.apiKey ==
            markers['${repaired ? 'replacement' : 'original'}-$index'],
        'Edited secure marker not retained',
      );
      storageCheck(
        peer.baseUrl == 'http://127.0.0.1:${42000 + index}' &&
            peer.apiKey == markers['peer-$index'],
        'Peer not preserved',
      );
      storageCheck(
        original.label == 'Shared name' && peer.label == 'Shared name',
        'Labels changed',
      );
      await prefs.reload();
      final ordinary = jsonEncode({
        for (final k in prefs.getKeys()) k: prefs.get(k),
      });
      storageCheck(
        markers.values.every((m) => !ordinary.contains(m)) &&
            !ordinary.contains('apiKey'),
        'Credential leaked to preferences',
      );
    }

    for (var i = 0; i < cases.length; i++) {
      final (width, scale) = cases[i];
      await binding.setSurfaceSize(Size(width, 1000));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            key: ValueKey('$phase-$i'),
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
      // Chat's connection draft preloads the selected saved credential. Clear
      // that unsaved field before any capture, without touching canonical storage.
      await tester.enterText(control('hermes-api-key-field'), '');
      await tester.pumpAndSettle();
      final entry = 'hermes-endpoint-profile-edit-original-$i';
      if (phase == 'write') {
        await reach(entry);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          final result = await Process.run('/usr/bin/import', [
            '-window',
            'root',
            '$root/cache/storage-entry-$i.png',
          ]);
          storageCheck(result.exitCode == 0, 'Public entry capture failed');
        });
      }
      await activate(entry);
      storageCheck(
        tester
            .widget<TextField>(control('hermes-saved-edit-key'))
            .controller!
            .text
            .isEmpty,
        'Replacement field not blank',
      );
      if (phase == 'write') {
        await edit('hermes-saved-edit-url', 'http://127.0.0.1:${43000 + i}');
        await activate('hermes-saved-edit-cancel');
        await canonical(i, false);
        await activate(entry);
        await edit('hermes-saved-edit-url', 'http://127.0.0.1:${43000 + i}');
        await edit('hermes-saved-edit-key', markers['replacement-$i']!);
        // Deny real Secret Service CreateItem, retaining readable canonical data.
        await tester.runAsync(() => storageControl(root, 'deny'));
        await activate('hermes-saved-edit-save');
        expect(control('hermes-saved-edit-dialog'), findsOneWidget);
        expect(control('hermes-saved-edit-notice'), findsOneWidget);
        expect(
          tester.widget<Text>(control('hermes-saved-edit-notice')).data,
          AppLocalizations.of(
            tester.element(control('hermes-saved-edit-notice')),
          ).chatSavedEndpointSaveFailed,
        );
        expect(
          find.text(
            'Saved connection updated. The active conversation is unchanged.',
          ),
          findsNothing,
        );
        storageCheck(
          tester
                  .widget<TextField>(control('hermes-saved-edit-url'))
                  .controller!
                  .text ==
              'http://127.0.0.1:${43000 + i}',
          'Failed-save draft lost',
        );
        storageCheck(
          tester
                  .widget<TextField>(control('hermes-saved-edit-key'))
                  .controller!
                  .text ==
              markers['replacement-$i'],
          'Failed-save credential draft lost',
        );
        await canonical(i, false);
        await tester.runAsync(() => storageControl(root, 'allow'));
        await activate('hermes-saved-edit-save');
        expect(control('hermes-saved-edit-dialog'), findsNothing);
        await canonical(i, true);
        await activate(entry);
      } else {
        await canonical(i, true);
      }
      storageCheck(
        tester
            .widget<TextField>(control('hermes-saved-edit-key'))
            .controller!
            .text
            .isEmpty,
        'Reopened replacement field not blank',
      );
      await reach('hermes-saved-edit-cancel');
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        final result = await Process.run('/usr/bin/import', [
          '-window',
          'root',
          '$root/cache/storage-$phase-$i.png',
        ]);
        storageCheck(result.exitCode == 0, 'Native capture failed');
      });
      await activate('hermes-saved-edit-cancel');
      await canonical(i, true);
      expect(tester.takeException(), isNull);
    }
    storageCheck(
      channel.connects == initialConnects &&
          channel.disconnects == initialDisconnects &&
          fixture.requests.length == initialReads &&
          fixture.mutationAttempts == 0 &&
          fixture.forbiddenReadAttempts == 0,
      'Unexpected connection or mutation',
    );
    File('$root/cache/storage-$phase.json').writeAsStringSync(
      jsonEncode({
        'phase': phase,
        'native_pid': pid,
        'cases': cases.length,
        'real_plugins': true,
        'canonical_peer_preserved': true,
        'preferences_secret_free': true,
        'reopened_key_blank': true,
        'cancel_no_mutation': true,
        'denied_save_retry': phase == 'write',
        'connect_delta': 0,
        'mutation_attempts': 0,
        'active_read_delta': 0,
      }),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
