import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wing/app/wing_app.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';
import 'package:wing/main_local_setup_recovery_e2e.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import '../features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../features/hermes_chat/support/fake_hermes_channel.dart';

void main() {
  testWidgets(
    'production welcome honors disabled local setup capability',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localLinuxSetupAvailableProvider.overrideWithValue(false),
            hermesEndpointStoreProvider.overrideWithValue(
              FakeHermesEndpointStore(),
            ),
            hermesChannelProvider.overrideWithValue(
              FakeHermesChannel.disconnected(),
            ),
          ],
          child: const WingApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Optional setup and pairing'));
      await tester.tap(find.text('Optional setup and pairing'));
      await tester.pumpAndSettle();
      expect(find.text('Set up Hermes on this computer'), findsNothing);
      expect(find.text('Get Started'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  test(
    'typed fixture cancellation fences late completion without setup replay',
    () async {
      final fixture = SetupRecoveryFixture();
      final controller = LocalHermesSetupController(fixture.host);
      await controller.inspect();
      expect(controller.status, LocalHermesSetupStatus.missing);
      final pending = controller.setup();
      await Future<void>.delayed(Duration.zero);
      final cancelling = controller.cancel();
      await Future<void>.delayed(Duration.zero);
      fixture.finish(true);
      await cancelling;
      await pending;
      expect(controller.status, LocalHermesSetupStatus.cancelled);
      expect(fixture.inspects, 1);
      expect(fixture.setups, 1);
      expect(fixture.cancels, 1);
      await controller.inspect();
      expect(controller.status, LocalHermesSetupStatus.ready);
      expect(fixture.inspects, 2);
      expect(fixture.setups, 1);
      controller.dispose();
      fixture.dispose();
    },
  );
}
