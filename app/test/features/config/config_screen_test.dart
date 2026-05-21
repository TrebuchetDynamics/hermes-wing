import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import '../../support/test_navivox_channel.dart';
import 'package:navivox/features/config/screens/config_screen.dart';

void main() {
  testWidgets('shows empty-state message when no schema is loaded', (
    tester,
  ) async {
    final channel = TestNavivoxChannel();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: ConfigScreen()),
      ),
    );

    expect(find.text('No config available'), findsOneWidget);
  });

  testWidgets('renders each schema field with its current value', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..emitConfigSchema(const {
        'fields': [
          {'name': 'provider', 'type': 'string', 'required': true},
          {'name': 'temperature', 'type': 'number', 'required': false},
        ],
      })
      ..emitConfigValues(const {'provider': 'anthropic', 'temperature': 0.4});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: ConfigScreen()),
      ),
    );

    expect(find.text('provider'), findsOneWidget);
    expect(find.text('anthropic'), findsOneWidget);
    expect(find.text('temperature'), findsOneWidget);
    expect(find.text('0.4'), findsOneWidget);
  });

  testWidgets(
    'editing a number field calls sendConfigSet through the channel',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..emitConfigSchema(const {
          'fields': [
            {'name': 'temperature', 'type': 'number', 'required': false},
          ],
        })
        ..emitConfigValues(const {'temperature': 0.4});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(home: ConfigScreen()),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('config-edit-temperature')));
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('config-input-temperature')),
        '0.7',
      );
      await tester.tap(find.byKey(const ValueKey('config-save-temperature')));
      await tester.pump();

      expect(channel.configSetCalls, isNotEmpty);
      final last = channel.configSetCalls.last;
      expect(last.field, 'temperature');
      expect(last.value, 0.7);
    },
  );
}
