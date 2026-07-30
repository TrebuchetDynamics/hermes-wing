import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

Widget _localizedApp(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets('per-message actions are reachable without a pointer', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel();
    channel.beginStreamingTurn('Ask something.');
    channel.completeStreamingTurn(text: 'An assistant reply.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: _localizedApp(const HermesChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Reply and Copy for a single turn hang off a long-press gesture. Assistive
    // technology cannot perform a raw long press, so the gesture has to be
    // published as a semantics action for it to be operable at all.
    final bubble = find.ancestor(
      of: find.text('An assistant reply.', findRichText: true),
      matching: find.byType(GestureDetector),
    );
    expect(bubble, findsWidgets);

    final exposesLongPress = tester
        .widgetList<GestureDetector>(bubble)
        .any((detector) => detector.onLongPress != null);
    expect(
      exposesLongPress,
      isTrue,
      reason: 'the message bubble should own the long-press action',
    );

    final node = tester.getSemantics(bubble.first);
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.longPress),
      isTrue,
      reason:
          'message actions must be operable without pointer input; a bare '
          'GestureDetector long press that is excluded from semantics would '
          'strand screen-reader users with no route to Reply or Copy',
    );

    semantics.dispose();
  });
}
