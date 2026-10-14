import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/hermes/setup/secure_hermes_serve_recovery_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'support/local_serve_fixture_storage.dart';
import 'support/local_serve_read_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('two-process exact serve owner restoration without replay', (
    tester,
  ) async {
    const phase = String.fromEnvironment('SERVE_RESTORATION_PHASE');
    expect(phase, isIn(['first', 'second']));
    final cache = Platform.environment['XDG_CACHE_HOME']!;
    final ready =
        jsonDecode(
              await File('$cache/serve-restoration-ready.json').readAsString(),
            )
            as Map;
    final origin = ready['origin'] as String;
    SharedPreferences.setMockInitialValues({});
    final store = SecureHermesServeRecoveryStore(
      secureStorage: ServeFixtureStorage(
        File('$cache/synthetic-serve-recovery.json'),
      ),
    );
    final channel = HermesApiChannel(serveRecoveryStore: store);
    final container = ProviderContainer(
      overrides: [
        hermesEndpointStoreProvider.overrideWithValue(
          const EmptyHermesEndpointStore(),
        ),
        hermesChannelProvider.overrideWithValue(channel),
      ],
    );
    Future<Map<String, dynamic>> control(String action) async {
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          Uri.parse('$origin/fixture/$action'),
        );
        request.headers.set(
          'Authorization',
          'Bearer ${LocalServeReadFixture.token}',
        );
        final response = await request.close();
        expect(response.statusCode, 200);
        final body = await utf8.decoder.bind(response).join();
        return body.isEmpty ? {} : jsonDecode(body) as Map<String, dynamic>;
      } finally {
        client.close(force: true);
      }
    }

    Future<void> waitFor(bool Function() done) async {
      for (var i = 0; i < 200 && !done(); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(done(), true, reason: 'Serve restoration control did not settle');
    }

    Future<void> press(String key) async {
      final target = find.byKey(ValueKey(key));
      expect(target, findsOneWidget);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
    }

    try {
      if (phase == 'first') {
        await tester.runAsync(() async {
          await channel.connectLocalServeReads(
            baseUrl: origin,
            credential: LocalServeReadFixture.token,
          );
          await channel.selectProfile('demo');
        });
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HermesChatScreen(),
          ),
        ),
      );
      if (phase == 'first') {
        await press('hermes-local-serve-chat');
        await waitFor(() => channel.state.serveChat?.canSubmit == true);
      } else {
        await waitFor(
          () =>
              channel.state.errorMessage != null &&
              channel.state.selectedProfileId == 'demo',
        );
        expect(channel.state.activeSessionId, 'demo-session');
        expect(channel.state.serveChat, isNull);
        final before = await tester.runAsync(() => control('receipt'));
        expect(
          [before!['sends'], before['answers'], before['stops']],
          [1, 1, 1],
        );
        await tester.runAsync(() => control('allow'));
        await press('hermes-local-serve-chat');
        await waitFor(() => channel.state.serveChat?.canSubmit == true);
        expect(
          channel.state.activeMessages.single.text,
          'synthetic first turn',
        );
        final recovered = await tester.runAsync(() => control('receipt'));
        expect(
          [recovered!['sends'], recovered['answers'], recovered['stops']],
          [1, 1, 1],
        );
      }
      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        'synthetic ${phase == 'first' ? 'first' : 'later'} turn',
      );
      await tester.pump();
      await press('hermes-send-button');
      await waitFor(() => channel.state.serveChat?.running == true);
      if (phase == 'first') {
        await tester.runAsync(() => control('approval'));
        await waitFor(
          () => find
              .byKey(const ValueKey('hermes-approval-once'))
              .evaluate()
              .isNotEmpty,
        );
        await press('hermes-approval-once');
        await waitFor(
          () => find
              .byKey(const ValueKey('hermes-approval-banner'))
              .evaluate()
              .isEmpty,
        );
        await press('hermes-composer-stop-chip');
        await waitFor(
          () => channel.state.serveChat?.needsReconciliation == true,
        );
        expect(channel.state.serveChat!.canSubmit, false);
      }
      final saved = await tester.runAsync(store.load);
      expect(saved!.checkpoint.profile, 'demo');
      expect(saved.checkpoint.origin.toString(), origin);
      expect(saved.checkpoint.storedSessionId, 'demo-session');
      expect(saved.checkpoint.runtimeSessionId, 'runtime-demo-session');
      expect(saved.checkpoint.uncertain, true);
      final receipt = await tester.runAsync(() => control('receipt'));
      await File('$cache/serve-restoration-$phase.json').writeAsString(
        jsonEncode({
          ...receipt!,
          'native_pid': pid,
          'profile': 'demo',
          'stored': 'demo-session',
          'runtime': 'runtime-demo-session',
          'uncertain': true,
          'phase': phase,
          'denied_read_recovered': phase == 'second',
        }),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
    } finally {
      container.dispose();
      channel.dispose();
    }
  });
}
