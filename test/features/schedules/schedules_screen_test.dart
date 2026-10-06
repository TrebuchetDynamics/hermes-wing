import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
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
  HermesChannel channel, {
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
  final search = find.byKey(const ValueKey('schedules-search'));
  final clear = find.byKey(const ValueKey('schedules-clear-filters'));
  Finder filter(String label) => find.widgetWithText(ChoiceChip, label);

  testWidgets(
    'search ignores undisplayed metadata and keeps literal characters',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _capabilities(),
        jobs: [
          HermesJob(
            id: 'bounded',
            name: '${'x' * 120}hidden_name',
            scheduleDisplay: '${'y' * 160}hidden_schedule',
          ),
          const HermesJob(
            id: 'literal',
            name: 'Review [weekly]',
            enabled: true,
          ),
        ],
      );
      addTearDown(channel.dispose);
      await tester.pumpWidget(_testApp(channel));
      await tester.pumpAndSettle();
      for (final query in ['hidden_name', 'hidden_schedule']) {
        await tester.enterText(search, query);
        await tester.pumpAndSettle();
        expect(find.text('No matching schedules'), findsOneWidget);
      }
      await tester.enterText(search, '[WEEKLY]');
      await tester.pumpAndSettle();
      expect(find.text('Review [weekly]'), findsOneWidget);
      expect(channel.loadJobsCalls, 0);
    },
  );

  testWidgets('clear restores existing enabled/next-run/name ordering', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      jobs: const [
        _pausedJob,
        HermesJob(
          id: 'later',
          name: 'A later check',
          enabled: true,
          nextRunAt: '2026-07-20T09:00:00Z',
        ),
        _morningJob,
        _errorJob,
      ],
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();
    await tester.enterText(search, 'check');
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Morning check')).dy,
      lessThan(tester.getTopLeft(find.text('A later check')).dy),
    );
    await tester.tap(clear);
    await tester.pumpAndSettle();
    final cards = tester.widgetList<Card>(find.byType(Card)).toList();
    expect(cards, hasLength(4));
    for (var i = 0; i < cards.length; i++) {
      expect(
        find.descendant(
          of: find.byWidget(cards[i]),
          matching: find.text(
            [
              'Morning check',
              'A later check',
              'Evening review',
              'Failed task',
            ][i],
          ),
        ),
        findsOneWidget,
      );
    }
    expect(channel.loadJobsCalls, 0);
  });

  for (final fails in [false, true]) {
    testWidgets(
      'old jobs ${fails ? 'failure' : 'success'} cannot return after owner change',
      (tester) async {
        final pending = Completer<String>();
        var defer = false;
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              if (uri.path == '/api/jobs') {
                if (defer) {
                  defer = false;
                  return pending.future;
                }
                return jsonEncode({
                  'jobs': [
                    {
                      'id': uri.port == 8642 ? 'morning' : 'new-owner',
                      'name': uri.port == 8642
                          ? 'Morning check'
                          : 'New owner task',
                      'enabled': true,
                    },
                  ],
                });
              }
              return switch (uri.path) {
                '/health' => '{"status":"ok"}',
                '/v1/capabilities' =>
                  '{"schema_version":1,"auth":{"type":"bearer","required":true,"granted_scopes":["tasks:read"]},"endpoints":{"jobs":{"method":"GET","path":"/api/jobs","required_scopes":["tasks:read"]}}}',
                '/api/sessions' => '{"data":[]}',
                _ => throw StateError('unexpected read route'),
              };
            },
          ),
        );
        addTearDown(channel.dispose);
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        expect(channel.state.status, HermesConnectionStatus.connected);
        await tester.pumpWidget(_testApp(channel));
        await tester.pumpAndSettle();
        await tester.enterText(search, 'morning');
        await tester.tap(filter('Disabled'));
        defer = true;
        await tester.tap(
          find.byKey(const ValueKey('schedules-refresh-button')),
        );
        await tester.pump();
        await channel.connect(baseUrl: 'http://127.0.0.1:8643');
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(search).controller!.text, isEmpty);
        expect(tester.widget<ChoiceChip>(filter('All')).selected, isTrue);
        expect(find.text('New owner task'), findsOneWidget);
        if (fails) {
          pending.completeError(StateError('obsolete jobs failure'));
        } else {
          pending.complete('{"jobs":[{"id":"old","name":"Old owner task"}]}');
        }
        await tester.pumpAndSettle();
        expect(find.text('New owner task'), findsOneWidget);
        expect(find.text('Old owner task'), findsNothing);
        expect(
          find.text('Schedules could not be loaded from Hermes.'),
          findsNothing,
        );
        expect(channel.state.jobs.single.id, 'new-owner');
      },
    );
  }

  testWidgets('literal local search matches displayed name, ID and schedule', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      capabilities: _capabilities(),
      jobs: const [_morningJob, _pausedJob, _errorJob],
    );
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();
    for (final query in ['mOrNiNg CHECK', 'MORNING', 'dAiLy AT']) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(find.text('Morning check'), findsOneWidget);
      expect(find.text('Evening review'), findsNothing);
    }
    await tester.enterText(search, 'PAUSED');
    await tester.pumpAndSettle();
    expect(find.text('Evening review'), findsOneWidget);
    expect(find.text('Morning check'), findsNothing);
    for (final query in ['private remote', '.*', '[']) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(find.text('No matching schedules'), findsOneWidget);
      expect(find.text('No schedules yet'), findsNothing);
      expect(find.byType(Card), findsNothing);
    }
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(find.text('Morning check'), findsOneWidget);
    expect(tester.widget<TextButton>(clear).onPressed, isNotNull);
    expect(tester.widget<TextButton>(clear).focusNode!.hasFocus, isTrue);
    await tester.tap(clear);
    await tester.enterText(search, 'DAILY');
    await tester.pumpAndSettle();
    expect(find.text('Morning check'), findsOneWidget);
    expect(find.text('Evening review'), findsNothing);
    expect(channel.loadJobsCalls, 0);
    expect(channel.connectCalls, isEmpty);
    expect(channel.selectProfileCalls, isEmpty);
    expect(channel.createSessionCalls, isEmpty);
    expect(channel.sentTextAttachments, isEmpty);
    expect(channel.stopActiveTurnCalls, 0);
  });

  testWidgets(
    'enabled filtering combines with search without changing status',
    (tester) async {
      const enabledError = HermesJob(
        id: 'enabled-error',
        name: 'Enabled failure',
        enabled: true,
        state: 'error',
      );
      const enabledPaused = HermesJob(
        id: 'enabled-paused',
        name: 'Enabled pause',
        enabled: true,
        state: 'paused',
      );
      final channel = FakeHermesChannel(
        capabilities: _capabilities(),
        jobs: const [
          _morningJob,
          _pausedJob,
          _errorJob,
          enabledError,
          enabledPaused,
        ],
      );
      addTearDown(channel.dispose);
      await tester.pumpWidget(_testApp(channel));
      await tester.pumpAndSettle();
      await tester.tap(filter('Enabled'));
      await tester.enterText(search, 'enabled-');
      await tester.pumpAndSettle();
      expect(find.text('Enabled failure'), findsOneWidget);
      expect(find.text('Enabled pause'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(filter('Disabled'));
      await tester.pumpAndSettle();
      expect(find.text('No matching schedules'), findsOneWidget);
      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      expect(find.text('Evening review'), findsOneWidget);
      expect(find.text('Failed task'), findsOneWidget);
      expect(find.text('Enabled failure'), findsNothing);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(filter('All')).selected, isTrue);
      expect(channel.loadJobsCalls, 0);
    },
  );

  testWidgets(
    'same-owner refresh preserves filters; gateway and profile reset',
    (tester) async {
      final channel = _InventoryChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_testApp(channel));
      await tester.pumpAndSettle();
      await tester.enterText(search, 'morning');
      await tester.tap(filter('Disabled'));
      await tester.tap(find.byKey(const ValueKey('schedules-refresh-button')));
      await tester.pumpAndSettle();
      expect(channel.loadJobsCalls, 1);
      expect(tester.widget<TextField>(search).controller!.text, 'morning');
      expect(tester.widget<ChoiceChip>(filter('Disabled')).selected, isTrue);
      channel.emit(channel.state.copyWith(capabilities: _capabilities()));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, 'morning');
      expect(tester.widget<ChoiceChip>(filter('Disabled')).selected, isTrue);
      for (final next in [
        channel.state.copyWith(connectedBaseUrl: 'https://other.invalid'),
        channel.state.copyWith(selectedProfileId: 'writer'),
      ]) {
        channel.emit(next);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(search).controller!.text, isEmpty);
        expect(tester.widget<ChoiceChip>(filter('All')).selected, isTrue);
        await tester.enterText(search, 'morning');
        await tester.tap(filter('Disabled'));
      }
    },
  );

  testWidgets(
    'refresh replaces matching inventory while preserving query/filter',
    (tester) async {
      final channel = FakeHermesChannel(
        capabilities: _capabilities(),
        jobs: const [_morningJob, _pausedJob],
        refreshedJobs: const [
          HermesJob(id: 'weekly', name: 'Weekly review', state: 'paused'),
        ],
      );
      addTearDown(channel.dispose);
      await tester.pumpWidget(_testApp(channel));
      await tester.pumpAndSettle();
      await tester.enterText(search, 'REVIEW');
      await tester.tap(filter('Disabled'));
      await tester.pumpAndSettle();
      expect(find.text('Evening review'), findsOneWidget);
      expect(channel.loadJobsCalls, 0);
      await tester.tap(find.byKey(const ValueKey('schedules-refresh-button')));
      await tester.pumpAndSettle();
      expect(find.text('Weekly review'), findsOneWidget);
      expect(find.text('Evening review'), findsNothing);
      expect(tester.widget<TextField>(search).controller!.text, 'REVIEW');
      expect(tester.widget<ChoiceChip>(filter('Disabled')).selected, isTrue);
      expect(channel.loadJobsCalls, 1);
    },
  );

  testWidgets(
    'authority loss hides stale matches and controls; empty is distinct',
    (tester) async {
      final channel = _InventoryChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(_testApp(channel));
      await tester.pumpAndSettle();
      final connected = channel.state;
      await tester.enterText(search, 'morning');
      for (final next in [
        connected.copyWith(capabilities: _capabilities(jobs: false)),
        connected.copyWith(capabilities: _capabilities(grantTasksRead: false)),
        connected.copyWith(status: HermesConnectionStatus.disconnected),
        connected.copyWith(status: HermesConnectionStatus.connecting),
        connected.copyWith(
          optionalResourceErrors: {
            HermesOptionalResource.jobs: 'private diagnostics',
          },
        ),
      ]) {
        channel.emit(next);
        await tester.pump();
        expect(search, findsNothing);
        expect(clear, findsNothing);
        expect(filter('All'), findsNothing);
        expect(find.text('Morning check'), findsNothing);
        expect(find.text('No matching schedules'), findsNothing);
      }
      channel.emit(connected.copyWith(jobs: []));
      await tester.pumpAndSettle();
      expect(find.text('No schedules yet'), findsOneWidget);
      expect(find.text('No matching schedules'), findsNothing);
      expect(channel.loadJobsCalls, 0);
    },
  );

  for (final width in [390.0, 1280.0]) {
    testWidgets('search/filter/clear keyboard semantics fit $width at 200%', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel(
        capabilities: _capabilities(),
        jobs: const [_morningJob, _pausedJob],
      );
      addTearDown(channel.dispose);
      await tester.pumpWidget(_testApp(channel, textScale: 2));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Search schedules'), findsOneWidget);
      await tester.enterText(search, 'missing');
      await tester.pumpAndSettle();
      await tester.ensureVisible(filter('Disabled'));
      Focus.of(tester.element(find.text('Disabled').first)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(filter('Disabled')).selected, isTrue);
      await tester.ensureVisible(clear);
      Focus.of(tester.element(find.text('Clear filters'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        search,
        -150,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(tester.widget<ChoiceChip>(filter('All')).selected, isTrue);
      expect(tester.takeException(), isNull);
      expect(channel.loadJobsCalls, 0);
      semantics.dispose();
    });
  }

  for (final initiallyEmpty in [false, true]) {
    testWidgets(
      'pull refresh reloads ${initiallyEmpty ? "empty" : "short"} inventory',
      (tester) async {
        final channel = FakeHermesChannel(
          capabilities: _capabilities(),
          jobs: initiallyEmpty ? const [] : const [_morningJob],
          refreshedJobs: const [_pausedJob],
        );
        addTearDown(channel.dispose);
        await tester.pumpWidget(_testApp(channel));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, 350));
        await tester.pumpAndSettle();

        expect(channel.loadJobsCalls, 1);
        expect(find.text('Evening review'), findsOneWidget);
        expect(find.text('Morning check'), findsNothing);
      },
    );
  }

  testWidgets('pull refresh cannot overlap a button refresh', (tester) async {
    final channel = _RacingJobsChannel();
    addTearDown(channel.dispose);
    await tester.pumpWidget(_testApp(channel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedules-refresh-button')));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(channel.gates, hasLength(1));
    channel.gates.single.complete();
    await tester.pumpAndSettle();
  });

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
    expect(
      find.descendant(of: find.byType(Card), matching: find.text('Disabled')),
      findsNothing,
    );
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
    expect(find.byType(RefreshIndicator), findsNothing);
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
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
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

class _InventoryChannel extends FakeHermesChannel {
  _InventoryChannel()
    : super(capabilities: _capabilities(), jobs: const [_morningJob]);

  HermesChannelState? _snapshot;

  @override
  HermesChannelState get state => _snapshot ?? super.state;

  void emit(HermesChannelState next) {
    _snapshot = next;
    notifyListeners();
  }
}
