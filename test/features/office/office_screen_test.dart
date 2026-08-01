import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/office/screens/office_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

GatewaySummary _summary({
  required String id,
  required String name,
  String? preview,
}) => GatewaySummary(
  profiles: [HermesProfile(id: id, displayName: name, revision: 'r-$id')],
  sessionsByProfile: {
    id: [
      HermesSession(
        id: 'session-$id',
        source: 'test',
        title: 'Private session title',
        preview: preview,
        lastActive: '2026-07-16T12:00:00Z',
      ),
    ],
  },
);

class _FailingOfficeChannel extends FakeHermesChannel {
  _FailingOfficeChannel() : super(status: HermesConnectionStatus.disconnected);

  @override
  Future<void> connect({required String baseUrl, String? apiKey}) async {
    throw StateError('private office transport failure');
  }
}

Widget _testApp({
  required FakeHermesChannel channel,
  required HermesGatewayDirectory directory,
  double textScale = 1,
}) => ProviderScope(
  overrides: [
    hermesChannelProvider.overrideWithValue(channel),
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
    home: const OfficeScreen(),
  ),
);

void main() {
  testWidgets(
    'shows searchable authoritative gateway agents without previews',
    (tester) async {
      final channel = FakeHermesChannel.disconnected();
      addTearDown(channel.dispose);
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(
            id: 'alpha',
            label: 'Alpha Gateway',
            baseUrl: 'https://alpha',
          ),
          HermesEndpointConfig(
            id: 'beta',
            label: 'Beta Gateway',
            baseUrl: 'https://beta',
          ),
        ],
        loader: FakeGatewaySummaryLoader({
          'alpha': _summary(
            id: 'alice',
            name: 'Alice',
            preview: 'private office preview sentinel',
          ),
          'beta': _summary(id: 'bob', name: 'Bob'),
        }),
        activeChannel: channel,
      );
      await directory.refresh();

      await tester.pumpWidget(_testApp(channel: channel, directory: directory));
      await tester.pumpAndSettle();

      expect(find.text('Office'), findsWidgets);
      expect(find.text('2 agents'), findsWidgets);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Alpha Gateway'), findsOneWidget);
      expect(find.text('Beta Gateway'), findsOneWidget);
      expect(find.text('1 session'), findsNWidgets(2));
      expect(
        find.textContaining('private office preview sentinel'),
        findsNothing,
      );
      expect(find.textContaining('Private session title'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('office-agent-search')),
        'beta',
      );
      await tester.pump();

      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Showing 1 of 2 agents'), findsOneWidget);
    },
  );

  testWidgets('fallback default contact remains usable at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'legacy',
          label: 'Legacy Gateway',
          baseUrl: 'https://legacy',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'legacy': const GatewaySummary(
          profiles: [],
          sessionsByProfile: {},
          unscopedSessions: [
            HermesSession(id: 'legacy-session', source: 'test'),
          ],
        ),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(
      _testApp(channel: channel, directory: directory, textScale: 2),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byKey(const ValueKey('office-agent-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Default agent'), findsOneWidget);
    expect(find.text('Gateway default contact'), findsOneWidget);
    expect(find.text('1 session'), findsWidgets);
    expect(find.textContaining('Wallet'), findsNothing);
    expect(find.textContaining('Account'), findsNothing);
  });

  testWidgets('open failure is bounded and keeps the Office available', (
    tester,
  ) async {
    final channel = _FailingOfficeChannel();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha Gateway',
          baseUrl: 'https://alpha',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': _summary(id: 'alice', name: 'Alice'),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(_testApp(channel: channel, directory: directory));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('office-open-alpha-alice')));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not open this Hermes agent. Refresh and try again.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('private office transport failure'),
      findsNothing,
    );
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('open chat activates the selected gateway agent', (tester) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha Gateway',
          baseUrl: 'https://alpha',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': _summary(id: 'alice', name: 'Alice'),
      }),
      activeChannel: channel,
    );
    await directory.refresh();
    final router = GoRouter(
      initialLocation: AppRoutes.office,
      routes: [
        GoRoute(
          path: AppRoutes.office,
          builder: (context, state) => const OfficeScreen(),
        ),
        GoRoute(
          path: AppRoutes.hermes,
          builder: (context, state) =>
              const Text('Chat destination', key: ValueKey('chat-destination')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('office-open-alpha-alice')));
    await tester.pumpAndSettle();

    expect(channel.connectCalls.single.baseUrl, 'https://alpha');
    expect(channel.selectProfileCalls, ['alice']);
    expect(
      directory.activeContactId,
      const GatewayContactId(gatewayId: 'alpha', profileId: 'alice'),
    );
    expect(find.byKey(const ValueKey('chat-destination')), findsOneWidget);
  });

  testWidgets('the Office title and agent count each render once', (
    tester,
  ) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [
        HermesEndpointConfig(
          id: 'alpha',
          label: 'Alpha Gateway',
          baseUrl: 'https://alpha',
        ),
      ],
      loader: FakeGatewaySummaryLoader({
        'alpha': _summary(id: 'alice', name: 'Alice'),
      }),
      activeChannel: channel,
    );
    await directory.refresh();

    await tester.pumpWidget(_testApp(channel: channel, directory: directory));
    await tester.pumpAndSettle();

    expect(find.text('Office'), findsOneWidget);
    expect(find.text('1 agent'), findsOneWidget);
  });
}
