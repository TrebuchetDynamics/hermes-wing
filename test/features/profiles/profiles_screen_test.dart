import 'dart:async';

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
      var wingLinkCalls = 0;

      await tester.pumpWidget(
        _profilesTestApp(
          channel,
          directory: directory,
          wingLinkClientBuilder: ({required origin, required token}) =>
              WingLinkClient(
                origin: origin,
                token: token,
                get: (_, _) async {
                  wingLinkCalls++;
                  return '''{"profiles":[{"id":"link","name":"Link","topology_revision":"top-1","source":"cli","gateway_state":"running","actions":{"rename":{"revision":"rev-1"},"delete":{"revision":"rev-1"}}}]}''';
                },
              ),
        ),
      );
      await tester.pumpAndSettle();

      expect(wingLinkCalls, 1);
      expect(find.text('Profiles unavailable'), findsNothing);
      expect(find.text('Link'), findsOneWidget);
      expect(find.text('New Profile'), findsOneWidget);
    },
  );

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
          ),
          HermesEndpointConfig(
            id: 'link-endpoint',
            label: 'Alpha · link',
            baseUrl: 'https://a.example:8642/p/link',
            apiKey: 'link-secret',
            wingLinkOrigin: 'https://a.example:8654',
            wingLinkToken: 'wlc-secret',
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
          wingLinkClientBuilder: ({required origin, required token}) =>
              WingLinkClient(
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
          ),
          HermesEndpointConfig(
            id: 'link-endpoint',
            label: 'Alpha · link',
            baseUrl: 'https://a.example:8642/p/link',
            apiKey: 'link-secret',
            wingLinkOrigin: 'https://a.example:8654',
            wingLinkToken: 'wlc-secret',
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
          wingLinkClientBuilder: ({required origin, required token}) =>
              WingLinkClient(
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
        wingLinkClientBuilder: ({required origin, required token}) =>
            WingLinkClient(
              origin: origin,
              token: token,
              get: (_, _) async {
                listCalls++;
                return '''{"profiles":[{"id":"link","name":"link","topology_revision":"rev-$listCalls","source":"cli","gateway_state":"running","actions":{"rename":{"revision":"rev-$listCalls"},"delete":{"revision":"rev-$listCalls"}}}]}''';
              },
              patch: (_, _, _) async =>
                  throw const WingLinkException('Wing Link HTTP 412'),
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
        wingLinkClientBuilder: ({required origin, required token}) =>
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
          wingLinkClientBuilder: ({required origin, required token}) =>
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
