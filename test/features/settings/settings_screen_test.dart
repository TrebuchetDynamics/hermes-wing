import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/features/gateway/screens/gateway_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('voice command editor fits a narrow phone above the keyboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final keyboardInset = ValueNotifier<double>(0);
    addTearDown(keyboardInset.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => ValueListenableBuilder<double>(
            valueListenable: keyboardInset,
            builder: (context, inset, _) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(390, 844),
                viewInsets: EdgeInsets.only(bottom: inset),
                textScaler: const TextScaler.linear(2),
              ),
              child: child!,
            ),
          ),
          home: const VoiceSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final advanced = find.byKey(const ValueKey('voice-advanced-expansion'));
    await tester.scrollUntilVisible(advanced, 300);
    await tester.pumpAndSettle();
    expect(advanced.hitTestable(), findsOneWidget);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    final commandWord = find.byKey(const ValueKey('settings-command-word'));
    await Scrollable.ensureVisible(tester.element(commandWord), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(commandWord);
    await tester.pumpAndSettle();
    keyboardInset.value = 360;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('settings-command-word-field')),
      findsOneWidget,
    );
    final save = find.byKey(const ValueKey('settings-command-word-save'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(save.hitTestable(), findsOneWidget);
  });

  testWidgets('settings manage gateways without rendering credentials', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(
          id: 'a',
          label: 'Alpha',
          baseUrl: 'https://a',
          apiKey: 'sentinel-api-key',
        ),
        HermesEndpointConfig(
          id: 'b',
          label: 'Beta',
          baseUrl: 'https://b',
          apiKey: 'b-secret',
        ),
      ],
    );
    final loader = FakeGatewaySummaryLoader({
      'a': gatewaySummary(['a1']),
      'b': gatewaySummary(['b1']),
    });
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: loader,
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GatewayScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-connect-another-gateway')),
      findsOneWidget,
    );
    expect(find.text('Hermes Agent dashboard'), findsNothing);
    expect(
      find.text('Credentials stay in secure storage; values hidden'),
      findsOneWidget,
    );
    expect(find.textContaining('sentinel-api-key'), findsNothing);

    var gatewayMenu = find.byKey(const ValueKey('settings-gateway-menu-a'));
    await Scrollable.ensureVisible(tester.element(gatewayMenu), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(gatewayMenu);
    await tester.pumpAndSettle();
    expect(find.text('Manage profiles'), findsOneWidget);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-gateway-rename-field')),
      'Work',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    gatewayMenu = find.byKey(const ValueKey('settings-gateway-menu-a'));
    await Scrollable.ensureVisible(tester.element(gatewayMenu), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(gatewayMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refresh status'));
    await tester.pumpAndSettle();
    expect(loader.calls.where((id) => id == 'a'), hasLength(2));
    expect(loader.calls.where((id) => id == 'b'), hasLength(1));

    gatewayMenu = find.byKey(const ValueKey('settings-gateway-menu-a'));
    await Scrollable.ensureVisible(tester.element(gatewayMenu), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(gatewayMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-gateway-remove-dialog')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('settings-gateway-remove-confirm')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets(
    'settings preserves independent controls for imported Agent endpoints',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final store = FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(
            id: 'default-endpoint',
            label: 'BlueBlack · default',
            baseUrl: 'http://127.0.0.1:8642/p/default',
          ),
          HermesEndpointConfig(
            id: 'coder-endpoint',
            label: 'BlueBlack · coder',
            baseUrl: 'http://127.0.0.1:8642/p/coder',
          ),
        ],
      );
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({
          'default-endpoint': gatewaySummary(['default']),
          'coder-endpoint': gatewaySummary(['coder']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const GatewayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BlueBlack'), findsNothing);
      expect(find.text('BlueBlack · default'), findsOneWidget);
      expect(find.text('BlueBlack · coder'), findsOneWidget);
      expect(find.textContaining('2 profiles'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('settings-gateway-menu-default-endpoint')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Manage profiles'), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Update connection'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('settings-gateway-remove-confirm')),
      );
      await tester.pumpAndSettle();
      expect(store.deleteProfileCalls, ['default-endpoint']);
      expect((await store.loadProfiles()).single.id, 'coder-endpoint');
      expect(find.text('BlueBlack'), findsNothing);
    },
  );

  testWidgets(
    'settings rotates an inactive gateway connection without revealing credentials',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final store = FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(
            id: 'a',
            label: 'Alpha',
            baseUrl: 'https://old.example',
            apiKey: 'old-sentinel-secret',
          ),
        ],
      );
      final loader = FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      });
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: loader,
        activeChannel: channel,
      );
      await directory.refresh();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GatewayScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('settings-gateway-menu-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update connection'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('settings-gateway-base-url-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('settings-gateway-api-key-field')),
        findsOneWidget,
      );
      expect(find.textContaining('old-sentinel-secret'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('settings-gateway-api-key-field')),
            )
            .controller
            ?.text,
        isEmpty,
      );

      await tester.enterText(
        find.byKey(const ValueKey('settings-gateway-base-url-field')),
        'ftp://invalid.example',
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-gateway-connection-save')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Enter an HTTP or HTTPS gateway origin.'),
        findsOneWidget,
      );
      expect(store.saveCalls, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('settings-gateway-base-url-field')),
        'https://new.example/private?secret=value',
      );
      await tester.enterText(
        find.byKey(const ValueKey('settings-gateway-api-key-field')),
        'rotated-sentinel-secret',
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-gateway-connection-save')),
      );
      await tester.pumpAndSettle();

      expect(store.saveCalls.single.id, 'a');
      expect(store.saveCalls.single.baseUrl, 'https://new.example');
      expect(store.saveCalls.single.apiKey, 'rotated-sentinel-secret');
      expect(directory.gateways.single.baseUrl, 'https://new.example');
      expect(find.textContaining('rotated-sentinel-secret'), findsNothing);
      expect(find.textContaining('old-sentinel-secret'), findsNothing);
      expect(loader.calls, ['a', 'a']);
    },
  );

  testWidgets('gateway connection editor fits a phone at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(
      profiles: const [
        HermesEndpointConfig(id: 'a', baseUrl: 'https://a.example'),
      ],
    );
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({
        'a': gatewaySummary(['a1']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const GatewayScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-gateway-menu-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update connection'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Update gateway connection'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-gateway-base-url-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-gateway-connection-save')),
      findsOneWidget,
    );
  });

  testWidgets('chat spellcheck preference is enabled by default and persists', (
    tester,
  ) async {
    tester.platformDispatcher.nativeSpellCheckServiceDefinedTestValue = true;
    addTearDown(tester.platformDispatcher.clearNativeSpellCheckServiceDefined);
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(profiles: const []);
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader(const {}),
      activeChannel: channel,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-category-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat').last);
    await tester.pumpAndSettle();
    final spellcheck = find.byKey(const ValueKey('chat-spellcheck-enabled'));
    await Scrollable.ensureVisible(tester.element(spellcheck), alignment: 0.5);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(spellcheck).value, isTrue);
    await tester.tap(spellcheck);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(spellcheck).value, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'wing.chat.spellcheck_enabled',
      ),
      isFalse,
    );
  });

  testWidgets('settings overview fits a narrow phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(profiles: const []);
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader(const {}),
      activeChannel: channel,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('settings uses Desktop category navigation and aligned rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final store = FakeHermesEndpointStore(profiles: const []);
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader(const {}),
      activeChannel: channel,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('settings-category-layout')),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNothing);
    expect(find.byKey(const ValueKey('settings-theme-mode')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-voice-link')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('settings-category-voice')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-voice-link')), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('settings-category-connections')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-connections-link')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-diagnostics-link')),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNothing);
  });

  for (final size in [const Size(320, 700), const Size(1200, 800)]) {
    testWidgets('all categories and controls fit at 200% in $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.nativeSpellCheckServiceDefinedTestValue = true;
      addTearDown(
        tester.platformDispatcher.clearNativeSpellCheckServiceDefined,
      );
      SharedPreferences.setMockInitialValues({});
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                padding: const EdgeInsets.only(bottom: 24),
              ),
              child: child!,
            ),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('settings-compact-layout')),
        findsOneWidget,
      );
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getString('wing.theme.mode'),
        'dark',
      );
      final palette = find.byKey(const ValueKey('settings-palette-picker'));
      await tester.ensureVisible(palette);
      await tester.tap(palette);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Forest').last);
      await tester.tap(find.text('Forest').last);
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getString('wing.theme.palette'),
        'forest',
      );
      for (final category in ['Chat', 'Voice', 'Connections', 'Appearance']) {
        await tester.tap(
          find.byKey(const ValueKey('settings-category-picker')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(category).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (category == 'Chat') {
          expect(
            find.byKey(const ValueKey('settings-voice-link')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('chat-spellcheck-enabled')),
            findsOneWidget,
          );
        } else if (category == 'Voice') {
          final voice = find.byKey(const ValueKey('settings-voice-link'));
          await tester.ensureVisible(voice);
          await tester.pumpAndSettle();
          expect(voice.hitTestable(), findsOneWidget);
          expect(
            find.byKey(const ValueKey('chat-spellcheck-enabled')),
            findsNothing,
          );
        } else if (category == 'Connections') {
          final diagnostics = find.byKey(
            const ValueKey('settings-diagnostics-link'),
          );
          await tester.ensureVisible(diagnostics);
          expect(diagnostics.hitTestable(), findsOneWidget);
        }
        final viewport = tester.getRect(find.byType(ListView).last);
        expect(viewport.bottom, lessThanOrEqualTo(size.height - 24));
      }
      final selection = tester.widget<SegmentedButton<ThemeMode>>(
        find.byKey(const ValueKey('settings-theme-mode')),
      );
      expect(selection.selected, {ThemeMode.dark});
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('category and destination rows work from the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/settings/voice',
          builder: (_, _) => const Scaffold(body: Text('Voice destination')),
        ),
        GoRoute(
          path: '/settings/diagnostics',
          builder: (_, _) =>
              const Scaffold(body: Text('Diagnostics destination')),
        ),
        GoRoute(
          path: '/gateway',
          builder: (_, _) =>
              const Scaffold(body: Text('Connections destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> activateWithKeyboard(Finder target) async {
      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused != null &&
            (focused == tester.element(target) ||
                find
                    .ancestor(
                      of: find.byElementPredicate((e) => e == focused),
                      matching: target,
                    )
                    .evaluate()
                    .isNotEmpty)) {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          return;
        }
      }
      fail('Target was not keyboard reachable: $target');
    }

    await activateWithKeyboard(
      find.byKey(const ValueKey('settings-category-voice')),
    );
    expect(find.byKey(const ValueKey('settings-voice-link')), findsOneWidget);
    await activateWithKeyboard(
      find.byKey(const ValueKey('settings-voice-link')),
    );
    expect(find.text('Voice destination'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await activateWithKeyboard(
      find.byKey(const ValueKey('settings-category-connections')),
    );
    await activateWithKeyboard(
      find.byKey(const ValueKey('settings-diagnostics-link')),
    );
    expect(find.text('Diagnostics destination'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await activateWithKeyboard(
      find.byKey(const ValueKey('settings-connections-link')),
    );
    expect(find.text('Connections destination'), findsOneWidget);
  });
}
