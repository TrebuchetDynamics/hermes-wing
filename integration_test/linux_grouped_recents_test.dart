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

import 'support/grouped_recents_fixture.dart';
import 'support/linux_test_isolation.dart';

// Actual native shell and HTTP channel, synthetic server, injected Flutter keys.
// This does not qualify live Agent, physical input/IME, or OS window minimization.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final root = requireLinuxTestRoot('wing-linux-recents.');
  if (Platform.environment['HOME'] != '$root/home' ||
      Platform.environment['WING_ISOLATED_PREFERENCES'] != '1') {
    throw StateError('Use the isolated grouped-recents runner');
  }
  testWidgets('native grouped recents return rejects obsolete exact-row Open', (
    tester,
  ) async {
    final fixture = await GroupedRecentsFixture.start(
      Platform.environment['WING_RECENTS_ORIGIN']!,
    );
    addTearDown(fixture.dispose);
    await fixture.setup('POST', '/e2e/hermes/reset');

    final seeded = await fixture.setup('POST', '/api/sessions', {
      'id': 'synthetic-native-recents',
    });
    expect((seeded['session'] as Map)['id'], 'synthetic-native-recents');
    final setupState = await fixture.setup('GET', '/e2e/hermes/run-count');
    var channel = RecordingNativeChannel();
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
                    children: [Text('Page $path'), const TextField()],
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
    tester.view.physicalSize = const Size(1280, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await channel.connect(baseUrl: fixture.origin);
    expect(channel.state.isConnected, true);
    expect(channel.state.selectedProfileId, isNull);
    expect(channel.state.activeSessionId, 'e2e-hermes-session');
    final bootstrap = List<Map<String, Object?>>.from(fixture.requests);
    expect(bootstrap, isNotEmpty);
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
    final semantics = tester.ensureSemantics();
    var semanticsDisposed = false;
    addTearDown(() {
      if (!semanticsDisposed) semantics.dispose();
    });
    final row = find.byKey(
      const ValueKey('shell-open-session-synthetic-native-recents'),
    );
    final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));
    final phases = <Map<String, Object?>>[];
    final focus = <Map<String, Object?>>[];
    String getPath() => router.routeInformationProvider.value.uri.path;
    Future<void> key(LogicalKeyboardKey value) async {
      await tester.sendKeyEvent(value);
      await tester.pumpAndSettle();
    }

    Future<void> reach(Finder target, {bool reverse = false}) async {
      bool focused() =>
          tester
              .getSemantics(target)
              .getSemanticsData()
              .flagsCollection
              .isFocused
              .toBoolOrNull() ==
          true;
      var tabs = 0;
      while (!focused() && tabs < 60) {
        if (reverse) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        tabs++;
      }
      expect(focused(), true);
      final rect = tester.getRect(target);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
      focus.add({
        'key': tester.widget(target).key.toString(),
        'reverse': reverse,
        'tabs': tabs,
        'rect': [rect.left, rect.top, rect.right, rect.bottom],
      });
    }

    Future<void> hideReturn(String mode) async {
      if (mode == 'collapse') {
        await reach(toggle);
        await key(LogicalKeyboardKey.space);
      } else {
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();
      }
      for (final reverse in [false, true]) {
        for (var i = 0; i < 16; i++) {
          if (reverse) {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          if (reverse) {
            await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          }
          await tester.pumpAndSettle();
          expect(row, findsNothing);
          expect(
            find.byKey(const ValueKey('shell-session-access')),
            findsNothing,
          );
        }
      }
      if (mode == 'collapse') {
        await reach(toggle, reverse: true);
        await key(LogicalKeyboardKey.enter);
      } else {
        tester.view.physicalSize = const Size(1280, 600);
        await tester.pumpAndSettle();
      }
      expect(row, findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    final exactRead = {
      'method': 'GET',
      'path': '/api/sessions/synthetic-native-recents/messages',
      'query': {'limit': '500', 'offset': '0', 'order': 'latest'},
    };
    var accepted = 0;
    void observe() {
      if (channel.state.activeSessionId == 'synthetic-native-recents') {
        accepted++;
      }
    }

    channel.addListener(observe);
    for (final mode in ['collapse', 'compact']) {
      final start = fixture.requests.length;
      await reach(row);
      await hideReturn(mode);
      await reach(row);
      await key(LogicalKeyboardKey.tab);
      await reach(row, reverse: true);
      expect(fixture.requests.length, start);
      await key(
        mode == 'collapse'
            ? LogicalKeyboardKey.enter
            : LogicalKeyboardKey.space,
      );
      await waitFor(tester, () => getPath() == '/hermes');
      expect(channel.state.activeSessionId, 'synthetic-native-recents');
      expect(fixture.requests.skip(start).toList(), [exactRead]);
      phases.add({
        'phase': '$mode return Open',
        'requests': fixture.requests.skip(start).toList(),
      });
      router.go('/tools');
      await tester.pumpAndSettle();
    }
    expect(accepted, 2);
    channel.removeListener(observe);
    // Each deliberate reconnect resets the active tuple. Its reads are setup,
    // not hide/return traffic, and must equal the captured bootstrap exactly.
    for (final mode in ['collapse', 'compact', 'generation', 'channel']) {
      final resetStart = fixture.requests.length;
      await channel.connect(baseUrl: fixture.origin);
      await tester.pumpAndSettle();
      expect(fixture.requests.skip(resetStart).toList(), bootstrap);
      final old = channel;
      final start = fixture.requests.length;
      fixture.hold();
      await reach(row);
      await key(LogicalKeyboardKey.enter);
      await fixture.held!.future.timeout(const Duration(seconds: 10));
      expect(getPath(), '/tools');
      expect(fixture.requests.skip(start).toList(), [exactRead]);
      if (mode == 'generation') {
        await channel.connect(baseUrl: fixture.origin);
        await tester.pumpAndSettle();
      } else if (mode == 'channel') {
        channel = RecordingNativeChannel();
        channels.add(channel);
        await channel.connect(baseUrl: fixture.origin);
        container.updateOverrides([
          hermesChannelProvider.overrideWithValue(channel),
          hermesDirectoryLifetimeProvider.overrideWithValue(lifetime),
        ]);
        await tester.pumpAndSettle();
      } else {
        await hideReturn(mode);
      }
      await fixture.settle();
      await old.lastSelection;
      await waitFor(
        tester,
        () => find.text('Opening session…').evaluate().isEmpty,
      );
      await tester.pumpAndSettle();
      expect(getPath(), '/tools');
      expect(old.state.activeSessionId, 'e2e-hermes-session');
      expect(old.state.messages.containsKey('synthetic-native-recents'), false);
      expect(channel.state.activeSessionId, 'e2e-hermes-session');
      expect(
        channel.state.messages.containsKey('synthetic-native-recents'),
        false,
      );
      expect(channel.state.errorMessage, isNull);
      final obsoleteReads = fixture.requests.skip(start).toList();
      expect(obsoleteReads, [
        exactRead,
        if (mode == 'generation' || mode == 'channel') ...bootstrap,
      ]);
      final freshStart = fixture.requests.length;
      var freshAdmissions = 0;
      void fresh() {
        if (channel.state.activeSessionId == 'synthetic-native-recents') {
          freshAdmissions++;
        }
      }

      channel.addListener(fresh);
      await reach(row);
      await key(LogicalKeyboardKey.space);
      await waitFor(tester, () => getPath() == '/hermes');
      channel.removeListener(fresh);
      expect(freshAdmissions, 1);
      expect(fixture.requests.skip(freshStart).toList(), [exactRead]);
      phases.add({
        'phase': 'pending $mode',
        'obsolete_admissions': 0,
        'fresh_admissions': freshAdmissions,
        'requests': obsoleteReads,
        'fresh_requests': fixture.requests.skip(freshStart).toList(),
      });
      router.go('/tools');
      await tester.pumpAndSettle();
    }
    expect(fixture.requests.every((r) => r['method'] == 'GET'), true);
    final finalState = await fixture.setup('GET', '/e2e/hermes/run-count');
    expect(finalState, setupState);
    expect(finalState['runCount'], 0);
    expect(tester.takeException(), isNull);
    final receipt = {
      'synthetic': true,
      'native_pid': pid,
      'platform': Platform.operatingSystem,
      'text_scale': 2,
      'bootstrap': bootstrap,
      'phases': phases,
      'focus': focus,
      'requests': fixture.requests,
      'request_count': fixture.requests.length,
      'history_count': fixture.requests
          .where((r) => r['path'].toString().endsWith('/messages'))
          .length,
      'mutation_count': 0,
      'selection_calls': channels.expand((c) => c.selectionCalls).toList(),
      'selection_completions': channels.fold<int>(
        0,
        (count, c) => count + c.completions,
      ),
      'setup': [
        'reset POST',

        'seed POST',
        'run-count receipt GETs',
        'explicit channel connections',
      ],
      'physical_keyboard': 'NOT_CHECKED',
      'window_minimization': 'NOT_CHECKED',
    };
    File(
      '${Platform.environment['WING_RECENTS_LOGS']}/native-receipt.json',
    ).writeAsStringSync('${jsonEncode(receipt)}\n');
    debugPrint('RECENTS_RECEIPT ${jsonEncode(receipt)}');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    semantics.dispose();
    semanticsDisposed = true;
  });
}

Future<void> waitFor(WidgetTester tester, bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(ready(), true, reason: 'Native exact-row admission timed out');
}

/// Records the public action boundary without changing production HTTP,
/// admission guards, domain state or responses. Awaiting completion proves that
/// an obsolete operation settled, not merely that its server socket closed.
class RecordingNativeChannel extends HermesApiChannel {
  final selectionCalls = <String>[];
  int completions = 0;
  Future<void>? lastSelection;

  @override
  Future<void> selectSession(String id, {bool Function()? canAccept}) {
    selectionCalls.add(id);
    final operation = super.selectSession(id, canAccept: canAccept);
    return lastSelection = operation.whenComplete(() => completions++);
  }
}
