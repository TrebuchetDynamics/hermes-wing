import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Only this isolated fake uses the installed plugin platform interface.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:wing/features/settings/providers/shell_preferences_provider.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';
import 'chat_text_direction_settings_test.dart' show app;

const _key = 'wing.shell.session_list_density';
Finder _choice(String value) =>
    find.byKey(ValueKey('settings-session-density-$value'));

void main() {
  testWidgets(
    'session density persists locally without changing existing preferences',
    (tester) async {
      const preserved = <String, Object>{
        'wing.shell.sidebar_expanded': false,
        'wing.chat.transcript_text_scale': 1.37,
        'wing.chat.spellcheck_enabled': false,
        'wing.chat.text_direction': 'rtl',
        'wing.chat.reasoning_collapsed_by_default': true,
        'wing.chat.user_bubble_transparency': 37,
        'wing.theme.mode': 'dark',
        'wing.theme.palette': 'forest',
        'wing.chat.avatar_family': 'legacy',
        'wing.appearance.avatar_variation.v1': 5,
        'wing.hermes.pinned_sessions.v1': <String>[
          '["synthetic-gateway","default","synthetic-active"]',
        ],
      };
      final originalStore = SharedPreferencesStorePlatform.instance;
      addTearDown(() {
        SharedPreferences.resetStatic();
        SharedPreferencesStorePlatform.instance = originalStore;
      });
      for (final (stored, expected) in <(Object?, WingSessionListDensity)>[
        (null, WingSessionListDensity.compact),
        ('compact', WingSessionListDensity.compact),
        ('unknown', WingSessionListDensity.compact),
        (true, WingSessionListDensity.compact),
        (3, WingSessionListDensity.compact),
        (<String>['detailed'], WingSessionListDensity.compact),
        ('comfortable', WingSessionListDensity.comfortable),
        ('detailed', WingSessionListDensity.detailed),
      ]) {
        SharedPreferences.resetStatic();
        final store = _RecordingPreferences({...preserved, _key: ?stored});
        SharedPreferencesStorePlatform.instance = store;
        final container = ProviderContainer();
        final controller = container.read(
          wingSessionListDensityProvider.notifier,
        );
        await tester.pumpAndSettle();
        expect(container.read(wingSessionListDensityProvider), expected);
        expect(
          store.writes,
          isEmpty,
          reason: 'Hydration never normalizes storage',
        );
        for (final density in WingSessionListDensity.values) {
          await controller.setDensity(density);
          final prefs = await SharedPreferences.getInstance();
          expect(
            prefs.get(_key),
            density == WingSessionListDensity.compact ? null : density.name,
          );
          for (final entry in preserved.entries) {
            expect(prefs.get(entry.key), entry.value);
          }
          final reloaded = ProviderContainer();
          reloaded.read(wingSessionListDensityProvider);
          await tester.pumpAndSettle();
          expect(reloaded.read(wingSessionListDensityProvider), density);
          reloaded.dispose();
        }
        expect(store.writes, everyElement('flutter.$_key'));
        container.dispose();
      }
      SharedPreferences.resetStatic();
      final delayed = _RecordingPreferences({...preserved, _key: 'comfortable'})
        ..readGate = Completer<void>();
      SharedPreferencesStorePlatform.instance = delayed;
      final early = ProviderContainer();
      final controller = early.read(wingSessionListDensityProvider.notifier);
      final first = controller.setDensity(WingSessionListDensity.detailed);
      final second = controller.setDensity(WingSessionListDensity.compact);
      delayed.readGate!.complete();
      await tester.pumpAndSettle();
      await Future.wait([first, second]);
      expect(
        early.read(wingSessionListDensityProvider),
        WingSessionListDensity.compact,
      );
      delayed.writeGate = Completer<void>();
      final writes = [controller.setDensity(WingSessionListDensity.detailed)];
      await tester.pumpAndSettle();
      writes.add(controller.setDensity(WingSessionListDensity.compact));
      writes.add(controller.setDensity(WingSessionListDensity.comfortable));
      delayed.writeGate!.complete();
      await tester.pumpAndSettle();
      await Future.wait(writes);
      expect((await delayed.getAll())['flutter.$_key'], 'comfortable');
      delayed.fail = true;
      await controller.setDensity(WingSessionListDensity.detailed);
      expect(
        early.read(wingSessionListDensityProvider),
        WingSessionListDensity.detailed,
      );
      delayed.fail = false;
      await controller.setDensity(WingSessionListDensity.comfortable);
      final writesBeforeDispose = delayed.writes.length;
      early.dispose();
      await controller.setDensity(WingSessionListDensity.compact);
      expect(delayed.writes.length, writesBeforeDispose);
      for (final entry in preserved.entries) {
        expect((await delayed.getAll())['flutter.${entry.key}'], entry.value);
      }
      final gate = Completer<SharedPreferences>();
      final disposed = ProviderContainer(
        overrides: [
          wingSessionListDensityProvider.overrideWith(
            () => WingSessionListDensityController(
              loadPreferences: () => gate.future,
            ),
          ),
        ],
      );
      final abandoned = disposed.read(wingSessionListDensityProvider.notifier);
      final abandonedWrite = abandoned.setDensity(
        WingSessionListDensity.compact,
      );
      disposed.dispose();
      gate.complete(await SharedPreferences.getInstance());
      await tester.pumpAndSettle();
      await abandonedWrite;
      expect(delayed.writes.length, writesBeforeDispose);
      expect((await delayed.getAll())['flutter.$_key'], 'comfortable');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'session density field routes to Window layout without Agent calls',
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
          'appearance.session-density',
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
        expect(_choice('compact'), findsOneWidget);
        expect(find.text('Session List Density'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('settings-theme-gallery')),
          findsNothing,
        );
        for (final value in ['comfortable', 'detailed', 'compact']) {
          final choice = _choice(value);
          await tester.ensureVisible(choice);
          FocusManager.instance.primaryFocus?.unfocus();
          var reached = false;
          for (var i = 0; i < 60; i++) {
            FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
              e,
            ) {
              if (e.widget.key == ValueKey('settings-session-density-$value')) {
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
          expect(tester.widget<ChoiceChip>(choice).selected, isTrue);
          expect(
            tester.getSemantics(choice).getSemanticsData().label.toLowerCase(),
            contains(value),
          );
          expect(
            (await SharedPreferences.getInstance()).get(_key),
            value == 'compact' ? null : value,
          );
        }
        Future<void> search() async {
          await tester.tap(find.byKey(const ValueKey('settings-search')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextField),
            'Session List Density',
          );
          await tester.pumpAndSettle();
        }

        final result = find.byKey(
          const ValueKey('settings-search-setting-appearance.session-density'),
        );
        await search();
        await tester.tap(result);
        await tester.pumpAndSettle();
        expect(target, (
          'config:appearance',
          'window-layout',
          'appearance.session-density',
        ));
        await search();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(_choice('compact'), findsOneWidget);
        await search();
        navigation.value = ('typography', null);
        await tester.pumpAndSettle();
        await tester.tap(result);
        await tester.pumpAndSettle();
        expect(_choice('compact'), findsNothing);
        expect(
          find.byKey(const ValueKey('settings-chat-text-scale-100')),
          findsOneWidget,
        );
        expect(target, (
          'config:appearance',
          'window-layout',
          'appearance.session-density',
        ));
        expect(channel.connectCalls, isEmpty);
        expect(channel.selectProfileCalls, isEmpty);
        expect(channel.loadProvidersCalls, 0);
        expect(channel.selectSessionCalls, isEmpty);
        expect(channel.createSessionCalls, isEmpty);
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
    if (fail) throw StateError('synthetic storage failure');
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    writes.add(key);
    await writeGate?.future;
    if (fail) throw StateError('synthetic storage failure');
    return super.remove(key);
  }
}
