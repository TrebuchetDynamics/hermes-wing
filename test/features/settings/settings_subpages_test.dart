import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'one compact menu opens child pages and breadcrumb returns at $scale',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'wing.chat.transcript_text_scale': 1.37,
        });
        final channel = FakeHermesChannel();
        addTearDown(channel.dispose);
        (String, String?, String?)? target;
        await _mount(
          tester,
          channel,
          320,
          scale,
          SettingsScreen(
            initialCategory: 'voice',
            onTargetChanged: (category, page, setting) =>
                target = (category, page, setting),
          ),
        );
        expect(
          find.byKey(const ValueKey('settings-appearance-page-picker')),
          findsNothing,
        );
        await tester.tap(
          find.byKey(const ValueKey('settings-category-picker')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Typography').last);
        await tester.pumpAndSettle();
        expect(target, ('config:appearance', 'typography', null));
        expect(
          find.byKey(const ValueKey('settings-chat-text-scale-137')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('settings-breadcrumb-current')),
              )
              .data,
          'Typography',
        );
        final parent = find.byKey(const ValueKey('settings-breadcrumb-parent'));
        await tester.ensureVisible(parent);
        await tester.tap(parent);
        await tester.pumpAndSettle();
        expect(target, ('config:appearance', 'theme', null));
        expect(
          find.byKey(const ValueKey('settings-theme-gallery')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('settings-breadcrumb-current')),
              )
              .data,
          'Theme',
        );
        expect(
          (await SharedPreferences.getInstance()).getDouble(
            'wing.chat.transcript_text_scale',
          ),
          1.37,
        );
        expect(channel.connectCalls, isEmpty);
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.loadProvidersCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'only the active leaf is selected and disclosure follows deliberate navigation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await _mount(
        tester,
        channel,
        1280,
        1,
        const SettingsScreen(initialPage: 'typography'),
      );
      final parent = find.byKey(const ValueKey('settings-category-appearance'));
      final leaf = find.byKey(
        const ValueKey('settings-appearance-page-typography'),
      );
      expect(tester.widget<ListTile>(parent).selected, isFalse);
      expect(tester.widget<ListTile>(leaf).selected, isTrue);
      await tester.tap(find.byKey(const ValueKey('settings-category-voice')));
      await tester.pumpAndSettle();
      expect(leaf, findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('settings-appearance-expand')),
      );
      await tester.pumpAndSettle();
      expect(leaf, findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-content-voice')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-category-connections')),
      );
      await tester.pumpAndSettle();
      expect(leaf, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an open search cannot replace a newer navigation intent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final category = ValueNotifier('voice');
    addTearDown(category.dispose);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    var selections = 0;
    await _mount(
      tester,
      channel,
      1280,
      1,
      ValueListenableBuilder<String>(
        valueListenable: category,
        builder: (_, value, _) => SettingsScreen(
          initialCategory: value,
          onTargetChanged: (_, _, _) => selections++,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('settings-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Chat text size');
    category.value = 'connections';
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings-search-setting-chat-text-scale')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-content-connections')),
      findsOneWidget,
    );
    expect(selections, 0);
    expect(channel.connectCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('field search opens its subpage at $width / $scale', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({
          'wing.chat.transcript_text_scale': 1.37,
          'wing.appearance.avatar_variation.v1': 5,
        });
        (String, String?, String?)? target;
        final channel = FakeHermesChannel();
        addTearDown(channel.dispose);
        await _mount(
          tester,
          channel,
          width,
          scale,
          SettingsScreen(
            initialPage: 'typography',
            onTargetChanged: (category, page, setting) =>
                target = (category, page, setting),
          ),
        );
        expect(
          find
              .byKey(const ValueKey('settings-chat-text-scale-137'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('settings-theme-gallery')),
          findsNothing,
        );

        Future<void> search(String text) async {
          await tester.tap(find.byKey(const ValueKey('settings-search')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), text);
          await tester.pumpAndSettle();
        }

        await search('dark theme');
        await tester.tap(
          find.byKey(const ValueKey('settings-search-setting-theme')),
        );
        await tester.pumpAndSettle();
        expect(target, ('config:appearance', 'theme', 'theme'));
        expect(
          find.byKey(const ValueKey('settings-theme-gallery')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('settings-chat-text-scale-137')),
          findsNothing,
        );

        await search('Chat text size');
        await tester.tap(
          find.byKey(const ValueKey('settings-search-setting-chat-text-scale')),
        );
        await tester.pumpAndSettle();
        expect(target, ('config:appearance', 'typography', 'chat-text-scale'));
        expect(
          find
              .byKey(const ValueKey('settings-chat-text-scale-137'))
              .hitTestable(),
          findsOneWidget,
        );
        await search('dark theme');
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(target, ('config:appearance', 'typography', 'chat-text-scale'));
        expect(
          find.byKey(const ValueKey('settings-chat-text-scale-137')),
          findsOneWidget,
        );
        expect(channel.connectCalls, isEmpty);
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.loadProvidersCalls, 0);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('wing.chat.transcript_text_scale'), 1.37);
        expect(prefs.getInt('wing.appearance.avatar_variation.v1'), 5);
        expect(prefs.getString('wing.theme.mode'), isNull);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Appearance caret only expands and parent opens first supported child',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var changes = 0;
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await _mount(
        tester,
        channel,
        1280,
        1,
        SettingsScreen(
          initialPage: 'typography',
          onTargetChanged: (_, _, _) => changes++,
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-appearance-expand')),
      );
      await tester.pumpAndSettle();
      expect(changes, 0);
      expect(
        find.byKey(const ValueKey('settings-chat-text-scale-100')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('settings-appearance-page-typography')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('settings-category-appearance')),
      );
      await tester.pumpAndSettle();
      expect(changes, 1);
      expect(
        find.byKey(const ValueKey('settings-theme-gallery')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('settings-chat-text-scale-100')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mounted field intent takes precedence over page and unknown targets fall back',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final intent = ValueNotifier<(String?, String?)>((
        'theme',
        'chat-text-scale',
      ));
      addTearDown(intent.dispose);
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await _mount(
        tester,
        channel,
        1280,
        1,
        ValueListenableBuilder<(String?, String?)>(
          valueListenable: intent,
          builder: (_, value, _) =>
              SettingsScreen(initialPage: value.$1, initialSetting: value.$2),
        ),
      );
      expect(
        find.byKey(const ValueKey('settings-chat-text-scale-100')),
        findsOneWidget,
      );
      intent.value = ('theme', null);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('settings-theme-gallery')),
        findsOneWidget,
      );
      intent.value = ('unsupported-page', 'unsupported-setting');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('settings-theme-gallery')),
        findsOneWidget,
      );
      expect(channel.connectCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _mount(
  WidgetTester tester,
  FakeHermesChannel channel,
  double width,
  double scale,
  Widget screen,
) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
