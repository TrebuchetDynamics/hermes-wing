import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';

import 'chat_text_direction_settings_test.dart' show app;

void main() {
  testWidgets(
    'collapse thinking persists locally and hydrates without changing direction or scale',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'wing.chat.text_direction': 'rtl',
        'wing.chat.transcript_text_scale': 1.37,
        'wing.chat.reasoning_collapsed_by_default': true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(wingChatPreferencesProvider.notifier)
          .setReasoningCollapsedByDefault(false);
      await tester.pumpAndSettle();
      expect(
        container.read(wingChatPreferencesProvider).reasoningCollapsedByDefault,
        isFalse,
      );
      expect(
        container.read(wingChatPreferencesProvider).textDirection,
        WingChatTextDirection.rtl,
      );
      expect(
        container.read(wingChatPreferencesProvider).transcriptTextScale,
        1.37,
      );
      await tester.pumpWidget(
        app(
          container,
          const SettingsScreen(
            initialPage: 'theme',
            initialSetting: 'appearance.reasoning-collapsed',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final control = find.byKey(
        const ValueKey('settings-reasoning-collapsed'),
      );
      expect(tester.widget<SwitchListTile>(control).value, isFalse);
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      expect(control.hitTestable(), findsOneWidget);
      await tester.tap(control);
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('wing.chat.reasoning_collapsed_by_default'), isTrue);
      expect(prefs.getString('wing.chat.text_direction'), 'rtl');
      expect(prefs.getDouble('wing.chat.transcript_text_scale'), 1.37);
      final reloaded = ProviderContainer();
      addTearDown(reloaded.dispose);
      reloaded.read(wingChatPreferencesProvider);
      await tester.pumpAndSettle();
      expect(
        reloaded.read(wingChatPreferencesProvider).reasoningCollapsedByDefault,
        isTrue,
      );
    },
  );

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'thinking setting search reaches Chat display at 200 percent: $width',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        (String, String?, String?)? target;
        await tester.pumpWidget(
          app(
            container,
            SettingsScreen(
              onTargetChanged: (category, page, setting) =>
                  target = (category, page, setting),
            ),
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('settings-search')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Collapse thinking');
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey(
              'settings-search-setting-appearance.reasoning-collapsed',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(target, (
          'config:appearance',
          'chat-display',
          'appearance.reasoning-collapsed',
        ));
        expect(
          find.byKey(const ValueKey('settings-reasoning-collapsed')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
