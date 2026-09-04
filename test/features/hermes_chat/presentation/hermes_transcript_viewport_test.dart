import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_transcript_viewport.dart';

void main() {
  testWidgets('missing canonical anchor safely returns to latest', (
    tester,
  ) async {
    final scroll = ScrollController();
    final viewport = HermesTranscriptViewportController(scroll)..setOwner('A');
    addTearDown(viewport.dispose);
    addTearDown(scroll.dispose);
    Widget app(bool hasAnchor) => MaterialApp(
      home: SizedBox(
        key: viewport.listKey,
        child: ListView(
          controller: scroll,
          reverse: true,
          children: [
            const SizedBox(height: 120),
            SizedBox(
              key: hasAnchor ? viewport.rowKey('message') : null,
              height: 200,
            ),
            const SizedBox(height: 1000),
          ],
        ),
      ),
    );
    await tester.pumpWidget(app(true));
    scroll.jumpTo(140);
    viewport.userScrolled(nearLatest: false);
    await tester.pump();
    final generation = viewport.beginAuthoritativeRefresh();
    viewport.retainRows({});
    await tester.pumpWidget(app(false));
    expect(viewport.mode, HermesViewportMode.restoring);
    expect(viewport.generation, generation);
    expect(scroll.hasClients, isTrue);
    viewport.restore(generation);
    await tester.pump();
    await tester.pump();
    expect(viewport.mode, HermesViewportMode.followingLatest);
    expect(scroll.offset, scroll.position.minScrollExtent);
  });

  test(
    'user browsing and explicit owner changes invalidate deferred restoration',
    () {
      final scroll = ScrollController();
      final viewport = HermesTranscriptViewportController(scroll)
        ..setOwner('A');
      viewport.userScrolled(nearLatest: false);
      expect(viewport.mode, HermesViewportMode.browsing);
      final restore = viewport.beginAuthoritativeRefresh();
      expect(viewport.mode, HermesViewportMode.restoring);
      viewport.userScrolled(nearLatest: false);
      expect(viewport.generation, greaterThan(restore));
      viewport.setOwner('B');
      viewport.setOwner('A');
      expect(viewport.mode, HermesViewportMode.followingLatest);
      viewport.dispose();
      scroll.dispose();
    },
  );

  testWidgets(
    'canonical refresh restores a visible semantic row and respects later user intent',
    (tester) async {
      final scroll = ScrollController();
      final viewport = HermesTranscriptViewportController(scroll)
        ..setOwner('A');
      addTearDown(viewport.dispose);
      addTearDown(scroll.dispose);
      var extraHeight = 0.0;
      Widget app() => MaterialApp(
        home: SizedBox(
          key: viewport.listKey,
          child: ListView(
            controller: scroll,
            reverse: true,
            children: [
              SizedBox(height: 120 + extraHeight),
              SizedBox(
                key: viewport.rowKey('message'),
                height: 200,
                child: const Text('synthetic row'),
              ),
              const SizedBox(height: 1000),
            ],
          ),
        ),
      );
      await tester.pumpWidget(app());
      scroll.jumpTo(140);
      viewport.userScrolled(nearLatest: false);
      await tester.pump();
      final before = tester.getTopLeft(find.text('synthetic row')).dy;
      final generation = viewport.beginAuthoritativeRefresh();
      extraHeight = 80;
      await tester.pumpWidget(app());
      viewport.restore(generation);
      await tester.pump();
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('synthetic row')).dy,
        closeTo(before, 1),
      );
      expect(viewport.mode, HermesViewportMode.browsing);
      final obsolete = viewport.beginAuthoritativeRefresh();
      viewport.userScrolled(nearLatest: false);
      final offset = scroll.offset;
      viewport.restore(obsolete);
      await tester.pump();
      expect(scroll.offset, offset);
    },
  );
}
