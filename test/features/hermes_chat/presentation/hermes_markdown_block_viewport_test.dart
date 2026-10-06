import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wing/features/hermes_chat/presentation/hermes_markdown_block_viewport.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_rich_text.dart';
import 'package:wing/l10n/app_localizations.dart';

class _Mounts {
  int live = 0;
  int peak = 0;
  int created = 0;
}

class _Probe extends StatefulWidget {
  const _Probe(this.mounts, this.child);
  final _Mounts mounts;
  final Widget child;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    final counts = widget.mounts;
    counts.created++;
    counts.live++;
    if (counts.live > counts.peak) counts.peak = counts.live;
  }

  @override
  void deactivate() {
    widget.mounts.live--;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('far jumps never transiently mount skipped code blocks', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final mounts = _Mounts();
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 360,
          child: HermesMarkdownBlockViewport(
            controller: scroll,
            source: '1000 distinct short fenced blocks',
            children: List.generate(
              1000,
              (index) => _Probe(
                mounts,
                HermesRichText('```text\nSynthetic block $index\n```'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(mounts.peak, lessThan(30));
    for (final fraction in [1.0, 0.0, .8, .2, 1.0]) {
      mounts.peak = mounts.live;
      mounts.created = 0;
      scroll.jumpTo(scroll.position.maxScrollExtent * fraction);
      await tester.pumpAndSettle();
      // Count inside initState/deactivate, not merely after garbage collection.
      debugPrint(
        'jump=$fraction peak=${mounts.peak} created=${mounts.created}',
      );
      expect(mounts.peak, lessThan(30));
      expect(mounts.created, lessThan(30));
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Synthetic block 999'), findsOneWidget);
  });

  testWidgets('variable extents remain natural and sequential with no gaps', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final heights = List.generate(
      120,
      (i) => [32.0, 180.0, 64.0, 420.0, 95.0][i % 5],
    );
    final seen = <int>{};
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 360,
          child: HermesMarkdownBlockViewport(
            controller: scroll,
            source: 'variable natural extents',
            children: [
              for (var i = 0; i < heights.length; i++)
                SizedBox(
                  key: ValueKey('block-$i'),
                  height: heights[i],
                  child: Text('Block $i'),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var step = 0; step < 400; step++) {
      final mounted = <int>[];
      for (var i = 0; i < heights.length; i++) {
        final finder = find.byKey(ValueKey('block-$i'));
        if (finder.evaluate().isEmpty) continue;
        mounted.add(i);
        seen.add(i);
        expect(tester.getSize(finder).height, heights[i]);
      }
      for (var i = 1; i < mounted.length; i++) {
        expect(mounted[i], mounted[i - 1] + 1);
        expect(
          tester.getTopLeft(find.byKey(ValueKey('block-${mounted[i]}'))).dy,
          closeTo(
            tester
                .getBottomLeft(find.byKey(ValueKey('block-${mounted[i - 1]}')))
                .dy,
            .001,
          ),
        );
      }
      if (scroll.offset >= scroll.position.maxScrollExtent) break;
      scroll.jumpTo(
        (scroll.offset + 120).clamp(0, scroll.position.maxScrollExtent),
      );
      await tester.pumpAndSettle();
    }
    expect(seen, containsAll(List.generate(120, (i) => i)));
    expect(
      scroll.position.maxScrollExtent,
      closeTo(heights.reduce((a, b) => a + b) - 360, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mixed Markdown keeps its eager natural extents during traversal',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final blocks = List.generate(
        48,
        (i) => switch (i % 6) {
          0 => '# Synthetic heading $i',
          1 => 'Synthetic paragraph $i ${'wrapped words ' * (i + 1)}',
          2 => '| Synthetic $i | Value |\n| --- | --- |\n| Cell | Bounded |',
          3 => '> Synthetic quotation $i\n>\n> Second line',
          4 => '- Synthetic item $i\n- Nested content\n  - Child',
          _ => '```text\nSynthetic code $i\nsecond line\n```',
        },
      );
      List<Widget> children() => [
        for (var i = 0; i < blocks.length; i++)
          SizedBox(
            key: ValueKey('markdown-$i'),
            child: HermesRichText(blocks[i]),
          ),
      ];
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final natural = List.generate(
        blocks.length,
        (i) => tester.getSize(find.byKey(ValueKey('markdown-$i'))).height,
      );
      expect(natural.toSet().length, greaterThan(6));
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 440,
            height: 360,
            child: HermesMarkdownBlockViewport(
              controller: scroll,
              source: blocks.join('\n\n'),
              children: children(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final seen = <int>{};
      for (var step = 0; step < 300; step++) {
        final mounted = <int>[];
        for (var i = 0; i < blocks.length; i++) {
          final finder = find.byKey(ValueKey('markdown-$i'));
          if (finder.evaluate().isEmpty) continue;
          seen.add(i);
          mounted.add(i);
          expect(tester.getSize(finder).height, closeTo(natural[i], .001));
        }
        for (var i = 1; i < mounted.length; i++) {
          expect(mounted[i], mounted[i - 1] + 1);
          expect(
            tester
                .getTopLeft(find.byKey(ValueKey('markdown-${mounted[i]}')))
                .dy,
            closeTo(
              tester
                  .getBottomLeft(
                    find.byKey(ValueKey('markdown-${mounted[i - 1]}')),
                  )
                  .dy,
              .001,
            ),
          );
        }
        if (scroll.offset >= scroll.position.maxScrollExtent) break;
        scroll.jumpTo(
          (scroll.offset + 100).clamp(0, scroll.position.maxScrollExtent),
        );
        await tester.pumpAndSettle();
      }
      expect(seen, containsAll(List.generate(blocks.length, (i) => i)));
      expect(
        scroll.position.maxScrollExtent,
        closeTo(natural.reduce((a, b) => a + b) - 360, .001),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a very tall first block does not hide a short mixed tail', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final mounts = _Mounts();
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 360,
          child: HermesMarkdownBlockViewport(
            controller: scroll,
            source: 'tall first then variable tail',
            children: [
              _Probe(
                mounts,
                const SizedBox(height: 4000, child: Text('Tall block')),
              ),
              for (var i = 1; i < 1000; i++)
                _Probe(
                  mounts,
                  SizedBox(
                    height: 40.0 + (i * 37 % 170),
                    child: Text('Tail $i'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    mounts.peak = mounts.live;
    mounts.created = 0;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Tail 999'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Tail 999')).dy,
      lessThanOrEqualTo(360),
    );
    expect(mounts.peak, lessThan(30));
    expect(mounts.created, lessThan(30));
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Tall block'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estimate refinement keeps a middle jump at its sought index', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final mounts = _Mounts();
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 360,
          child: HermesMarkdownBlockViewport(
            controller: scroll,
            source: 'short beginning then taller independent blocks',
            children: [
              for (var i = 0; i < 1000; i++)
                _Probe(
                  mounts,
                  SizedBox(
                    height: i < 20 ? 40 : 900,
                    child: Text('Indexed block $i'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final sought = ((scroll.position.maxScrollExtent * .5) / 40).floor();
    mounts.peak = mounts.live;
    mounts.created = 0;
    scroll.jumpTo(scroll.position.maxScrollExtent * .5);
    await tester.pumpAndSettle();
    expect(find.text('Indexed block $sought'), findsOneWidget);
    expect(find.text('Indexed block 999'), findsNothing);
    expect(mounts.peak, lessThan(30));
    expect(mounts.created, lessThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('extent cache resets for width scale theme and source changes', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    var width = 600.0;
    var scale = 1.0;
    var lineHeight = 1.0;
    var source = 'original';
    var count = 100;
    final viewportKey = GlobalKey();
    Future<void> rebuild() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: 18, height: lineHeight),
            ),
          ),
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: SizedBox(
                width: width,
                height: 360,
                child: HermesMarkdownBlockViewport(
                  key: viewportKey,
                  controller: scroll,
                  source: source,
                  children: List.generate(
                    count,
                    (i) => Text(
                      '$source $i ${'synthetic wrapped words ' * 25}',
                      key: ValueKey('text-$i'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await rebuild();
    final initial = scroll.position.maxScrollExtent;
    scroll.jumpTo(initial * .75);
    await tester.pumpAndSettle();
    final anchor = tester
        .widgetList<Text>(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.key != null,
          ),
        )
        .first
        .key!;
    width = 260;
    await rebuild();
    expect(find.byKey(anchor), findsOneWidget);
    expect(scroll.position.maxScrollExtent, greaterThan(initial));
    final narrow = scroll.position.maxScrollExtent;
    scale = 2;
    await rebuild();
    expect(scroll.position.maxScrollExtent, greaterThan(narrow));
    final scaled = scroll.position.maxScrollExtent;
    lineHeight = 2;
    await rebuild();
    expect(scroll.position.maxScrollExtent, greaterThan(scaled));
    source = 'replacement';
    count = 3;
    await rebuild();
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.textContaining('replacement 0'), findsOneWidget);
    expect(find.textContaining('original'), findsNothing);
    expect(scroll.position.maxScrollExtent, lessThan(scaled));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed large Markdown preserves table link image and expansion', (
    tester,
  ) async {
    Uri? launched;
    const png =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
    final longCode = List.generate(
      20,
      (i) => 'Synthetic expanded line $i',
    ).join('\n');
    final source =
        '# Mixed heading\n\n| Name | Value |\n| --- | --- |\n| Synthetic cell | 7 |\n\n[Safe link](https://example.test/docs)\n\n![Synthetic pixel](data:image/png;base64,$png)\n\n```text\n$longCode\n```\n\n${List.generate(180, (i) => '## Section $i\n\n${'Wrapped synthetic paragraph $i. ' * (i % 7 + 1)}\n\n> Quoted synthetic $i\n\n- Item $i\n- Next item\n\n```text\nSample $i\n```\n\n').join()}Tail complete';
    expect(source.length, greaterThan(32768));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: HermesRichText(
            source,
            launchUri: (uri) async {
              launched = uri;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mixed heading', findRichText: true), findsOneWidget);
    expect(find.text('Synthetic cell', findRichText: true), findsOneWidget);
    expect(find.byType(Table), findsWidgets);
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.bySemanticsLabel('Synthetic pixel'), findsOneWidget);
    await tester.tap(find.text('Safe link', findRichText: true));
    await tester.pump();
    expect(launched, Uri.parse('https://example.test/docs'));
    final vertical = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .firstWhere((s) => s.position.maxScrollExtent > 10000);
    for (
      var i = 0;
      i < 8 &&
          find.byKey(const ValueKey('hermes-code-toggle')).evaluate().isEmpty;
      i++
    ) {
      vertical.position.jumpTo(vertical.position.pixels + 80);
      await tester.pumpAndSettle();
    }
    final collapsedExtent = vertical.position.maxScrollExtent;
    await tester.tap(find.byKey(const ValueKey('hermes-code-toggle')).first);
    await tester.pumpAndSettle();
    expect(find.text(longCode), findsOneWidget);
    expect(vertical.position.maxScrollExtent, greaterThan(collapsedExtent));
    final expandedExtent = vertical.position.maxScrollExtent;
    for (
      var i = 0;
      i < 20 && !find.text('Show less').hitTestable().evaluate().isNotEmpty;
      i++
    ) {
      vertical.position.jumpTo(vertical.position.pixels + 80);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(vertical.position.maxScrollExtent, lessThan(expandedExtent));
    vertical.position.jumpTo(vertical.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Tail complete', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'production large Markdown retains final exact code copy',
    (tester) async {
      String? copied;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final source =
          'Selected excerpt stays copyable\n\n${List.generate(1000, (i) => '```text\nSynthetic distinct short block $i\n```\n\n').join()}```text\nFinal exact source\n```';
      await tester.pumpWidget(
        _app(SingleChildScrollView(child: HermesRichText(source))),
      );
      await tester.pumpAndSettle();
      final text = find.text(
        'Selected excerpt stays copyable',
        findRichText: true,
      );
      final point = tester.getTopLeft(text) + const Offset(20, 10);
      await tester.tapAt(point, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(point, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(copied, 'Selected');
      final vertical = tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .firstWhere((s) => s.position.maxScrollExtent > 10000);
      vertical.position.jumpTo(vertical.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('Final exact source'), findsOneWidget);
      final block = find.ancestor(
        of: find.text('Final exact source'),
        matching: find.byKey(const ValueKey('hermes-code-block')),
      );
      await tester.tap(
        find.descendant(
          of: block,
          matching: find.byKey(const ValueKey('hermes-code-copy')),
        ),
      );
      await tester.pump();
      expect(copied, 'Final exact source');
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
