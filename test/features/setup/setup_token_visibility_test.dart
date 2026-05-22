import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';

void main() {
  testWidgets('pairing token can be shown and hidden without losing text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SetupScreen())),
    );

    final tokenFieldFinder = find.widgetWithText(TextField, 'Pairing token');
    TextField tokenField() => tester.widget<TextField>(tokenFieldFinder);

    expect(tokenField().obscureText, isTrue);
    expect(find.byTooltip('Show pairing token'), findsOneWidget);

    await tester.enterText(tokenFieldFinder, 'nvbx_visible_when_requested');
    await tester.tap(find.byTooltip('Show pairing token'));
    await tester.pump();

    expect(tokenField().obscureText, isFalse);
    expect(find.byTooltip('Hide pairing token'), findsOneWidget);
    expect(tokenField().controller?.text, 'nvbx_visible_when_requested');

    await tester.tap(find.byTooltip('Hide pairing token'));
    await tester.pump();

    expect(tokenField().obscureText, isTrue);
    expect(find.byTooltip('Show pairing token'), findsOneWidget);
    expect(tokenField().controller?.text, 'nvbx_visible_when_requested');
  });
}
