import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/wing_link/local_wing_link_host.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_add_screen.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';
import 'package:wing/features/local_setup/screens/local_hermes_setup_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/features/hermes_chat/widgets/platform_local_connection_panel.dart';
import 'package:wing/router/routes/app_routes.dart';

import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

class _MetadataDiscovery extends LocalHermesHomeDiscovery {
  @override
  Future<LocalHermesHomeInspection> inspectDefault() async =>
      const LocalHermesHomeInspection.directory('/synthetic/.hermes');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 1280.0]) {
    testWidgets('primary paths and cancel retain production owner at $width', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <String>[];
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, _) async {
            requests.add('GET ${uri.path}');
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
                  'required': false,
                  'granted_scopes': ['sessions:read'],
                },
                'endpoints': {
                  'sessions': {'method': 'GET', 'path': '/api/sessions'},
                  'session_messages': {
                    'method': 'GET',
                    'path': '/api/sessions/{session_id}/messages',
                  },
                },
              }),
              '/api/sessions' =>
                '{"data":[{"id":"keep","source":"api_server","title":"Keep conversation"}]}',
              '/api/sessions/keep/messages' =>
                '{"object":"list","session_id":"keep","data":[{"id":"keep-message","session_id":"keep","role":"assistant","content":"Canonical owner history"}],"pagination":{"limit":500,"offset":0,"order":"latest","returned":1}}',
              _ => throw StateError('Unexpected deterministic GET'),
            };
          },
          post: (uri, _, _) async {
            requests.add('POST ${uri.path}');
            throw StateError('No mutation is allowed');
          },
        ),
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'https://example.invalid');
      expect(
        channel.state.isConnected,
        isTrue,
        reason: channel.state.errorMessage,
      );
      expect(channel.state.activeSessionId, 'keep');
      final store = FakeHermesEndpointStore();
      final directory = HermesGatewayDirectory(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      final hostCalls = <List<String>>[];
      final host = LocalWingLinkHost(
        executablePath: '/opt/hermes-wing/wing',
        runner: (_, args) async {
          hostCalls.add(args);
          return const LocalWingLinkProcessResult(
            exitCode: 0,
            stdout:
                '{"protocol_version":2,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"setup_available":true}',
          );
        },
      );
      final router = GoRouter(
        initialLocation: '/hermes',
        routes: [
          GoRoute(path: '/hermes', builder: (_, _) => const HermesChatScreen()),
          GoRoute(
            path: '/hermes/add',
            builder: (_, _) => const HermesAddScreen(),
          ),
          GoRoute(
            path: AppRoutes.localSetup,
            builder: (_, _) => const LocalHermesSetupScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWith((_) => channel),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesGatewayDirectoryProvider.overrideWith((_) => directory),
            localWingLinkHostProvider.overrideWithValue(host),
            platformLocalHomeDiscoveryProvider.overrideWithValue(
              _MetadataDiscovery(),
            ),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final owner = channel.state;
      final before = requests.toList();
      unawaited(router.push<void>('/hermes/add'));
      await tester.pumpAndSettle();
      final primary = find.descendant(
        of: _key('hermes-primary-connection-modes'),
        matching: find.byType(ChoiceChip),
      );
      expect(tester.widgetList<ChoiceChip>(primary).map((w) => w.key), [
        const ValueKey('hermes-connection-mode-local'),
        const ValueKey('hermes-connection-mode-ssh'),
        const ValueKey('hermes-connection-mode-remote'),
      ]);
      expect(
        tester
            .widgetList<ChoiceChip>(primary)
            .map((w) => (w.label as Text).data),
        ['Local', 'SSH', 'Remote'],
      );
      expect(
        (tester.widget<ChoiceChip>(_key('hermes-remote-transport-remote')).label
                as Text)
            .data,
        'Remote HTTPS',
      );
      expect(
        (tester.widget<ChoiceChip>(_key('hermes-remote-transport-vpn')).label
                as Text)
            .data,
        'VPN / NetBird / Tailscale',
      );
      await _keyboardActivate(tester, 'hermes-remote-transport-vpn');
      expect(
        tester.widget<ChoiceChip>(_key('hermes-remote-transport-vpn')).selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(_key('hermes-connection-mode-remote'))
            .selected,
        isTrue,
      );
      expect(
        find.textContaining('network location as authorization'),
        findsOneWidget,
      );
      await _keyboardActivate(tester, 'hermes-connection-mode-remote');
      expect(
        tester.widget<ChoiceChip>(_key('hermes-remote-transport-vpn')).selected,
        isTrue,
      );
      await _keyboardActivate(tester, 'hermes-remote-transport-remote');
      expect(
        tester
            .widget<ChoiceChip>(_key('hermes-remote-transport-remote'))
            .selected,
        isTrue,
      );
      await _keyboardActivate(tester, 'hermes-connection-mode-ssh');
      expect(_key('hermes-remote-connection-modes'), findsNothing);
      expect(_key('managed-ssh-host'), findsOneWidget);
      expect(_key('managed-ssh-password'), findsOneWidget);
      expect(_key('managed-ssh-agent-port'), findsOneWidget);
      expect(_key('hermes-base-url-field'), findsNothing);
      expect(
        find.textContaining('Start the fixed tunnel outside Wing'),
        findsNothing,
      );
      await _keyboardActivate(tester, 'hermes-connection-mode-local');
      expect(find.text('Directory found — discovery only'), findsOneWidget);
      expect(_key('platform-local-choose-home'), findsOneWidget);
      expect(_key('hermes-open-local-setup'), findsNothing);
      await tester.ensureVisible(_key('platform-local-advanced-endpoint'));
      await tester.tap(_key('platform-local-advanced-endpoint'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(_key('hermes-base-url-field'));
      expect(field.controller!.text, 'http://127.0.0.1:8642');
      expect(channel.state.connectedBaseUrl, 'https://example.invalid');
      // The form's loopback default does not retarget the active owner.
      await tester.enterText(
        _key('hermes-base-url-field'),
        'https://other.example.invalid',
      );
      expect(hostCalls, isEmpty);
      expect(_key('hermes-primary-connection-modes'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Canonical owner history'), findsOneWidget);
      expect(channel.state, same(owner));
      expect(channel.state.selectedProfileId, 'default');
      expect(channel.state.activeSessionId, 'keep');
      expect(requests, before);
      expect(store.saveCalls, isEmpty);
      expect(store.clearCalls, 0);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}

Future<void> _keyboardActivate(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  for (var i = 0; i < 40; i++) {
    final focused = FocusManager.instance.primaryFocus?.context;
    var found = false;
    focused?.visitAncestorElements((element) {
      if (element.widget.key == ValueKey(key)) found = true;
      return !found;
    });
    if (found) {
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
  fail('Keyboard traversal did not reach $key');
}
