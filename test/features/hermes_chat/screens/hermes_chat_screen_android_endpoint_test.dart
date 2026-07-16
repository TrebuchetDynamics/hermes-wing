import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

void main() {
  testWidgets('Android uses the configured network Hermes endpoint', (
    tester,
  ) async {
    const configuredBaseUrl = String.fromEnvironment('WING_HERMES_BASE_URL');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      debugDefaultTargetPlatformOverride = null;
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(
            FakeHermesChannel.disconnected(),
          ),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(home: HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('hermes-base-url-field')),
          )
          .controller
          ?.text,
      configuredBaseUrl,
    );
    expect(find.text('Connect to your Hermes VPS'), findsOneWidget);
    expect(find.text('Android emulator'), findsNothing);

    final developerShortcuts = find.byKey(
      const ValueKey('hermes-developer-shortcuts'),
    );
    await tester.ensureVisible(developerShortcuts);
    await tester.tap(developerShortcuts);
    await tester.pumpAndSettle();

    expect(find.text('This device'), findsNothing);
    expect(find.text('Android emulator'), findsOneWidget);
    expect(find.text('Clear server details'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
