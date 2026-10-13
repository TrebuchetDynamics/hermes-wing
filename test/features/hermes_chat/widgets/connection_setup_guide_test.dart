import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/widgets/connection_setup_guide.dart';
import 'package:wing/l10n/app_localizations.dart';

void main() {
  for (final browser in [false, true]) {
    testWidgets(
      'guide explains token setup without claiming registration $browser',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ConnectionSetupGuide(
                  browserOrigin: browser ? 'http://127.0.0.1:8767' : null,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('1. Prepare Hermes Agent'), findsOneWidget);
        Future<void> next() async {
          final button = find.byKey(const ValueKey('connection-guide-next'));
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
        }

        await next();
        expect(find.textContaining('/p/<profile>'), findsOneWidget);
        await next();
        expect(find.textContaining('API_SERVER_KEY'), findsOneWidget);
        expect(find.textContaining('would not grant access'), findsOneWidget);
        final disabled = tester.widget<OutlinedButton>(
          find.byType(OutlinedButton),
        );
        expect(disabled.onPressed, isNull);
        await next();
        if (browser) {
          expect(find.text('4. Allow this browser'), findsOneWidget);
          expect(find.textContaining('http://127.0.0.1:8767'), findsOneWidget);
          await next();
        }
        expect(find.text('Check, save, then chat'), findsOneWidget);
        expect(
          find.textContaining('Only a reply proves generation'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
