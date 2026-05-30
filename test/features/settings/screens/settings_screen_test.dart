import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/settings/screens/settings_screen.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/test_material_app.dart';

void main() {
  testWidgets('renders continuous voice controls for the active server', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const SettingsScreen()),
    );

    expect(find.text('Voice settings'), findsOneWidget);
    expect(find.text('Continuous voice'), findsOneWidget);
    expect(find.text('Command word'), findsOneWidget);
    expect(find.text('navi'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-command-word')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Say "navi"'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    final trustSwitch = find.byKey(const ValueKey('voice-trust-local'));
    expect(tester.widget<SwitchListTile>(trustSwitch).value, isFalse);

    await tester.tap(trustSwitch);
    await tester.pump();

    expect(tester.widget<SwitchListTile>(trustSwitch).value, isTrue);
  });

  testWidgets('settings explain global scope and link to management tabs', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const SettingsScreen()),
    );

    expect(find.text('Global app settings'), findsOneWidget);
    expect(
      find.text(
        'Voice controls stay local to this app. Gateway and profile settings live in their own screens.',
      ),
      findsOneWidget,
    );
    expect(find.text('Manage gateways'), findsOneWidget);
    expect(find.text('Manage profile contacts'), findsOneWidget);

    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('settings-manage-gateways')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('settings-manage-profiles')),
          )
          .onTap,
      isNotNull,
    );
  });

  testWidgets('settings summarize registered gateways and profile contacts', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
        NavivoxServer(id: 'remote', name: 'Remote Gormes', status: 'offline'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
        ),
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'link',
          displayName: 'Link Reviewer',
          serverLabel: 'local',
          health: NavivoxProfileHealth.warning,
          latestPreview: 'Reviewing',
        ),
        NavivoxProfileContact(
          serverId: 'remote',
          profileId: 'sidon',
          displayName: 'Sidon Planner',
          serverLabel: 'remote',
          health: NavivoxProfileHealth.offline,
          latestPreview: 'Away',
        ),
      ], selectedKey: 'local::mineru');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const SettingsScreen()),
    );

    await tester.scrollUntilVisible(find.text('Management overview'), 200);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-management-overview')),
      findsOneWidget,
    );
    expect(find.text('Management overview'), findsOneWidget);
    expect(find.text('2 Gormes gateways · 3 profile contacts'), findsOneWidget);
  });

  testWidgets('settings expose the active gateway and profile scope', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
        ),
      ], selectedKey: 'local::mineru');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const SettingsScreen()),
    );

    await tester.scrollUntilVisible(find.text('Current session scope'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Current session scope'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-current-gateway')),
      findsOneWidget,
    );
    expect(find.text('Active Gormes gateway'), findsOneWidget);
    expect(find.text('Local Gormes · local · online'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-current-profile')),
      findsOneWidget,
    );
    expect(find.text('Active profile contact'), findsOneWidget);
    expect(find.text('Mineru Builder · local/mineru · online'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('settings-current-gateway')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('settings-current-profile')),
          )
          .onTap,
      isNotNull,
    );
  });
}
