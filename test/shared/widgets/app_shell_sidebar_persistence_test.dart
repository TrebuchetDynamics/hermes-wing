import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';
import 'app_shell_navigation_groups_test.dart' as navigation;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shell restores a saved collapsed sidebar without Agent calls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wing.shell.sidebar_expanded': false,
    });
    tester.view.physicalSize = const Size(1280, 900);
    final channel = FakeHermesChannel.disconnected();
    await navigation.pumpShell(tester, channel);

    expect(
      tester.getSize(find.byKey(const ValueKey('desktop-sidebar'))).width,
      64,
    );
    navigation.expectNoChannelCalls(channel);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard collapse survives a fresh shell and provider scope', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel.disconnected();
    await navigation.pumpShell(tester, channel);
    final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
    final toggle = find.byKey(const ValueKey('desktop-sidebar-toggle'));
    final draftState = tester.state(find.byType(TextField));
    await tester.enterText(find.byKey(const ValueKey('draft')), 'local draft');
    await navigation.reach(tester, toggle);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 64);
    expect(tester.state(find.byType(TextField)), same(draftState));
    expect(find.text('local draft'), findsOneWidget);
    expect(navigation.flag(tester, toggle, focused: true), isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'wing.shell.sidebar_expanded',
      ),
      isFalse,
    );
    navigation.expectNoChannelCalls(channel);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final replacement = FakeHermesChannel.disconnected();
    await navigation.pumpShell(tester, replacement);
    expect(tester.getSize(sidebar).width, 64);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 250);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'wing.shell.sidebar_expanded',
      ),
      isTrue,
    );
    navigation.expectNoChannelCalls(replacement);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('compact layout and route changes retain the saved choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    final channel = FakeHermesChannel.disconnected();
    final router = await navigation.pumpShell(tester, channel);
    final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
    await tester.tap(find.byKey(const ValueKey('desktop-sidebar-toggle')));
    await tester.pumpAndSettle();
    router.go('/tools');
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 64);
    tester.view.physicalSize = const Size(390, 900);
    await tester.pumpAndSettle();
    expect(sidebar, findsNothing);
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 64);
    navigation.expectNoChannelCalls(channel);
    expect(tester.takeException(), isNull);
  });
}
