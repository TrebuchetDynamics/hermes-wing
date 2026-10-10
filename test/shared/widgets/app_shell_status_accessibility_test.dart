import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';
import '../../../integration_test/support/status_accessibility_native_fixture.dart';

const statusProfile = 'Synthetic enlarged status inspection profile';
const statusModel =
    'synthetic-provider/long-current-model-for-status-inspection';

FakeHermesChannel statusChannel() => FakeHermesChannel(
  profiles: const [
    HermesProfile(
      id: 'synthetic-status',
      displayName: statusProfile,
      revision: 'r1',
      model: statusModel,
    ),
  ],
  selectedProfileId: 'synthetic-status',
  connectedBaseUrl: 'http://127.0.0.1:8642',
);

Widget statusApp(
  FakeHermesChannel channel,
  double scale, {
  String location = '/hermes',
}) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(channel)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: AppShell(
      location: location,
      child: const Scaffold(body: Text('Synthetic status workspace')),
    ),
  ),
);

Future<void> inspectStatus(WidgetTester tester, double width) async {
  if (width < 600) {
    // The existing compact equivalent is the keyboard-operable More sheet.
    for (var i = 0; i < 60; i++) {
      final context = FocusManager.instance.primaryFocus?.context;
      if (context
              ?.findAncestorWidgetOfExactType<NavigationDestination>()
              ?.label ==
          'More') {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(statusModel), findsOneWidget);
    expect(tester.widget<Text>(find.text(statusModel)).maxLines, isNull);
    return;
  }
  final bar = find.byKey(const ValueKey('app-shell-status-bar'));
  for (var i = 0; i < 80; i++) {
    final context = FocusManager.instance.primaryFocus?.context;
    var inBar = false;
    context?.visitAncestorElements((element) {
      if (element.widget.key == const ValueKey('app-shell-status-bar')) {
        inBar = true;
      }
      return !inBar;
    });
    if (inBar) {
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final values = find.descendant(of: bar, matching: find.byType(Text));
      final full = values
          .evaluate()
          .map((e) => e.widget as Text)
          .where((t) => t.data == statusModel);
      expect(full, hasLength(1));
      expect(
        full.single.maxLines,
        isNull,
        reason: 'Keyboard inspection must show the entire model, not ellipsis',
      );
      expect(full.single.overflow, isNot(TextOverflow.ellipsis));
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('No keyboard full-value inspection in the status bar');
}

void main() {
  testWidgets(
    'open status follows recovering failure and replacement without mutation',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = StatusAccessibilityNativeFixture();
      addTearDown(fixture.dispose);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(statusApp(fixture, 2));
      await tester.pumpAndSettle();
      await inspectStatus(tester, 1280);
      expect(find.bySemanticsLabel('Model: $statusModel'), findsOneWidget);
      for (final phase in ['recovering', 'failed', 'replacement']) {
        fixture.phase(phase);
        await tester.pumpAndSettle();
        expect(find.text(statusModel), findsNothing);
        if (phase == 'replacement') {
          expect(
            find.text(StatusAccessibilityNativeFixture.replacementModel),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel(
              'Profile: ${StatusAccessibilityNativeFixture.replacementProfile}',
            ),
            findsOneWidget,
          );
        } else {
          expect(find.text('Disconnected'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
      expect(fixture.mutationCounts.values, everyElement(0));
      semantics.dispose();
    },
  );
  for (final width in [390.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('current labeled status keyboard inspection $width $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = statusChannel();
        addTearDown(channel.dispose);
        await tester.pumpWidget(statusApp(channel, scale));
        await tester.pumpAndSettle();
        await inspectStatus(tester, width);
        expect(tester.takeException(), isNull);
        if (width < 600) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        }
        await channel.disconnect();
        await tester.pumpAndSettle();
        expect(find.text(statusModel), findsNothing);
        if (width >= 600) expect(find.text('Disconnected'), findsOneWidget);
        expect(channel.stopActiveTurnCalls, 0);
      });
    }
  }
}
