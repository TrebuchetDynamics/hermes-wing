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

const _key = 'wing.chat.tool_display';
final _setting = find.byKey(const ValueKey('settings-tool-display'));

void main() {
  testWidgets('tool display persists without changing existing preferences', (
    tester,
  ) async {
    const preserved = <String, Object>{
      'wing.chat.transcript_text_scale': 1.37,
      'wing.chat.spellcheck_enabled': false,
      'wing.chat.text_direction': 'rtl',
      'wing.chat.reasoning_collapsed_by_default': true,
      'wing.chat.user_bubble_transparency': 37,
      'wing.chat.backdrop_enabled': true,
      'wing.chat.hide_thread_timeline': true,
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
      'product',
      'technical',
      true,
      1,
      <String>['technical'],
    ]) {
      SharedPreferences.resetStatic();
      final store = _RecordingPreferences({...preserved, _key: ?stored});
      SharedPreferencesStorePlatform.instance = store;
      final container = ProviderContainer();
      final controller = container.read(wingChatPreferencesProvider.notifier);
      await tester.pumpAndSettle();
      expect(container.read(wingChatPreferencesProvider).isHydrated, isTrue);
      expect(
        container.read(wingChatPreferencesProvider).toolDisplay,
        stored == 'technical'
            ? WingToolDisplay.technical
            : WingToolDisplay.product,
      );
      expect(
        store.writes,
        isEmpty,
        reason: 'Hydration never normalizes storage',
      );
      expect((await store.getAll())['flutter.$_key'], stored);
      for (final enabled in WingToolDisplay.values) {
        controller.setToolDisplay(enabled);
        await tester.pumpAndSettle();
        expect(
          (await store.getAll())['flutter.$_key'],
          enabled == WingToolDisplay.technical ? 'technical' : null,
        );
        final reloaded = ProviderContainer();
        reloaded.read(wingChatPreferencesProvider);
        await tester.pumpAndSettle();
        expect(reloaded.read(wingChatPreferencesProvider).toolDisplay, enabled);
        reloaded.dispose();
        for (final entry in preserved.entries) {
          expect((await store.getAll())['flutter.${entry.key}'], entry.value);
        }
      }
      expect(store.writes, everyElement('flutter.$_key'));
      controller.setToolDisplay(WingToolDisplay.technical);
      // All existing setters must carry the new field forward.
      controller.setSpellcheckEnabled(false);
      controller.setTranscriptTextScale(1.37);
      controller.setTextDirection(WingChatTextDirection.rtl);
      controller.setReasoningCollapsedByDefault(true);
      controller.setUserBubbleTransparency(37);
      controller.setBackdropEnabled(true);
      controller.setHideThreadTimeline(true);
      await tester.pumpAndSettle();
      expect(
        container.read(wingChatPreferencesProvider).toolDisplay,
        WingToolDisplay.technical,
      );
      for (final entry in preserved.entries) {
        expect((await store.getAll())['flutter.${entry.key}'], entry.value);
      }
      container.dispose();
    }
    SharedPreferences.resetStatic();
    final delayed = _RecordingPreferences({...preserved, _key: 'technical'})
      ..readGate = Completer<void>();
    SharedPreferencesStorePlatform.instance = delayed;
    final early = ProviderContainer();
    final controller = early.read(wingChatPreferencesProvider.notifier);
    controller.setToolDisplay(WingToolDisplay.technical);
    controller.setToolDisplay(WingToolDisplay.product);
    delayed.readGate!.complete();
    await tester.pumpAndSettle();
    expect(
      early.read(wingChatPreferencesProvider).toolDisplay,
      WingToolDisplay.product,
    );
    expect(early.read(wingChatPreferencesProvider).transcriptTextScale, 1.37);
    delayed.writeGate = Completer<void>();
    controller.setToolDisplay(WingToolDisplay.technical);
    await tester.pumpAndSettle();
    controller.setToolDisplay(WingToolDisplay.product);
    controller.setToolDisplay(WingToolDisplay.technical);
    delayed.writeGate!.complete();
    await tester.pumpAndSettle();
    expect((await delayed.getAll())['flutter.$_key'], 'technical');
    delayed.fail = true;
    controller.setToolDisplay(WingToolDisplay.product);
    await tester.pumpAndSettle();
    expect(
      early.read(wingChatPreferencesProvider).toolDisplay,
      WingToolDisplay.product,
    );
    delayed.fail = false;
    controller.setToolDisplay(WingToolDisplay.technical);
    await tester.pumpAndSettle();
    final before = delayed.writes.length;
    controller.setToolDisplay(WingToolDisplay.product);
    early.dispose();
    controller.setToolDisplay(WingToolDisplay.product);
    await tester.pumpAndSettle();
    expect(delayed.writes.length, before);
    SharedPreferences.resetStatic();
    delayed.readGate = Completer<void>();
    final abandoned = ProviderContainer();
    abandoned
        .read(wingChatPreferencesProvider.notifier)
        .setToolDisplay(WingToolDisplay.product);
    abandoned.dispose();
    delayed.readGate!.complete();
    await tester.pumpAndSettle();
    expect(delayed.writes.length, before);
    for (final entry in preserved.entries) {
      expect((await delayed.getAll())['flutter.${entry.key}'], entry.value);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tool display field routes to Chat display without Agent calls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final width in [390.0, 1280.0]) {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel();
      final container = ProviderContainer(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
      );
      final navigation = ValueNotifier<(String, String?)>((
        'theme',
        'appearance.tool-view',
      ));
      (String, String?, String?)? target;
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
      expect(_setting, findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-theme-gallery')),
        findsNothing,
      );
      expect(
        tester.getTopLeft(find.text('Hide thread timeline bars')).dy,
        lessThan(tester.getTopLeft(_setting).dy),
      );
      final technical = find.widgetWithText(ChoiceChip, 'Technical');
      await tester.ensureVisible(technical);
      FocusManager.instance.primaryFocus?.unfocus();
      var reached = false;
      for (var i = 0; i < 80; i++) {
        FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
          reached =
              e.widget.key == const ValueKey('settings-tool-display-technical');
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
        container.read(wingChatPreferencesProvider).toolDisplay,
        WingToolDisplay.technical,
      );
      final product = find.widgetWithText(ChoiceChip, 'Product');
      final node = tester.getSemantics(product);
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
        container.read(wingChatPreferencesProvider).toolDisplay,
        WingToolDisplay.product,
      );
      Future<void> search(String query) async {
        await tester.tap(find.byKey(const ValueKey('settings-search')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();
      }

      final result = find.byKey(
        const ValueKey('settings-search-setting-appearance.tool-view'),
      );
      for (final query in [
        'Tool Call Display',
        'technical',
        'product',
        'payload',
        'result',
        'output',
      ]) {
        await search(query);
        await tester.tap(result);
        await tester.pumpAndSettle();
        expect(target, (
          'config:appearance',
          'chat-display',
          'appearance.tool-view',
        ));
        expect(_setting, findsOneWidget);
      }
      await search('Tool Call Display');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(_setting, findsOneWidget);
      await search('Tool Call Display');
      navigation.value = ('typography', null);
      await tester.pumpAndSettle();
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(_setting, findsNothing);
      expect(channel.connectCalls, isEmpty);
      expect(channel.selectProfileCalls, isEmpty);
      expect(channel.loadProvidersCalls, 0);
      expect(channel.loadEarlierMessagesCalls, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      channel.dispose();
      navigation.dispose();
    }
    semantics.dispose();
  });
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
