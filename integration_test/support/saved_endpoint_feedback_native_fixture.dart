import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'saved_endpoint_edit_native_fixture.dart';

/// Storage denial is deterministic; this is not a keyring qualification.
class FeedbackStore extends SavedEditStore {
  bool fail = true;
  int attempts = 0;

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
    String? wingLinkHostFingerprint,
    String? wingLinkDeviceId,
  }) async {
    attempts++;
    if (fail) throw StateError('Synthetic storage denial');
    await super.save(
      baseUrl: baseUrl,
      apiKey: apiKey,
      label: label,
      profileId: profileId,
    );
  }
}

Finder feedbackControl(String key) => find.byKey(ValueKey(key));

Future<void> feedbackReach(WidgetTester tester, String key) async {
  for (var i = 0; i < 160; i++) {
    var focused = false;
    final context = FocusManager.instance.primaryFocus?.context;
    if (context?.widget.key == ValueKey(key)) focused = true;
    context?.visitAncestorElements((element) {
      if (element.widget.key == ValueKey(key)) focused = true;
      return !focused;
    });
    if (focused) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Keyboard did not reach $key');
}

/// Read the beginning, then bounded overlapping keyboard pages to the end.
/// No test-driver ensureVisible, dragging, or pointer activation is used.
Future<void> feedbackRead(
  WidgetTester tester,
  String text,
  Future<void> Function(String suffix) capture,
) async {
  final finder = find.text(text);
  expect(finder, findsOneWidget);
  expect(tester.renderObject<RenderParagraph>(finder).didExceedMaxLines, false);
  final viewport = find
      .ancestor(of: finder, matching: find.byType(SingleChildScrollView))
      .first;
  final bounds = tester.getRect(viewport);
  var rectangle = tester.getRect(finder);
  expect(rectangle.top >= bounds.top - 1, true);
  expect(
    rectangle.left >= bounds.left - 1 && rectangle.right <= bounds.right + 1,
    true,
  );
  await capture('start');
  var pages = 0;
  while (rectangle.bottom > bounds.bottom + 1 && pages < 4) {
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    rectangle = tester.getRect(finder);
    await capture('page-${++pages}');
  }
  expect(rectangle.bottom <= bounds.bottom + 1, true);
}
