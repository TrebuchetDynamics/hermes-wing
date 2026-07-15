import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/core/hermes/models/hermes_capabilities.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/providers/screens/providers_screen.dart';
import 'package:navivox/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

HermesCapabilityDocument _capabilities(List<String> scopes) =>
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
        'providers': {
          'method': 'GET',
          'path': '/api/providers',
          'required_scopes': ['providers:read'],
        },
        'provider_credential_set': {
          'method': 'PUT',
          'path': '/api/providers/{slug}/credential',
          'required_scopes': ['providers:write'],
        },
        'models': {
          'method': 'GET',
          'path': '/api/models',
          'required_scopes': ['models:read'],
        },
        'models_assignment': {
          'method': 'PUT',
          'path': '/api/models/assignment',
          'required_scopes': ['models:write'],
        },
      },
    });

const _openAiProvider = HermesProvider(
  slug: 'openai',
  label: 'OpenAI',
  authType: 'api_key',
  envVars: ['OPENAI_API_KEY'],
  configured: true,
  keyHint: '····ab12',
);

const _anthropicProvider = HermesProvider(
  slug: 'anthropic',
  label: 'Anthropic',
  authType: 'api_key',
  envVars: ['ANTHROPIC_API_KEY'],
);

HermesModelInventory _inventory() => HermesModelInventory(
  catalog: HermesModelCatalog.fromJson(const {
    'providers': {
      'openai': {
        'models': [
          {'id': 'gpt-5', 'description': 'Flagship'},
        ],
      },
      'anthropic': {
        'models': [
          {'id': 'claude-opus-4', 'description': 'Deep reasoning'},
        ],
      },
    },
  }),
  assignment: const HermesModelAssignment(
    activeProvider: 'openai',
    activeModel: 'gpt-5',
    revision: 'rev-models-1',
  ),
);

/// A [FakeHermesChannel] whose visible `providers`/`modelInventory` are
/// selected by whichever profile is currently `selectedProfileId`, keyed by
/// [providersByProfile]/[modelsByProfile]. The plain fake's lists are fixed
/// at construction and never change, which is not enough to prove
/// `ProvidersScreen` refetches and re-renders after a mid-session profile
/// switch.
class _ProfileSwitchingFakeChannel extends FakeHermesChannel {
  _ProfileSwitchingFakeChannel({
    required this.providersByProfile,
    required this.modelsByProfile,
    required HermesCapabilityDocument capabilities,
    required String selectedProfileId,
  }) : super(
         capabilities: capabilities,
         providers: providersByProfile[selectedProfileId] ?? const [],
         modelInventory: modelsByProfile[selectedProfileId],
         selectedProfileId: selectedProfileId,
       );

  final Map<String, List<HermesProvider>> providersByProfile;
  final Map<String, HermesModelInventory> modelsByProfile;

  @override
  HermesChannelState get state {
    final base = super.state;
    final profileId = base.selectedProfileId;
    return base.copyWith(
      providers: providersByProfile[profileId] ?? const [],
      modelInventory:
          modelsByProfile[profileId] ?? const HermesModelInventory(),
    );
  }
}

Widget _testApp(FakeHermesChannel channel, {double textScale = 1.0}) =>
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
        home: const ProvidersScreen(),
      ),
    );

void main() {
  testWidgets('loads providers and models on mount', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(const [
        'providers:read',
        'providers:write',
        'models:read',
        'models:write',
      ]),
      providers: const [_openAiProvider, _anthropicProvider],
      modelInventory: _inventory(),
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(channel.loadProvidersCalls, greaterThanOrEqualTo(1));
    expect(channel.loadModelsCalls, greaterThanOrEqualTo(1));
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('Anthropic'), findsOneWidget);
    // Presence badge from `configured`.
    expect(find.text('Configured'), findsWidgets);
    // Masked hint (never a full key).
    expect(find.textContaining('····ab12'), findsWidgets);
  });

  testWidgets(
    'reloads providers and models when the selected profile changes mid-session',
    (tester) async {
      final channel = _ProfileSwitchingFakeChannel(
        capabilities: _capabilities(const [
          'providers:read',
          'providers:write',
          'models:read',
          'models:write',
        ]),
        providersByProfile: {
          'profile-a': const [_openAiProvider],
          'profile-b': const [_anthropicProvider],
        },
        modelsByProfile: {'profile-a': _inventory(), 'profile-b': _inventory()},
        selectedProfileId: 'profile-a',
      );
      addTearDown(channel.dispose);

      await tester.pumpWidget(_testApp(channel));
      await tester.pumpAndSettle();

      expect(channel.loadProvidersCalls, 1);
      expect(channel.loadModelsCalls, 1);
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('Anthropic'), findsNothing);

      await channel.selectProfile('profile-b');
      await tester.pumpAndSettle();

      expect(channel.loadProvidersCalls, 2);
      expect(channel.loadModelsCalls, 2);
      expect(find.text('OpenAI'), findsNothing);
      expect(find.text('Anthropic'), findsOneWidget);
    },
  );

  testWidgets('write scopes expose mutation affordances', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(const [
        'providers:read',
        'providers:write',
        'models:read',
        'models:write',
      ]),
      providers: const [_openAiProvider],
      modelInventory: _inventory(),
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Manage credential'), findsWidgets);
    expect(find.text('Choose model'), findsOneWidget);
  });

  testWidgets('read-only token hides set/remove/validate', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(const ['providers:read', 'models:read']),
      providers: const [_openAiProvider],
      modelInventory: _inventory(),
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    // Provider presence is still visible.
    expect(find.text('OpenAI'), findsOneWidget);
    // But no write affordances anywhere.
    expect(find.text('Manage credential'), findsNothing);
    expect(find.text('Set'), findsNothing);
    expect(find.text('Remove'), findsNothing);
    expect(find.text('Validate'), findsNothing);
    expect(find.text('Choose model'), findsNothing);
  });

  testWidgets('model picker shows catalog and calls assignModel', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(const [
        'providers:read',
        'providers:write',
        'models:read',
        'models:write',
      ]),
      providers: const [_openAiProvider],
      modelInventory: _inventory(),
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose model'));
    await tester.pumpAndSettle();

    // The picker surfaces the catalog: the active provider's model is shown,
    // and the anthropic provider is selectable from the provider dropdown.
    expect(find.text('gpt-5'), findsWidgets);
    expect(find.byType(DropdownButtonFormField<String>), findsWidgets);

    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();

    expect(channel.assignModelCalls, isNotEmpty);
    expect(channel.assignModelCalls.first['revision'], 'rev-models-1');
  });

  testWidgets('shows a loading indicator while connecting', (tester) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.connecting,
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a connection error when the channel is in error', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.error,
      errorMessage: 'boom',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Providers could not be loaded from Hermes.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an unavailable message without provider access', (
    tester,
  ) async {
    final channel = FakeHermesChannel(capabilities: null);
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Providers unavailable'), findsOneWidget);
  });

  testWidgets('shows an empty state with read access but no providers', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(const ['providers:read']),
      providers: const [],
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('No providers available'), findsOneWidget);
  });

  testWidgets('retains content and actions at 200% text scale', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(const [
        'providers:read',
        'providers:write',
        'models:read',
        'models:write',
      ]),
      providers: const [_openAiProvider],
      modelInventory: _inventory(),
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('Manage credential'), findsWidgets);
    expect(find.text('Choose model'), findsOneWidget);
  });
}
