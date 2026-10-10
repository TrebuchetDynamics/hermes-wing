import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/settings/providers/shell_preferences_provider.dart';

class DelayedPreferences implements SharedPreferences {
  final writes = <(bool, Completer<bool>)>[];
  bool value = true;

  @override
  bool? getBool(String key) => value;

  @override
  Future<bool> setBool(String key, bool value) async {
    final completion = Completer<bool>();
    writes.add((value, completion));
    await completion.future;
    this.value = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FailOncePreferences extends DelayedPreferences {
  int attempts = 0;

  @override
  Future<bool> setBool(String key, bool value) async {
    if (attempts++ == 0) throw StateError('Storage unavailable');
    this.value = value;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a user toggle during preference loading wins over the stored value',
    () async {
      SharedPreferences.setMockInitialValues({
        'wing.shell.sidebar_expanded': true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(wingSidebarExpandedProvider.notifier);

      final saved = controller.setSidebarExpanded(false);
      expect(container.read(wingSidebarExpandedProvider), isFalse);
      await saved;
      expect(container.read(wingSidebarExpandedProvider), isFalse);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'wing.shell.sidebar_expanded',
        ),
        isFalse,
      );
    },
  );

  test(
    'rapid toggles serialize writes so stale completion cannot win',
    () async {
      final preferences = DelayedPreferences();
      final container = ProviderContainer(
        overrides: [
          wingSidebarExpandedProvider.overrideWith(
            () => WingShellPreferencesController(
              loadPreferences: () async => preferences,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(wingSidebarExpandedProvider.notifier);
      await controller.loaded;
      final first = controller.setSidebarExpanded(false);
      await Future<void>.delayed(Duration.zero);
      final second = controller.setSidebarExpanded(true);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(wingSidebarExpandedProvider), isTrue);
      expect(preferences.writes, hasLength(1));
      preferences.writes.first.$2.complete(true);
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(preferences.writes, hasLength(2));
      preferences.writes.last.$2.complete(true);
      await second;
      expect(preferences.value, isTrue);
    },
  );

  test('unreadable storage does not undo an early user choice', () async {
    final pending = Completer<SharedPreferences>();
    final container = ProviderContainer(
      overrides: [
        wingSidebarExpandedProvider.overrideWith(
          () => WingShellPreferencesController(
            loadPreferences: () => pending.future,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(wingSidebarExpandedProvider.notifier);
    final saved = controller.setSidebarExpanded(false);
    pending.completeError(StateError('Storage unavailable'));
    await saved;
    expect(container.read(wingSidebarExpandedProvider), isFalse);
  });

  test('a failed write does not poison subsequent saves', () async {
    final preferences = FailOncePreferences();
    final container = ProviderContainer(
      overrides: [
        wingSidebarExpandedProvider.overrideWith(
          () => WingShellPreferencesController(
            loadPreferences: () async => preferences,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(wingSidebarExpandedProvider.notifier);
    await controller.loaded;
    await controller.setSidebarExpanded(false);
    expect(container.read(wingSidebarExpandedProvider), isFalse);
    await controller.setSidebarExpanded(true);
    expect(preferences.attempts, 2);
    expect(preferences.value, isTrue);
  });

  test('late preference loading is harmless after provider disposal', () async {
    final pending = Completer<SharedPreferences>();
    final container = ProviderContainer(
      overrides: [
        wingSidebarExpandedProvider.overrideWith(
          () => WingShellPreferencesController(
            loadPreferences: () => pending.future,
          ),
        ),
      ],
    );
    final controller = container.read(wingSidebarExpandedProvider.notifier);
    container.dispose();
    pending.complete(DelayedPreferences());
    await controller.loaded;
  });
}
