import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wing/core/hermes/setup/hermes_gateway_invite.dart';
import 'package:wing/features/enrollment/widgets/gateway_qr_builder.dart';
import 'package:wing/features/enrollment/widgets/gateway_login_panel.dart';
import 'package:wing/l10n/app_localizations.dart';

Widget app(Widget child) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('QR creator never emits credential or malformed origin', (
    tester,
  ) async {
    await tester.pumpWidget(app(const GatewayQrBuilder()));
    final fields = find.byType(TextField);
    await tester.enterText(
      fields.first,
      'https://example.invalid?token=synthetic',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Show connection QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    await tester.enterText(fields.first, 'https://example.invalid');
    await tester.enterText(fields.last, 'my_bot');
    await tester.tap(find.widgetWithText(FilledButton, 'Show connection QR'));
    await tester.pumpAndSettle();
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.semanticsLabel, isNotNull);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      HermesGatewayInvite(
        origin: Uri.parse('https://example.invalid'),
        profile: 'my_bot',
      ).encode(),
      isNot(contains('token')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual phone login entry opens without network or camera', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(app(const GatewayLoginPanel()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gateway-sign-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('gateway-scan')), findsNothing);
    expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
    expect(find.byKey(const ValueKey('gateway-reconnect')), findsNothing);
    expect(find.textContaining('synthetic'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });
}
