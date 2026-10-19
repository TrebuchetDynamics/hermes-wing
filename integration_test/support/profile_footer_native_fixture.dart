import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';
import 'package:wing/shared/widgets/app_shell.dart';
import 'package:wing/shared/widgets/app_shell_desktop_style.dart';

import '../../test/features/hermes_chat/support/fake_hermes_gateway_directory.dart';
import '../../test/shared/widgets/app_shell_focus_traversal_test.dart' as focus;
import '../../test/shared/widgets/app_shell_navigation_groups_test.dart'
    as navigation;
import '../../test/shared/widgets/app_shell_profile_footer_test.dart' as footer;

Future<int> expectPaintedProfileFooterFocus(WidgetTester tester) async {
  final rect = tester.getRect(footer.manage);
  final pixels = (await tester.runAsync(() async {
    final image =
        await (tester.binding.renderViews.first.debugLayer! as OffsetLayer)
            .toImage(const Rect.fromLTWH(0, 0, 1280, 720));
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data;
  }))!;
  final style = AppShellDesktopStyle.forBrightness(
    Theme.of(tester.element(footer.manage)).brightness,
  );
  // The focus border is translucent over the rail, not an opaque RGB token.
  // Match rendered pixels (as in the footer widget oracle), not Material state.
  final color = Color.alphaBlend(style.secondary, style.rail);
  var outline = 0;
  for (var y = rect.top.toInt(); y < rect.top.toInt() + 3; y++) {
    for (var x = rect.left.toInt() + 12; x < rect.right.toInt() - 12; x++) {
      final offset = (y * 1280 + x) * 4;
      if ((pixels.getUint8(offset) - (color.r * 255).round()).abs() <= 1 &&
          (pixels.getUint8(offset + 1) - (color.g * 255).round()).abs() <= 1 &&
          (pixels.getUint8(offset + 2) - (color.b * 255).round()).abs() <= 1) {
        outline++;
      }
    }
  }
  expect(outline, greaterThanOrEqualTo(24));
  return outline;
}

Future<Map<String, Object?>> runProfileFooterJourney(
  WidgetTester tester,
  Future<void> Function(Size) resize,
) async {
  final phases = <Map<String, Object?>>[];
  final traces = <Map<String, Object?>>[];
  final recovery = <Map<String, Object?>>[];
  for (final scale in [1.0, 2.0]) {
    await resize(const Size(1280, 720));
    // Keep layer capture coordinates aligned with the framework layout viewport.
    tester.view.physicalSize = const Size(1280, 720);
    final old = footer.DisplayChannel(
      footer.displayState().copyWith(activeSessionId: 'synthetic-session-a'),
    );
    final replacement = footer.DisplayChannel(
      footer
          .displayState(
            id: 'b',
            name: 'Profile B /home/example/private token=dummy',
          )
          .copyWith(activeSessionId: 'synthetic-session-b'),
    );
    addTearDown(replacement.dispose);
    final router = await footer.pumpFooter(
      tester,
      old,
      scale: scale,
      realDestination: true,
    );
    final semantics = tester.ensureSemantics();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppShell)),
    );
    var channel = old;
    void passiveOverrides() => container.updateOverrides([
      hermesChannelProvider.overrideWithValue(channel),
      hermesGatewayDirectoryProvider.overrideWith(
        (_) => throw StateError('Passive footer constructed a directory'),
      ),
    ]);
    passiveOverrides();
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));
    final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
    final draft = find.byKey(const ValueKey('draft'));
    Future<void> toggleSidebar() async {
      await navigation.reach(tester, toggle);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }

    if (tester.getSize(sidebar).width == 64) await toggleSidebar();
    footer.expectDisplay(tester, 'Profile A');
    Future<void> trace(String phase) async {
      await navigation.reach(tester, footer.manage);
      await tester.pump(const Duration(milliseconds: 350));
      expect(footer.manage.hitTestable(), findsOneWidget);
      final rect = tester.getRect(footer.manage);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(1280));
      expect(rect.bottom, lessThanOrEqualTo(720));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      final outline = await expectPaintedProfileFooterFocus(tester);
      final focused = FocusManager.instance.primaryFocus;
      await focus.tab(tester);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await focus.tab(tester, backwards: true);
      expect(FocusManager.instance.primaryFocus, same(focused));
      await focus.tab(tester, backwards: true);
      expect(
        navigation.flag(
          tester,
          find.bySemanticsLabel('Settings'),
          focused: true,
        ),
        isTrue,
      );
      await focus.tab(tester);
      expect(FocusManager.instance.primaryFocus, same(focused));
      traces.add({
        'phase': phase,
        'scale': scale,
        'rect': [rect.left, rect.top, rect.right, rect.bottom],
        'outline_pixels': outline,
        'inverse_traversal': true,
        'label': tester.getSemantics(footer.manage).label,
      });
    }

    await trace('expanded');
    await toggleSidebar();
    expect(tester.getSize(sidebar).width, 64);
    await trace('collapsed');
    channel = replacement;
    passiveOverrides();
    await tester.pumpAndSettle();
    old.change(
      footer
          .displayState(name: 'Obsolete owner')
          .copyWith(activeSessionId: 'obsolete-session'),
    );
    await tester.pumpAndSettle();
    const safeLabel =
        'Manage profiles — Profile: Profile B [redacted-path] token=[redacted]';
    expect(tester.getSemantics(footer.manage).label, safeLabel);
    final owner = replacement.state;
    await tester.enterText(draft, 'synthetic local draft');
    for (final size in [const Size(390, 720), const Size(1280, 720)]) {
      await resize(size);
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(sidebar, size.width == 390 ? findsNothing : findsOneWidget);
      expect(
        ProviderScope.containerOf(tester.element(find.byType(AppShell))),
        same(container),
      );
      expect(replacement.state, same(owner));
    }
    expect(tester.getSize(sidebar).width, 64);
    expect(tester.getSemantics(footer.manage).label, safeLabel);
    await trace('adaptive-return');
    for (final key in [LogicalKeyboardKey.space, LogicalKeyboardKey.enter]) {
      if (key == LogicalKeyboardKey.enter) {
        await toggleSidebar();
        footer.expectDisplay(
          tester,
          'Profile B [redacted-path] token=[redacted]',
        );
      }
      await trace(key == LogicalKeyboardKey.space ? 'space' : 'enter');
      // The real destination owns its directory; passive phases must never construct it.
      final loader = FakeGatewaySummaryLoader(const {});
      container.updateOverrides([
        hermesChannelProvider.overrideWithValue(replacement),
        hermesGatewayDirectoryProvider.overrideWith(
          (_) => directoryFor(
            configs: const [],
            loader: loader,
            activeChannel: replacement,
          ),
        ),
      ]);
      var navigations = 0;
      void onNavigation() {
        if (router.routeInformationProvider.value.uri.path == '/profiles') {
          navigations++;
        }
      }

      router.routerDelegate.addListener(onNavigation);
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profiles');
      expect(navigations, 1);
      expect(find.byType(ProfilesScreen), findsOneWidget);
      expect(find.text('New Profile'), findsNothing);
      expect(find.byKey(const ValueKey('profiles-search')), findsNothing);
      expect(replacement.state, same(owner));
      expect(owner.selectedProfileId, 'b');
      expect(owner.activeSessionId, 'synthetic-session-b');
      phases.add({
        'scale': scale,
        'key': key == LogicalKeyboardKey.space ? 'space' : 'enter',
        'navigations': navigations,
        'profile': owner.selectedProfileId,
        'session': owner.activeSessionId,
        'reads': 0,
        'sends': 0,
        'mutations': 0,
      });
      final returnSize = key == LogicalKeyboardKey.space
          ? const Size(390, 720)
          : const Size(1280, 720);
      await resize(returnSize);
      tester.view.physicalSize = returnSize;
      await tester.pumpAndSettle();
      old.change(footer.displayState(name: 'Retired during management return'));
      await tester.pumpAndSettle();
      final chat = find.byKey(const ValueKey('chat-workspace-overlay-close'));
      await navigation.reach(tester, chat);
      final returnFocused = navigation.flag(tester, chat, focused: true);
      expect(returnFocused, isTrue);
      expect(chat.hitTestable(), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/hermes');
      expect(find.byType(ProfilesScreen), findsNothing);
      expect(replacement.state, same(owner));
      // Ordinary go routing recreates this route-local editor; no draft store is added.
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
      final routeReads = loader.calls.length;
      expect(
        routeReads,
        0,
        reason: 'No configured inventory source or read grant',
      );
      passiveOverrides();
      await tester.pumpAndSettle();
      replacement.change(
        owner.copyWith(status: HermesConnectionStatus.disconnected),
      );
      await tester.pumpAndSettle();
      if (returnSize.width == 1280) {
        expect(
          tester.getSemantics(footer.manage).label,
          'Manage profiles — Profile: Not loaded',
        );
      }
      old.change(footer.displayState(name: 'Retired while disconnected'));
      await tester.pumpAndSettle();
      replacement.change(owner);
      await tester.pumpAndSettle();
      old.change(footer.displayState(name: 'Retired after reconnect'));
      await tester.pumpAndSettle();
      expect(replacement.state, same(owner));
      expect(router.routeInformationProvider.value.uri.path, '/hermes');
      expect(navigations, 1);
      router.routerDelegate.removeListener(onNavigation);
      expect(loader.calls.length, routeReads);
      if (returnSize.width == 390) {
        expect(sidebar, findsNothing);
        await resize(const Size(1280, 720));
        tester.view.physicalSize = const Size(1280, 720);
        await tester.pumpAndSettle();
      }
      expect(tester.getSemantics(footer.manage).label, safeLabel);
      await trace(
        key == LogicalKeyboardKey.space ? 'compact-recovery' : 'wide-recovery',
      );
      recovery.add({
        'scale': scale,
        'return_width': returnSize.width,
        'return_focused': returnFocused,
        'route': router.routeInformationProvider.value.uri.path,
        'profile': replacement.state.selectedProfileId,
        'session': replacement.state.activeSessionId,
        'profiles_route_reads': routeReads,
        'reconnected': replacement.state.isConnected,
        'retired_notifications': 3,
        'draft': tester
            .widget<EditableText>(find.byType(EditableText))
            .controller
            .text,
      });
      router.go('/tools');
      await tester.pumpAndSettle();
    }
    await toggleSidebar();
    expect(tester.getSize(sidebar).width, 64);
    for (final c in [old, replacement]) {
      navigation.expectNoChannelCalls(c);
      expect(c.readProfileSoulCalls, isEmpty);
      expect(c.validateProviderCredentialCalls, isEmpty);
      expect(c.sentVoiceTranscripts, isEmpty);
      expect([
        c.loadEarlierMessagesCalls,
        c.loadMoreSessionsCalls,
        c.reconcileActiveSessionCalls,
        c.loadDetailedHealthCalls,
        c.loadModelsCalls,
        c.refreshModelsCalls,
        c.steerActiveTurnCalls.length,
      ], everyElement(0));
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }
  return {
    'phase': 'profile-footer',
    'scales': [1.0, 2.0],
    'input': 'WidgetTester.sendKeyEvent in native Flutter engine',
    'resize_seam':
        'IntegrationTestWidgetsFlutterBinding.setSurfaceSize + TestFlutterView.physicalSize',
    'owner_replacement': true,
    'obsolete_notification_ignored': true,
    'compact_sidebar_absent': true,
    'returned_width': 64.0,
    'reads': 0,
    'sends': 0,
    'mutations': 0,
    'phases': phases,
    'focus': traces,
    'recovery': recovery,
  };
}
