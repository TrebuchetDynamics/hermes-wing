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
import 'app_shell_navigation_groups_test.dart' as navigation;

Future<void> tab(WidgetTester tester, {bool backwards = false}) async {
  if (backwards) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (backwards) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

Future<void> reachEditor(WidgetTester tester) async {
  for (var i = 0; i < 32; i++) {
    if (tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode
        .hasFocus) {
      return;
    }
    await tab(tester);
  }
  fail('Keyboard traversal did not reach the route editor');
}

Future<void> pumpBoundary(
  WidgetTester tester,
  FakeHermesChannel channel, {
  Widget? routeBody,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(channel.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.providers,
    routes: [
      ShellRoute(
        builder: (_, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.providers,
            builder: (_, _) => Scaffold(
              body:
                  routeBody ??
                  const SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 400),
                        TextField(key: ValueKey('route-editor')),
                      ],
                    ),
                  ),
            ),
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
}

void main() {
  testWidgets('shell boundary retains route-local reading order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    final channel = FakeHermesChannel.disconnected();
    await pumpBoundary(
      tester,
      channel,
      routeBody: Stack(
        children: [
          Positioned(
            top: 200,
            left: 0,
            child: TextButton(
              onPressed: () {},
              child: const Text('Lower route control'),
            ),
          ),
          Positioned(
            top: 20,
            left: 0,
            child: TextButton(
              onPressed: () {},
              child: const Text('Upper route control'),
            ),
          ),
        ],
      ),
    );
    final semantics = tester.ensureSemantics();
    await navigation.reach(
      tester,
      find.byKey(const ValueKey('desktop-sidebar-toggle')),
    );
    for (final label in navigation.routes.keys) {
      await tab(tester);
      expect(
        navigation.flag(tester, find.bySemanticsLabel(label), focused: true),
        isTrue,
        reason: label,
      );
    }
    await tab(tester);
    expect(
      navigation.flag(
        tester,
        find.bySemanticsLabel('Upper route control'),
        focused: true,
      ),
      isTrue,
    );
    await tab(tester);
    expect(
      navigation.flag(
        tester,
        find.bySemanticsLabel('Lower route control'),
        focused: true,
      ),
      isTrue,
    );
    await tab(tester, backwards: true);
    expect(
      navigation.flag(
        tester,
        find.bySemanticsLabel('Upper route control'),
        focused: true,
      ),
      isTrue,
    );
    await tab(tester, backwards: true);
    expect(
      navigation.flag(tester, find.bySemanticsLabel('Settings'), focused: true),
      isTrue,
    );
    navigation.expectNoChannelCalls(channel);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
  testWidgets('sidebar auto-scroll cannot break route editor keyboard reversal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    final channel = FakeHermesChannel.disconnected();
    await pumpBoundary(tester, channel);
    final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
    final scrollable = find.descendant(
      of: sidebar,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));
    await reachEditor(tester);
    final editor = tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode;
    final before = position.pixels;
    await tab(tester);
    final destination = FocusManager.instance.primaryFocus;
    expect(editor.hasFocus, isFalse);
    expect(destination, isNotNull);
    final after = position.pixels;

    await tab(tester, backwards: true);
    expect(
      editor.hasFocus,
      isTrue,
      reason: 'Sidebar geometry must not reorder the shell/route boundary',
    );
    await tab(tester);
    expect(FocusManager.instance.primaryFocus, same(destination));
    await tab(tester, backwards: true);
    expect(editor.hasFocus, isTrue);
    // Independently force keyboard scrolling through every existing destination.
    final semantics = tester.ensureSemantics();
    final offsets = <double>{before, after};
    for (final label in navigation.routes.keys) {
      final target = find.bySemanticsLabel(label);
      await navigation.reach(tester, target);
      expect(target.hitTestable(), findsOneWidget);
      offsets.add(position.pixels);
    }
    expect(offsets.length, greaterThan(1));
    navigation.expectNoChannelCalls(channel);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final size in [const Size(1280, 900), const Size(1280, 360)]) {
    testWidgets(
      'bidirectional scrolling survives collapse resize and disposal at $size',
      (tester) async {
        tester.view.physicalSize = size;
        final channel = FakeHermesChannel.disconnected();
        await pumpBoundary(tester, channel);
        final semantics = tester.ensureSemantics();
        for (final collapsed in [false, true]) {
          if (collapsed) {
            await navigation.reach(
              tester,
              find.byKey(const ValueKey('desktop-sidebar-toggle')),
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
          }
          for (final backwards in [false, true]) {
            for (final label
                in backwards
                    ? navigation.routes.keys.toList().reversed
                    : navigation.routes.keys) {
              final target = find.bySemanticsLabel(label);
              await navigation.reach(tester, target, backwards: backwards);
              expect(target.hitTestable(), findsOneWidget);
              final focused = FocusManager.instance.primaryFocus;
              await tab(tester, backwards: backwards);
              await tab(tester, backwards: !backwards);
              expect(
                FocusManager.instance.primaryFocus,
                same(focused),
                reason: label,
              );
            }
          }
        }
        tester.view.physicalSize = const Size(390, 900);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsOneWidget);
        await reachEditor(tester);
        final editor = tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode;
        await tab(tester);
        await tab(tester, backwards: true);
        expect(editor.hasFocus, isTrue);
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.byTooltip('Expand'), findsOneWidget);
        await navigation.reach(tester, find.bySemanticsLabel('Settings'));
        navigation.expectNoChannelCalls(channel);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
