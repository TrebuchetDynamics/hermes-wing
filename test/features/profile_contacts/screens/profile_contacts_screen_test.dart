import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/profile_contacts/screens/profile_contacts_screen.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/app/test_material_app.dart';

void main() {
  testWidgets('shows the legacy Gormes notice pointing to Hermes', (
    tester,
  ) async {
    final channel = TestNavivoxChannel();

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: const ProfileContactsScreen(),
      ),
    );

    expect(find.byKey(const ValueKey('gormes-legacy-notice')), findsOneWidget);
  });
}
