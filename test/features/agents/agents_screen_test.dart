import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel_state.dart';
import 'package:navivox/core/hermes/models/hermes_capabilities.dart';
import 'package:navivox/core/hermes/models/hermes_profile.dart';
import 'package:navivox/features/agents/screens/agents_screen.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

HermesCapabilityDocument _profileCapabilities(List<String> scopes) =>
    HermesCapabilityDocument.fromJson({
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
          'path': '/api/profiles/{profile_id}',
          'required_scopes': ['profiles:write'],
        },
        'profile_delete': {
          'method': 'DELETE',
          'path': '/api/profiles/{profile_id}',
          'required_scopes': ['profiles:write'],
        },
      },
    });

Widget _agentsTestApp(FakeHermesChannel channel, {double textScale = 1.0}) =>
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
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

  testWidgets('shows a loading indicator while connecting', (tester) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.connecting,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_agentsTestApp(channel));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(CircularProgressIndicator)).label,
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
