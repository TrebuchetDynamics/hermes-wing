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

const _key = 'wing.chat.backdrop_enabled';
final _toggle = find.byKey(const ValueKey('settings-chat-backdrop'));

void main() {
  testWidgets(
    'chat backdrop persists locally without changing existing preferences',
    (tester) async {
      const preserved = <String, Object>{
        'wing.chat.transcript_text_scale': 1.37,
        'wing.chat.spellcheck_enabled': false,
        'wing.chat.text_direction': 'rtl',
        'wing.chat.reasoning_collapsed_by_default': true,
        'wing.chat.user_bubble_transparency': 37,
        'wing.theme.mode': 'dark',
        'wing.theme.palette': 'forest',
        'wing.chat.avatar_family': 'legacy',
        'wing.appearance.avatar_variation.v1': 5,
        'wing.shell.sidebar_expanded': false,
        'wing.shell.session_list_density': 'detailed',
        'wing.hermes.pinned_sessions.v1': <String>['synthetic-pin'],
      };
      final originalStore = SharedPreferencesStorePlatform.instance;
      addTearDown(() {
        SharedPreferences.resetStatic();
        SharedPreferencesStorePlatform.instance = originalStore;
      });
      for (final stored in <Object?>[
        null,
        false,
        true,
        'true',
        1,
        <String>['true'],
      ]) {
        SharedPreferences.resetStatic();
        final store = _RecordingPreferences({...preserved, _key: ?stored});
        SharedPreferencesStorePlatform.instance = store;
        final container = ProviderContainer();
        final controller = container.read(wingChatPreferencesProvider.notifier);
        await tester.pumpAndSettle();
        expect(container.read(wingChatPreferencesProvider).isHydrated, isTrue);
        expect(
          container.read(wingChatPreferencesProvider).backdropEnabled,
          stored == true,
        );
        expect(
          store.writes,
          isEmpty,
          reason: 'Hydration never normalizes storage',
        );
        expect((await store.getAll())['flutter.$_key'], stored);
        for (final enabled in [true, false]) {
          controller.setBackdropEnabled(enabled);
          await tester.pumpAndSettle();
          expect(
            (await store.getAll())['flutter.$_key'],
            enabled ? true : null,
          );
          final reloaded = ProviderContainer();
          reloaded.read(wingChatPreferencesProvider);
          await tester.pumpAndSettle();
          expect(
            reloaded.read(wingChatPreferencesProvider).backdropEnabled,
            enabled,
          );
          reloaded.dispose();
          for (final entry in preserved.entries) {
            expect((await store.getAll())['flutter.${entry.key}'], entry.value);
          }
        }
        expect(store.writes, everyElement('flutter.$_key'));
        controller.setBackdropEnabled(true);
        // All existing setters must carry the new field forward.
        controller.setSpellcheckEnabled(false);
        controller.setTranscriptTextScale(1.37);
        controller.setTextDirection(WingChatTextDirection.rtl);
        controller.setReasoningCollapsedByDefault(true);
        controller.setUserBubbleTransparency(37);
        await tester.pumpAndSettle();
        expect(
          container.read(wingChatPreferencesProvider).backdropEnabled,
          isTrue,
        );
        for (final entry in preserved.entries) {
          expect((await store.getAll())['flutter.${entry.key}'], entry.value);
        }
        container.dispose();
      }
      SharedPreferences.resetStatic();
      final delayed = _RecordingPreferences({...preserved, _key: true})
        ..readGate = Completer<void>();
      SharedPreferencesStorePlatform.instance = delayed;
      final early = ProviderContainer();
      final controller = early.read(wingChatPreferencesProvider.notifier);
      controller.setBackdropEnabled(true);
      controller.setBackdropEnabled(false);
      delayed.readGate!.complete();
      await tester.pumpAndSettle();
      expect(early.read(wingChatPreferencesProvider).backdropEnabled, isFalse);
      expect(early.read(wingChatPreferencesProvider).transcriptTextScale, 1.37);
      delayed.writeGate = Completer<void>();
      controller.setBackdropEnabled(true);
      await tester.pumpAndSettle();
      controller.setBackdropEnabled(false);
      controller.setBackdropEnabled(true);
      delayed.writeGate!.complete();
      await tester.pumpAndSettle();
      expect((await delayed.getAll())['flutter.$_key'], true);
      delayed.fail = true;
      controller.setBackdropEnabled(false);
      await tester.pumpAndSettle();
      expect(early.read(wingChatPreferencesProvider).backdropEnabled, isFalse);
      delayed.fail = false;
      controller.setBackdropEnabled(true);
      await tester.pumpAndSettle();
      final before = delayed.writes.length;
      controller.setBackdropEnabled(false);
      early.dispose();
      controller.setBackdropEnabled(false);
      await tester.pumpAndSettle();
      expect(delayed.writes.length, before);
      SharedPreferences.resetStatic();
      delayed.readGate = Completer<void>();
      final abandoned = ProviderContainer();
      abandoned
          .read(wingChatPreferencesProvider.notifier)
          .setBackdropEnabled(false);
      abandoned.dispose();
      delayed.readGate!.complete();
      await tester.pumpAndSettle();
      expect(delayed.writes.length, before);
      for (final entry in preserved.entries) {
        expect((await delayed.getAll())['flutter.${entry.key}'], entry.value);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'chat backdrop field routes to Window layout without Agent calls',
    (tester) async {
      final semantics = tester.ensureSemantics();
      for (final width in [390.0, 1280.0]) {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 1200);
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
          'appearance.backdrop',
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
        expect(_toggle, findsOneWidget);
        expect(find.text('Chat Backdrop'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('settings-theme-gallery')),
          findsNothing,
        );
        expect(
          tester.getTopLeft(find.text('Session List Density')).dy,
          lessThan(tester.getTopLeft(_toggle).dy),
        );
        await tester.ensureVisible(_toggle);
        FocusManager.instance.primaryFocus?.unfocus();
        var reached = false;
        for (var i = 0; i < 80; i++) {
          FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
            e,
          ) {
            reached = e.widget.key == const ValueKey('settings-chat-backdrop');
            return !reached;
          });
          if (reached) break;
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        }
        expect(reached, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(
          container.read(wingChatPreferencesProvider).backdropEnabled,
          isTrue,
        );
        final node = tester.getSemantics(_toggle);
        expect(node.getSemanticsData().label, contains('Chat Backdrop'));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        tester.binding.performSemanticsAction(
          SemanticsActionEvent(
            viewId: tester.view.viewId,
            nodeId: node.id,
            type: SemanticsAction.tap,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          container.read(wingChatPreferencesProvider).backdropEnabled,
          isFalse,
        );
        expect(
          (await SharedPreferences.getInstance()).containsKey(_key),
          isFalse,
        );
        Future<void> search(String query) async {
          await tester.tap(find.byKey(const ValueKey('settings-search')));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), query);
          await tester.pumpAndSettle();
        }

        final result = find.byKey(
          const ValueKey('settings-search-setting-appearance.backdrop'),
        );
        for (final query in ['Chat Backdrop', 'background', 'statue']) {
          await search(query);
          await tester.tap(result);
          await tester.pumpAndSettle();
          expect(target, (
            'config:appearance',
            'window-layout',
            'appearance.backdrop',
          ));
          expect(_toggle, findsOneWidget);
        }
        await search('Chat Backdrop');
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(_toggle, findsOneWidget);
        await search('Chat Backdrop');
        navigation.value = ('typography', null);
        await tester.pumpAndSettle();
        await tester.tap(result);
        await tester.pumpAndSettle();
        expect(_toggle, findsNothing);
        expect(
          find.byKey(const ValueKey('settings-chat-text-scale-100')),
          findsOneWidget,
        );
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
  bool fail = false;
  @override
  Future<Map<String, Object>> getAll() async {
    await readGate?.future;
    return super.getAll();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes.add(key);
    await writeGate?.future;
    if (fail) throw StateError('Synthetic storage failure');
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    writes.add(key);
    await writeGate?.future;
    if (fail) throw StateError('Synthetic storage failure');
    return super.remove(key);
  }
}
