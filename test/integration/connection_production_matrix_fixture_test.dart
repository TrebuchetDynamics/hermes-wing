import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wing/app/wing_app.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';

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
      expect(find.text('Local setup'), findsNothing);
      expect(find.text('Set up Hermes on this computer'), findsNothing);
      expect(find.text('Get Started'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
