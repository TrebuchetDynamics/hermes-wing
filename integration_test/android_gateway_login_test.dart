import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/enrollment/widgets/gateway_login_panel.dart';
import 'package:wing/l10n/app_localizations.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android gateway login manual fallback is usable at enlarged text',
    (tester) async {
      if (!Platform.isAndroid ||
          !const bool.fromEnvironment('WING_GATEWAY_LOGIN_QA')) {
        throw StateError('Use isolated QA app');
      }
      for (final scale in [1.0, 2.0]) {
        await binding.setSurfaceSize(const Size(390, 1000));
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(child: GatewayLoginPanel()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final address = find.byKey(const ValueKey('gateway-address'));
        await tester.ensureVisible(address);
        await tester.enterText(address, 'http://example.invalid');
        final action = find.byKey(const ValueKey('gateway-sign-in'));
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            'Gateway sign-in or connection could not be completed.',
          ),
          findsOneWidget,
        );
        expect(find.text('Access token'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await binding.setSurfaceSize(null);
      binding.reportData = {
        'gateway_login':
            'native Android UI and secure storage load; insecure input refused; 100/200% text. Camera and real browser auth not qualified.',
      };
    },
  );
}
