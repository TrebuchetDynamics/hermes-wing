import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

Widget app(ProviderContainer container, Widget settings, {double scale = 1}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: settings,
      ),
    );
Finder choice(String value) =>
    find.byKey(ValueKey('settings-chat-text-direction-$value'));

void main() {
  testWidgets(
    'text direction persists locally without changing existing preferences',
    (tester) async {
      const preserved = <String, Object>{
        'wing.chat.transcript_text_scale': 1.37,
        'wing.chat.spellcheck_enabled': false,
        'wing.theme.mode': 'dark',
        'wing.theme.palette': 'forest',
        'wing.chat.avatar_family': 'legacy',
        'wing.appearance.avatar_variation.v1': 5,
      };
      SharedPreferences.setMockInitialValues(preserved);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        app(container, const SettingsScreen(initialPage: 'chat-display')),
      );
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('wing.chat.text_direction'), isNull);
      for (final value in ['rtl', 'ltr', 'auto']) {
        await tester.ensureVisible(choice(value));
        await tester.tap(choice(value));
        await tester.pumpAndSettle();
        expect(
          prefs.getString('wing.chat.text_direction'),
          value == 'auto' ? isNull : value,
        );
        for (final entry in preserved.entries) {
          expect(prefs.get(entry.key), entry.value);
        }
        final reloaded = ProviderContainer();
        reloaded.read(wingChatPreferencesProvider);
        await tester.pumpAndSettle();
        expect(
          reloaded.read(wingChatPreferencesProvider).textDirection.name,
          value,
        );
        reloaded.dispose();
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final stored in <Object?>[null, '', 'unexpected', 42]) {
    testWidgets(
      'absent or malformed direction remains untouched until chosen: $stored',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'wing.chat.text_direction': ?stored,
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(wingChatPreferencesProvider);
        await tester.pumpAndSettle();
        expect(
          container.read(wingChatPreferencesProvider).textDirection,
          WingChatTextDirection.auto,
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.get('wing.chat.text_direction'), stored);
        container
            .read(wingChatPreferencesProvider.notifier)
            .setTextDirection(WingChatTextDirection.auto);
        await tester.pumpAndSettle();
        expect(prefs.containsKey('wing.chat.text_direction'), isFalse);
      },
    );
  }

  testWidgets(
    'new direction choice wins late hydration while preserving saved scale',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'wing.chat.text_direction': 'ltr',
        'wing.chat.transcript_text_scale': 1.37,
        'wing.chat.spellcheck_enabled': false,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(wingChatPreferencesProvider.notifier);
      controller.setTextDirection(WingChatTextDirection.rtl);
      await tester.pumpAndSettle();
      expect(
        container.read(wingChatPreferencesProvider).textDirection,
        WingChatTextDirection.rtl,
      );
      expect(
        container.read(wingChatPreferencesProvider).transcriptTextScale,
        1.37,
      );
      expect(
        container.read(wingChatPreferencesProvider).spellcheckEnabled,
        isFalse,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('wing.chat.text_direction'), 'rtl');
      expect(prefs.getDouble('wing.chat.transcript_text_scale'), 1.37);
      expect(prefs.getBool('wing.chat.spellcheck_enabled'), isFalse);
    },
  );

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'text direction field routes to Chat display without Agent calls at $width',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel();
        addTearDown(channel.dispose);
        final container = ProviderContainer(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
        );
        addTearDown(container.dispose);
        (String, String?, String?)? target;
        final navigation = ValueNotifier<(String, String?)>((
          'theme',
          'appearance.text-direction',
        ));
        addTearDown(navigation.dispose);
        await tester.pumpWidget(
          app(
            container,
            ValueListenableBuilder<(String, String?)>(
              valueListenable: navigation,
              builder: (_, intent, _) => SettingsScreen(
                initialCategory: 'config:appearance',
                initialPage: intent.$1,
                initialSetting: intent.$2,
                onTargetChanged: (category, page, setting) =>
                    target = (category, page, setting),
              ),
            ),
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(choice('auto'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('settings-theme-gallery')),
          findsNothing,
        );
        await tester.ensureVisible(choice('rtl'));
        FocusManager.instance.primaryFocus?.unfocus();
        var reached = false;
        for (var i = 0; i < 60; i++) {
          final context = FocusManager.instance.primaryFocus?.context;
          context?.visitAncestorElements((element) {
            if (element.widget.key ==
                const ValueKey('settings-chat-text-direction-rtl')) {
              reached = true;
            }
            return !reached;
          });
          if (reached) break;
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        }
        expect(reached, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(choice('rtl')).selected, isTrue);
        await tester.tap(find.byKey(const ValueKey('settings-search')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Text direction');
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey('settings-search-setting-appearance.text-direction'),
          ),
        );
        await tester.pumpAndSettle();
        expect(target, (
          'config:appearance',
          'chat-display',
          'appearance.text-direction',
        ));
        expect(choice('rtl'), findsOneWidget);

        Future<void> searchDirection() async {
          await tester.tap(find.byKey(const ValueKey('settings-search')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'Text direction');
          await tester.pumpAndSettle();
        }

        await searchDirection();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(choice('rtl'), findsOneWidget);
        await searchDirection();
        navigation.value = ('typography', null);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey('settings-search-setting-appearance.text-direction'),
          ),
        );
        await tester.pumpAndSettle();
        expect(choice('rtl'), findsNothing);
        expect(
          find.byKey(const ValueKey('settings-chat-text-scale-100')),
          findsOneWidget,
        );
        expect(target, (
          'config:appearance',
          'chat-display',
          'appearance.text-direction',
        ));
        expect(channel.connectCalls, isEmpty);
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.loadProvidersCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
