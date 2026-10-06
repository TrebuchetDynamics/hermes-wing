import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_job.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/schedules/screens/schedules_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

const _searchKey = ValueKey('schedules-search');
const _refreshKey = ValueKey('schedules-refresh-button');
const _failure = 'Schedules could not be loaded from Hermes.';
const _jobs = [
  HermesJob(id: 'morning', name: 'Morning check', enabled: true),
  HermesJob(id: 'evening', name: 'Evening review', enabled: false),
];

HermesCapabilityDocument _capabilities({
  bool granted = true,
  bool jobs = true,
}) => HermesCapabilityDocument.fromJson({
  'schema_version': 1,
  'auth': {
    'type': 'bearer',
    'required': true,
    'granted_scopes': [if (granted) 'tasks:read'],
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

class _Channel extends FakeHermesChannel {
  _Channel({HermesChannelState? initial})
    : current =
          initial ??
          HermesChannelState(
            status: HermesConnectionStatus.connected,
            connectedBaseUrl: 'https://agent.invalid',
            selectedProfileId: 'default',
            capabilities: _capabilities(),
            jobs: _jobs,
          );

  HermesChannelState current;
  final gates = <Completer<void>>[];
  @override
  HermesChannelState get state => current;

  void emit(HermesChannelState next) {
    current = next;
    notifyListeners();
  }

  @override
  Future<void> loadJobs() {
    loadJobsCalls++;
    final gate = Completer<void>();
    gates.add(gate);
    return gate.future;
  }
}

class _Harness {
  _Harness(this.channel) {
    container = ProviderContainer(
      overrides: [hermesChannelProvider.overrideWith((ref) => channel)],
    );
  }
  _Channel channel;
  late final ProviderContainer container;

  void replace(_Channel next) {
    channel = next;
    container.invalidate(hermesChannelProvider);
    // Evaluate the actual provider transition without waiting for a frame.
    expect(container.read(hermesChannelProvider), same(next));
  }

  Widget app({double scale = 1}) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: const SchedulesScreen(),
    ),
  );
}

VoidCallback _button(WidgetTester tester) =>
    tester.widget<IconButton>(find.byKey(_refreshKey)).onPressed!;
Future<void> Function() _pull(WidgetTester tester) =>
    tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh;
String _query(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(_searchKey)).controller!.text;
Finder _filter(String label) => find.widgetWithText(ChoiceChip, label);

HermesChannelState _transition(String kind, HermesChannelState state) =>
    switch (kind) {
      'host' => state.copyWith(connectedBaseUrl: 'https://other.invalid'),
      'profile' => state.copyWith(selectedProfileId: 'writer'),
      'selecting' => state.copyWith(isSelectingProfile: true),
      'disconnect' => state.copyWith(
        status: HermesConnectionStatus.disconnected,
      ),
      'grant' => state.copyWith(capabilities: _capabilities(granted: false)),
      'operation' => state.copyWith(capabilities: _capabilities(jobs: false)),
      _ => throw StateError('unknown deterministic transition'),
    };

void main() {
  for (final action in ['button', 'pull']) {
    testWidgets('cached $action rejected on replacement before rebuild', (
      tester,
    ) async {
      final old = _Channel();
      final next = _Channel(initial: old.state);
      final harness = _Harness(old);
      addTearDown(harness.container.dispose);
      addTearDown(old.dispose);
      addTearDown(next.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      final button = _button(tester);
      final pull = _pull(tester);
      harness.replace(next);
      if (action == 'button') {
        button();
      } else {
        final done = pull();
        expect(old.loadJobsCalls, 0);
        expect(next.loadJobsCalls, 0);
        await done;
      }
      expect(old.loadJobsCalls, 0);
      expect(next.loadJobsCalls, 0);
      await tester.pumpAndSettle();
      _button(tester)();
      next.gates.single.complete();
      await tester.pumpAndSettle();
    });
  }

  for (final fails in [false, true]) {
    testWidgets(
      'old completion $fails cannot restore replacement failed inventory',
      (tester) async {
        final old = _Channel();
        final next = _Channel(initial: old.state);
        final harness = _Harness(old);
        addTearDown(harness.container.dispose);
        addTearDown(old.dispose);
        addTearDown(next.dispose);
        await tester.pumpWidget(harness.app());
        await tester.pumpAndSettle();
        _button(tester)();
        harness.replace(next);
        await tester.pump();
        _button(tester)();
        next.gates.single.completeError(StateError('current private failure'));
        await tester.pumpAndSettle();
        expect(find.text(_failure), findsOneWidget);
        if (fails) {
          old.gates.single.completeError(
            StateError('obsolete private failure'),
          );
        } else {
          old.gates.single.complete();
        }
        await tester.pumpAndSettle();
        expect(find.text(_failure), findsOneWidget);
        expect(find.text('Morning check'), findsNothing);
        expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
        next.gates.last.complete();
        await tester.pumpAndSettle();
        expect(find.text('Morning check'), findsOneWidget);
      },
    );
  }

  testWidgets('disposed Retry cannot issue a read', (tester) async {
    final channel = _Channel();
    final harness = _Harness(channel);
    addTearDown(harness.container.dispose);
    addTearDown(channel.dispose);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    _button(tester)();
    channel.gates.single.completeError(StateError('current private failure'));
    await tester.pumpAndSettle();
    final retry = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Retry'))
        .onPressed!;
    await tester.pumpWidget(const SizedBox());
    retry();
    await tester.pumpAndSettle();
    expect(channel.loadJobsCalls, 1);
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets('identical-ID replacement fences old completion $fails', (
      tester,
    ) async {
      final old = _Channel();
      final next = _Channel(
        initial: old.state,
      ); // Shares the capability object.
      final harness = _Harness(old);
      addTearDown(harness.container.dispose);
      addTearDown(old.dispose);
      addTearDown(next.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_searchKey), 'morning');
      await tester.tap(_filter('Disabled'));
      final cached = _button(tester);
      cached();
      await tester.pump();
      expect(old.loadJobsCalls, 1);
      harness.replace(next);
      await tester.pump();
      expect(_query(tester), isEmpty);
      expect(tester.widget<ChoiceChip>(_filter('All')).selected, isTrue);
      expect(
        tester.widget<IconButton>(find.byKey(_refreshKey)).onPressed,
        isNotNull,
      );
      expect(find.text('Morning check'), findsOneWidget);
      cached();
      expect(old.loadJobsCalls, 1);
      expect(next.loadJobsCalls, 0);
      _button(tester)();
      await tester.pump();
      expect(next.loadJobsCalls, 1);
      if (fails) {
        old.gates.single.completeError(StateError('obsolete private failure'));
      } else {
        old.gates.single.complete();
      }
      await tester.pump();
      expect(find.text(_failure), findsNothing);
      expect(
        tester.widget<IconButton>(find.byKey(_refreshKey)).onPressed,
        isNull,
      );
      expect(find.text('Morning check'), findsOneWidget);
      next.gates.single.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(find.byKey(_refreshKey)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'replacement clears failed owner and stale Retry before rebuild',
    (tester) async {
      final old = _Channel();
      final next = _Channel(initial: old.state);
      final harness = _Harness(old);
      addTearDown(harness.container.dispose);
      addTearDown(old.dispose);
      addTearDown(next.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(_searchKey), 'morning');
      await tester.tap(_filter('Disabled'));
      _button(tester)();
      old.gates.single.completeError(StateError('sanitized transport failure'));
      await tester.pumpAndSettle();
      final retry = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Retry'))
          .onPressed!;
      harness.replace(next);
      retry();
      expect(old.loadJobsCalls, 1);
      expect(next.loadJobsCalls, 0);
      await tester.pumpAndSettle();
      expect(find.text(_failure), findsNothing);
      expect(_query(tester), isEmpty);
      expect(tester.widget<ChoiceChip>(_filter('All')).selected, isTrue);
      expect(find.text('Morning check'), findsOneWidget);
      _button(tester)();
      next.gates.single.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('A B A replacement before rebuild loses controls and callbacks', (
    tester,
  ) async {
    final a = _Channel();
    final b = _Channel(initial: a.state);
    final harness = _Harness(a);
    addTearDown(harness.container.dispose);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(_searchKey), 'morning');
    await tester.tap(_filter('Disabled'));
    final button = _button(tester);
    final pull = _pull(tester);
    harness.replace(b);
    harness.replace(a);
    button();
    await pull();
    expect(a.loadJobsCalls, 0);
    expect(b.loadJobsCalls, 0);
    await tester.pumpAndSettle();
    expect(_query(tester), isEmpty);
    expect(tester.widget<ChoiceChip>(_filter('All')).selected, isTrue);
    _button(tester)();
    a.gates.single.complete();
    await tester.pumpAndSettle();
  });

  for (final kind in [
    'host',
    'profile',
    'selecting',
    'disconnect',
    'grant',
    'operation',
  ]) {
    for (final roundtrip in [false, true]) {
      for (final action in ['button', 'pull', 'retry']) {
        testWidgets('cached $action rejected after $kind roundtrip=$roundtrip', (
          tester,
        ) async {
          final channel = _Channel();
          final harness = _Harness(channel);
          addTearDown(harness.container.dispose);
          addTearDown(channel.dispose);
          await tester.pumpWidget(harness.app());
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(_searchKey), 'morning');
          await tester.tap(_filter('Disabled'));
          late Future<void> Function() callback;
          if (action == 'button') {
            final button = _button(tester);
            callback = () async => button();
          } else if (action == 'pull') {
            callback = _pull(tester);
          } else {
            _button(tester)();
            channel.gates.single.completeError(StateError('private failure'));
            await tester.pumpAndSettle();
            final retry = tester
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Retry'),
                )
                .onPressed!;
            callback = () async => retry();
          }
          final calls = channel.loadJobsCalls;
          final original = channel.state;
          channel.emit(_transition(kind, original));
          if (roundtrip) channel.emit(original);
          // No pump: callback must validate live owner, not last rendered state.
          final done = callback();
          expect(channel.loadJobsCalls, calls);
          // Release erroneously admitted work so the pre-fix red run cannot hang.
          for (final gate in channel.gates) {
            if (!gate.isCompleted) gate.complete();
          }
          await done;
          await tester.pumpAndSettle();
          if (roundtrip || kind == 'host' || kind == 'profile') {
            expect(_query(tester), isEmpty);
            expect(tester.widget<ChoiceChip>(_filter('All')).selected, isTrue);
            _button(tester)();
            expect(channel.loadJobsCalls, calls + 1);
            channel.gates.last.complete();
            await tester.pumpAndSettle();
          } else {
            expect(find.byKey(_refreshKey), findsNothing);
          }
        });
      }
    }
    for (final fails in [false, true]) {
      testWidgets('pending $kind roundtrip fences completion $fails', (
        tester,
      ) async {
        final channel = _Channel();
        final harness = _Harness(channel);
        addTearDown(harness.container.dispose);
        addTearDown(channel.dispose);
        await tester.pumpWidget(harness.app());
        await tester.pumpAndSettle();
        _button(tester)();
        final original = channel.state;
        channel.emit(_transition(kind, original));
        channel.emit(original);
        await tester.pump();
        _button(tester)();
        expect(channel.loadJobsCalls, 2);
        if (fails) {
          channel.gates.first.completeError(StateError('old private failure'));
        } else {
          channel.gates.first.complete();
        }
        await tester.pump();
        expect(find.text(_failure), findsNothing);
        expect(
          tester.widget<IconButton>(find.byKey(_refreshKey)).onPressed,
          isNull,
        );
        channel.gates.last.complete();
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets('ordinary updates retain pending state and duplicate admission', (
    tester,
  ) async {
    final channel = _Channel();
    final harness = _Harness(channel);
    addTearDown(harness.container.dispose);
    addTearDown(channel.dispose);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(_searchKey), 'morning');
    await tester.tap(_filter('Enabled'));
    final button = _button(tester);
    final pull = _pull(tester);
    button();
    button();
    await pull();
    channel.emit(channel.state.copyWith(jobs: [..._jobs]));
    channel.emit(channel.state.copyWith(capabilities: _capabilities()));
    await tester.pump();
    expect(channel.loadJobsCalls, 1);
    expect(_query(tester), 'morning');
    expect(tester.widget<ChoiceChip>(_filter('Enabled')).selected, isTrue);
    expect(
      tester.widget<IconButton>(find.byKey(_refreshKey)).onPressed,
      isNull,
    );
    channel.gates.single.completeError(StateError('current private failure'));
    await tester.pumpAndSettle();
    expect(find.text(_failure), findsOneWidget);
    expect(find.textContaining('private failure'), findsNothing);
    channel.emit(channel.state.copyWith(capabilities: _capabilities()));
    await tester.pumpAndSettle();
    expect(find.text(_failure), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    channel.gates.last.complete();
    await tester.pumpAndSettle();
    expect(_query(tester), 'morning');
  });

  for (final fails in [false, true]) {
    testWidgets('dispose rejects cached actions and late completion $fails', (
      tester,
    ) async {
      final channel = _Channel();
      final harness = _Harness(channel);
      addTearDown(harness.container.dispose);
      addTearDown(channel.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      final button = _button(tester);
      final pull = _pull(tester);
      button();
      await tester.pumpWidget(const SizedBox());
      button();
      await pull();
      expect(channel.loadJobsCalls, 1);
      if (fails) {
        channel.gates.single.completeError(StateError('late private failure'));
      } else {
        channel.gates.single.complete();
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'refresh progress and Retry keyboard semantics at $width 200%',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final channel = _Channel();
        final harness = _Harness(channel);
        addTearDown(harness.container.dispose);
        addTearDown(channel.dispose);
        await tester.pumpWidget(harness.app(scale: 2));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Search schedules'), findsOneWidget);
        expect(find.bySemanticsLabel('Clear filters'), findsOneWidget);
        Focus.of(tester.element(find.byIcon(Icons.refresh))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(channel.loadJobsCalls, 1);
        expect(
          find.bySemanticsLabel('Refreshing scheduled jobs'),
          findsOneWidget,
        );
        channel.gates.single.completeError(StateError('private transport'));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Retry'), findsOneWidget);
        Focus.of(tester.element(find.text('Retry'))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        expect(channel.loadJobsCalls, 2);
        channel.gates.last.complete();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Morning check'),
          150,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.text('Morning check'), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
