import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/shared/tips/wing_tips.dart';

void main() {
  test(
    'tips are hidden until loaded, then visible when never dismissed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Before the async load completes nothing may flash on screen.
      expect(
        container.read(wingTipsProvider).shouldShow(WingTip.moreDestinations),
        isFalse,
      );

      await container.read(wingTipsProvider.notifier).loaded;
      expect(
        container.read(wingTipsProvider).shouldShow(WingTip.moreDestinations),
        isTrue,
      );
    },
  );

  test('dismissing a tip persists across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(wingTipsProvider.notifier).loaded;

    await container.read(wingTipsProvider.notifier).dismiss(WingTip.voice);

    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    restarted.read(wingTipsProvider);
    await restarted.read(wingTipsProvider.notifier).loaded;

    final tips = restarted.read(wingTipsProvider);
    expect(tips.shouldShow(WingTip.voice), isFalse);
    expect(tips.shouldShow(WingTip.moreDestinations), isTrue);
  });

  test('hostile stored data is ignored', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.wing.tips.dismissed.v1': <String>['nonsense', 'voice'],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(wingTipsProvider);
    await container.read(wingTipsProvider.notifier).loaded;

    final tips = container.read(wingTipsProvider);
    expect(tips.shouldShow(WingTip.voice), isFalse);
    expect(tips.shouldShow(WingTip.approvals), isTrue);
  });
}
