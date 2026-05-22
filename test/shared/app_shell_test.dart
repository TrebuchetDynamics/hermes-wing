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

  testWidgets('mobile chat list uses hamburger drawer instead of bottom nav', (
    tester,
  ) async {
    await _withMobileSurface(tester, () async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(location: '/chats', child: Text('Contact list')),
        ),
      );

      expect(find.text('Contact list'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byTooltip('Open navigation menu'), findsOneWidget);
      expect(find.text('Servers'), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Chats'), findsWidgets);
      expect(find.text('Servers'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
    });
  });

  testWidgets('mobile hamburger button is flat and theme-colored', (
    tester,
  ) async {
    await _withMobileSurface(tester, () async {
      await tester.pumpWidget(
        MaterialApp(
          theme: navivoxLightTheme,
          home: const AppShell(location: '/chats', child: Text('Contact list')),
        ),
      );

      expect(find.byTooltip('Open navigation menu'), findsOneWidget);
      final menuButton = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(menuButton.backgroundColor, navivoxLightTheme.colorScheme.surface);
      expect(menuButton.foregroundColor, navivoxLightTheme.colorScheme.primary);
      expect(menuButton.elevation, 0);
      expect(menuButton.highlightElevation, 0);
      expect(menuButton.shape, const CircleBorder());
    });
  });

  testWidgets('mobile drawer uses Telegram-blue branded header', (
    tester,
  ) async {
    await _withMobileSurface(tester, () async {
      await tester.pumpWidget(
        MaterialApp(
          theme: navivoxLightTheme,
          home: const AppShell(location: '/chats', child: Text('Contact list')),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final header = tester.widget<DrawerHeader>(find.byType(DrawerHeader));
      final decoration = header.decoration as BoxDecoration?;

      expect(decoration?.color, navivoxLightTheme.colorScheme.primary);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('Navivox'), findsOneWidget);
      expect(find.text('Gormes operator console'), findsOneWidget);
    });
  });

  testWidgets('top-level navigation includes Memory dashboard in drawer', (
    tester,
  ) async {
    await _withMobileSurface(tester, () async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(location: '/memory', child: Text('Memory body')),
        ),
      );

      expect(find.text('Memory body'), findsOneWidget);
      expect(find.byTooltip('Open navigation menu'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Memory'), findsWidgets);
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
