import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/widgets/chat_profile_picker.dart';

import 'hermes_chat_profile_picker_test.dart' as profile;

final _header = find.byKey(const ValueKey('hermes-profile-switcher'));
final _pickers = find.byType(ChatProfilePicker, skipOffstage: false);
final _searches = find.byKey(
  const ValueKey('chat-profile-search'),
  skipOffstage: false,
);

void _expectCount(int count) {
  expect(_pickers, findsNWidgets(count));
  expect(_searches, findsNWidgets(count));
}

void _expectAtMostOne() {
  final count = _pickers.evaluate().length;
  expect(count, lessThanOrEqualTo(1));
  _expectCount(count);
}

Future<void> _dismiss(WidgetTester tester) async {
  if (_pickers.evaluate().isNotEmpty) {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  }
  await tester.pumpAndSettle();
  _expectCount(0);
  // No queued opener may appear after dismissal or another frame.
  await tester.pump(const Duration(seconds: 1));
  _expectCount(0);
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );

  for (final width in [390.0, 1280.0]) {
    for (final input in ['pointer', 'keyboard']) {
      testWidgets('rapid public $input entry and dismissal at $width', (
        tester,
      ) async {
        final h = await profile.pumpChat(
          tester,
          width,
          disableAnimations: false,
        );
        final original = h.channel.state;
        final position = tester.getCenter(_header);
        if (input == 'keyboard') {
          await profile.tabTo(
            tester,
            const ValueKey('hermes-profile-switcher'),
          );
          await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
          for (var i = 0; i < 3; i++) {
            await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
          }
          await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
        } else {
          // Real hit testing, including the modal barrier once inserted.
          for (var i = 0; i < 3; i++) {
            await tester.tapAt(position);
          }
        }
        await tester.pump();
        _expectAtMostOne();
        for (final elapsed in [16, 80, 160]) {
          if (input == 'keyboard') {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
            await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
            await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
          } else {
            await tester.tapAt(position);
          }
          await tester.pump(Duration(milliseconds: elapsed));
          _expectAtMostOne();
          profile.expectNoMutations(h.channel);
        }
        await tester.pumpAndSettle();
        _expectAtMostOne();
        await _dismiss(tester);
        expect(identical(h.channel.state, original), isTrue);
        profile.expectNoMutations(h.channel);

        // A fresh explicit open must still work, with one current route.
        await profile.openPicker(tester);
        _expectCount(1);
        expect(
          tester.widget<TextField>(profile.search).controller!.text,
          isEmpty,
        );
        expect(tester.widget<ListTile>(profile.row('active')).selected, isTrue);
        await tester.tap(profile.row('active'));
        await tester.pump();
        _expectAtMostOne();
        await tester.pump(const Duration(milliseconds: 80));
        _expectAtMostOne();
        await tester.pumpAndSettle();
        _expectCount(0);
        profile.expectNoMutations(h.channel);

        await profile.openPicker(tester);
        _expectCount(1);
        await tester.tap(profile.row('beta'));
        await tester.pumpAndSettle();
        _expectCount(0);
        expect(h.channel.selectProfileCalls, ['beta']);
        expect(h.channel.state.selectedProfileId, 'beta');
        expect(h.channel.selectSessionCalls, isEmpty);
        expect(h.channel.createSessionCalls, isEmpty);
        expect(h.channel.sentImageDataUrls, isEmpty);
        expect(h.channel.sentVoiceTranscripts, isEmpty);
        expect(h.channel.lockSessionModelCalls, isEmpty);
        expect(h.channel.assignModelCalls, isEmpty);
        expect(h.channel.respondToApprovalCalls, isEmpty);
        expect(h.channel.stopActiveTurnCalls, 0);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('held Enter through active-row dismissal at $width', (
      tester,
    ) async {
      final h = await profile.pumpChat(tester, width, disableAnimations: false);
      await profile.tabTo(tester, const ValueKey('hermes-profile-switcher'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      _expectCount(1);
      expect(
        FocusManager.instance.primaryFocus,
        tester.widget<TextField>(profile.search).focusNode,
      );
      // Select the active row normally, then keep the physical Enter held
      // while modal focus returns and the reverse animation is still running.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      for (final elapsed in [0, 16, 80]) {
        await tester.pump(Duration(milliseconds: elapsed));
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
        _expectAtMostOne();
        profile.expectNoMutations(h.channel);
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      _expectCount(0);
      await tester.pump(const Duration(seconds: 1));
      _expectCount(0);
      await profile.openPicker(tester);
      _expectCount(1);
      await _dismiss(tester);
      profile.expectNoMutations(h.channel);
      expect(tester.takeException(), isNull);
    });

    testWidgets('public manage and owner invalidation reopen at $width', (
      tester,
    ) async {
      final h = await profile.pumpChat(tester, width, disableAnimations: false);
      final original = h.channel.state;
      await profile.openPicker(tester);
      _expectCount(1);
      h.channel.change(
        original.copyWith(status: HermesConnectionStatus.disconnected),
      );
      h.channel.change(original);
      await tester.pumpAndSettle();
      _expectCount(0);
      profile.expectNoMutations(h.channel);
      await profile.tabTo(tester, const ValueKey('hermes-profile-switcher'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      _expectCount(1);
      await profile.tabTo(tester, const ValueKey('chat-profile-manage'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      _expectCount(0);
      expect(h.router.routeInformationProvider.value.uri.path, '/profiles');
      expect(find.text('Profiles destination'), findsOneWidget);
      profile.expectNoMutations(h.channel);
      expect(tester.takeException(), isNull);
    });
  }
}
