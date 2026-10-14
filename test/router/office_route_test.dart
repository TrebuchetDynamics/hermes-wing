import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../features/hermes_chat/support/fake_hermes_channel.dart';
import '../features/hermes_chat/support/fake_hermes_gateway_directory.dart';

void main() {
  testWidgets('retired office URL uses fallback without changing the owner', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    final owner = channel.state;
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
    router.go('/office');

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

    expect(find.text('Page not found'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(channel.state.selectedProfileId, owner.selectedProfileId);
    expect(channel.state.activeSessionId, owner.activeSessionId);
    expect(channel.connectCalls, isEmpty);
    expect(channel.createSessionCalls, isEmpty);
    expect(channel.selectProfileCalls, isEmpty);
    expect(channel.selectSessionCalls, isEmpty);
    expect(channel.sentTextAttachments, isEmpty);
    await tester.tap(find.text('Return to chat'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.hermes);
    expect(find.byType(AppShell), findsOneWidget);
    expect(channel.state.activeSessionId, owner.activeSessionId);
    expect(channel.createSessionCalls, isEmpty);
    expect(channel.selectSessionCalls, isEmpty);
    expect(channel.sentTextAttachments, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
