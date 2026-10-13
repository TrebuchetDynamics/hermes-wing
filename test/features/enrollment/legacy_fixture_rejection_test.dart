import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../integration_test/hermes_features_maestro_main.dart' as fixture;

void main() {
  testWidgets(
    'Maestro fixture rejects pairing and recovers to direct options',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final previousErrorHandler = FlutterError.onError;
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      await fixture.main();
      await tester.pumpAndSettle();
      final pairing = find.text('Legacy input rejection fixture');
      await tester.scrollUntilVisible(
        pairing,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(pairing);
      await tester.pumpAndSettle();
      expect(
        find.text('Pairing links are no longer supported'),
        findsOneWidget,
      );
      expect(find.text('Paste pairing link'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hermes-welcome')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
