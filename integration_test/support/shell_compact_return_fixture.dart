import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/providers/shell_preferences_provider.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../../test/features/hermes_chat/support/fake_hermes_channel.dart';
import '../../test/shared/widgets/app_shell_navigation_groups_test.dart'
    as navigation;
import 'shell_persistence_fixture.dart';

Future<Map<String, Object?>> runShellCompactReturnJourney(
  WidgetTester tester,
  Future<void> Function(Size) resize,
) async {
  await resize(const Size(1280, 900));
  final collapse = await runShellPersistenceJourney(tester, 'collapse');
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AppShell)),
  );
  final channel = container.read(hermesChannelProvider) as FakeHermesChannel;
  final draft = find.byKey(const ValueKey('draft'));
  final draftState = tester.state(find.byType(TextField));
  await tester.enterText(draft, 'local draft');
  final preferences = await tester.runAsync(SharedPreferences.getInstance);
  final before = preferences!.getBool('wing.shell.sidebar_expanded');
  expect(before, isFalse);
  final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
  for (final size in [const Size(390, 900), const Size(1280, 900)]) {
    await resize(size);
    await tester.pumpAndSettle();
    expect(sidebar, size.width == 390 ? findsNothing : findsOneWidget);
    if (size.width == 1280) expect(tester.getSize(sidebar).width, 64);
    expect(tester.state(find.byType(TextField)), same(draftState));
    expect(find.text('local draft'), findsOneWidget);
    expect(
      ProviderScope.containerOf(tester.element(find.byType(AppShell))),
      same(container),
    );
    expect(container.read(wingSidebarExpandedProvider), isFalse);
    await tester.runAsync(preferences.reload);
    expect(preferences.getBool('wing.shell.sidebar_expanded'), before);
  }
  navigation.expectNoChannelCalls(channel);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.readProfileSoulCalls, isEmpty);
  expect(channel.validateProviderCredentialCalls, isEmpty);
  expect([
    channel.loadEarlierMessagesCalls,
    channel.loadMoreSessionsCalls,
    channel.reconcileActiveSessionCalls,
    channel.loadDetailedHealthCalls,
    channel.loadModelsCalls,
    channel.refreshModelsCalls,
    channel.steerActiveTurnCalls.length,
  ], everyElement(0));
  expect(tester.takeException(), isNull);
  return {
    ...collapse,
    'phase': 'compact-return',
    'compact_width': 390,
    'returned_width': 1280,
    'compact_sidebar_absent': true,
    'draft_state_retained': true,
    'draft_text_retained': true,
    'provider_scope_retained': true,
    'preference_unchanged': true,
    'resize_seam': 'IntegrationTestWidgetsFlutterBinding.setSurfaceSize',
  };
}
