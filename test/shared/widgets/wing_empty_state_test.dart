import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/widgets/wing_empty_state.dart';

void main() {
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
