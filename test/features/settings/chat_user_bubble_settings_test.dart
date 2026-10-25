import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Only this isolated fake uses the installed plugin platform interface.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import 'chat_text_direction_settings_test.dart' show app;

const _key = 'wing.chat.user_bubble_transparency';
final _slider = find.byKey(const ValueKey('settings-user-bubble-transparency'));

void main() {
  testWidgets(
    'message bubble transparency persists locally without changing existing preferences',
    (tester) async {
      const preserved = <String, Object>{
        'wing.chat.transcript_text_scale': 1.37,
        'wing.chat.spellcheck_enabled': false,
        'wing.chat.text_direction': 'rtl',
        'wing.chat.reasoning_collapsed_by_default': true,
        'wing.theme.mode': 'dark',
        'wing.theme.palette': 'forest',
        'wing.chat.avatar_family': 'legacy',
        'wing.appearance.avatar_variation.v1': 5,
      };
      final originalStore = SharedPreferencesStorePlatform.instance;
      addTearDown(() {
        SharedPreferences.resetStatic();
        SharedPreferencesStorePlatform.instance = originalStore;
      });
      SharedPreferences.resetStatic();
      final store = _RecordingPreferences(preserved);
      SharedPreferencesStorePlatform.instance = store;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        app(container, const SettingsScreen(initialPage: 'chat-display')),
      );
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_key), isFalse);
      expect(store.writes, isEmpty);
      expect(_slider, findsOneWidget);
      for (final value in [37, 100, 0]) {
        tester.widget<Slider>(_slider).onChanged!(value.toDouble());
        await tester.pumpAndSettle();
        expect(prefs.get(_key), value == 0 ? isNull : value);
        for (final entry in preserved.entries) {
          expect(prefs.get(entry.key), entry.value);
        }
        await tester.pumpWidget(const SizedBox());
        final reloaded = ProviderContainer();
        await tester.pumpWidget(
          app(reloaded, const SettingsScreen(initialPage: 'chat-display')),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(_slider).value, value.toDouble());
        await tester.pumpWidget(const SizedBox());
        reloaded.dispose();
        await tester.pumpWidget(
          app(container, const SettingsScreen(initialPage: 'chat-display')),
        );
        await tester.pumpAndSettle();
      }
      expect(store.writes, everyElement('flutter.$_key'));
      await tester.pumpWidget(const SizedBox());
      for (final (stored, expected) in <(Object?, int)>[
        (null, 0),
        ('', 0),
        ('37', 0),
        (true, 0),
        (<String>['37'], 0),
        (double.nan, 0),
        (double.infinity, 0),
        (double.negativeInfinity, 0),
        (36.6, 37),
        (37, 37),
        (37.4, 37),
        (37.5, 38),
        (-5.5, 0),
        (110.2, 100),
      ]) {
        SharedPreferences.resetStatic();
        final values = {...preserved, _key: ?stored};
        final backend = _RecordingPreferences(values);
        SharedPreferencesStorePlatform.instance = backend;
        final loaded = ProviderContainer();
        loaded.read(wingChatPreferencesProvider);
        await tester.pumpAndSettle();
        expect(loaded.read(wingChatPreferencesProvider).isHydrated, isTrue);
        expect(
          loaded.read(wingChatPreferencesProvider).userBubbleTransparency,
          expected,
        );
        expect(
          backend.writes,
          isEmpty,
          reason: 'Hydration must never normalize storage',
        );
        final saved = await backend.getAll();
        for (final entry in values.entries) {
          expect(saved['flutter.${entry.key}'], entry.value);
        }
        loaded
            .read(wingChatPreferencesProvider.notifier)
            .setUserBubbleTransparency(0);
        await tester.pumpAndSettle();
        expect((await backend.getAll()).containsKey('flutter.$_key'), isFalse);
        expect(backend.writes, ['flutter.$_key']);
        for (final entry in preserved.entries) {
          expect((await backend.getAll())['flutter.${entry.key}'], entry.value);
        }
        loaded.dispose();
      }

      SharedPreferences.resetStatic();
      final delayed = _RecordingPreferences({...preserved, _key: 100});
      delayed.readGate = Completer<void>();
      SharedPreferencesStorePlatform.instance = delayed;
      final early = ProviderContainer();
      final choices = early.read(wingChatPreferencesProvider.notifier);
      choices.setUserBubbleTransparency(100);
      choices.setUserBubbleTransparency(37);
      delayed.readGate!.complete();
      await tester.pumpAndSettle();
      expect(
        early.read(wingChatPreferencesProvider).userBubbleTransparency,
        37,
      );
      expect(early.read(wingChatPreferencesProvider).transcriptTextScale, 1.37);
      expect(
        early.read(wingChatPreferencesProvider).spellcheckEnabled,
        isFalse,
      );
      expect(
        early.read(wingChatPreferencesProvider).textDirection,
        WingChatTextDirection.rtl,
      );
      expect(
        early.read(wingChatPreferencesProvider).reasoningCollapsedByDefault,
        isTrue,
      );
      delayed.writeGate = Completer<void>();
      choices.setUserBubbleTransparency(100);
      await tester.pumpAndSettle();
      choices.setUserBubbleTransparency(0);
      choices.setUserBubbleTransparency(36.6);
      delayed.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(
        early.read(wingChatPreferencesProvider).userBubbleTransparency,
        37,
      );
      final committed = await delayed.getAll();
      expect(committed['flutter.$_key'], 37);
      expect(committed['flutter.$_key'], isA<int>());
      for (final entry in preserved.entries) {
        expect(committed['flutter.${entry.key}'], entry.value);
      }
      expect(delayed.writes, everyElement('flutter.$_key'));
      early.dispose();
      SharedPreferences.resetStatic();
      final cold = ProviderContainer();
      cold.read(wingChatPreferencesProvider);
      await tester.pumpAndSettle();
      expect(cold.read(wingChatPreferencesProvider).userBubbleTransparency, 37);
      cold.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'message bubble field routes to Chat display without Agent calls',
    (tester) async {
      final semantics = tester.ensureSemantics();
      for (final width in [390.0, 1280.0]) {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = FakeHermesChannel();
        final container = ProviderContainer(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
        );
        (String, String?, String?)? target;
        final navigation = ValueNotifier<(String, String?)>((
          'theme',
          'appearance.user-bubble',
        ));
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
        expect(_slider, findsOneWidget);
        expect(find.text('Message Bubble'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('settings-theme-gallery')),
          findsNothing,
        );
        await tester.ensureVisible(_slider);
        FocusManager.instance.primaryFocus?.unfocus();
        var reached = false;
        for (var i = 0; i < 60; i++) {
          FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
            e,
          ) {
            if (e.widget.key ==
                const ValueKey('settings-user-bubble-transparency')) {
              reached = true;
            }
            return !reached;
          });
          if (reached) break;
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        }
        expect(reached, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(_slider).value, 1);
        final node = tester.getSemantics(_slider);
        final data = node.getSemanticsData();
        expect(data.label, 'Message Bubble');
        expect(data.value, '1%');
        expect(data.hasAction(SemanticsAction.increase), isTrue);
        expect(data.hasAction(SemanticsAction.decrease), isTrue);
        tester.binding.performSemanticsAction(
          SemanticsActionEvent(
            viewId: tester.view.viewId,
            nodeId: node.id,
            type: SemanticsAction.increase,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(_slider).value, 2);
        expect(find.text('2%'), findsOneWidget);

        Future<void> searchBubble() async {
          await tester.tap(find.byKey(const ValueKey('settings-search')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'Message Bubble');
          await tester.pumpAndSettle();
        }

        final result = find.byKey(
          const ValueKey('settings-search-setting-appearance.user-bubble'),
        );
        await searchBubble();
        await tester.tap(result);
        await tester.pumpAndSettle();
        expect(target, (
          'config:appearance',
          'chat-display',
          'appearance.user-bubble',
        ));
        expect(_slider, findsOneWidget);
        await searchBubble();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(_slider, findsOneWidget);
        await searchBubble();
        navigation.value = ('typography', null);
        await tester.pumpAndSettle();
        await tester.tap(result);
        await tester.pumpAndSettle();
        expect(_slider, findsNothing);
        expect(
          find.byKey(const ValueKey('settings-chat-text-scale-100')),
          findsOneWidget,
        );
        expect(target, (
          'config:appearance',
          'chat-display',
          'appearance.user-bubble',
        ));
        expect(channel.connectCalls, isEmpty);
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.loadProvidersCalls, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        channel.dispose();
        navigation.dispose();
      }
      semantics.dispose();
    },
  );
}

class _RecordingPreferences extends InMemorySharedPreferencesStore {
  _RecordingPreferences(Map<String, Object> values)
    : super.withData({
        for (final entry in values.entries) 'flutter.${entry.key}': entry.value,
      });

  final writes = <String>[];
  Completer<void>? readGate;
  Completer<void>? writeGate;

  @override
  Future<Map<String, Object>> getAll() async {
    await readGate?.future;
    return super.getAll();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes.add(key);
    await writeGate?.future;
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    writes.add(key);
    await writeGate?.future;
    return super.remove(key);
  }
}
