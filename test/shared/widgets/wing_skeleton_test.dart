import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/widgets/wing_skeleton.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('loading rows fit inside a parent scrollable', (tester) async {
    await tester.pumpWidget(
      _host(
        ListView(
          children: const [
            WingSkeletonList(rows: 2, semanticLabel: 'Loading connections'),
          ],
        ),
        disableAnimations: true,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(WingSkeletonRow), findsNWidgets(2));
    expect(
      tester.getSize(find.byKey(const ValueKey('wing-skeleton-list'))).height,
      greaterThan(0),
    );
  });

  testWidgets('renders the requested number of placeholder rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const WingSkeletonList(rows: 4, semanticLabel: 'Loading agents')),
    );

    expect(find.byKey(const ValueKey('wing-skeleton-list')), findsOneWidget);
    expect(find.byType(WingSkeletonRow), findsNWidgets(4));
  });

  testWidgets('announces the loading label to assistive tech', (tester) async {
    await tester.pumpWidget(
      _host(const WingSkeletonList(rows: 2, semanticLabel: 'Loading agents')),
    );

    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('wing-skeleton-list')))
          .label,
      contains('Loading agents'),
    );
  });

  testWidgets('the pulse animates unless animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const WingSkeletonList(rows: 1, semanticLabel: 'Loading')),
    );
    final animated = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('wing-skeleton-pulse')),
    );
    final before = animated.opacity.value;
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester
          .widget<FadeTransition>(
            find.byKey(const ValueKey('wing-skeleton-pulse')),
          )
          .opacity
          .value,
      isNot(before),
    );

    await tester.pumpWidget(
      _host(
        const WingSkeletonList(rows: 1, semanticLabel: 'Loading'),
        disableAnimations: true,
      ),
    );
    final still = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('wing-skeleton-pulse')),
    );
    final frozen = still.opacity.value;
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester
          .widget<FadeTransition>(
            find.byKey(const ValueKey('wing-skeleton-pulse')),
          )
          .opacity
          .value,
      frozen,
    );
  });
}
