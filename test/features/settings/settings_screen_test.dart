import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

void main() {
  testWidgets('surfaces optional inventory failures without raw errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel(
      optionalResourceErrors: const {
        HermesOptionalResource.skills: 'Authorization: Bearer private-value',
        HermesOptionalResource.models: '/home/operator/private-models',
      },
    );
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            const EmptyHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings-copy-diagnostics')),
      300,
    );

    expect(find.text('Inventory warnings'), findsOneWidget);
    expect(find.text('Models, skills unavailable'), findsOneWidget);
    expect(find.textContaining('private-value'), findsNothing);
    expect(find.textContaining('/home/operator'), findsNothing);
  });

  testWidgets('copies the bounded Hermes diagnostics snapshot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final channel = FakeHermesChannel(
      status: HermesConnectionStatus.connected,
      models: const ['hermes-3'],
    );
    addTearDown(channel.dispose);
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          hermesEndpointStoreProvider.overrideWithValue(
            const EmptyHermesEndpointStore(),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final copy = find.byKey(const ValueKey('settings-copy-diagnostics'));
    await tester.scrollUntilVisible(copy, 300);
    await tester.tap(copy);
    await tester.pump();

    expect(copiedText, contains('Hermes Wing diagnostics'));
    expect(copiedText, contains('Models: hermes-3'));
    expect(copiedText, contains('Secrets: excluded'));
    expect(find.text('Hermes diagnostics copied'), findsOneWidget);
  });
}
