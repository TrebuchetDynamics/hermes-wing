import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/theme/wing_theme.dart';

import 'hermes_features_maestro_main.dart' as fixture;

// Uses the real Linux preferences plugin. The launcher provides a fresh XDG
// directory shared by two separate app processes, never the user's preferences.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  WidgetController.hitTestWarningShouldBeFatal = true;
  final phase = Platform.environment['WING_PERSISTENCE_PHASE'];
  final config = Platform.environment['XDG_CONFIG_HOME'] ?? '';
  if (Platform.environment['WING_ISOLATED_PREFERENCES'] != '1' ||
      !config.startsWith('/tmp/wing-linux-persistence.') ||
      !{'write', 'verify'}.contains(phase)) {
    throw StateError('Use the isolated Linux persistence launcher.');
  }

  testWidgets('Linux real preferences $phase through settings and groups UI', (
    tester,
  ) async {
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousErrorHandler = FlutterError.onError;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    await fixture.main();
    await tester.pumpAndSettle();

    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> open(String destination) async {
      await tester.scrollUntilVisible(
        find.text(destination),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(find.text(destination));
    }

    await open('Chat fixture');
    await tap(find.byTooltip('All chats'));
    if (phase == 'write') {
      await tap(find.text('New group'));
      await tester.enterText(
        find.byKey(const ValueKey('chat-group-name-field')),
        'Fixture group',
      );
      await tap(find.text('Save'));
      await tap(find.byTooltip('Move to group').first);
      await tap(find.text('Fixture group').last);
      await tap(find.byTooltip('Show menu').first);
      await tap(find.text('Rename'));
      await tester.enterText(
        find.byKey(const ValueKey('chat-group-name-field')),
        'Fixture renamed',
      );
      await tap(find.text('Save'));
    }
    expect(find.text('Fixture renamed'), findsOneWidget);
    await tap(find.text('Fixture controls'));
    await tap(find.text('Check persisted groups'));
    await tap(find.text('Fixture controls'));
    expect(find.text('Group saved: true'), findsOneWidget);
    expect(find.text('Group moved: true'), findsOneWidget);
    expect(find.text('Submitted turns: 0'), findsOneWidget);
    await tap(find.text('Close controls'));
    await tap(find.text('Fixture home'));

    await open('Settings fixture');
    final mode = find.byKey(const ValueKey('settings-theme-mode'));
    final palette = find.byKey(const ValueKey('settings-palette-picker'));
    if (phase == 'write') {
      await tap(find.text('Dark'));
      await tap(palette);
      await tap(find.text('Forest').last);
    }
    expect(tester.widget<SegmentedButton<ThemeMode>>(mode).selected, {
      ThemeMode.dark,
    });
    expect(
      tester.widget<DropdownButton<WingThemePalette>>(palette).value,
      WingThemePalette.forest,
    );
    await tap(find.byKey(const ValueKey('settings-voice-link')));
    final spoken = find.byKey(const ValueKey('voice-speak-replies-enabled'));
    if (phase == 'write') await tap(spoken);
    expect(tester.widget<SwitchListTile>(spoken).value, isTrue);
    await tap(find.byKey(const ValueKey('voice-advanced-expansion')));
    final command = find.byKey(const ValueKey('settings-command-word'));
    if (phase == 'write') {
      await tap(command);
      await tester.enterText(
        find.byKey(const ValueKey('settings-command-word-field')),
        'fixturepause',
      );
      await tap(find.byKey(const ValueKey('settings-command-word-save')));
    }
    expect(find.text('fixturepause'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
