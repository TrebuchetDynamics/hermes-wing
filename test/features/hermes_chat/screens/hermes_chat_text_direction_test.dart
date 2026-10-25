import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final focus = original.focusNode!;
      focus.requestFocus();
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
        expect(focus.hasFocus, isTrue);
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
      expect(channel.connectCalls, isEmpty);
      expect(channel.createSessionCalls, isEmpty);
      expect(channel.loadEarlierMessagesCalls, 0);
      expect(channel.loadProvidersCalls, 0);
      expect(channel.reconcileActiveSessionCalls, 0);
      expect(channel.sentImageDataUrls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final direction in [null, TextDirection.rtl, TextDirection.ltr]) {
    testWidgets(
      'inline code links preserve safe activation and plain copy: $direction',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final opened = <Uri>[];
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        const source =
            '[`code()`](https://example.invalid) and `code()` and [`bad()`](javascript:bad)';
        Widget render(String data) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HermesRichText(
              data,
              textDirection: direction,
              launchUri: (uri) async {
                opened.add(uri);
                return true;
              },
            ),
          ),
        );
        await tester.pumpWidget(render('[`code()`](https://example.invalid)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('code()', findRichText: true).first);
        await tester.pumpAndSettle();
        expect(opened, [Uri.parse('https://example.invalid')]);
        opened.clear();
        await tester.pumpWidget(
          render('Before [`code()`](https://example.invalid) after.'),
        );
        await tester.pumpAndSettle();
        if (direction != TextDirection.rtl) {
          final paragraphs = tester.renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byType(HermesRichText),
              matching: find.byType(RichText),
            ),
          );
          expect(
            paragraphs.where((paragraph) {
              final text = paragraph.text.toPlainText();
              return text.contains('Before ') && text.contains(' after.');
            }),
            hasLength(1),
            reason: 'Auto/LTR code must not split continuous paragraph flow',
          );
        }
        await tester.pumpWidget(
          render('[ordinary](https://example.invalid/ordinary)'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('ordinary', findRichText: true).last);
        await tester.pumpAndSettle();
        expect(opened, [Uri.parse('https://example.invalid/ordinary')]);
        opened.clear();
        await tester.pumpWidget(
          render(
            '[`reference()`][target]\n\n[target]: https://example.invalid/reference',
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('reference()', findRichText: true).last);
        await tester.pumpAndSettle();
        expect(opened, [Uri.parse('https://example.invalid/reference')]);
        opened.clear();
        await tester.pumpWidget(render(source));
        await tester.pumpAndSettle();
        if (direction != null) {
          opened.clear();
          await tester.tap(find.text('code()', findRichText: true).last);
          await tester.pumpAndSettle();
          expect(opened, isEmpty);
          await tester.tap(find.text('bad()', findRichText: true).last);
          await tester.pumpAndSettle();
          expect(opened, isEmpty);
          var linkFocused = false;
          for (var i = 0; i < 40; i++) {
            FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
              element,
            ) {
              final widget = element.widget;
              if (widget is Semantics && widget.properties.link == true) {
                linkFocused = true;
              }
              return !linkFocused;
            });
            if (linkFocused) break;
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
          }
          expect(linkFocused, isTrue);
          final link = tester.getSemantics(
            find.text('code()', findRichText: true).first,
          );
          expect(link.flagsCollection.isLink, isTrue);
          expect(link.flagsCollection.isFocused.toBoolOrNull(), isTrue);
          expect(
            link.getSemanticsData().hasAction(SemanticsAction.focus),
            isTrue,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(opened, [Uri.parse('https://example.invalid')]);
        }
        final region = tester.state<SelectableRegionState>(
          find.byType(SelectableRegion).first,
        );
        region.selectAll(SelectionChangedCause.keyboard);
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        region.contextMenuButtonItems
            .firstWhere((item) => item.type == ContextMenuButtonType.copy)
            .onPressed
            ?.call();
        await tester.pumpAndSettle();
        expect(copied, 'code() and code() and bad()');
        expect(
          tester.widget<HermesRichText>(find.byType(HermesRichText)).data,
          source,
        );
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'wrapped mixed Markdown preserves copy across live RTL LTR Auto changes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final words = List.filled(9, 'mixed שלום prose').join(' ');
      final source =
          'Prefix $words `first()` $words `second()` tail.\n\n- List `third()` with words.\n\n> Quote `fourth()` with words.\n\n```dart\ncode line one\ncode line two\n```';
      String? baseline;
      for (final direction in [
        null,
        TextDirection.rtl,
        TextDirection.ltr,
        null,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: HermesRichText(source, textDirection: direction),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final region = tester.state<SelectableRegionState>(
          find.byType(SelectableRegion).first,
        );
        region.selectAll(SelectionChangedCause.keyboard);
        await tester.pumpAndSettle();
        region.contextMenuButtonItems
            .firstWhere((item) => item.type == ContextMenuButtonType.copy)
            .onPressed
            ?.call();
        await tester.pumpAndSettle();
        baseline ??= copied;
        expect(
          copied,
          baseline,
          reason: 'Selection source order at $direction',
        );
        expect(
          copied!.indexOf('first()'),
          lessThan(copied!.indexOf('second()')),
        );
        expect(
          copied!.indexOf('third()'),
          lessThan(copied!.indexOf('fourth()')),
        );
        expect(copied, contains('code line one\ncode line two'));
        expect(tester.takeException(), isNull);
      }
    },
  );
}
