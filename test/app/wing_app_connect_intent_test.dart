import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wing/app/wing_app.dart';

void main() {
  const channel = MethodChannel(
    'com.trebuchetdynamics.hermes.wing/connect_intents',
  );

  testWidgets('an initial Android pairing intent opens enrollment', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'initialConnectIntent') return null;
      return {
        'payload':
            'wing://connect?origin=https%3A%2F%2Fhermes.example&code=once',
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(const WingApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Connect to Hermes'), findsOneWidget);
  });
}
