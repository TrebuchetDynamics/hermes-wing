import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_job.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/schedules/screens/schedules_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import '../hermes_chat/support/fake_hermes_gateway_directory.dart';

HermesCapabilityDocument _capabilities({
  bool jobs = true,
  bool grantTasksRead = true,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': [if (grantTasksRead) 'tasks:read'],
  },
  'endpoints': {
    if (jobs)
      'jobs': {
        'method': 'GET',
        'path': '/api/jobs',
        'required_scopes': ['tasks:read'],
      },
  },
});

const _morningJob = HermesJob(
  id: 'morning',
  name: 'Morning check',
  enabled: true,
  state: 'active',
  scheduleDisplay: 'Daily at 09:00',
  nextRunAt: '2026-07-19T09:00:00Z',
  lastRunAt: '2026-07-18T09:00:00Z',
);

const _pausedJob = HermesJob(
  id: 'paused',
  name: 'Evening review',
  state: 'paused',
  scheduleDisplay: '0 18 * * *',
  lastError: 'private remote stack trace',
);

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
    home: const SchedulesScreen(),
  ),
);

void main() {
  testWidgets('shows advertised jobs as a read-only schedule inventory', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      jobs: const [_morningJob, _pausedJob],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Schedules'), findsWidgets);
    expect(find.text('Morning check'), findsOneWidget);
    expect(find.text('Daily at 09:00'), findsOneWidget);
    expect(find.text('Evening review'), findsOneWidget);
    expect(find.text('0 18 * * *'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Last run reported an error.'), findsOneWidget);
    expect(find.textContaining('private remote'), findsNothing);
    expect(find.textContaining('Read-only schedule inventory'), findsOneWidget);
    expect(find.text('New task'), findsNothing);
  });

  testWidgets('refresh reloads jobs through the advertised channel seam', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      jobs: const [_morningJob],
      refreshedJobs: const [_pausedJob],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedules-refresh-button')));
    await tester.pumpAndSettle();

    expect(channel.loadJobsCalls, 1);
    expect(find.text('Morning check'), findsNothing);
    expect(find.text('Evening review'), findsOneWidget);
  });

  testWidgets('unsupported schedule inventory fails closed', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(jobs: false),
      jobs: const [_morningJob],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('This gateway did not advertise scheduled-job inventory.'),
      findsOneWidget,
    );
    expect(find.text('Morning check'), findsNothing);
    expect(
      find.byKey(const ValueKey('schedules-refresh-button')),
      findsNothing,
    );
  });

  testWidgets('schedule inventory requires the granted tasks read scope', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(grantTasksRead: false),
      jobs: const [_morningJob],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('This gateway did not advertise scheduled-job inventory.'),
      findsOneWidget,
    );
    expect(find.text('Morning check'), findsNothing);
    expect(
      find.byKey(const ValueKey('schedules-refresh-button')),
      findsNothing,
    );
    expect(channel.loadJobsCalls, 0);
  });

  testWidgets('load failure is distinct and does not expose raw errors', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      jobs: const [_morningJob],
      optionalResourceErrors: const {
        HermesOptionalResource.jobs: 'private jobs transport failure',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(
      find.text('Schedules could not be loaded from Hermes.'),
      findsOneWidget,
    );
    expect(find.textContaining('private jobs'), findsNothing);
    expect(find.text('Morning check'), findsNothing);
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
    await tester.tap(find.byKey(const ValueKey('schedules-gateway-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    expect(directory.activeContactId?.gatewayId, 'beta');
    expect(channel.connectCalls.last.baseUrl, 'https://beta');
  });

  testWidgets('retains schedule content at 200% text scale', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      jobs: const [_morningJob],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Morning check'), findsOneWidget);
  });
}
