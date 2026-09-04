import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/soul/screens/soul_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

Widget _testApp(FakeHermesChannel channel) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(channel)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const SoulScreen(),
  ),
);

HermesCapabilityDocument _personaCapabilities({
  List<String> scopes = const ['profiles:read', 'profiles:write'],
  List<String> extraRequiredScopes = const [],
  bool includeProfileContext = true,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  if (includeProfileContext)
    'profile_context': {
      'type': 'query',
      'name': 'profile',
      'required': true,
      'default_profile_id': 'default',
    },
  'auth': {'type': 'bearer', 'required': true, 'granted_scopes': scopes},
  'endpoints': {
    'profile_soul': {
      'method': 'GET',
      'path': '/api/profiles/{name}/soul',
      'required_scopes': ['profiles:read', ...extraRequiredScopes],
    },
    'profile_soul_update': {
      'method': 'PUT',
      'path': '/api/profiles/{name}/soul',
      'required_scopes': ['profiles:write', ...extraRequiredScopes],
    },
  },
});

void main() {
  testWidgets('blocks the route when the SOUL contract is absent', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coder', revision: 'rev-1'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));

    expect(find.text('Profiles unavailable'), findsOneWidget);
    expect(find.text('Persona'), findsOneWidget);
    expect(channel.readProfileSoulCalls, isEmpty);
  });

  testWidgets('reuses the revision-aware profile persona editor', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _personaCapabilities(),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coder', revision: 'rev-1'),
      ],
      selectedProfileId: 'coder',
      profileSoul: const HermesProfileSoul(
        soul: 'You are a careful coding assistant.',
        revision: 'soul-rev-1',
      ),
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Coder persona'), findsOneWidget);
    expect(find.text('You are a careful coding assistant.'), findsOneWidget);
    expect(channel.readProfileSoulCalls, ['coder']);

    await tester.enterText(find.byType(TextFormField), 'Updated persona');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(channel.writeProfileSoulCalls, [
      {
        'profileId': 'coder',
        'soul': 'Updated persona',
        'revision': 'soul-rev-1',
      },
    ]);
  });

  testWidgets('blocks default persona without profile query context', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _personaCapabilities(includeProfileContext: false),
      profiles: const [
        HermesProfile(id: 'default', displayName: 'Default', revision: 'rev-1'),
      ],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));

    expect(find.text('Profiles unavailable'), findsOneWidget);
    expect(channel.readProfileSoulCalls, isEmpty);
  });

  testWidgets('requires both persona scopes before loading SOUL', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _personaCapabilities(scopes: const ['profiles:read']),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coder', revision: 'rev-1'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));

    expect(find.text('Profiles unavailable'), findsOneWidget);
    expect(channel.readProfileSoulCalls, isEmpty);
  });

  testWidgets('requires every declared SOUL endpoint scope', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _personaCapabilities(
        extraRequiredScopes: const ['profiles:admin'],
      ),
      profiles: const [
        HermesProfile(id: 'coder', displayName: 'Coder', revision: 'rev-1'),
      ],
      selectedProfileId: 'coder',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));

    expect(find.text('Profiles unavailable'), findsOneWidget);
    expect(channel.readProfileSoulCalls, isEmpty);
  });
}
