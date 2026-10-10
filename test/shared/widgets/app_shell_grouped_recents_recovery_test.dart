import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';

import 'app_shell_global_session_access_test.dart' as support;
import 'app_shell_grouped_recents_test.dart' as grouped;

final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));

void noIncidentalWork(support.Harness h, support.DelayedChannel channel) {
  h.noIncidentalWork();
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.renameSessionCalls, isEmpty);
  expect(channel.deleteSessionCalls, isEmpty);
  expect(channel.forkSessionCalls, isEmpty);
  expect(channel.sentImageDataUrls, isEmpty);
  expect(channel.sentTextAttachments, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.stopActiveTurnCalls, 0);
  expect(channel.refreshModelsCalls, 0);
  expect(channel.assignModelCalls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.selectProfileCalls, isEmpty);
  expect(channel.connectCalls, isEmpty);
  expect(channel.loadMoreSessionsCalls, 0);
  expect(channel.loadEarlierMessagesCalls, 0);
  expect(channel.loadModelsCalls, 0);
}

Future<void> key(WidgetTester tester, LogicalKeyboardKey value) async {
  await tester.sendKeyEvent(value);
  await tester.pumpAndSettle();
}

Future<void> hideAndReturn(WidgetTester tester, String mode) async {
  if (mode == 'collapse') {
    await grouped.reach(tester, toggle);
    await key(tester, LogicalKeyboardKey.space);
  } else {
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
  }
  expect(grouped.inventory, findsNothing);
  // Traverse the hidden layout in both directions. Disposed rows are absent,
  // not merely painted off-screen or actionable through a lingering focus node.
  for (final reverse in [false, true]) {
    for (var i = 0; i < 16; i++) {
      if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(grouped.open('a1'), findsNothing);
      expect(grouped.open('b1'), findsNothing);
    }
  }
  if (mode == 'collapse') {
    await grouped.reach(tester, toggle, reverse: true);
    await key(tester, LogicalKeyboardKey.enter);
  } else {
    tester.view.physicalSize = const Size(1280, 600);
    await tester.pumpAndSettle();
  }
  expect(grouped.open('b1'), findsOneWidget);
  expect(tester.takeException(), isNull);
}

support.DelayedChannel channel() {
  final value = support.DelayedChannel();
  value.change(
    value.state.copyWith(sessions: grouped.rows, activeSessionId: 'a1'),
  );
  return value;
}

void main() {
  for (final mode in ['collapse', 'compact']) {
    testWidgets('keyboard $mode return restores forward/reverse exact Open', (
      tester,
    ) async {
      final h = support.Harness(channel());
      await h.pump(tester, height: 600, scale: 2);
      final semantics = tester.ensureSemantics();
      await grouped.reach(tester, grouped.open('b1'));
      await hideAndReturn(tester, mode);
      await grouped.reach(tester, grouped.open('b1'));
      await grouped.reach(tester, grouped.open('a1'), reverse: true);
      expect(h.channel.selectSessionCalls, isEmpty);
      noIncidentalWork(h, h.channel);
      await key(tester, LogicalKeyboardKey.enter);
      expect(h.channel.selectSessionCalls, ['a1']);
      expect(h.channel.state.activeSessionId, 'a1');
      expect(h.path, '/hermes');
      h.router.go('/tools');
      await tester.pumpAndSettle();
      await grouped.reach(tester, grouped.open('b1'), reverse: true);
      await key(tester, LogicalKeyboardKey.space);
      expect(h.channel.selectSessionCalls, ['a1', 'b1']);
      expect(h.channel.state.activeSessionId, 'b1');
      expect(h.path, '/hermes');
      noIncidentalWork(h, h.channel);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  for (final owner in ['profile A-B-A', 'identical-ID channel']) {
    for (final mode in ['visible', 'collapse', 'compact']) {
      testWidgets('pending grouped Open rejects $owner through $mode return', (
        tester,
      ) async {
        final original = channel()..gate = Completer<void>();
        final h = support.Harness(original);
        await h.pump(tester, height: 600, scale: 2);
        final semantics = tester.ensureSemantics();
        await grouped.reach(tester, grouped.open('b1'));
        await key(tester, LogicalKeyboardKey.enter);
        expect(original.selectSessionCalls, ['b1']);
        expect(h.path, '/tools');
        expect(find.text('Opening session…'), findsOneWidget);
        expect(tester.widget<TextButton>(grouped.open('b1')).onPressed, isNull);
        expect(original.selectSessionCalls, ['b1']);
        var current = original;
        final before = original.state;
        if (owner == 'profile A-B-A') {
          original.change(before.copyWith(selectedProfileId: 'replacement'));
          original.change(before);
        } else {
          current = channel();
          addTearDown(current.dispose);
          h.container.updateOverrides([
            hermesChannelProvider.overrideWithValue(current),
            hermesDirectoryLifetimeProvider.overrideWithValue(h.lifetime),
            hermesGatewayDirectoryProvider.overrideWith((_) => h.directory),
          ]);
          await h.container.pump();
        }
        await tester.pumpAndSettle();
        if (mode != 'visible') await hideAndReturn(tester, mode);
        // A reconnect roundtrip must also remain read/action-free. Owner-only
        // cases above still discriminate A-B-A and channel replacement first.
        original.gate!.complete();
        await tester.pumpAndSettle();
        expect(h.path, '/tools');
        expect(original.state.activeSessionId, 'a1');
        expect(current.state.activeSessionId, 'a1');
        expect(current.state.activeMessages, isEmpty);
        expect(
          find.text('Could not open the session. Try again in Chat.'),
          findsNothing,
        );
        final settled = current.state;
        current.change(
          settled.copyWith(status: HermesConnectionStatus.disconnected),
        );
        await tester.pumpAndSettle();
        expect(grouped.open('b1'), findsNothing);
        current.change(settled);
        await tester.pumpAndSettle();
        expect(original.selectSessionCalls, ['b1']);
        if (!identical(current, original)) {
          expect(current.selectSessionCalls, isEmpty);
        }
        noIncidentalWork(h, original);
        noIncidentalWork(h, current);
        // Fresh keyboard intent is admitted, not replayed by returning/reconnecting.
        current.gate = null;
        await grouped.reach(tester, grouped.open('b1'));
        await grouped.reach(tester, grouped.open('a1'), reverse: true);
        await grouped.reach(tester, grouped.open('b1'));
        await key(tester, LogicalKeyboardKey.space);
        expect(
          current.selectSessionCalls,
          identical(current, original) ? ['b1', 'b1'] : ['b1'],
        );
        expect(current.state.activeSessionId, 'b1');
        expect(h.path, '/hermes');
        noIncidentalWork(h, current);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
}
