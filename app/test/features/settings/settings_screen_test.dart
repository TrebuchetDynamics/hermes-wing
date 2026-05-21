import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/settings/screens/settings_screen.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  testWidgets('renders continuous voice controls for the active server', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Voice settings'), findsOneWidget);
    expect(find.text('Continuous voice'), findsOneWidget);
    expect(find.text('Command word'), findsOneWidget);
    expect(find.text('navi'), findsOneWidget);

    final trustSwitch = find.byKey(const ValueKey('voice-trust-local'));
    expect(tester.widget<SwitchListTile>(trustSwitch).value, isFalse);

    await tester.tap(trustSwitch);
    await tester.pump();

    expect(tester.widget<SwitchListTile>(trustSwitch).value, isTrue);
  });
}
