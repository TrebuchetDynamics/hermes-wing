import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_skill.dart';
import 'package:wing/core/hermes/models/hermes_toolset.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/tools/screens/tools_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesCapabilityDocument _capabilities({
  bool skills = true,
  bool toolsets = true,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'auth': {'type': 'bearer', 'required': true},
  'endpoints': {
    if (skills) 'skills': {'method': 'GET', 'path': '/v1/skills'},
    if (toolsets) 'toolsets': {'method': 'GET', 'path': '/v1/toolsets'},
  },
});

Widget _testApp(
  FakeHermesChannel channel, {
  double textScale = 1,
  HermesGatewayDirectory? directory,
}) => ProviderScope(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
    if (directory != null)
      hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
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
    home: const ToolsScreen(),
  ),
);

void main() {
  testWidgets('shows advertised installed skills and enabled toolsets', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      skills: const ['browser-use', 'github'],
      enabledToolsets: const ['web', 'memory'],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Tools'), findsWidgets);
    expect(find.text('Installed skills'), findsOneWidget);
    expect(find.text('browser-use'), findsOneWidget);
    expect(find.text('github'), findsOneWidget);
    expect(find.text('Enabled toolsets'), findsOneWidget);
    expect(find.text('web'), findsOneWidget);
    expect(find.text('memory'), findsOneWidget);
  });

  testWidgets('shows and searches bounded installed skill metadata', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      skills: const ['browser-use', 'github'],
      skillDetails: const [
        HermesSkill(
          name: 'browser-use',
          description: 'Automate an approved browser session.',
          category: 'browser',
        ),
        HermesSkill(
          name: 'github',
          description: 'Work with source repositories.',
          category: 'development',
        ),
      ],
      enabledToolsets: const ['web'],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Automate an approved browser session.'), findsOneWidget);
    expect(find.text('browser'), findsOneWidget);
    expect(find.text('Work with source repositories.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('installed-skills-search')),
      'source',
    );
    await tester.pump();

    expect(find.text('github'), findsOneWidget);
    expect(find.text('browser-use'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('installed-skills-search')),
      'no-match',
    );
    await tester.pump();

    expect(find.text('No installed skills match this search.'), findsOneWidget);
  });

  testWidgets('shows and searches bounded resolved toolset metadata', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      toolsets: const [
        HermesToolset(
          name: 'default',
          label: 'Default Tools',
          description: 'Core file and terminal tools.',
          enabled: true,
          configured: true,
          tools: ['read_file', 'terminal'],
        ),
        HermesToolset(
          name: 'web',
          label: 'Web Tools',
          description: 'Search approved web sources.',
          tools: ['web_search'],
        ),
      ],
      enabledToolsets: const ['default'],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Toolsets'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Default Tools'), findsOneWidget);
    expect(find.text('Core file and terminal tools.'), findsOneWidget);
    expect(
      find.textContaining('Enabled · Configured · 2 resolved tools'),
      findsOneWidget,
    );
    expect(find.text('Web Tools'), findsOneWidget);
    expect(
      find.textContaining('Disabled · Not configured · 1 resolved tool'),
      findsOneWidget,
    );
    expect(find.byType(Switch), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('toolsets-search')),
      'web_search',
    );
    await tester.pump();
    expect(find.text('Web Tools'), findsOneWidget);
    expect(find.text('Default Tools'), findsNothing);

    await tester.tap(find.text('Web Tools'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Chip, 'web_search'), findsOneWidget);
  });

  testWidgets('gateway picker activates the selected saved gateway', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha',
          baseUrl: 'https://alpha',
        ),
        HermesEndpointConfig(
          id: 'beta',
          label: 'Beta',
          baseUrl: 'https://beta',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default']),
        'beta': gatewaySummary(['default']),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(_testApp(channel, directory: directory));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tools-gateway-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(directory.activeContactId?.gatewayId, 'beta');
    expect(channel.connectCalls.last.baseUrl, 'https://beta');
  });

  testWidgets('retains inventory at 200% text scale', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      skills: const ['browser-use'],
      skillDetails: const [
        HermesSkill(
          name: 'browser-use',
          description: 'Automate an approved browser session.',
          category: 'browser',
        ),
      ],
      toolsets: const [
        HermesToolset(
          name: 'web',
          label: 'Web Tools',
          description: 'Search and inspect approved public web sources.',
          enabled: true,
          configured: true,
          tools: ['web_search', 'web_open'],
        ),
      ],
      enabledToolsets: const ['web'],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('browser-use'), findsOneWidget);
    expect(find.text('Automate an approved browser session.'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Web Tools'), findsOneWidget);
    expect(find.textContaining('2 resolved tools'), findsOneWidget);
  });

  testWidgets('load failures are distinct and do not expose raw errors', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      skills: const ['stale-skill'],
      skillDetails: const [
        HermesSkill(
          name: 'stale-skill',
          description: 'private stale skill description',
        ),
      ],
      toolsets: const [
        HermesToolset(
          name: 'stale-toolset',
          description: 'private stale toolset description',
          enabled: true,
          tools: ['private_tool'],
        ),
      ],
      enabledToolsets: const ['stale-toolset'],
      optionalResourceErrors: const {
        HermesOptionalResource.skills: 'private skills transport failure',
        HermesOptionalResource.toolsets: 'private toolsets transport failure',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Installed skills could not be loaded from Hermes.'),
      findsOneWidget,
    );
    expect(
      find.text('Enabled toolsets could not be loaded from Hermes.'),
      findsOneWidget,
    );
    expect(find.textContaining('private'), findsNothing);
    expect(find.text('stale-skill'), findsNothing);
    expect(find.text('stale-toolset'), findsNothing);
  });

  testWidgets('declared catalog scopes must also be granted', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: HermesCapabilityDocument.fromJson({
        'schema_version': 1,
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': <String>[],
        },
        'endpoints': {
          'skills': {
            'method': 'GET',
            'path': '/v1/skills',
            'required_scopes': ['skills:read'],
          },
          'toolsets': {
            'method': 'GET',
            'path': '/v1/toolsets',
            'required_scopes': ['tools:read'],
          },
        },
      }),
      skills: const ['stale-skill'],
      skillDetails: const [HermesSkill(name: 'stale-skill')],
      enabledToolsets: const ['stale-toolset'],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('This gateway did not advertise installed skill inventory.'),
      findsOneWidget,
    );
    expect(
      find.text('This gateway did not advertise enabled toolset inventory.'),
      findsOneWidget,
    );
    expect(find.text('stale-skill'), findsNothing);
    expect(find.text('stale-toolset'), findsNothing);
  });

  testWidgets('unsupported inventories fail closed instead of looking empty', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(skills: false, toolsets: false),
      skills: const ['stale-skill'],
      skillDetails: const [
        HermesSkill(name: 'stale-skill', description: 'stale description'),
      ],
      enabledToolsets: const ['stale-toolset'],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('This gateway did not advertise installed skill inventory.'),
      findsOneWidget,
    );
    expect(
      find.text('This gateway did not advertise enabled toolset inventory.'),
      findsOneWidget,
    );
    expect(find.text('stale-skill'), findsNothing);
    expect(find.text('stale-toolset'), findsNothing);
  });

  testWidgets('the gateway helper is the only inventory scope description', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      skills: const ['browser-use'],
      enabledToolsets: const ['web'],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Installed skills and resolved toolsets advertised by this gateway.',
      ),
      findsNothing,
    );
  });
}
