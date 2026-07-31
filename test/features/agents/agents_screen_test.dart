import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/agents/screens/agents_screen.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
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
  Future<void> selectProfile(String profileId) async {
    selectionAttempts += 1;
    await selectionGate.future;
    await super.selectProfile(profileId);
  }
}

Widget _agentsTestApp(
  FakeHermesChannel channel, {
  double textScale = 1.0,
  HermesGatewayDirectory? directory,
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
    home: const AgentsScreen(),
  ),
);

void main() {
  testWidgets(
    'disconnected channel shows a neutral select-gateway prompt, not the '
    'unavailable lock state',
    (tester) async {
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);

      await tester.pumpWidget(_agentsTestApp(channel));
      await tester.pumpAndSettle();

      expect(find.text('Select a gateway'), findsOneWidget);
      expect(find.text('Agents unavailable'), findsNothing);
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

    await tester.pumpWidget(_agentsTestApp(channel, directory: directory));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('agents-gateway-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(channel.connectCalls.single.baseUrl, 'https://b');
    expect(directory.activeContactId?.gatewayId, 'beta');
  });

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

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Agent'));
    await tester.pumpAndSettle();

    expect(find.text('Create agent'), findsOneWidget);
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

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Coding Agent'), findsOneWidget);
    expect(find.text('ID: coder'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('New Agent'), findsNothing);
    expect(find.text('Delete agent'), findsNothing);
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

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);
    expect(find.text('Delete agent'), findsOneWidget);
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

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Delete agent'), findsNothing);
  });

  testWidgets('shows a loading indicator while connecting', (tester) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.connecting,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pump();

    expect(find.byType(WingSkeletonList), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(WingSkeletonList)).label,
      contains('Loading agents'),
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

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Agents could not be loaded from Hermes.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an unavailable message without profile access', (
    tester,
  ) async {
    final channel = FakeHermesChannel(capabilities: null);
    addTearDown(channel.dispose);

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Agents unavailable'), findsOneWidget);
  });

  testWidgets('shows an empty state with read access but no agents', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _profileCapabilities(const ['profiles:read']),
      profiles: const [],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('No agents available'), findsOneWidget);
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

    await tester.pumpWidget(_agentsTestApp(channel));
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

    await tester.pumpWidget(_agentsTestApp(channel));
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

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pumpAndSettle();

    // Only the non-default agent exposes a delete affordance.
    expect(find.text('Delete agent'), findsOneWidget);
    expect(find.text('New Agent'), findsOneWidget);
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

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pumpAndSettle();

    final coderChat = find.widgetWithText(FilledButton, 'Chat').last;
    await tester.ensureVisible(coderChat);
    await tester.pumpAndSettle();
    await tester.tap(coderChat);
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['coder']);
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

    await tester.pumpWidget(_agentsTestApp(channel));
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

    await tester.pumpWidget(_agentsTestApp(channel));
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

    await tester.pumpWidget(_agentsTestApp(channel, textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Coding Agent'), findsOneWidget);
    expect(find.text('New Agent'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });
}
