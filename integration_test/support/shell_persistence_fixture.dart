import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/providers/shell_preferences_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../../test/features/hermes_chat/support/fake_hermes_channel.dart';
import '../../test/shared/widgets/app_shell_navigation_groups_test.dart'
    as navigation;

Future<Map<String, Object?>> runShellPersistenceJourney(
  WidgetTester tester,
  String phase,
) async {
  final semantics = tester.ensureSemantics();
  final channel = FakeHermesChannel.disconnected();
  await navigation.pumpShell(tester, channel);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AppShell)),
  );
  await tester.runAsync(
    () => container.read(wingSidebarExpandedProvider.notifier).loaded,
  );
  await tester.pumpAndSettle();
  final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
  final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));
  final initialWidth = tester.getSize(sidebar).width;
  expect(initialWidth, phase == 'collapse' ? 250 : 64);
  if (phase == 'collapse') {
    await navigation.reach(tester, toggle);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(navigation.flag(tester, toggle, focused: true), isTrue);
  }
  expect(tester.getSize(sidebar).width, 64);
  await tester.runAsync(() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    expect(preferences.getBool('wing.shell.sidebar_expanded'), isFalse);
  });
  navigation.expectNoChannelCalls(channel);
  final reads =
      channel.loadEarlierMessagesCalls +
      channel.loadMoreSessionsCalls +
      channel.reconcileActiveSessionCalls +
      channel.readProfileSoulCalls.length +
      channel.loadDetailedHealthCalls +
      channel.loadJobsCalls +
      channel.loadToolInventoryCalls +
      channel.loadProvidersCalls +
      channel.loadModelsCalls +
      channel.refreshModelsCalls +
      channel.validateProviderCredentialCalls.length;
  final sends =
      channel.sentTextAttachments.length + channel.sentVoiceTranscripts.length;
  final mutations =
      channel.connectCalls.length +
      channel.disconnectCalls +
      channel.createSessionCalls.length +
      channel.selectSessionCalls.length +
      channel.selectProfileCalls.length +
      channel.createProfileCalls.length +
      channel.renameProfileCalls.length +
      channel.deleteProfileCalls.length +
      channel.writeProfileSoulCalls.length +
      channel.renameSessionCalls.length +
      channel.deleteSessionCalls.length +
      channel.forkSessionCalls.length +
      channel.assignModelCalls.length +
      channel.lockSessionModelCalls.length +
      channel.respondToApprovalCalls.length +
      channel.stopActiveTurnCalls +
      channel.steerActiveTurnCalls.length +
      channel.setProviderCredentialCalls.length +
      channel.removeProviderCredentialCalls.length;
  expect([reads, sends, mutations], [0, 0, 0]);
  expect(tester.takeException(), isNull);
  semantics.dispose();
  return {
    'phase': phase,
    'initial_width': initialWidth,
    'restored_width': tester.getSize(sidebar).width,
    'keyboard_collapse': phase == 'collapse',
    'persisted_expanded': false,
    'reads': reads,
    'sends': sends,
    'mutations': mutations,
  };
}

Future<void> runUnavailableStorageJourney(WidgetTester tester) async {
  final channel = FakeHermesChannel.disconnected();
  addTearDown(channel.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        wingSidebarExpandedProvider.overrideWith(
          () => WingShellPreferencesController(
            loadPreferences: () async => throw StateError('Storage denied'),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppShell(
          location: AppRoutes.hermes,
          child: Scaffold(body: Text('Isolated shell')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final semantics = tester.ensureSemantics();
  await navigation.reach(
    tester,
    find.byKey(const ValueKey('desktop-sidebar-toggle')),
  );
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
  expect(
    tester.getSize(find.byKey(const ValueKey('desktop-sidebar'))).width,
    64,
  );
  navigation.expectNoChannelCalls(channel);
  expect(tester.takeException(), isNull);
  semantics.dispose();
}
