import 'dart:async';

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

const _errorJob = HermesJob(
  id: 'error',
  name: 'Failed task',
  enabled: false,
  state: 'error',
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

class _DeferredJobsChannel extends FakeHermesChannel {
  _DeferredJobsChannel(this.gate)
    : super(capabilities: _capabilities(), jobs: const [_morningJob]);

  final Completer<void> gate;

  @override
  Future<void> loadJobs() async {
    await gate.future;
    await super.loadJobs();
  }
}

void main() {
  testWidgets('old refresh cannot report failure after gateway roundtrip', (
    tester,
  ) async {
    final channel = _RacingJobsChannel();
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
    await tester.tap(find.byKey(const ValueKey('schedules-refresh-button')));
    await tester.pump();
    for (final label in ['Beta', 'Alpha']) {
      await tester.tap(find.byKey(const ValueKey('schedules-gateway-picker')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(milliseconds: 300));
    }
    final refresh = find.byKey(const ValueKey('schedules-refresh-button'));
    expect(tester.widget<IconButton>(refresh).onPressed, isNotNull);
    await tester.tap(refresh);
    await tester.pump();
    channel.gates.first.completeError(StateError('old refresh failure'));
    await tester.pump();
    expect(find.text('Scheduled jobs could not be refreshed.'), findsNothing);
    expect(tester.widget<IconButton>(refresh).onPressed, isNull);
    channel.gates.last.complete();
    await tester.pumpAndSettle();
  });
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

  testWidgets('renders errored jobs as errors even when disabled', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      jobs: const [_errorJob],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Failed task'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Disabled'), findsNothing);
  });

  testWidgets('refresh exposes labelled progress and blocks duplicate taps', (
    tester,
  ) async {
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    final channel = _DeferredJobsChannel(gate);
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    final refresh = find.byKey(const ValueKey('schedules-refresh-button'));
    await tester.tap(refresh);
    await tester.pump();

    expect(tester.widget<IconButton>(refresh).onPressed, isNull);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.descendant(
              of: refresh,
              matching: find.byType(CircularProgressIndicator),
            ),
          )
          .semanticsLabel,
      'Refreshing scheduled jobs',
    );

    gate.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(refresh).onPressed, isNotNull);
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
      refreshedJobs: const [_pausedJob],
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
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(channel.loadJobsCalls, 1);
    expect(find.text('Evening review'), findsOneWidget);
  });

  testWidgets('empty inventory offers an explicit refresh action', (
    tester,
  ) async {
    final channel = FakeHermesChannel(capabilities: _capabilities());
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('No schedules yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Refresh schedules'));
    await tester.pumpAndSettle();
    expect(channel.loadJobsCalls, 1);
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

  testWidgets('Schedules title renders once in the app bar', (tester) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      jobs: const [_morningJob],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();

    expect(find.text('Schedules'), findsOneWidget);
  });

  testWidgets('long schedule cards fit narrow screens at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const job = HermesJob(
      id: 'long-job',
      name: 'Long scheduled repository maintenance and review task',
      enabled: true,
      state: 'active',
      scheduleDisplay: 'Every weekday at 09:00 in the selected profile',
    );
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      jobs: const [job],
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(_testApp(channel, textScale: 2));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Long scheduled repository maintenance and review task'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final title = find.text(
      'Long scheduled repository maintenance and review task',
    );
    expect(title, findsOneWidget);
    expect(tester.widget<Text>(title).maxLines, isNull);
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

class _RacingJobsChannel extends FakeHermesChannel {
  _RacingJobsChannel() : super(capabilities: _capabilities());
  final gates = <Completer<void>>[];

  @override
  Future<void> loadJobs() {
    final gate = Completer<void>();
    gates.add(gate);
    return gate.future;
  }
}
