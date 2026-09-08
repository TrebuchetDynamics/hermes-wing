import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_rich_text.dart';
import 'package:wing/l10n/app_localizations.dart';

// Run under Xvfb so the real clipboard belongs only to this test display.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final width in [420.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final direction in TextDirection.values) {
        testWidgets(
          'native reader width=$width scale=$scale direction=${direction.name}',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final original = '${'a' * 2047}👩🏽‍💻${'b' * 35000}END';
            final source = ValueNotifier(original);
            addTearDown(source.dispose);
            addTearDown(() => Clipboard.setData(const ClipboardData(text: '')));
            await tester.pumpWidget(
              MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: Directionality(
                      textDirection: direction,
                      child: Scaffold(
                        body: SingleChildScrollView(
                          child: ValueListenableBuilder<String>(
                            valueListenable: source,
                            builder: (_, text, _) => HermesRichText(text),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final copy = find.byKey(const ValueKey('hermes-large-text-copy'));
            expect(copy, findsOneWidget);
            await tester.tap(copy);
            await tester.pumpAndSettle();
            expect(
              (await Clipboard.getData(Clipboard.kTextPlain))?.text == original,
              isTrue,
            );
            expect(find.byType(SelectionArea), findsOneWidget);
            final listFinder = find.descendant(
              of: find.byType(HermesRichText),
              matching: find.byType(ListView),
            );
            final delegate =
                tester.widget<ListView>(listFinder).childrenDelegate
                    as SliverChildBuilderDelegate;
            final first =
                delegate.builder(tester.element(listFinder), 0) as Text;
            expect(first.data!.endsWith('👩🏽‍💻'), isTrue);
            final scroll = tester
                .stateList<ScrollableState>(
                  find.descendant(
                    of: find.byType(HermesRichText),
                    matching: find.byType(Scrollable),
                  ),
                )
                .single;
            // The first chunk can be taller than the viewport at large scales.
            // Tap its visible start, not the off-screen center of the paragraph.
            await tester.tapAt(
              tester.getTopLeft(find.text(first.data!).first) +
                  const Offset(24, 24),
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
            await tester.pumpAndSettle();
            expect(scroll.position.pixels, greaterThan(0));
            for (var attempt = 0; attempt < 10; attempt++) {
              scroll.position.jumpTo(scroll.position.maxScrollExtent);
              await tester.pumpAndSettle();
              if (find.textContaining('END').evaluate().isNotEmpty) break;
            }
            expect(find.textContaining('END'), findsOneWidget);
            source.value += 'TAIL';
            await tester.pumpAndSettle();
            scroll.position.jumpTo(scroll.position.maxScrollExtent);
            await tester.pumpAndSettle();
            expect(find.textContaining('TAIL'), findsOneWidget);
            await tester.tap(copy);
            await tester.pumpAndSettle();
            expect(
              (await Clipboard.getData(Clipboard.kTextPlain))?.text ==
                  '${original}TAIL',
              isTrue,
            );
            tester.view.physicalSize = const Size(320, 700);
            await tester.pumpAndSettle();
            expect(copy.hitTestable(), findsOneWidget);
            source.value = '# Heading\n\n**bold**';
            await tester.pumpAndSettle();
            expect(copy, findsNothing);
            expect(find.text('bold', findRichText: true), findsOneWidget);
            source.value = original;
            await tester.pumpAndSettle();
            expect(copy, findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
