import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/needle_spike/needle_spike_flag.dart';
import 'package:navivox/features/needle_spike/providers/needle_spike_providers.dart';
import 'package:navivox/features/needle_spike/services/needle_model_install_service.dart';
import 'package:navivox/router/app_routes.dart';
import 'package:navivox/router/providers/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/hermes_chat/support/fake_hermes_channel.dart';
import '../features/hermes_chat/support/fake_hermes_endpoint_store.dart';

void main() {
  test('needle spike route is absent unless NEEDLE_SPIKE is defined', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    final topLevelPaths = router.configuration.routes.whereType<GoRoute>().map(
      (r) => r.path,
    );
    if (needleSpikeEnabled) {
      expect(topLevelPaths, contains(AppRoutes.needleSpike));
    } else {
      expect(topLevelPaths, isNot(contains(AppRoutes.needleSpike)));
    }
  });

  if (needleSpikeEnabled) {
    testWidgets('pushed spike route stacks over Settings for a round-trip', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(const {});
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(FakeHermesChannel()),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(),
          ),
          // Never resolves: keeps the spike screen on its install card
          // without touching path_provider or real file IO in this test.
          needleInstallServiceProvider.overrideWith(
            (ref) => Completer<NeedleModelInstallService>().future,
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go(AppRoutes.settings);
      await tester.pumpAndSettle();
      expect(router.canPop(), isFalse);

      unawaited(router.push(AppRoutes.needleSpike));
      await tester.pumpAndSettle();

      // The spike screen must stack over Settings, not replace the match
      // stack, so the operator can navigate back during evaluation.
      expect(router.canPop(), isTrue);

      router.pop();
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.settings,
      );
    });
  }
}
