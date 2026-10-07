import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';

const routes = {
  'Chat': AppRoutes.hermes,
  'Office': AppRoutes.office,
  'Schedules': AppRoutes.schedules,
  'Providers': AppRoutes.providers,
  'Connections': AppRoutes.gateway,
  'Tools': AppRoutes.tools,
  'Profiles': AppRoutes.profiles,
  'Persona': AppRoutes.soul,
  'Settings': AppRoutes.settings,
};

Future<GoRouter> pumpShell(
  WidgetTester tester,
  FakeHermesChannel channel,
) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(channel.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.hermes,
    routes: [
      ShellRoute(
        builder: (_, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          for (final path in routes.values)
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(
                body: Column(
                  children: [
                    Text('Page $path'),
                    const TextField(key: ValueKey('draft')),
                  ],
                ),
              ),
            ),
          GoRoute(
            path: '${AppRoutes.settings}/voice',
            builder: (_, _) => const Scaffold(body: Text('Nested settings')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

bool flag(WidgetTester tester, Finder finder, {bool focused = false}) {
  final flags = tester.getSemantics(finder).getSemanticsData().flagsCollection;
  return (focused ? flags.isFocused : flags.isSelected).toBoolOrNull() == true;
}

Future<void> reach(
  WidgetTester tester,
  Finder target, {
  bool backwards = false,
}) async {
  for (var i = 0; i < 30; i++) {
    if (flag(tester, target, focused: true)) return;
    if (backwards) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (backwards) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
  }
  expect(flag(tester, target, focused: true), isTrue);
}

void expectNoChannelCalls(FakeHermesChannel channel) {
  for (final calls in [
    channel.connectCalls,
    channel.createSessionCalls,
    channel.selectProfileCalls,
    channel.selectSessionCalls,
    channel.sentTextAttachments,
    channel.createProfileCalls,
    channel.renameProfileCalls,
    channel.deleteProfileCalls,
    channel.writeProfileSoulCalls,
    channel.renameSessionCalls,
    channel.deleteSessionCalls,
    channel.forkSessionCalls,
    channel.assignModelCalls,
    channel.lockSessionModelCalls,
    channel.respondToApprovalCalls,
    channel.setProviderCredentialCalls,
    channel.removeProviderCredentialCalls,
  ]) {
    expect(calls, isEmpty);
  }
  expect(channel.disconnectCalls, 0);
  expect(channel.stopActiveTurnCalls, 0);
  expect(channel.loadJobsCalls, 0);
  expect(channel.loadToolInventoryCalls, 0);
  expect(channel.loadProvidersCalls, 0);
}

void main() {
  for (final collapsed in [false, true]) {
    testWidgets(
      'named groups navigate every route with keyboard, collapsed=$collapsed',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        final semantics = tester.ensureSemantics();
        final channel = FakeHermesChannel.disconnected();
        final router = await pumpShell(tester, channel);
        expect(find.bySemanticsLabel('Workflow'), findsOneWidget);
        expect(find.bySemanticsLabel('Utilities'), findsOneWidget);
        final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));
        final pageState = tester.state(find.byType(TextField));
        await tester.enterText(
          find.byKey(const ValueKey('draft')),
          'local draft',
        );
        if (collapsed) {
          await reach(tester, toggle);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(tester.state(find.byType(TextField)), same(pageState));
          expect(find.text('local draft'), findsOneWidget);
        }
        final replacement = FakeHermesChannel.disconnected();
        addTearDown(replacement.dispose);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(AppShell)),
        );
        container.updateOverrides([
          hermesChannelProvider.overrideWithValue(replacement),
        ]);
        await tester.pumpAndSettle();
        expect(
          find.byTooltip(collapsed ? 'Expand' : 'Collapse'),
          findsOneWidget,
        );
        expect(tester.state(find.byType(TextField)), same(pageState));
        expect(find.text('local draft'), findsOneWidget);
        final workflow = find.byKey(
          const ValueKey('desktop-workflow-navigation'),
        );
        final utilities = find.byKey(
          const ValueKey('desktop-utility-navigation'),
        );
        expect(
          tester.getTopLeft(workflow).dy,
          lessThan(tester.getTopLeft(utilities).dy),
        );
        var index = 0;
        for (final entry in routes.entries) {
          final target = find.bySemanticsLabel(entry.key);
          await reach(tester, target, backwards: index.isOdd);
          expect(target.hitTestable(), findsOneWidget);
          await tester.sendKeyEvent(
            index.isOdd ? LogicalKeyboardKey.space : LogicalKeyboardKey.enter,
          );
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, entry.value);
          expect(flag(tester, target), isTrue);
          for (final other in routes.keys.where((name) => name != entry.key)) {
            expect(
              flag(tester, find.bySemanticsLabel(other)),
              isFalse,
              reason: other,
            );
          }
          expect(
            find.byTooltip(collapsed ? 'Expand' : 'Collapse'),
            findsOneWidget,
          );
          index++;
        }
        router.go('${AppRoutes.settings}/voice');
        await tester.pumpAndSettle();
        expect(flag(tester, find.bySemanticsLabel('Settings')), isTrue);
        expectNoChannelCalls(channel);
        expectNoChannelCalls(replacement);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'short 200% layout reaches both groups and mobile More recovers routes',
    (tester) async {
      tester.view.physicalSize = const Size(900, 360);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel.disconnected();
      await pumpShell(tester, channel);
      for (final label in routes.keys) {
        final target = find.bySemanticsLabel(label);
        await reach(tester, target);
        expect(target.hitTestable(), findsOneWidget);
      }
      final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));
      expect(toggle.hitTestable(), findsOneWidget);
      await reach(tester, toggle);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      channel.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Expand'), findsOneWidget);
      for (final label in routes.keys) {
        final target = find.bySemanticsLabel(label);
        await reach(tester, target, backwards: true);
        expect(target.hitTestable(), findsOneWidget);
      }
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.bySemanticsLabel('Workflow'), findsNothing);
      for (final label in [
        'Office',
        'Schedules',
        'Providers',
        'Tools',
        'Persona',
        'Settings',
      ]) {
        await tester.tap(find.text('More').hitTestable());
        await tester.pumpAndSettle();
        final row = find.widgetWithText(ListTile, label);
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.tap(row);
        await tester.pumpAndSettle();
        // More uses the existing imperative push contract; the displayed page,
        // not the root route-information URI, is the active destination.
        expect(find.text('Page ${routes[label]}'), findsOneWidget);
      }
      tester.view.physicalSize = const Size(900, 360);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Expand'), findsOneWidget);
      await reach(tester, find.bySemanticsLabel('Settings'));
      expect(flag(tester, find.bySemanticsLabel('Settings')), isTrue);
      expectNoChannelCalls(channel);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
