import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/router/app_router.dart';

void main() {
  test('every shell destination builds a transition page', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    final shell = router.configuration.routes.first as ShellRoute;
    final destinations = shell.routes.cast<GoRoute>();
    expect(destinations, isNotEmpty);
    for (final route in destinations) {
      expect(
        route.pageBuilder,
        isNotNull,
        reason: '${route.path} should use the shared fade transition page',
      );
    }
  });

  testWidgets('the shared page fades its child in', (tester) async {
    final page = wingFadeThroughPage(
      key: const ValueKey('page'),
      child: const Text('destination', textDirection: TextDirection.ltr),
    );
    expect(page, isA<CustomTransitionPage<void>>());

    final transition = (page as CustomTransitionPage<void>).transitionsBuilder(
      _FakeContext(),
      const AlwaysStoppedAnimation(0.5),
      const AlwaysStoppedAnimation(0),
      const SizedBox(),
    );
    expect(transition, isA<FadeTransition>());
  });
}

class _FakeContext extends Fake implements BuildContext {}
