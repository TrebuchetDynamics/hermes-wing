import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_rich_text.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  testWidgets(
    'local text direction updates prose and composer without changing draft ownership',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
      });
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      const user = 'Hello שלום';
      const assistant =
          'Response مرحبا\n\n- List שלום\n\n> Quote مرحبا\n\nUse `inline() שלום` here.\n\n```dart\ncode() שלום\n```';
      channel.replaceTranscript([
        HermesChatTurn(
          id: 'direction-user',
          sessionId: 'sess_1',
          author: HermesTurnAuthor.user,
          createdAt: DateTime.utc(2026),
          text: user,
        ),
        HermesChatTurn(
          id: 'direction-assistant',
          sessionId: 'sess_1',
          author: HermesTurnAuthor.assistant,
          createdAt: DateTime.utc(2026),
          text: assistant,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HermesChatScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('hermes-composer-field'));
      final original = tester.widget<TextField>(field);
      final controller = original.controller!;
      final focus = original.focusNode;
      const draft = TextEditingValue(
        text: 'Draft שלום',
        selection: TextSelection(baseOffset: 1, extentOffset: 5),
        composing: TextRange(start: 0, end: 5),
      );
      controller.value = draft;
      await tester.pumpAndSettle();
      final state = channel.state;
      final settings = container.read(wingChatPreferencesProvider.notifier);
      for (final direction in [
        WingChatTextDirection.rtl,
        WingChatTextDirection.ltr,
        WingChatTextDirection.auto,
      ]) {
        settings.setTextDirection(direction);
        await tester.pumpAndSettle();
        final current = tester.widget<TextField>(field);
        expect(current.textDirection, direction.forcedDirection);
        expect(identical(current.controller, controller), isTrue);
        expect(identical(current.focusNode, focus), isTrue);
        expect(controller.value, draft);
        final rich = tester
            .widgetList<HermesRichText>(find.byType(HermesRichText))
            .toList();
        expect(rich.map((text) => text.data), containsAll([user, assistant]));
        expect(
          rich.every((text) => text.textDirection == direction.forcedDirection),
          isTrue,
        );
        final paragraphs = find.descendant(
          of: find.byType(HermesRichText),
          matching: find.byType(RichText),
        );
        for (final key in ['Hello שלום', 'List שלום', 'Quote مرحبا']) {
          final prose = paragraphs
              .evaluate()
              .map((element) => element.renderObject)
              .whereType<RenderParagraph>()
              .where((paragraph) => paragraph.text.toPlainText().contains(key));
          expect(prose, isNotEmpty);
          expect(
            prose.every(
              (paragraph) =>
                  paragraph.textDirection ==
                  (direction.forcedDirection ?? TextDirection.ltr),
            ),
            isTrue,
          );
        }
        final code = tester.renderObject<RenderParagraph>(
          find
              .descendant(
                of: find.byKey(const ValueKey('hermes-code-content')),
                matching: find.byType(RichText),
              )
              .last,
        );
        expect(code.textDirection, TextDirection.ltr);
        expect(code.text.toPlainText(), 'code() שלום');
        if (direction != WingChatTextDirection.auto) {
          final inline = tester.widget<Text>(find.text('inline() שלום'));
          expect(inline.textDirection, TextDirection.ltr);
        }
        expect(Directionality.of(tester.element(field)), TextDirection.ltr);
        expect(identical(channel.state, state), isTrue);
        expect(channel.stopActiveTurnCalls, 0);
      }
      expect(channel.selectSessionCalls, isEmpty);
      expect(channel.selectProfileCalls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
