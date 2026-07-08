import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/router/app_routes.dart';
import 'package:navivox/shared/widgets/app_shell.dart';

void main() {
  testWidgets('app shell exposes Hermes and Settings destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('body')), findsOneWidget);
    expect(find.text('HERMES ONE'), findsOneWidget);
    expect(find.text('Hermes'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Chats'), findsNothing);
    expect(find.text('Gateways'), findsNothing);
    expect(find.text('Profiles'), findsNothing);
    expect(find.text('Memory'), findsNothing);
    expect(find.text('Config'), findsNothing);
  });
}
