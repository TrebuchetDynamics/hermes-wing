import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/app.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/profiles/widgets/profile_directory_browser_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';

import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import 'support/linux_test_isolation.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  WidgetController.hitTestWarningShouldBeFatal = true;
  Map<String, dynamic> manifest(String variable) {
    final path = Platform.environment[variable];
    if (path == null) throw StateError('A private live manifest is required.');
    final value = jsonDecode(File(path).readAsStringSync());
    return (value is List ? value.first : value) as Map<String, dynamic>;
  }

  Future<void> until(WidgetTester tester, bool Function() ready) async {
    await tester.pump();
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (!ready()) {
      if (DateTime.now().isAfter(deadline)) {
        throw TestFailure('Live UI state did not become ready.');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 350));
  }

  setUp(() {
    // Only local preferences/storage are isolated; all Agent and Link requests
    // use their real clients. Persistence has a separate two-process suite.
    SharedPreferences.setMockInitialValues({});
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
  });

  testWidgets(
    'live session organization pagination rename pin search export delete',
    (tester) async {
      final agent = manifest('WING_LIVE_PROFILE_MANIFEST');
      final client = HermesApiClient(
        config: HermesApiConfig.fromBaseUrl(
          agent['origin'] as String,
          apiKey: agent['token'] as String,
        ),
      );
      final created = <String>[];
      addTearDown(() async {
        for (final id in created) {
          await client.deleteSession(id);
        }
      });
      final prefix = 'wing-linux-org-${DateTime.now().microsecondsSinceEpoch}';
      // Setup only: real Agent metadata, no inference or database injection.
      for (var i = 0; i < 51; i++) {
        final session = await client.createSession(
          id: '$prefix-$i',
          title: 'Linux organization $i',
        );
        created.add(session.id);
      }
      final target = created.first;
      final channel = HermesApiChannel();
      addTearDown(channel.dispose);
      await channel.connect(
        baseUrl: agent['origin'] as String,
        apiKey: agent['token'] as String,
      );
      expect(channel.state.isConnected, isTrue);
      expect(channel.state.hasMoreSessions, isTrue);
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesEndpointStoreProvider.overrideWithValue(
              const EmptyHermesEndpointStore(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HermesChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> openPanel() =>
          tap(find.byKey(const ValueKey('hermes-sessions-button')));
      await openPanel();
      await tap(find.text('Load more sessions').last);
      await until(tester, () => !channel.state.isLoadingMoreSessions);
      expect(channel.state.hasMoreSessions, isFalse);
      expect(channel.state.sessions.any((row) => row.id == target), isTrue);
      final search = find.byKey(const ValueKey('hermes-session-search-field'));
      await tester.enterText(search, 'Linux organization 0');
      await tester.pumpAndSettle();
      final menu = find.byKey(ValueKey('hermes-session-menu-$target')).last;
      await tap(menu);
      await tap(find.text('Pin').last);
      expect(find.text('Pinned'), findsWidgets);
      await tap(menu);
      await tap(find.text('Rename').last);
      await tester.enterText(
        find.byKey(const ValueKey('hermes-session-title-field')),
        'Linux organization renamed',
      );
      await tap(find.byKey(const ValueKey('hermes-session-title-save')));
      await until(
        tester,
        () => channel.state.sessions.any(
          (row) =>
              row.id == target && row.title == 'Linux organization renamed',
        ),
      );
      expect(
        (await client.listSessionsPage(limit: 200)).sessions.any(
          (row) =>
              row.id == target && row.title == 'Linux organization renamed',
        ),
        isTrue,
      );
      await openPanel();
      await tester.enterText(search, 'Linux organization renamed');
      await tester.pumpAndSettle();
      await tap(menu);
      await tap(find.text('Copy details').last);
      final exported = (await Clipboard.getData('text/plain'))?.text ?? '';
      expect(
        exported.contains('Linux organization renamed') &&
            exported.contains(target),
        isTrue,
      );
      await tap(menu);
      await tap(find.text('Unpin').last);
      await tap(menu);
      await tap(find.text('Delete').last);
      await tap(find.text('Delete').last);
      await until(
        tester,
        () => !channel.state.sessions.any((row) => row.id == target),
      );
      expect(
        (await client.listSessionsPage(
          limit: 200,
        )).sessions.any((row) => row.id == target),
        isFalse,
      );
      created.remove(target);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'live Tools search/refresh, Office activation and capability gaps',
    (tester) async {
      final agent = manifest('WING_LIVE_PROFILE_MANIFEST');
      final link = manifest('WING_LIVE_LINK_MANIFEST');
      final channel = HermesApiChannel();
      final store = FakeHermesEndpointStore(
        profiles: [
          HermesEndpointConfig(
            id: 'linux-live-journeys',
            label: 'Linux test gateway',
            baseUrl: agent['origin'] as String,
            apiKey: agent['token'] as String,
            wingLinkOrigin: link['wing_link_origin'] as String,
            wingLinkToken: link['wing_link_token'] as String,
            wingLinkDeviceId: link['wing_link_credential_id'] as String,
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesChannelProvider.overrideWithValue(channel),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const WingApp()),
      );
      final directory = container.read(hermesGatewayDirectoryProvider);
      await directory.start();
      await directory.refresh();
      await directory.activateGateway('linux-live-journeys');
      expect(channel.state.isConnected, isTrue);
      final router = container.read(routerProvider);
      router.go('/tools');
      await until(
        tester,
        () => find.byKey(const ValueKey('tools-refresh')).evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(const ValueKey('tools-refresh')));
      await until(
        tester,
        () =>
            tester
                .widget<IconButton>(find.byKey(const ValueKey('tools-refresh')))
                .onPressed !=
            null,
      );
      expect(channel.state.optionalResourceErrors.isEmpty, isTrue);
      for (final key in ['installed-skills-search', 'toolsets-search']) {
        final field = find.byKey(ValueKey(key));
        if (field.evaluate().isEmpty) {
          continue; // A genuinely empty inventory has no filter.
        }
        await tester.ensureVisible(field);
        await tester.enterText(field, 'wing-nonexistent-search-result');
        await tester.pumpAndSettle();
        expect(find.textContaining('match this search.'), findsWidgets);
        await tester.enterText(field, '');
        await tester.pumpAndSettle();
      }
      router.go('/office');
      final search = find.byKey(const ValueKey('office-agent-search'));
      await until(tester, () => search.evaluate().isNotEmpty);
      await tester.enterText(search, 'wing-nonexistent-search-result');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('office-open-linux-live-journeys-default')),
        findsNothing,
      );
      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('office-refresh')));
      await until(tester, () => !directory.refreshing);
      final open = find.byKey(
        const ValueKey('office-open-linux-live-journeys-default'),
      );
      await tester.ensureVisible(open);
      await tester.tap(open);
      await until(
        tester,
        () => router.routeInformationProvider.value.uri.path == '/hermes',
      );
      expect(channel.state.isConnected, isTrue);
      for (final entry in {
        '/providers': 'Providers unavailable',
        '/tasks': 'Schedules unavailable',
      }.entries) {
        router.go(entry.key);
        await until(tester, () => find.text(entry.value).evaluate().isNotEmpty);
        expect(find.text('Manage credential'), findsNothing);
        expect(find.text('Assign'), findsNothing);
      }
      router.go('/soul');
      final personaGate = channel.state.selectedProfile == null
          ? 'Choose a profile'
          : 'Persona editing unavailable';
      await until(tester, () => find.text(personaGate).evaluate().isNotEmpty);
      expect(
        channel.state.capabilities!.endpoints.containsKey(
          'profile_soul_update',
        ),
        isFalse,
      );
      expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'live directory grant, native browse, file exclusion and revocation',
    (tester) async {
      final issued = manifest('WING_LIVE_LINK_MANIFEST');
      final binary = Platform.environment['WING_LIVE_LINK_BINARY']!;
      final root = requireLinuxLiveDirectoryRoot(
        Platform.environment['WING_LIVE_DIRECTORY_ROOT']!,
        requireLinuxTestRoot('wing-linux-coverage.'),
      );
      final client = WingLinkClient(
        origin: Uri.parse(issued['wing_link_origin'] as String),
        token: issued['wing_link_token'] as String,
      );
      final grant = await Process.run(binary, ['directories', 'grant', root]);
      expect(grant.exitCode, 0);
      final id = (grant.stdout as String).trim().split('\t').first;
      var revoked = false;
      addTearDown(() async {
        if (!revoked) await Process.run(binary, ['directories', 'revoke', id]);
      });
      final roots = await client.listDirectoryRoots();
      final granted = roots.singleWhere((row) => row.name == 'grant-root');
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showProfileDirectoryBrowser(
                  context,
                  loadRoots: client.listDirectoryRoots,
                  loadChildren: (handle, offset) => client.listChildDirectories(
                    handle: handle,
                    offset: offset,
                  ),
                ),
                child: const Text('Browse approved folders'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Browse approved folders'));
      await until(tester, () => find.text('grant-root').evaluate().isNotEmpty);
      await tester.tap(find.text('grant-root'));
      await until(
        tester,
        () => find.text('child-folder').evaluate().isNotEmpty,
      );
      expect(find.text('private-file.txt'), findsNothing);
      final revoke = await Process.run(binary, ['directories', 'revoke', id]);
      expect(revoke.exitCode, 0);
      revoked = true;
      await tester.tap(find.text('child-folder'));
      await until(
        tester,
        () => find.text('No approved folders').evaluate().isNotEmpty,
      );
      expect(find.text('child-folder'), findsNothing);
      expect(
        (await client.listDirectoryRoots()).any(
          (row) => row.handle == granted.handle,
        ),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
