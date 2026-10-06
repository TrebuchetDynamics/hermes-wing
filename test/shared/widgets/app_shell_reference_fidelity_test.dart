import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/widgets/app_shell_desktop_style.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';
import 'app_shell_navigation_groups_test.dart' as navigation;

void main() {
  testWidgets(
    'redesigned shell uses Desktop palette and navigation type scale',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      final channel = FakeHermesChannel.disconnected();
      await navigation.pumpShell(tester, channel);
      final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
      final rail = tester.widget<ColoredBox>(
        find.descendant(of: sidebar, matching: find.byType(ColoredBox)).first,
      );
      expect(rail.color, const Color(0xfff8f8f8));
      expect(
        Theme.of(
          tester.element(find.byType(TextField)),
        ).scaffoldBackgroundColor,
        Colors.white,
      );
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Chat'),
      );
      expect(button.style!.textStyle!.resolve({})!.fontSize, 13);
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.widgetWithText(TextButton, 'Chat'),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.size, 16);
      expect(find.text('Workflow'), findsNothing);
      expect(find.text('Utilities'), findsNothing);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('app-shell-status-bar')))
            .height,
        26,
      );
      navigation.expectNoChannelCalls(channel);
    },
  );

  test('Desktop shell colors and focus states retain readable contrast', () {
    for (final brightness in Brightness.values) {
      final style = AppShellDesktopStyle.forBrightness(brightness);
      for (final pair in [
        (style.accent, Color.alphaBlend(style.selection, style.rail)),
        (style.foreground, style.rail),
        (style.secondary, style.rail),
        (style.accent, style.hover),
      ]) {
        final a = pair.$1.computeLuminance();
        final b = pair.$2.computeLuminance();
        final contrast = ((a > b ? a : b) + 0.05) / ((a < b ? a : b) + 0.05);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason: '$brightness $pair',
        );
      }
      final button = style.navigationStyle(selected: true);
      expect(button.overlayColor!.resolve({WidgetState.hovered}), style.hover);
      expect(
        button.side!.resolve({WidgetState.focused})!.color,
        style.secondary,
      );
    }
  });

  testWidgets(
    'reference sidebar footprint and header retain keyboard draft ownership',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      final semantics = tester.ensureSemantics();
      final channel = FakeHermesChannel.disconnected();
      await navigation.pumpShell(tester, channel);
      final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
      final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));
      final editorState = tester.state(find.byType(TextField));
      await tester.enterText(
        find.byKey(const ValueKey('draft')),
        'local draft',
      );

      expect(tester.getSize(sidebar).width, 250);
      expect(find.text('Hermes Agent client'), findsNothing);
      // Desktop's clean header parks the toggle top-right, not under a wordmark.
      final toggleRect = tester.getRect(toggle);
      expect(toggleRect.center.dx, greaterThan(200));
      expect(toggleRect.bottom, lessThanOrEqualTo(64));
      expect(toggleRect.width, greaterThanOrEqualTo(48));
      expect(toggleRect.height, greaterThanOrEqualTo(48));
      final selected = find.widgetWithText(TextButton, 'Chat');
      final button = tester.widget<TextButton>(selected);
      final colors = Theme.of(tester.element(selected)).colorScheme;
      expect(button.style!.foregroundColor!.resolve({}), colors.primary);
      expect(
        button.style!.backgroundColor!.resolve({}),
        AppShellDesktopStyle.forBrightness(colors.brightness).selection,
      );
      expect(tester.getSize(selected).height, greaterThanOrEqualTo(48));
      expect(
        button.style!.shape!.resolve({}),
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      );
      expect(navigation.flag(tester, find.bySemanticsLabel('Chat')), isTrue);

      await navigation.reach(tester, toggle);
      await tester.pump(const Duration(milliseconds: 350));
      final toggleMaterial = tester.widget<Material>(
        find.descendant(of: toggle, matching: find.byType(Material)).first,
      );
      expect(
        (toggleMaterial.shape! as RoundedRectangleBorder).side.color,
        AppShellDesktopStyle.forBrightness(Brightness.light).secondary,
        reason: 'The actual IconButton Material must paint the focus outline',
      );
      final pixels = (await tester.runAsync(() async {
        final image =
            await (tester.binding.renderViews.first.debugLayer! as OffsetLayer)
                .toImage(const Rect.fromLTWH(0, 0, 1280, 900));
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data;
      }))!;
      final rect = tester.getRect(toggle);
      var outlinePixels = 0;
      for (var y = rect.top.toInt(); y < rect.top.toInt() + 3; y++) {
        for (var x = rect.left.toInt() + 12; x < rect.right.toInt() - 12; x++) {
          final offset = (y * 1280 + x) * 4;
          if (pixels.getUint8(offset) == 0x55 &&
              pixels.getUint8(offset + 1) == 0x55 &&
              pixels.getUint8(offset + 2) == 0x55) {
            outlinePixels++;
          }
        }
      }
      expect(
        outlinePixels,
        greaterThanOrEqualTo(24),
        reason:
            'Settled keyboard focus must paint a continuous high-contrast edge',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.getSize(sidebar).width, 64);
      expect(navigation.flag(tester, toggle, focused: true), isTrue);
      expect(tester.state(find.byType(TextField)), same(editorState));
      expect(find.text('local draft'), findsOneWidget);
      expect(navigation.flag(tester, find.bySemanticsLabel('Chat')), isTrue);
      expect(
        find.byKey(const ValueKey('app-shell-status-bar')),
        findsOneWidget,
      );
      navigation.expectNoChannelCalls(channel);
      expect(tester.takeException(), isNull);
      semantics.dispose();

      // Exercise the same IconButton rendering path in both themes and icons,
      // including hover + focus; inspecting ButtonStyle.side alone misses ink
      // overlays painting over the Material shape's border.
      for (final brightness in Brightness.values) {
        final style = AppShellDesktopStyle.forBrightness(brightness);
        for (final icon in [Icons.chevron_left, Icons.chevron_right]) {
          final focus = FocusNode();
          final states = WidgetStatesController();
          await tester.pumpWidget(
            MaterialApp(
              theme: style.sidebarTheme(ThemeData(brightness: brightness)),
              home: Scaffold(
                backgroundColor: style.rail,
                body: Center(
                  child: IconButton(
                    key: const ValueKey('rendered-toggle'),
                    focusNode: focus,
                    statesController: states,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    style: style.toggleStyle(),
                    icon: Icon(icon, size: 16),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          );
          focus.requestFocus();
          states.update(WidgetState.hovered, true);
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 350));
          final control = find.byKey(const ValueKey('rendered-toggle'));
          final material = tester.widget<Material>(
            find.descendant(of: control, matching: find.byType(Material)).first,
          );
          final shape = material.shape! as RoundedRectangleBorder;
          expect(shape.side.color, style.secondary);
          expect(shape.side.width, 2);
          expect(tester.getSize(control), const Size(48, 48));
          final rendered = (await tester.runAsync(() async {
            final image =
                await (tester.binding.renderViews.first.debugLayer!
                        as OffsetLayer)
                    .toImage(const Rect.fromLTWH(0, 0, 1280, 900));
            final data = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            image.dispose();
            return data;
          }))!;
          final bounds = tester.getRect(control);
          // All four straight edges contain uninterrupted opaque outline pixels.
          for (var delta = -12; delta < 12; delta++) {
            for (final point in [
              Offset(bounds.center.dx + delta, bounds.top + 1),
              Offset(bounds.center.dx + delta, bounds.bottom - 2),
              Offset(bounds.left + 1, bounds.center.dy + delta),
              Offset(bounds.right - 2, bounds.center.dy + delta),
            ]) {
              final index = (point.dy.toInt() * 1280 + point.dx.toInt()) * 4;
              final color = Color.fromARGB(
                255,
                rendered.getUint8(index),
                rendered.getUint8(index + 1),
                rendered.getUint8(index + 2),
              );
              expect(
                color,
                style.secondary,
                reason: '$brightness $icon edge $point',
              );
              final a = color.computeLuminance();
              final b = style.rail.computeLuminance();
              expect(
                ((a > b ? a : b) + 0.05) / ((a < b ? a : b) + 0.05),
                greaterThanOrEqualTo(3),
              );
            }
          }
          await tester.pumpWidget(const SizedBox());
          focus.dispose();
          states.dispose();
        }
      }
    },
  );
}
