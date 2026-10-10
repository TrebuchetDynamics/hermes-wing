import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wing/app/wing_app.dart';
import 'package:wing/features/enrollment/providers/hermes_enrollment_provider.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';

import '../features/hermes_chat/support/fake_hermes_channel.dart';
import '../features/hermes_chat/support/fake_hermes_endpoint_store.dart';

void main() {
  const channel = MethodChannel(
    'com.trebuchetdynamics.hermes.wing/connect_intents',
  );

  testWidgets(
    'an initial Android pairing intent opens enrollment',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final messenger = tester.binding.defaultBinaryMessenger;
      const events = MethodChannel(
        'com.trebuchetdynamics.hermes.wing/connect_intents/events',
      );
      messenger.setMockMethodCallHandler(events, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(events, null));
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'initialConnectIntent') return null;
        return {
          'payload':
              'wing://connect?origin=https%3A%2F%2Fhermes.example&code=once',
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final store = FakeHermesEndpointStore();
      final hermes = FakeHermesChannel.disconnected();
      addTearDown(hermes.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hermesChannelProvider.overrideWithValue(hermes),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesEnrollmentControllerProvider.overrideWith((ref) {
              final controller = HermesEnrollmentController(
                endpointStore: store,
                inspectEnrollment: ({required origin, required code}) async =>
                    throw StateError('Fixture inspection rejected'),
                exchangeEnrollment: ({required origin, required code}) async =>
                    throw StateError('No exchange allowed'),
              );
              return controller;
            }),
          ],
          child: const WingApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connect to Hermes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
