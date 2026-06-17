import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/settings/screens/settings_screen.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/app/test_material_app.dart';
import '../../shared/fixtures/profile_contact_channel_fixtures.dart';
import '../../shared/fixtures/profile_contact_fixtures.dart';

void main() {
  testWidgets('renders continuous voice controls for the active server', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers([localGormesServer], activeServerId: 'local');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const SettingsScreen()),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Local voice preferences'), findsOneWidget);
    expect(find.text('Continuous voice'), findsOneWidget);
    expect(find.text('Command word'), findsOneWidget);
    expect(find.text('navi'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-command-word')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Say "navi"'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    final trustSwitch = find.byKey(const ValueKey('voice-trust-local'));
    await tester.scrollUntilVisible(trustSwitch, 200);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(trustSwitch).value, isFalse);

    await tester.tap(trustSwitch);
    await tester.pump();

    expect(tester.widget<SwitchListTile>(trustSwitch).value, isTrue);
  });

  testWidgets('speak-replies toggle defaults off and can be enabled', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers([localGormesServer], activeServerId: 'local');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const SettingsScreen()),
    );

    final speakReplies = find.byKey(
      const ValueKey('voice-speak-replies-enabled'),
    );
    await tester.scrollUntilVisible(speakReplies, 200);
    await tester.pumpAndSettle();

    expect(find.text('Speak replies aloud'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(speakReplies).value, isFalse);

    await tester.tap(speakReplies);
    await tester.pump();

    expect(tester.widget<SwitchListTile>(speakReplies).value, isTrue);
  });

  testWidgets('settings explain local scope and link to management tabs', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers([localGormesServer], activeServerId: 'local');

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const SettingsScreen()),
    );

    expect(find.text('Local settings'), findsOneWidget);
    expect(
      find.text(
        'Preferences on this Navivox install. Gormes config, profile contacts, and gateway auth live in their own surfaces.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Command word, local capture, and voice trust stay in Navivox.',
      ),
      findsOneWidget,
    );
    final manageGateways = find.byKey(
      const ValueKey('settings-manage-gateways'),
    );
    await tester.scrollUntilVisible(manageGateways, 200);
    await tester.pumpAndSettle();

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
      ..seedServers([
        localGormesServer,
        remoteGormesServer,
      ], activeServerId: 'local')
      ..seedProfileContacts([
        mineruBuilderProfile(latestPreview: 'Ready', workspaceRootCount: 0),
        linkReviewerProfile(),
        sidonPlannerProfile(),
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
    final channel = localGormesMineruChannel(
      contact: mineruBuilderProfile(
        latestPreview: 'Ready',
        workspaceRootCount: 0,
      ),
    );

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
