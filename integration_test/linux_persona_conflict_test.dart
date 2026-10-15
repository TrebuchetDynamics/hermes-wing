import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/profiles/widgets/profile_editor_sheet.dart';

import '../test/features/profiles/profile_persona_ownership_test.dart'
    show Conflict;
import '../test/features/soul/persona_route_completion_test.dart'
    show PersonaRouteFixture;

// Traverse the rendered control, never its callback or FocusNode.
Future<void> focusControl(WidgetTester tester, Finder control) async {
  final target = tester.element(control);
  bool focused() {
    var found = false;
    FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
      element,
    ) {
      if (element == target) found = true;
      return !found;
    });
    return found;
  }

  for (var i = 0; i < 60 && !focused(); i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
  expect(focused(), isTrue, reason: 'Control must be reachable by Tab');
}

Future<void> activate(WidgetTester tester, Finder control) async {
  await focusControl(tester, control);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  // A pending save animates until completion; settling here would time it out.
  await tester.pump();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final rows = <Map<String, Object?>>[];
  for (final width in [390.0, 1280.0]) {
    for (final modal in [false, true]) {
      testWidgets('native Persona recovery $width modal=$modal / 200%', (
        tester,
      ) async {
        final root = Platform.environment['WING_LOCAL_ROOT'];
        if (!Platform.isLinux ||
            root == null ||
            Platform.environment['HOME'] != '$root/home' ||
            Platform.environment['XDG_CONFIG_HOME'] != '$root/config' ||
            Platform.environment['XDG_DATA_HOME'] != '$root/data' ||
            Platform.environment['XDG_CACHE_HOME'] != '$root/cache' ||
            Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null) {
          throw StateError('Use the isolated Persona runner.');
        }
        await binding.setSurfaceSize(Size(width, 1400));
        final f = PersonaRouteFixture();
        await f.open(tester, width, configureView: false);
        final field = find.byType(TextFormField).last;
        final save = find.widgetWithText(FilledButton, 'Save');
        Future<void> enter(String text) async {
          await focusControl(tester, field);
          await tester.enterText(field, text);
          expect(f.text(tester), text);
        }

        Future<void> openModal() async {
          f.router.go('/profiles');
          await tester.pumpAndSettle();
          await activate(tester, find.widgetWithText(OutlinedButton, 'Edit'));
          await tester.pumpAndSettle();
          expect(find.byType(ProfileEditorSheet), findsOneWidget);
        }

        if (modal) await openModal();
        const draft = 'Synthetic local draft café.';
        const newer = 'Synthetic authoritative newer text.';
        await enter(draft);
        f.writeGate = Completer<String>();
        await activate(tester, save);
        expect(f.writes, hasLength(1));
        f.writeGate!.completeError(StateError('synthetic private failure'));
        await tester.pumpAndSettle();
        expect(f.text(tester), draft);
        expect(find.textContaining('could not complete'), findsOneWidget);
        expect(find.textContaining('synthetic private'), findsNothing);
        expect(f.writes, hasLength(1));

        f.writeGate = Completer<String>();
        await activate(tester, save);
        expect(f.writes, hasLength(2));
        f.document = newer;
        f.revision = 'r2';
        f.writeGate!.completeError(Conflict());
        await tester.pumpAndSettle();
        expect(f.text(tester), newer);
        expect(find.textContaining('changed elsewhere'), findsOneWidget);
        expect(f.writes, hasLength(2));
        await tester.pump(const Duration(seconds: 1));
        expect(f.writes, hasLength(2));
        await enter(draft);
        f.writeGate = null;
        await activate(tester, save);
        await tester.pumpAndSettle();
        f.expectProfiles();
        expect(f.writes.map((w) => w['revision']), ['r1', 'r1', 'r2']);
        expect(f.document, draft);

        if (modal) {
          await openModal();
        } else {
          await f.reopen(tester);
        }
        await enter('Old owner draft');
        f.writeGate = Completer<String>();
        await activate(tester, save);
        expect(f.writes, hasLength(4));
        await f.channel.connect(baseUrl: 'http://127.0.0.1:8643');
        await f.channel.selectProfile('coder');
        await tester.pumpAndSettle();
        // The old modal keeps its invalid admission; dismiss and deliberately reopen.
        if (modal) {
          await activate(tester, find.widgetWithText(TextButton, 'Cancel'));
          await tester.pumpAndSettle();
          await openModal();
        }
        await enter('Replacement owner draft');
        final reads = f.reads.length;
        f.writeGate!.completeError(Conflict());
        await tester.pumpAndSettle();
        expect(f.text(tester), 'Replacement owner draft');
        expect(f.reads, hasLength(reads));
        expect(f.writes, hasLength(4));
        expect(f.writes.map((w) => w['revision']), ['r1', 'r1', 'r2', 'r3']);
        expect(f.writes.last['origin'], 'http://localhost:8642');
        expect(find.textContaining('changed elsewhere'), findsNothing);
        expect(find.textContaining('could not complete'), findsNothing);
        expect(tester.takeException(), isNull);
        rows.add({
          'width': width,
          'modal': modal,
          'text_scale': 2,
          'ordinary_failure_retains_draft': true,
          'conflict_loads_authoritative_text': true,
          'revisions': ['r1', 'r1', 'r2', 'r3'],
          'writes': f.writes.length,
          'stale_completion_rejected': true,
          'automatic_replays': 0,
        });
        if (rows.length == 4) {
          File('$root/cache/persona-conflict.json').writeAsStringSync(
            jsonEncode({'native_pid': pid, 'journeys': rows}),
          );
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 500)),
          );
        }
      });
    }
  }
}
