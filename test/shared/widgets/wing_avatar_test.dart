import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/shared/widgets/wing_avatar.dart';

void main() {
  test('recipe retains exact framed endpoint/profile identities', () {
    expect(
      wingAvatarRecipe(['a:b', 'c'], 0),
      isNot(wingAvatarRecipe(['a', 'b:c'], 0)),
    );
    expect(
      wingAvatarRecipe(['host', 'A'], 0),
      isNot(wingAvatarRecipe(['host', 'a'], 0)),
    );
    expect(
      wingAvatarRecipe(['host', 'a'], 0),
      wingAvatarRecipe(['host', 'a'], 0),
    );
    expect(
      wingAvatarRecipe(['host', 'a'], 1),
      isNot(wingAvatarRecipe(['host', 'a'], 0)),
    );
  });
  testWidgets('mounted avatar changes and family survives a new container', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WingAvatar(identity: ['synthetic', 'profile']),
        ),
      ),
    );
    await tester.pumpAndSettle();
    WingAvatarPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(WingAvatar),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as WingAvatarPainter;
    final original = painter().recipe;
    expect(
      await container.read(wingAvatarVariationProvider.notifier).select(5),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(painter().recipe, isNot(original));
    final fresh = ProviderContainer();
    addTearDown(fresh.dispose);
    fresh.read(wingAvatarVariationProvider);
    await tester.pumpAndSettle();
    expect(fresh.read(wingAvatarVariationProvider), 5);
    expect(
      await fresh.read(wingAvatarVariationProvider.notifier).select(90),
      isFalse,
    );
    expect(fresh.read(wingAvatarVariationProvider), 5);
    expect(tester.takeException(), isNull);
  });
}
