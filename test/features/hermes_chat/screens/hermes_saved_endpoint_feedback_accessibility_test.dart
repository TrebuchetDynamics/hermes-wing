import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'hermes_chat_saved_endpoint_edit_test.dart' as predecessor;

Finder control(String key) => find.byKey(ValueKey(key));

bool focused(String key) {
  var found = false;
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
    found = e.widget.key == ValueKey(key);
    return !found;
  });
  return found;
}

Future<void> keyboard(WidgetTester tester, String key) async {
  for (var i = 0; i < 100; i++) {
    if (focused(key)) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Tab could not reach $key');
}

Future<void> activate(WidgetTester tester, String key) async {
  await keyboard(tester, key);
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await tester.pumpAndSettle();
}

Future<void> readable(
  WidgetTester tester,
  String text, {
  bool visible = false,
}) async {
  final finder = find.text(text);
  expect(finder, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(
    paragraph.didExceedMaxLines,
    false,
    reason: 'Complete copy must render',
  );
  if (visible) {
    final viewport = find
        .ancestor(of: finder, matching: find.byType(SingleChildScrollView))
        .first;
    final bounds = tester.getRect(viewport);
    var textBounds = tester.getRect(finder);
    expect(bounds.top <= textBounds.top + 1, true);
    for (var i = 0; bounds.bottom < textBounds.bottom - 1 && i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      textBounds = tester.getRect(finder);
    }
    expect(
      bounds.bottom >= textBounds.bottom - 1,
      true,
      reason: '$bounds versus $textBounds: $text',
    );
    expect(bounds.left <= textBounds.left + 1, true);
    expect(bounds.right >= textBounds.right - 1, true);
  }
}

void main() {
  for (final width in [1280.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final abandon in ['cancel', 'owner']) {
        testWidgets('late feedback after $abandon $width/$scale', (
          tester,
        ) async {
          final store = predecessor.Store();
          final probe = predecessor.Probe()..pending = Completer<String>();
          final channel = await predecessor.mount(
            tester,
            store,
            probe: probe,
            width: width,
            scale: scale,
          );
          await predecessor.edit(tester);
          final strings = AppLocalizations.of(
            tester.element(control('hermes-saved-edit-dialog')),
          );
          await keyboard(tester, 'hermes-saved-edit-test');
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump(const Duration(milliseconds: 100));
          if (abandon == 'cancel') {
            await keyboard(tester, 'hermes-saved-edit-cancel-test');
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pumpAndSettle();
          } else {
            await channel.connect(baseUrl: predecessor.second.baseUrl);
          }
          probe.pending!.complete(probe.body);
          await tester.pumpAndSettle();
          expect(find.text(strings.chatSavedEndpointTestSuccess), findsNothing);
          await readable(
            tester,
            abandon == 'cancel'
                ? strings.chatSavedEndpointTestCancelled
                : strings.chatSavedEndpointStale,
            visible: true,
          );
          await activate(tester, 'hermes-saved-edit-cancel');
          expect(store.attempts, 0);
          expect(store.saveCalls, isEmpty);
          expect(probe.calls, hasLength(1));
          expect(
            (await store.loadProfiles()).first.baseUrl,
            predecessor.first.baseUrl,
          );
          expect(
            (await store.loadProfiles()).last.baseUrl,
            predecessor.second.baseUrl,
          );
          expect(channel.connectCalls, hasLength(abandon == 'owner' ? 1 : 0));
          expect(tester.takeException(), isNull);
        });
      }
      testWidgets('readable keyboard feedback $width/$scale', (tester) async {
        final store = predecessor.Store()..fail = true;
        final probe = predecessor.Probe()..status = 403;
        final channel = await predecessor.mount(
          tester,
          store,
          probe: probe,
          width: width,
          scale: scale,
        );
        // Public saved-row action; editor traversal never uses ensureVisible.
        await predecessor.edit(tester);
        final strings = AppLocalizations.of(
          tester.element(control('hermes-saved-edit-dialog')),
        );
        await readable(tester, strings.chatSavedEndpointKeyHelp);
        await tester.enterText(
          control('hermes-saved-edit-url'),
          'https://draft.example.invalid',
        );
        await activate(tester, 'hermes-saved-edit-test');
        await readable(
          tester,
          strings.chatSavedEndpointTestDenied,
          visible: true,
        );
        final semantics = tester.ensureSemantics();
        expect(
          tester
              .getSemantics(control('hermes-saved-edit-notice'))
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          true,
        );
        semantics.dispose();
        expect(probe.calls, hasLength(1));
        await tester.pump(const Duration(seconds: 2));
        expect(probe.calls, hasLength(1));
        probe.status = 200;
        await activate(tester, 'hermes-saved-edit-test');
        await readable(
          tester,
          strings.chatSavedEndpointTestSuccess,
          visible: true,
        );
        probe.status = 500;
        await activate(tester, 'hermes-saved-edit-test');
        await readable(
          tester,
          strings.chatSavedEndpointTestFailed,
          visible: true,
        );
        expect(probe.calls, hasLength(3));
        await activate(tester, 'hermes-saved-edit-save');
        await readable(
          tester,
          strings.chatSavedEndpointSaveFailed,
          visible: true,
        );
        expect(store.attempts, 1);
        expect(store.saveCalls, isEmpty);
        expect(
          (await store.loadProfiles()).first.baseUrl,
          predecessor.first.baseUrl,
        );
        expect(
          tester
              .widget<TextField>(control('hermes-saved-edit-url'))
              .controller!
              .text,
          'https://draft.example.invalid',
        );
        store.fail = false;
        await activate(tester, 'hermes-saved-edit-save');
        expect(store.attempts, 2);
        expect(store.saveCalls.single.id, 'first');
        expect(
          (await store.loadProfiles()).last.baseUrl,
          predecessor.second.baseUrl,
        );
        expect(channel.connectCalls, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
