import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/shared/widgets/app_shell.dart';

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

  testWidgets('mobile chat list still shows top-level navigation', (
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
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Servers'), findsOneWidget);
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
