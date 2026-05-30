import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/shared/widgets/app_shell.dart';
import 'package:navivox/theme/navivox_theme.dart';

void main() {
  testWidgets('mobile chat thread hides app bottom navigation like Telegram', (
    tester,
  ) async {
    await _withMobileSurface(tester, () async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(
            location: '/chats/local/mineru',
            child: Text('Thread body'),
          ),
        ),
      );

      expect(find.text('Thread body'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Chats'), findsNothing);
      expect(find.text('Servers'), findsNothing);
    });
  });

  testWidgets('mobile top-level screens use a Telegram-like bottom nav', (
    tester,
  ) async {
    await _withMobileSurface(tester, () async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(location: '/chats', child: Text('Contact list')),
        ),
      );

      expect(find.text('Contact list'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byTooltip('Open navigation menu'), findsNothing);
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Servers'), findsNothing);
    });
  });

  testWidgets('mobile bottom navigation is compact and theme-colored', (
    tester,
  ) async {
    await _withMobileSurface(tester, () async {
      await tester.pumpWidget(
        MaterialApp(
          theme: navivoxLightTheme,
          home: const AppShell(location: '/chats', child: Text('Contact list')),
        ),
      );

      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );

      expect(navigationBar.height, 68);
      expect(navigationBar.elevation, 0);
      expect(navigationBar.selectedIndex, 0);
    });
  });

  testWidgets('mobile more menu plugs overflow destinations', (tester) async {
    await _withMobileSurface(tester, () async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(location: '/memory', child: Text('Memory body')),
        ),
      );

      expect(find.text('Memory body'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Servers'), findsOneWidget);
      expect(find.text('Config'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
    });
  });

  testWidgets('mobile overflow destination keeps More selected', (
    tester,
  ) async {
    await _withMobileSurface(tester, () async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(location: '/config', child: Text('Config body')),
        ),
      );

      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );

      expect(find.text('Config body'), findsOneWidget);
      expect(navigationBar.selectedIndex, 4);
    });
  });
}

Future<void> _withMobileSurface(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await body();
}
