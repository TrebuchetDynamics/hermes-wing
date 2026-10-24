import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/shared/widgets/app_shell.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/widgets/chat_workspace_overlay.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('overlay close shares page title row at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => ChatWorkspaceOverlay(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Page title'),
                  actions: [
                    IconButton(
                      key: const ValueKey('page-search'),
                      tooltip: 'Search',
                      onPressed: () {},
                      icon: const Icon(Icons.search),
                    ),
                    const AppShellMenuButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final close = find.byKey(const ValueKey('chat-workspace-overlay-close'));
      final title = find.text('Page title');
      expect(
        (tester.getCenter(close).dy - tester.getCenter(title).dy).abs(),
        lessThan(12),
      );
      final search = find.byKey(const ValueKey('page-search'));
      expect(tester.getRect(search).overlaps(tester.getRect(close)), isFalse);
      expect(search.hitTestable(), findsOneWidget);
      expect(close.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
