import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/widgets/wing_empty_state.dart';

void main() {
  testWidgets('recovery stays reachable in a short large-text viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 260);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var recovered = false;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: WingEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Connection unavailable',
            body:
                'Choose another gateway to continue working with your profiles.',
            actionLabel: 'Connect',
            onAction: () => recovered = true,
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Connect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect'));
    expect(recovered, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('can announce a dynamic failure as a live region', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WingEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Connection unavailable',
            body: 'Choose another gateway.',
            liveRegion: true,
          ),
        ),
      ),
    );

    expect(
      tester
          .getSemantics(find.text('Connection unavailable'))
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    semantics.dispose();
  });
}
