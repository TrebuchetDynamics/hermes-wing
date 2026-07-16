import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/widgets/app_shell.dart';

Widget _testApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets('Agents appears in More rather than the mobile bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.text('Agents'), findsNothing);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Agents'), findsOneWidget);
  });

  testWidgets('Providers appears in More rather than the mobile bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const AppShell(
          location: AppRoutes.hermes,
          child: SizedBox(key: ValueKey('body')),
        ),
      ),
    );

    expect(find.text('Providers'), findsNothing);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Providers'), findsOneWidget);
  });

  testWidgets('app shell exposes Hermes and Settings destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const AppShell(
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
