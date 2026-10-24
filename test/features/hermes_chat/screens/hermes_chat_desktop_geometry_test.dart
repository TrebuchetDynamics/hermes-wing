import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [390.0, 960.0, 1440.0]) {
    testWidgets('transcript and composer share panel geometry at $width', (
      tester,
    ) async {
      final channel = FakeHermesChannel();
      channel.beginStreamingTurn('Synthetic question');
      channel.completeStreamingTurn(
        text: 'Synthetic answer with readable prose.',
      );
      await _mount(tester, channel, width);
      final id = channel.state.activeMessages.last.id;
      final transcript = tester.getRect(
        find.byKey(const ValueKey('hermes-transcript')),
      );
      final reply = tester.getRect(find.byKey(ValueKey('hermes-turn-$id')));
      final replyBox =
          tester
                  .widget<Container>(find.byKey(ValueKey('hermes-turn-$id')))
                  .decoration!
              as BoxDecoration;
      expect(replyBox.color, Colors.transparent);
      expect(replyBox.borderRadius, BorderRadius.zero);
      final user = channel.state.activeMessages.firstWhere(
        (turn) => turn.author.name == 'user',
      );
      final userRect = tester.getRect(
        find.byKey(ValueKey('hermes-turn-${user.id}')),
      );
      expect(userRect.left, reply.left);
      expect(userRect.width, reply.width);
      final userBox =
          tester
                  .widget<Container>(
                    find.byKey(ValueKey('hermes-turn-${user.id}')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(userBox.borderRadius, BorderRadius.circular(3.2));
      final desktop = width >= 720;
      expect(reply.left - transcript.left, desktop ? 24 : 12);
      expect(transcript.right - reply.right, desktop ? 24 : 12);
      if (desktop) {
        final composer = tester.getRect(
          find.byKey(const ValueKey('hermes-desktop-command-bar')),
        );
        expect(composer.left - transcript.left, 16);
        expect(transcript.right - composer.right, 16);
        expect(reply.width, composer.width - 16);
      }
      final prose = find.text('Synthetic answer with readable prose.');
      final metadata = find.byKey(ValueKey('hermes-turn-metadata-$id'));
      expect(
        tester.getRect(metadata).top,
        greaterThanOrEqualTo(tester.getRect(prose).bottom),
      );
      expect(
        find.byKey(const ValueKey('hermes-assistant-avatar')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('Stop remains pinned when secondary controls scroll at 200%', (
    tester,
  ) async {
    final channel = FakeHermesChannel();
    await _mount(tester, channel, 960, scale: 2);
    final field = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.enterText(field, 'Retained local draft');
    channel.beginStreamingTurn('Synthetic active run');
    await tester.pump();
    final stop = find.byKey(const ValueKey('hermes-composer-stop-chip'));
    final original = tester.getRect(stop);
    final secondary = find.byKey(
      const ValueKey('hermes-composer-secondary-controls'),
    );
    await tester.drag(secondary, const Offset(-600, 0));
    await tester.pump();
    expect(tester.getRect(stop), original);
    expect(stop.hitTestable(), findsOneWidget);
    await tester.tap(stop);
    await tester.pumpAndSettle();
    expect(channel.stopActiveTurnCalls, 1);
    expect(
      tester.widget<TextField>(field).controller!.text,
      'Retained local draft',
    );
    expect(channel.state.activeSessionId, 'sess_1');
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<void> _mount(
  WidgetTester tester,
  FakeHermesChannel channel,
  double width, {
  double scale = 1,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(channel.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const AppShellSessionNavigation(child: HermesChatScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
