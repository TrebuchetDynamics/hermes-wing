import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/router/app_routes.dart';

import '../features/hermes_chat/support/fake_hermes_channel.dart';
import '../features/hermes_chat/support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('office route renders inside the app shell', (tester) async {
    final channel = FakeHermesChannel.disconnected();
    addTearDown(channel.dispose);
    final directory = directoryFor(
      configs: const [],
      loader: FakeGatewaySummaryLoader(const {}),
      activeChannel: channel,
    );
    await directory.refresh();
    final container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    router.go(AppRoutes.office);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Office'), findsWidgets);
    expect(find.text('No Hermes profiles available'), findsOneWidget);
    expect(find.text('HERMES ONE'), findsOneWidget);
  });
}
