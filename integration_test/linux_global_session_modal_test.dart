import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/providers/hermes_directory_lifetime.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import 'support/global_session_fixture.dart';
import 'support/linux_test_isolation.dart';

// Real Linux engine, shell and HTTP channel. Input is injected into Flutter,
// not an OS keyboard/IME or a physical accessibility qualification.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final root = requireLinuxTestRoot('wing-linux-panel.');
  if (Platform.environment['HOME'] != '$root/home' ||
      Platform.environment['WING_ISOLATED_PREFERENCES'] != '1') {
    throw StateError('Use the isolated global-session runner');
  }
  testWidgets('native global panel keyboard, acknowledgement and owner recovery', (
    tester,
  ) async {
    final fixture = await GlobalSessionFixture.start(
      Platform.environment['WING_PANEL_ORIGIN']!,
    );
    addTearDown(fixture.dispose);
    await fixture.setup('POST', '/e2e/hermes/reset');
    await fixture.setup('POST', '/api/sessions', {
      'id': 'synthetic-native-panel',
    });
    final setupState = await fixture.setup('GET', '/e2e/hermes/run-count');
    var nextId = 0;
    RecordingPanelChannel makeChannel() =>
        RecordingPanelChannel(() => 'synthetic-panel-created-${++nextId}');
    var channel = makeChannel();
    final channels = [channel];
    final lifetime = HermesDirectoryLifetime();
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesDirectoryLifetimeProvider.overrideWithValue(lifetime),
      ],
    );
    final router = GoRouter(
      initialLocation: '/tools',
      routes: [
        ShellRoute(
          builder: (_, state, child) =>
              AppShell(location: state.uri.path, child: child),
          routes: [
            for (final path in ['/tools', '/hermes', '/settings'])
              GoRoute(
                path: path,
                builder: (_, _) => Scaffold(
                  body: Column(
                    children: [
                      Text('Page $path'),
                      const TextField(key: ValueKey('route-draft')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
    addTearDown(() {
      router.dispose();
      container.dispose();
      lifetime.dispose();
      for (final c in channels) {
        c.dispose();
      }
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await channel.connect(baseUrl: fixture.origin);
    expect(channel.state.isConnected, true);
    expect(channel.state.activeSessionId, 'e2e-hermes-session');
    final bootstrap = List<Map<String, Object?>>.from(fixture.requests);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final phases = <Map<String, Object?>>[];
    final focus = <Map<String, Object?>>[];
    Finder keyed(String id) => find.byKey(ValueKey(id));
    final panel = keyed('hermes-sessions-panel');
    final search = keyed('hermes-session-search-field');
    final row = keyed('hermes-session-row-synthetic-native-panel');
    final create = keyed('hermes-sessions-new');
    final draft = keyed('route-draft');
    String path() => router.routeInformationProvider.value.uri.path;
    bool focused(Finder target) {
      if (target.evaluate().isEmpty) return false;
      final element = target.evaluate().single;
      final context = FocusManager.instance.primaryFocus?.context;
      var inside = identical(context, element);
      context?.visitAncestorElements((ancestor) {
        if (identical(ancestor, element)) inside = true;
        return !inside;
      });
      return inside;
    }

    Future<void> key(LogicalKeyboardKey value) async {
      await tester.sendKeyEvent(value);
      await tester.pumpAndSettle();
    }

    Future<void> reach(Finder target) async {
      var tabs = 0;
      while (!focused(target) && tabs < 80) {
        await key(LogicalKeyboardKey.tab);
        tabs++;
      }
      expect(focused(target), true, reason: target.toString());
      final rect = tester.getRect(target);
      final size = tester.view.physicalSize;
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(rect.bottom, lessThanOrEqualTo(size.height));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
      focus.add({
        'target': target.toString(),
        'tabs': tabs,
        'rect': [rect.left, rect.top, rect.right, rect.bottom],
        'viewport': [size.width, size.height],
      });
    }

    Future<void> open() async {
      await reach(draft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(panel, findsOneWidget);
      expect(focused(search), true);
    }

    Future<void> close() async {
      if (panel.evaluate().isNotEmpty) {
        // Pending admission excludes the row; route replacement can dispose
        // its focus. Traverse the surviving Close control before dismissal.
        await reach(keyed('global-sessions-close'));
        await key(LogicalKeyboardKey.escape);
      }
      expect(panel, findsNothing);
    }

    final passiveStart = fixture.requests.length;
    await open();
    for (final size in [
      const Size(390, 700),
      const Size(390, 480),
      const Size(1280, 900),
    ]) {
      final before = FocusManager.instance.primaryFocus;
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(before));
      for (final target in [
        search,
        create,
        row,
        keyed('global-sessions-close'),
      ]) {
        await reach(target);
      }
      for (final reverse in [false, true]) {
        for (var i = 0; i < 20; i++) {
          if (reverse) {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          }
          await key(LogicalKeyboardKey.tab);
          if (reverse) {
            await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          }
          expect(
            FocusManager.instance.primaryFocus!.context!
                .findAncestorWidgetOfExactType<Dialog>(),
            isNotNull,
          );
        }
      }
      await reach(search);
      await tester.enterText(search, 'synthetic-native-panel');
      await tester.pumpAndSettle();
      expect(row, findsOneWidget);
      expect(keyed('hermes-session-row-e2e-hermes-session'), findsNothing);
      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await close();
    expect(focused(draft), true);
    await open();
    await reach(keyed('global-sessions-close'));
    await key(LogicalKeyboardKey.space);
    expect(panel, findsNothing);
    expect(focused(draft), true);
    expect(fixture.requests.length, passiveStart);
    phases.add({'phase': 'adaptive passive', 'requests': []});

    Map<String, Object?> history(String id) => {
      'method': 'GET',
      'path': '/api/sessions/$id/messages',
      'query': {'limit': '500', 'offset': '0', 'order': 'latest'},
    };
    final creation = {'method': 'POST', 'path': '/api/sessions', 'query': {}};
    Future<void> reset() async {
      await close();
      router.go('/tools');
      await tester.pumpAndSettle();
      final start = fixture.requests.length;
      await channel.connect(baseUrl: fixture.origin);
      await tester.pumpAndSettle();
      expect(fixture.requests.skip(start).toList(), bootstrap);
    }

    for (final isNew in [false, true]) {
      for (final mode in [
        'route',
        'cancel',
        'generation',
        'channel',
        'session',
      ]) {
        debugPrint('PANEL_PHASE ${isNew ? 'New' : 'Open'} $mode');
        await reset();
        await open();
        if (!isNew) {
          await tester.enterText(search, 'synthetic-native-panel');
          await tester.pumpAndSettle();
        }
        final old = channel;
        final start = fixture.requests.length;
        final idBefore = nextId;
        fixture.hold(create: isNew);
        await reach(isNew ? create : row);
        await key(LogicalKeyboardKey.enter);
        await fixture.held!.future.timeout(const Duration(seconds: 10));
        expect(path(), '/tools');
        final pending = old.lastOperation!;
        expect(fixture.requests.skip(start).toList(), [
          isNew ? creation : history('synthetic-native-panel'),
        ]);
        await key(LogicalKeyboardKey.enter);
        expect(fixture.requests.length, start + 1);
        final setupStart = fixture.requests.length;
        switch (mode) {
          case 'route':
            router.go('/settings');
            await tester.pumpAndSettle();
            router.go('/tools');
            await tester.pumpAndSettle();
          case 'cancel':
            await close();
          case 'generation':
            await channel.connect(baseUrl: fixture.origin);
            await tester.pumpAndSettle();
          case 'channel':
            channel = makeChannel();
            channels.add(channel);
            await channel.connect(baseUrl: fixture.origin);
            container.updateOverrides([
              hermesChannelProvider.overrideWithValue(channel),
              hermesDirectoryLifetimeProvider.overrideWithValue(lifetime),
            ]);
            await tester.pumpAndSettle();
          case 'session':
            await channel.selectSession('e2e-hermes-session');
            await tester.pumpAndSettle();
        }
        final setupRequests = fixture.requests.skip(setupStart).toList();
        expect(setupRequests, [
          if (mode == 'generation' || mode == 'channel') ...bootstrap,
          if (mode == 'session') history('e2e-hermes-session'),
        ]);
        final replacement = channel.state.activeSessionId;
        await fixture.settle();
        await pending;
        await tester.pumpAndSettle();
        expect(path(), '/tools');
        expect(channel.state.activeSessionId, replacement);
        if (isNew) {
          expect(
            channel.state.activeSessionId,
            isNot('synthetic-panel-created-${idBefore + 1}'),
          );
        } else {
          expect(
            channel.state.activeSessionId,
            isNot('synthetic-native-panel'),
          );
        }
        expect(fixture.requests.length, setupStart + setupRequests.length);
        // New intentionally clears its former target before submission; cancelling
        // does not roll back an acknowledged server write or create a shadow row.
        final obsolete = fixture.requests.skip(start).toList();
        await close();
        await open();
        final freshStart = fixture.requests.length;
        var admissions = 0;
        final freshId = isNew
            ? 'synthetic-panel-created-${nextId + 1}'
            : 'synthetic-native-panel';
        void accepted() {
          if (channel.state.activeSessionId == freshId) admissions++;
        }

        channel.addListener(accepted);
        await reach(isNew ? create : row);
        await key(LogicalKeyboardKey.space);
        await waitFor(tester, () => path() == '/hermes');
        channel.removeListener(accepted);
        expect(admissions, 1);
        expect(channel.state.activeSessionId, freshId);
        expect(channel.state.errorMessage, isNull);
        expect(panel, findsNothing);
        expect(fixture.requests.skip(freshStart).toList(), [
          if (isNew) creation,
          history(freshId),
        ]);
        phases.add({
          'phase': '${isNew ? 'New' : 'Open'} pending $mode',
          'obsolete_admissions': 0,
          'replacement_session': replacement,
          'fresh_admissions': admissions,
          'acknowledged_session': freshId,
          'obsolete_requests': obsolete,
          'setup_requests': setupRequests,
          'fresh_requests': fixture.requests.skip(freshStart).toList(),
        });
        expect(tester.takeException(), isNull);
      }
    }
    await reset();
    await open();
    final failureStart = fixture.requests.length;
    fixture.hold(fail: true);
    await reach(row);
    await key(LogicalKeyboardKey.enter);
    await fixture.held!.future.timeout(const Duration(seconds: 10));
    final failed = channel.lastOperation!;
    final failureObserved = expectLater(failed, throwsA(isA<HttpException>()));
    await fixture.settle();
    await failureObserved;
    await tester.pumpAndSettle();
    expect(path(), '/tools');
    expect(panel, findsOneWidget);
    expect(channel.state.activeSessionId, 'e2e-hermes-session');
    await reach(keyed('global-sessions-retry'));
    await key(LogicalKeyboardKey.space);
    await waitFor(tester, () => path() == '/hermes');
    expect(fixture.requests.skip(failureStart).toList(), [
      history('synthetic-native-panel'),
      history('synthetic-native-panel'),
    ]);
    phases.add({
      'phase': 'failed Open explicit Retry',
      'requests': fixture.requests.skip(failureStart).toList(),
    });
    final mutations = fixture.requests
        .where((r) => r['method'] != 'GET')
        .toList();
    expect(mutations, List.generate(10, (_) => creation));
    final finalState = await fixture.setup('GET', '/e2e/hermes/run-count');
    expect(finalState, setupState);
    expect(finalState['runCount'], 0);
    expect(tester.takeException(), isNull);
    final receipt = {
      'synthetic': true,
      'native_pid': pid,
      'platform': Platform.operatingSystem,
      'text_scale': 2,
      'reduced_motion': true,
      'input': 'WidgetTester sendKeyEvent/enterText in native Flutter engine',
      'bootstrap': bootstrap,
      'phases': phases,
      'focus': focus,
      'requests': fixture.requests,
      'request_count': fixture.requests.length,
      'mutation_count': mutations.length,
      'unexpected_mutation_count': 0,
      'run_counters': finalState,
      'calls': channels.expand((c) => c.calls).toList(),
      'setup': [
        'reset POST',
        'seed POST',
        'counter GETs',
        'explicit reconnects and replacement selection',
      ],
      'physical_keyboard_ime': 'NOT_CHECKED',
      'live_agent': 'NOT_CHECKED',
      'secure_storage': 'NOT_CHECKED',
      'screen_reader': 'NOT_CHECKED',
      'packaged_distribution': 'NOT_CHECKED',
      'native_profile_switch':
          'NOT_CHECKED; nearest widget profile away/back regression rerun',
    };
    File(
      '${Platform.environment['WING_PANEL_LOGS']}/native-receipt.json',
    ).writeAsStringSync('${jsonEncode(receipt)}\n');
    debugPrint('PANEL_RECEIPT ${jsonEncode(receipt)}');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(ready(), true, reason: 'Native panel acknowledgement timed out');
}

// Observe public calls and completion only; production transport and admission
// remain unchanged. Deterministic IDs bind each acknowledged POST to its GET.
class RecordingPanelChannel extends HermesApiChannel {
  RecordingPanelChannel(String Function() idFactory)
    : super(sessionIdFactory: idFactory);
  final calls = <String>[];
  Future<void>? lastOperation;
  @override
  Future<void> selectSession(String id, {bool Function()? canAccept}) {
    calls.add('Open $id');
    return lastOperation = super.selectSession(id, canAccept: canAccept);
  }

  @override
  Future<void> createSession({String? title, bool Function()? canAccept}) {
    calls.add('New');
    return lastOperation = super.createSession(
      title: title,
      canAccept: canAccept,
    );
  }
}
