import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';

import '../../integration_test/hermes_features_maestro_main.dart';

Future<FeatureFixture> openChat(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixture = FeatureFixture();
  await fixture.initialize();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    fixture.router.dispose();
    fixture.channel.dispose();
    fixture.scale.dispose();
    fixture.reviewStep.dispose();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(fixture.channel),
        hermesAttachmentPickerProvider.overrideWithValue(
          fixture.interactions.pick,
        ),
        hermesGatewayDirectoryProvider.overrideWith((ref) => fixture.directory),
      ],
      child: fixture.buildApp(),
    ),
  );
  await tester.pumpAndSettle();
  fixture.router.go('/hermes');
  await tester.pumpAndSettle();
  return fixture;
}

Future<void> control(WidgetTester tester, String action) async {
  await tester.tap(find.text('Fixture controls'));
  await pumpFixture(tester);
  await tester.ensureVisible(find.text(action));
  await tester.tap(find.text(action));
  await pumpFixture(tester);
}

Future<void> receipt(WidgetTester tester, String text) async {
  await tester.tap(find.text('Fixture controls'));
  await pumpFixture(tester);
  await tester.ensureVisible(find.text(text));
  expect(find.text(text).hitTestable(), findsOneWidget);
  await tester.tap(find.text('Close controls'));
  await pumpFixture(tester);
}

// The deferred picker and in-flight turn intentionally keep spinners active.
Future<void> pumpFixture(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

void main() {
  testWidgets('deferred picker controls prove owner change and completion', (
    tester,
  ) async {
    final fixture = await openChat(tester);
    await control(tester, 'Pick deferred fixture');
    await tester.tap(find.byTooltip('Attach image or text file'));
    await tester.pump();
    await receipt(tester, 'Picker pending: true');
    await control(tester, 'Select second session');
    await receipt(tester, 'Active session: sess_2');
    await control(tester, 'Complete fixture picker');
    await receipt(tester, 'Picker completions: 1');
    await receipt(tester, 'Picker pending: false');
    expect(find.byTooltip('Remove attachment'), findsNothing);
    await control(tester, 'Select first session');
    await receipt(tester, 'Active session: sess_1');
    expect(find.byTooltip('Remove attachment'), findsNothing);
    await receipt(tester, 'Submitted turns: 0');
    await control(tester, 'Pick text fixture');
    await tester.tap(find.byTooltip('Attach image or text file'));
    await tester.pumpAndSettle();
    expect(find.text('fixture-note.txt'), findsOneWidget);
    await receipt(tester, 'Picker calls: 2');
    expect(fixture.interactions.pickerCompletions, 1);
    expect(fixture.channel.submittedTurns, 0);
  });

  testWidgets('approval controls dispatch deny, Stop, once without replay', (
    tester,
  ) async {
    final fixture = await openChat(tester);
    Future<void> send(String text) async {
      await tester.enterText(find.byType(TextField).first, text);
      await pumpFixture(tester);
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      await pumpFixture(tester);
    }

    expect(find.text('Message Fixture profile…'), findsOneWidget);
    await send('Fixture deny turn');
    expect(find.textContaining('Fixture approval 1'), findsWidgets);
    await tester.tap(find.text('Review'));
    await pumpFixture(tester);
    await tester.tap(find.text('Deny').last);
    await tester.pumpAndSettle();
    await receipt(tester, 'Approval decisions: 1');
    await send('Fixture stopped turn');
    expect(find.textContaining('Fixture approval 2'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('hermes-composer-stop-chip')));
    await pumpFixture(tester);
    expect(find.textContaining('Fixture approval 2'), findsNothing);
    await send('Fixture next turn');
    await tester.tap(find.text('Approve once'));
    await tester.pumpAndSettle();
    await control(tester, 'Disconnect fixture');
    await control(tester, 'Reconnect fixture');
    // Fixture reconnect retains the current contact and exact session.
    expect(find.textContaining('Fixture decision once'), findsWidgets);
    await receipt(tester, 'Submitted turns: 3');
    await receipt(tester, 'Approval decisions: 2');
    await receipt(tester, 'Stop calls: 1');
    await receipt(tester, 'Active session: sess_1');
    expect(find.textContaining('Fixture decision once'), findsWidgets);
    expect(fixture.channel.submittedTurns, 3);
    expect(fixture.channel.respondToApprovalCalls, hasLength(2));
    expect(fixture.channel.stopActiveTurnCalls, 1);
  });
}
