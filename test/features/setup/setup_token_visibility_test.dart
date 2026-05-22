import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';

void main() {
  testWidgets('pairing token can be shown and hidden without losing text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SetupScreen())),
    );

    final tokenFieldFinder = find.widgetWithText(TextField, 'Pairing token');
    TextField tokenField() => tester.widget<TextField>(tokenFieldFinder);

    expect(tokenField().obscureText, isTrue);
    expect(find.byTooltip('Show pairing token'), findsOneWidget);

    await tester.enterText(tokenFieldFinder, 'nvbx_visible_when_requested');
    await tester.ensureVisible(_tokenVisibilityButton('Show pairing token'));
    await tester.tap(_tokenVisibilityButton('Show pairing token'));
    await tester.pump();

    expect(tokenField().obscureText, isFalse);
    expect(find.byTooltip('Hide pairing token'), findsOneWidget);
    expect(tokenField().controller?.text, 'nvbx_visible_when_requested');

    await tester.ensureVisible(_tokenVisibilityButton('Hide pairing token'));
    await tester.tap(_tokenVisibilityButton('Hide pairing token'));
    await tester.pump();

    expect(tokenField().obscureText, isTrue);
    expect(find.byTooltip('Show pairing token'), findsOneWidget);
    expect(tokenField().controller?.text, 'nvbx_visible_when_requested');
  });
}

Finder _tokenVisibilityButton(String tooltip) {
  return find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == tooltip,
  );
}
