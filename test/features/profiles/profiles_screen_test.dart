import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/routes/app_routes.dart';
import 'package:wing/shared/widgets/wing_skeleton.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesCapabilityDocument _profileCapabilities(
  List<String> scopes, {
  bool advertisesDelete = true,
  bool advertisesSoul = false,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'profile_context': {
    'type': 'query',
    'name': 'profile',
    'required': true,
    'default_profile_id': 'default',
  },
  'auth': {'type': 'bearer', 'required': true, 'granted_scopes': scopes},
  'endpoints': {
    'profiles': {
      'method': 'GET',
      'path': '/api/profiles',
      'required_scopes': ['profiles:read'],
    },
    'profile_create': {
      'method': 'POST',
      'path': '/api/profiles',
      'required_scopes': ['profiles:write'],
    },
    'profile_update': {
      'method': 'PATCH',
      'path': '/api/profiles/{name}',
      'required_scopes': ['profiles:write'],
    },
    if (advertisesDelete)
      'profile_delete': {
        'method': 'DELETE',
        'path': '/api/profiles/{name}',
        'required_scopes': ['profiles:write'],
      },
    if (advertisesSoul) ...{
      'profile_soul': {
        'method': 'GET',
        'path': '/api/profiles/{name}/soul',
        'required_scopes': ['profiles:read'],
      },
      'profile_soul_update': {
        'method': 'PUT',
        'path': '/api/profiles/{name}/soul',
        'required_scopes': ['profiles:write'],
      },
    },
  },
});

class _GatedProfileSelectionChannel extends FakeHermesChannel {
  _GatedProfileSelectionChannel({
    required super.capabilities,
    required super.profiles,
    required super.selectedProfileId,
  });

  final selectionGate = Completer<void>();
  int selectionAttempts = 0;

  @override
  Future<void> selectProfile(
    String profileId, {
    bool allowDiscovered = false,
  }) async {
    selectionAttempts += 1;
    await selectionGate.future;
    await super.selectProfile(profileId, allowDiscovered: allowDiscovered);
  }
}

Widget _profilesTestApp(
  FakeHermesChannel channel, {
  double textScale = 1.0,
  HermesGatewayDirectory? directory,
  WingLinkClientBuilder? wingLinkClientBuilder,
}) => ProviderScope(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    hermesGatewayDirectoryProvider.overrideWith(
      (ref) =>
          directory ??
          directoryFor(
            configs: const [],
            loader: FakeGatewaySummaryLoader(const {}),
            activeChannel: channel,
          ),
    ),
    if (wingLinkClientBuilder != null)
      wingLinkClientBuilderProvider.overrideWithValue(wingLinkClientBuilder),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const ProfilesScreen(),
  ),
);

void main() {
  testWidgets(
    'profile lifecycle creates, uses, edits persona, renames, and removes an agent',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel(
        capabilities: _profileCapabilities(const [
          'profiles:read',
          'profiles:write',
        ], advertisesSoul: true),
        profiles: const [
          HermesProfile(
            id: 'default',
            displayName: 'Hermes One',
            revision: 'rev-default',
          ),
        ],
        selectedProfileId: 'default',
        profileSoul: const HermesProfileSoul(
          soul: 'Initial persona.',
          revision: 'soul-1',
        ),
      );
      addTearDown(channel.dispose);
      final router = GoRouter(
        initialLocation: AppRoutes.agents,
        routes: [
          GoRoute(
            path: AppRoutes.agents,
            builder: (_, _) => const ProfilesScreen(),
          ),
          GoRoute(
            path: AppRoutes.hermes,
            builder: (_, _) => const Scaffold(body: Text('Chat destination')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesGatewayDirectoryProvider.overrideWith(
              (ref) => directoryFor(
                configs: const [],
                loader: FakeGatewaySummaryLoader(const {}),
                activeChannel: channel,
              ),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'New Profile'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Lifecycle Agent',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pumpAndSettle();
      expect(channel.createProfileCalls, [
        {'name': 'Lifecycle Agent', 'cloneFrom': 'default'},
      ]);
      expect(find.text('Lifecycle Agent'), findsOneWidget);

      Finder lifecycleCard() => find.ancestor(
        of: find.text('Lifecycle Agent'),
        matching: find.byType(Card),
      );
      final chat = find.descendant(
        of: lifecycleCard(),
        matching: find.widgetWithText(FilledButton, 'Chat'),
      );
      await tester.ensureVisible(chat);
      await tester.tap(chat);
      await tester.pumpAndSettle();
      expect(channel.selectProfileCalls, ['lifecycle-agent']);
      expect(channel.state.selectedProfileId, 'lifecycle-agent');
      expect(find.text('Chat destination'), findsOneWidget);

      router.go(AppRoutes.agents);
      await tester.pumpAndSettle();
      final edit = find.descendant(
        of: lifecycleCard(),
        matching: find.widgetWithText(OutlinedButton, 'Edit'),
      );
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(channel.readProfileSoulCalls, ['lifecycle-agent']);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'Lifecycle Renamed');
      await tester.enterText(fields.last, 'Updated persona.');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(channel.renameProfileCalls.single, {
        'profileId': 'lifecycle-agent',
        'name': 'Lifecycle Renamed',
        'revision': 'rev-new',
      });
      expect(channel.writeProfileSoulCalls.single, {
        'profileId': 'lifecycle-agent',
        'soul': 'Updated persona.',
        'revision': 'soul-1',
      });
      expect(find.text('Lifecycle Renamed'), findsOneWidget);

      final renamedCard = find.ancestor(
        of: find.text('Lifecycle Renamed'),
        matching: find.byType(Card),
      );
      final remove = find.descendant(
        of: renamedCard,
        matching: find.widgetWithText(TextButton, 'Delete profile'),
      );
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete profile').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Lifecycle Renamed');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete profile'));
      await tester.pumpAndSettle();

      expect(channel.deleteProfileCalls.single, {
        'profileId': 'lifecycle-agent',
        'revision': 'rev-next',
      });
      expect(find.text('Lifecycle Renamed'), findsNothing);
      expect(channel.state.selectedProfileId, 'default');
    },
  );

  testWidgets('connection errors are bounded and offer Chat recovery', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'private endpoint and server stack trace',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Profiles could not be loaded from Hermes.'),
      findsOneWidget,
    );
    expect(find.textContaining('private endpoint'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Open chat'), findsOneWidget);
  });

  testWidgets(
    'disconnected channel shows a neutral select-gateway prompt, not the '
    'unavailable lock state',
    (tester) async {
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);

      await tester.pumpWidget(_profilesTestApp(channel));
      await tester.pumpAndSettle();

      expect(find.text('Select a gateway'), findsOneWidget);
      expect(find.text('Profiles unavailable'), findsNothing);
    },
  );

  testWidgets('gateway picker activates the selected gateway', (tester) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(id: 'alpha', label: 'Alpha', baseUrl: 'https://a'),
        HermesEndpointConfig(id: 'beta', label: 'Beta', baseUrl: 'https://b'),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
        'beta': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(_profilesTestApp(channel, directory: directory));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('agents-gateway-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(channel.connectCalls.single.baseUrl, 'https://b');
    expect(directory.activeContactId?.gatewayId, 'beta');
  });

  testWidgets(
    'Wing Link profiles remain manageable when Agent omits profile endpoints',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.disconnected,
      );
      addTearDown(channel.dispose);
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'alpha',
            label: 'Alpha',
            baseUrl: 'https://a.example:8642',
            wingLinkOrigin: 'https://a.example:8654',
            wingLinkToken: 'wlc-secret',
            wingLinkHostFingerprint: 'sha256/reviewed-pin',
          ),
        ],
        loader: FakeGatewaySummaryLoader({
          'alpha': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('alpha');
      final wingLinkCalls = <String>[];
      var directoryCapabilities = const [
        'directories.roots.read',
        'directories.children.read',
      ];
      var directoryScopes = const ['directories:read'];

      await tester.pumpWidget(
        _profilesTestApp(
          channel,
          directory: directory,
          wingLinkClientBuilder:
              ({
                required origin,
                required token,
                required hostFingerprint,
              }) => WingLinkClient(
                origin: origin,
                token: token,
                get: (uri, _) async {
                  wingLinkCalls.add(uri.path);
                  return switch (uri.path) {
                    '/v1/profiles' =>
                      '''{"profiles":[{"id":"link","name":"Link","topology_revision":"top-1","source":"cli","gateway_state":"running","actions":{"rename":{"revision":"rev-1"},"delete":{"revision":"rev-1"}}}]}''',
                    '/meta' => jsonEncode({
                      'protocol_generation': 2,
                      'minimum_protocol_generation': 1,
                      'supported_protocol_generations': [1, 2],
                      'version': 'test',
                      'host_fingerprint': 'sha256/test',
                      'capabilities': directoryCapabilities,
                    }),
                    '/v2/devices/self' => jsonEncode({
                      'device_id': 'cred_phone',
                      'name': 'Phone',
                      'scopes': directoryScopes,
                      'created_at': '2026-08-30T00:00:00Z',
                      'legacy': false,
                    }),
                    '/v2/directories' => '{"directories":[]}',
                    _ => throw StateError('unexpected GET $uri'),
                  };
                },
              ),
        ),
      );
      await tester.pumpAndSettle();

      expect(wingLinkCalls, ['/v1/profiles']);
      expect(find.text('Profiles unavailable'), findsNothing);
      expect(find.text('Link'), findsOneWidget);
      expect(find.text('Selected'), findsOneWidget);
      final selectedCard = find.ancestor(
        of: find.text('Selected'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: selectedCard, matching: find.text('Link')),
        findsOneWidget,
      );
      expect(find.text('New Profile'), findsOneWidget);
      expect(find.text('Browse folders'), findsOneWidget);

      final browseFolders = find.byKey(
        const ValueKey('agent-browse-folders-link'),
      );
      await tester.scrollUntilVisible(browseFolders, 200);
      await tester.tap(browseFolders);
      await tester.pumpAndSettle();

      expect(find.text('Approved folders'), findsOneWidget);
      expect(
        find.textContaining('wing-link directories grant PATH'),
        findsOneWidget,
      );
      expect(wingLinkCalls, [
        '/v1/profiles',
        '/meta',
        '/v2/devices/self',
        '/v2/directories',
      ]);

      await tester.tap(find.text('Close').last);
      await tester.pumpAndSettle();

      for (final capabilities in [
        const ['directories.roots.read'],
        const ['directories.children.read'],
      ]) {
        directoryCapabilities = capabilities;
        directoryScopes = const ['directories:read'];
        wingLinkCalls.clear();
        await tester.tap(browseFolders);
        await tester.pumpAndSettle();
        expect(
          find.textContaining('pair again with directory access'),
          findsOneWidget,
        );
        expect(wingLinkCalls, ['/meta']);
        await tester.pump(const Duration(seconds: 5));
      }

      directoryCapabilities = const [
        'directories.roots.read',
        'directories.children.read',
      ];
      directoryScopes = const [];
      wingLinkCalls.clear();
      await tester.tap(browseFolders);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('pair again with directory access'),
        findsOneWidget,
      );
      expect(wingLinkCalls, ['/meta', '/v2/devices/self']);
      expect(wingLinkCalls, isNot(contains('/v2/directories')));
    },
  );

  testWidgets('late same-gateway Wing Link inventory cannot replace a newer load', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
    );
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha',
          baseUrl: 'https://a.example:8642',
          wingLinkOrigin: 'https://a.example:8654',
          wingLinkToken: 'wlc-secret',
        ),
        HermesEndpointConfig(
          id: 'beta',
          label: 'Beta',
          baseUrl: 'https://b.example:8642',
          wingLinkOrigin: 'https://b.example:8654',
          wingLinkToken: 'wlc-secret',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
        'beta': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    await directory.activateGateway('alpha');
    final alphaResponses = [Completer<String>(), Completer<String>()];
    var alphaCalls = 0;

    await tester.pumpWidget(
      _profilesTestApp(
        channel,
        directory: directory,
        wingLinkClientBuilder:
            ({required origin, required token, required hostFingerprint}) =>
                WingLinkClient(
                  origin: origin,
                  token: token,
                  get: (_, _) {
                    if (origin.host == 'a.example') {
                      return alphaResponses[alphaCalls++].future;
                    }
                    return Future.value('{"profiles":[]}');
                  },
                ),
      ),
    );
    await tester.pump();
    expect(alphaCalls, 1);

    await tester.tap(find.byKey(const ValueKey('agents-gateway-picker')));
    await tester.pump();
    await tester.tap(find.text('Beta').last);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('agents-gateway-picker')));
    await tester.pump();
    await tester.tap(find.text('Alpha').last);
    await tester.pump();
    await tester.pump();
    expect(alphaCalls, 2);

    alphaResponses[1].complete(
      '''{"profiles":[{"id":"fresh","name":"Fresh","topology_revision":"fresh-rev","source":"cli","gateway_state":"running","actions":{}}]}''',
    );
    await tester.pumpAndSettle();
    expect(find.text('Fresh'), findsOneWidget);

    alphaResponses[0].complete(
      '''{"profiles":[{"id":"stale","name":"Stale","topology_revision":"stale-rev","source":"cli","gateway_state":"running","actions":{}}]}''',
    );
    await tester.pumpAndSettle();

    expect(find.text('Fresh'), findsOneWidget);
    expect(find.text('Stale'), findsNothing);
  });

  testWidgets(
    'Wing Link rows distinguish enrolled endpoints from inventory-only profiles',
    (tester) async {
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.disconnected,
      );
      addTearDown(channel.dispose);
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'default-endpoint',
            label: 'Alpha · default',
            baseUrl: 'https://a.example:8642/p/default',
            apiKey: 'default-secret',
            wingLinkOrigin: 'https://a.example:8654',
            wingLinkToken: 'wlc-secret',
            wingLinkHostFingerprint: 'sha256/reviewed-pin',
          ),
          HermesEndpointConfig(
            id: 'link-endpoint',
            label: 'Alpha · link',
            baseUrl: 'https://a.example:8642/p/link',
            apiKey: 'link-secret',
            wingLinkOrigin: 'https://a.example:8654',
            wingLinkToken: 'wlc-secret',
            wingLinkHostFingerprint: 'sha256/reviewed-pin',
          ),
        ],
        loader: FakeGatewaySummaryLoader({
          'default-endpoint': gatewaySummary(['default']),
          'link-endpoint': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('default-endpoint');

      await tester.pumpWidget(
        _profilesTestApp(
          channel,
          directory: directory,
          wingLinkClientBuilder:
              ({
                required origin,
                required token,
                required hostFingerprint,
              }) => WingLinkClient(
                origin: origin,
                token: token,
                get: (_, _) async =>
                    '''{"profiles":[{"id":"link","name":"Link","topology_revision":"top-1","source":"cli","gateway_state":"running","actions":{"rename":{"revision":"rev-1"},"delete":{"revision":"rev-1"}}},{"id":"newbie","name":"Newbie","topology_revision":"top-1","source":"cli","gateway_state":"stopped","actions":{"rename":{"revision":"rev-1"},"delete":{"revision":"rev-1"}}}]}''',
              ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enrolled'), findsOneWidget);
      final enrolledChat = tester.widget<FilledButton>(
        find.byKey(const ValueKey('agent-chat-link')),
      );
      expect(enrolledChat.onPressed, isNotNull);

      await tester.scrollUntilVisible(find.text('Newbie'), 500);
      expect(find.text('Not enrolled'), findsOneWidget);
      final inventoryOnlyChat = tester.widget<FilledButton>(
        find.byKey(const ValueKey('agent-chat-newbie')),
      );
      expect(inventoryOnlyChat.onPressed, isNull);
    },
  );

  testWidgets(
    'Wing Link enrolled profile chat activates its saved scoped endpoint',
    (tester) async {
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.disconnected,
      );
      addTearDown(channel.dispose);
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'default-endpoint',
            label: 'Alpha · default',
            baseUrl: 'https://a.example:8642/p/default',
            apiKey: 'default-secret',
            wingLinkOrigin: 'https://a.example:8654',
            wingLinkToken: 'wlc-secret',
            wingLinkHostFingerprint: 'sha256/reviewed-pin',
          ),
          HermesEndpointConfig(
            id: 'link-endpoint',
            label: 'Alpha · link',
            baseUrl: 'https://a.example:8642/p/link',
            apiKey: 'link-secret',
            wingLinkOrigin: 'https://a.example:8654',
            wingLinkToken: 'wlc-secret',
            wingLinkHostFingerprint: 'sha256/reviewed-pin',
          ),
        ],
        loader: FakeGatewaySummaryLoader({
          'default-endpoint': gatewaySummary(['default']),
          'link-endpoint': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('default-endpoint');
      channel.connectCalls.clear();

      await tester.pumpWidget(
        _profilesTestApp(
          channel,
          directory: directory,
          wingLinkClientBuilder:
              ({
                required origin,
                required token,
                required hostFingerprint,
              }) => WingLinkClient(
                origin: origin,
                token: token,
                get: (_, _) async =>
                    '''{"profiles":[{"id":"link","name":"Link","topology_revision":"top-1","source":"cli","gateway_state":"running","actions":{"rename":{"revision":"rev-1"},"delete":{"revision":"rev-1"}}}]}''',
              ),
        ),
      );
      await tester.pumpAndSettle();
      final chatButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('agent-chat-link')),
      );
      chatButton.onPressed!.call();
      await tester.pumpAndSettle();

      expect(channel.connectCalls, hasLength(1));
      expect(
        channel.connectCalls.single.baseUrl,
        'https://a.example:8642/p/link',
      );
      expect(channel.connectCalls.single.apiKey, 'link-secret');
      expect(directory.activeContactId?.gatewayId, 'link-endpoint');
    },
  );

  testWidgets(
    'Wing Link profile approval retries the same body and idempotency key',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.disconnected,
      );
      addTearDown(channel.dispose);
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'alpha',
            label: 'Alpha',
            baseUrl: 'https://a.example:8642',
            wingLinkOrigin: 'https://a.example:8654',
            wingLinkToken: 'wlc-secret',
            wingLinkHostFingerprint: 'sha256/reviewed-pin',
          ),
        ],
        loader: FakeGatewaySummaryLoader({
          'alpha': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('alpha');
      final requestBodies = <String>[];
      final idempotencyKeys = <String>[];

      await tester.pumpWidget(
        _profilesTestApp(
          channel,
          directory: directory,
          wingLinkClientBuilder:
              ({
                required origin,
                required token,
                required hostFingerprint,
              }) => WingLinkClient(
                origin: origin,
                token: token,
                get: (_, _) async => '{"profiles":[]}',
                post: (uri, headers, body) async {
                  requestBodies.add(body);
                  idempotencyKeys.add(headers['Idempotency-Key']!);
                  if (requestBodies.length == 1) {
                    return jsonEncode({
                      'error': {'code': 'approval_required'},
                      'approval_id': 'appr_pending',
                      'operation_id': 'op_pending',
                      'expires_at':
                          DateTime.now()
                              .add(const Duration(minutes: 1))
                              .millisecondsSinceEpoch ~/
                          1000,
                    });
                  }
                  return '{"profile":{"id":"readyqa","name":"readyqa","revision":"rev-1"}}';
                },
              ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Profile'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Profile name'),
        'readyqa',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Provider'),
        'openrouter',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Model'),
        'openai/gpt-5.2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New provider credential'),
        'write-only-fixture',
      );
      final create = find.widgetWithText(FilledButton, 'Create');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pump();
      final retry = find.text('Retry approved setup');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(requestBodies, hasLength(2));
      expect(requestBodies.last, requestBodies.first);
      expect(idempotencyKeys, hasLength(2));
      expect(idempotencyKeys.last, idempotencyKeys.first);
      expect(jsonDecode(requestBodies.first), {
        'name': 'readyqa',
        'provider': 'openrouter',
        'model': 'openai/gpt-5.2',
        'provider_api_key': 'write-only-fixture',
      });
      expect(find.text('write-only-fixture'), findsNothing);
    },
  );

  testWidgets('successful create closes when authoritative reload fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
    );
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha',
          baseUrl: 'https://a.example:8642',
          wingLinkOrigin: 'https://a.example:8654',
          wingLinkToken: 'wlc-secret',
          wingLinkHostFingerprint: 'sha256/reviewed-pin',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    await directory.activateGateway('alpha');
    var gets = 0;
    var posts = 0;

    await tester.pumpWidget(
      _profilesTestApp(
        channel,
        directory: directory,
        wingLinkClientBuilder:
            ({
              required origin,
              required token,
              required hostFingerprint,
            }) => WingLinkClient(
              origin: origin,
              token: token,
              get: (_, _) async {
                gets++;
                if (gets == 1) return '{"profiles":[]}';
                throw StateError('response lost');
              },
              post: (_, _, _) async {
                posts++;
                return '{"profile":{"id":"readyqa","name":"readyqa","revision":"rev-1"}}';
              },
            ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Profile name'),
      'readyqa',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Provider'),
      'openrouter',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Model'),
      'openai/gpt-5.2',
    );
    final create = find.widgetWithText(FilledButton, 'Create');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();

    expect(posts, 1);
    expect(gets, 2);
    expect(find.text('Create profile'), findsNothing);
    expect(find.text('Could not load local profiles.'), findsOneWidget);
  });

  testWidgets('Wing Link stale mutation refreshes inventory before retry', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.disconnected,
    );
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha',
          baseUrl: 'https://a.example:8642',
          wingLinkOrigin: 'https://a.example:8654',
          wingLinkToken: 'wlc-secret',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    await directory.activateGateway('alpha');
    var listCalls = 0;

    await tester.pumpWidget(
      _profilesTestApp(
        channel,
        directory: directory,
        wingLinkClientBuilder:
            ({
              required origin,
              required token,
              required hostFingerprint,
            }) => WingLinkClient(
              origin: origin,
              token: token,
              get: (_, _) async {
                listCalls++;
                return '''{"profiles":[{"id":"link","name":"link","topology_revision":"rev-$listCalls","source":"cli","gateway_state":"running","actions":{"rename":{"revision":"rev-$listCalls"},"delete":{"revision":"rev-$listCalls"}}}]}''';
              },
              patch: (_, _, _) async => throw const WingLinkHttpException(412),
            ),
      ),
    );
    await tester.pumpAndSettle();
    final editButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Edit').first,
    );
    editButton.onPressed!.call();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'link-renamed');
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(listCalls, 2);
    expect(
      find.text(
        'This profile changed elsewhere. The latest version has been loaded; '
        'review it before trying again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('native Hermes profile API takes precedence over Wing Link', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(
          id: 'native',
          displayName: 'Native profile',
          revision: 'native-rev',
        ),
      ],
      selectedProfileId: 'native',
    );
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha',
          baseUrl: 'https://a.example:8642',
          wingLinkOrigin: 'https://a.example:8654',
          wingLinkToken: 'wlc-secret',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['native']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    await directory.activateGateway('alpha');
    var wingLinkCalls = 0;

    await tester.pumpWidget(
      _profilesTestApp(
        channel,
        directory: directory,
        wingLinkClientBuilder:
            ({required origin, required token, required hostFingerprint}) =>
                WingLinkClient(
                  origin: origin,
                  token: token,
                  get: (_, _) async {
                    wingLinkCalls++;
                    return '{"profiles":[]}';
                  },
                ),
      ),
    );
    await tester.pumpAndSettle();

    expect(wingLinkCalls, 0);
    expect(find.text('Managed by Wing Link'), findsNothing);
  });

  testWidgets(
    'late native profile contract supersedes an in-flight Wing Link load',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'alpha',
            label: 'Alpha',
            baseUrl: 'https://a.example:8642',
            wingLinkOrigin: 'https://a.example:8654',
            wingLinkToken: 'wlc-secret',
            wingLinkHostFingerprint: 'sha256/reviewed-pin',
          ),
        ],
        loader: FakeGatewaySummaryLoader({
          'alpha': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      await directory.refresh();
      await directory.activateGateway('alpha');
      final wingLinkResponse = Completer<String>();

      await tester.pumpWidget(
        _profilesTestApp(
          channel,
          directory: directory,
          wingLinkClientBuilder:
              ({required origin, required token, required hostFingerprint}) =>
                  WingLinkClient(
                    origin: origin,
                    token: token,
                    get: (_, _) => wingLinkResponse.future,
                  ),
        ),
      );
      await tester.pump();
      channel.replaceCapabilitiesAndProfiles(
        _profileCapabilities(const ['profiles:read', 'profiles:write']),
        const [
          HermesProfile(
            id: 'native',
            displayName: 'Native profile',
            revision: 'native-rev',
          ),
        ],
      );
      await tester.pump();
      expect(find.text('Native profile'), findsOneWidget);

      wingLinkResponse.complete(
        '''{"profiles":[{"id":"link","name":"Link","topology_revision":"link-rev","source":"cli","gateway_state":"running","actions":{}}]}''',
      );
      await tester.pumpAndSettle();
      expect(find.text('Native profile'), findsOneWidget);
      expect(find.text('Link'), findsNothing);
    },
  );

  testWidgets('write access opens the create-agent editor', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(
          id: 'default',
          displayName: 'Hermes One',
          revision: 'rev-default',
        ),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Create profile'), findsOneWidget);
    expect(find.text('Clone from'), findsOneWidget);
  });

  testWidgets('read-only profile token hides mutation actions', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(
          id: 'coder',
          displayName: 'Coding Agent',
          revision: 'rev-1',
          skillsCount: 4,
        ),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Coding Agent'), findsOneWidget);
    expect(find.text('ID: coder'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('New Profile'), findsNothing);
    expect(find.text('Delete profile'), findsNothing);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('Agent name placeholders enable profile editing', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);
    expect(find.text('Delete profile'), findsOneWidget);
    expect(find.bySemanticsLabel('Chat with Coding Agent'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit Coding Agent'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete Coding Agent'), findsOneWidget);
  });

  testWidgets('edit sheet respects a missing profile delete endpoint', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ], advertisesDelete: false),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Delete profile'), findsNothing);
  });

  testWidgets('shows a loading indicator while connecting', (tester) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.connecting,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pump();

    expect(find.byType(WingSkeletonList), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(WingSkeletonList)).label,
      contains('Loading profiles'),
    );
  });

  testWidgets('shows a connection error when the channel is in error', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'boom',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Profiles could not be loaded from Hermes.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an unavailable message without profile access', (
    tester,
  ) async {
    final channel = FakeHermesChannel(capabilities: null);
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Profiles unavailable'), findsOneWidget);
  });

  testWidgets('shows an empty state with read access but no agents', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('No profiles available'), findsOneWidget);
  });

  testWidgets('seeds the default profile as selected on mount', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      // Nothing explicitly selected yet.
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    // Exactly one row is marked selected, and it is the default agent.
    expect(find.text('Selected'), findsOneWidget);
    final selectedCard = find.ancestor(
      of: find.text('Selected'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: selectedCard, matching: find.text('Hermes One')),
      findsOneWidget,
    );
  });

  testWidgets('uses a compact two-column profile layout on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
        HermesProfile(
          id: 'writer',
          displayName: 'Writing Agent',
          revision: 'w',
        ),
      ],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    final cards = find.byType(Card);
    expect(cards, findsNWidgets(3));
    expect(
      tester.getTopLeft(cards.at(1)).dx,
      greaterThan(tester.getTopLeft(cards.at(0)).dx),
    );
    expect(
      tester.getTopLeft(cards.at(2)).dy,
      greaterThan(tester.getTopLeft(cards.at(0)).dy),
    );
  });

  testWidgets('marks the selected agent with a selected semantics node', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && (widget.properties.selected ?? false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the default agent cannot be deleted from the list', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    // Only the non-default agent exposes a delete affordance.
    expect(find.text('Delete profile'), findsOneWidget);
    expect(find.text('New Profile'), findsOneWidget);
  });

  testWidgets('tapping Chat selects the profile client-side', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    final coderChat = find.widgetWithText(FilledButton, 'Chat').last;
    await tester.ensureVisible(coderChat);
    await tester.pumpAndSettle();
    await tester.tap(coderChat);
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['coder']);
  });

  testWidgets('failed profile selection is announced and remains recoverable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
      selectProfileFails: true,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();
    final coderChat = find.widgetWithText(FilledButton, 'Chat').last;
    await tester.ensureVisible(coderChat);
    await tester.pumpAndSettle();
    await tester.tap(coderChat);
    await tester.pumpAndSettle();

    final error = find.text('Hermes could not complete that profile change.');
    expect(error, findsOneWidget);
    expect(tester.getSemantics(error).flagsCollection.isLiveRegion, isTrue);
    expect(find.text('Coding Agent'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Chat opens the selected profile in chat', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.agents,
      routes: [
        GoRoute(
          path: AppRoutes.agents,
          builder: (_, _) => const ProfilesScreen(),
        ),
        GoRoute(
          path: AppRoutes.hermes,
          builder: (_, _) => const Scaffold(body: Text('Chat destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => directoryFor(
              configs: const [],
              loader: FakeGatewaySummaryLoader(const {}),
              activeChannel: channel,
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final coderChat = find.widgetWithText(FilledButton, 'Chat').last;
    await tester.ensureVisible(coderChat);
    await tester.pumpAndSettle();
    await tester.tap(coderChat);
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['coder']);
    expect(find.text('Chat destination'), findsOneWidget);
  });

  testWidgets('Android Back returns from profile chat to the profile list', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.agents,
      routes: [
        GoRoute(
          path: AppRoutes.agents,
          builder: (_, _) => const ProfilesScreen(),
        ),
        GoRoute(
          path: AppRoutes.hermes,
          builder: (_, _) => const Scaffold(body: Text('Chat destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => directoryFor(
              configs: const [],
              loader: FakeGatewaySummaryLoader(const {}),
              activeChannel: channel,
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Chat destination'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Profiles'), findsWidgets);
    expect(find.text('Coding Agent'), findsOneWidget);
  });

  testWidgets('rapid Chat taps push only one route', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.agents,
      routes: [
        GoRoute(
          path: AppRoutes.agents,
          builder: (_, _) => const ProfilesScreen(),
        ),
        GoRoute(
          path: AppRoutes.hermes,
          builder: (_, _) => const Scaffold(body: Text('Chat destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith(
            (ref) => directoryFor(
              configs: const [],
              loader: FakeGatewaySummaryLoader(const {}),
              activeChannel: channel,
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chat = find.widgetWithText(FilledButton, 'Chat');

    await tester.tap(chat);
    await tester.tap(chat, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Chat destination'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Profiles'), findsWidgets);
    expect(find.text('Hermes One'), findsOneWidget);
  });

  testWidgets('shows progress and blocks repeat taps while switching agents', (
    tester,
  ) async {
    final channel = _GatedProfileSelectionChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(() {
      if (!channel.selectionGate.isCompleted) channel.selectionGate.complete();
      channel.dispose();
    });

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    final coderChat = find.widgetWithText(FilledButton, 'Chat').last;
    await tester.scrollUntilVisible(coderChat, 300);
    await tester.tap(coderChat);
    await tester.pump();

    expect(channel.selectionAttempts, 1);
    expect(find.text('Switching…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Switching…'))
          .onPressed,
      isNull,
    );

    channel.selectionGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Switching…'), findsNothing);
    expect(channel.selectProfileCalls, ['coder']);
  });

  testWidgets('rename updates the visible display name', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Renamed Coder');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(channel.renameProfileCalls, [
      {'profileId': 'coder', 'name': 'Renamed Coder', 'revision': 'c'},
    ]);
    expect(find.text('Renamed Coder'), findsOneWidget);
  });

  testWidgets('retains content and actions at 200% text scale', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const [
        'profiles:read',
        'profiles:write',
      ]),
      profiles: const [
        HermesProfile(
          id: 'coder',
          displayName: 'Coding Agent',
          revision: 'c',
          skillsCount: 4,
        ),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_profilesTestApp(channel, textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Coding Agent'), findsOneWidget);
    expect(find.text('New Profile'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });
}
