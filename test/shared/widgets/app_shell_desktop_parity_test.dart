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

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

String _selectedLabel(WidgetTester tester) {
  final selected = find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.selected == true,
  );
  return tester
      .widget<Tooltip>(
        find.descendant(of: selected, matching: find.byType(Tooltip)),
      )
      .message!;
}

Future<GoRouter> _pumpShell(WidgetTester tester) async {
  final channel = FakeHermesChannel.disconnected();
  addTearDown(channel.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.profiles,
    routes: [
      ShellRoute(
        builder: (_, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          for (final path in [AppRoutes.hermes, AppRoutes.profiles])
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(
                body: Column(
                  children: [
                    Text('Page $path'),
                    const TextField(key: ValueKey('page-draft')),
                  ],
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
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('desktop sidebar toggles with keyboard without losing navigation', (
    tester,
  ) async {
    _size(tester, const Size(1280, 900));
    final semantics = tester.ensureSemantics();
    final router = await _pumpShell(tester);
    final railFinder = find.byKey(const ValueKey('desktop-sidebar'));
    final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));

    // Pin the existing expanded default and active route before collapsing.
    expect(find.byTooltip('Collapse'), findsOneWidget);
    expect(_selectedLabel(tester), 'Profiles');
    final expandedWidth = tester.getSize(railFinder).width;
    final pageState = tester.state(find.byType(TextField));
    await tester.enterText(find.byKey(const ValueKey('page-draft')), 'draft');
    expect(toggle.hitTestable(), findsOneWidget);
    expect(find.byTooltip('Collapse'), findsOneWidget);
    expect(
      tester
          .getSemantics(toggle)
          .getSemanticsData()
          .flagsCollection
          .isExpanded
          .toBoolOrNull(),
      isTrue,
    );

    // Reach the toggle through traversal, not a direct onPressed call.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    for (var step = 0; step < 20; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      if (tester
              .getSemantics(toggle)
              .getSemanticsData()
              .flagsCollection
              .isFocused
              .toBoolOrNull() ==
          true) {
        break;
      }
    }
    expect(
      tester
          .getSemantics(toggle)
          .getSemanticsData()
          .flagsCollection
          .isFocused
          .toBoolOrNull(),
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Expand'), findsOneWidget);
    expect(tester.getSize(railFinder).width, lessThan(expandedWidth));
    expect(_selectedLabel(tester), 'Profiles');
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.profiles);
    expect(tester.state(find.byType(TextField)), same(pageState));
    expect(find.text('draft'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-shell-status-bar')), findsOneWidget);
    expect(toggle.hitTestable(), findsOneWidget);
    expect(find.byTooltip('Expand'), findsOneWidget);
    expect(
      tester
          .getSemantics(toggle)
          .getSemanticsData()
          .flagsCollection
          .isExpanded
          .toBoolOrNull(),
      isFalse,
    );
    expect(
      tester
          .getSemantics(toggle)
          .getSemanticsData()
          .flagsCollection
          .isFocused
          .toBoolOrNull(),
      isTrue,
    );

    // Icon-only destinations remain named, operable and selected on navigation.
    final chat = find.bySemanticsLabel(RegExp(r'^Chat\b')).hitTestable();
    expect(chat, findsOneWidget);
    await tester.tap(chat);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.hermes);
    expect(_selectedLabel(tester), 'Chat');
    expect(find.byTooltip('Expand'), findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Collapse'), findsOneWidget);
    expect(_selectedLabel(tester), 'Chat');
    expect(tester.getSize(railFinder).width, expandedWidth);
    expect(find.byTooltip('Collapse'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('compact resize retains mobile navigation and desktop choice', (
    tester,
  ) async {
    _size(tester, const Size(900, 700));
    final router = await _pumpShell(tester);
    final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand'), findsOneWidget);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('desktop-sidebar')), findsNothing);
    expect(toggle, findsNothing);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
    expect(bar.destinations.length, 4);
    expect(find.text('More').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Chat').hitTestable());
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.hermes);

    tester.view.physicalSize = const Size(900, 700);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byTooltip('Expand'), findsOneWidget);
    expect(_selectedLabel(tester), 'Chat');
    expect(toggle.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggle stays reachable in a short window with enlarged text', (
    tester,
  ) async {
    _size(tester, const Size(900, 360));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpShell(tester);
    final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));
    expect(toggle.hitTestable(), findsOneWidget);
    await tester.ensureVisible(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings').hitTestable(), findsOneWidget);
    expect(toggle.hitTestable(), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand'), findsOneWidget);
    expect(toggle.hitTestable(), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Collapse'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
