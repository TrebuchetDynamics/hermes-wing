import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';

import '../../core/hermes/client/hermes_profile_soul_fidelity_test.dart'
    show documents, malformedDocuments;
import 'profile_persona_ownership_test.dart'
    show app, personaCapabilityJson, Conflict;

final field = find.byType(TextFormField).last;
final save = find.widgetWithText(FilledButton, 'Save');
String text(WidgetTester tester) =>
    tester.widget<TextFormField>(field).controller!.text;

class Fixture {
  Fixture(this.document);
  String document;
  String revision = 'r1';
  Map<String, Object?> malformedResponse = const {};
  bool malformed = false;
  bool conflict = false;
  bool malformedAcknowledgement = false;
  final writes = <Map<String, Object?>>[];
  int reads = 0;
  late final channel = HermesApiChannel(
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, _) async {
        if (uri.path == '/api/profiles/coder/soul') {
          expect(uri.queryParameters['profile'], 'coder');
          reads++;
          return jsonEncode({
            if (malformed) ...malformedResponse else 'soul': document,
            'revision': revision,
          });
        }
        return switch (uri.path) {
          '/health' => '{"status":"ok"}',
          '/v1/capabilities' => jsonEncode(personaCapabilityJson()),
          '/api/profiles' =>
            '{"data":[{"id":"coder","name":"Coder","revision":"p1"}]}',
          '/api/sessions' => '{"data":[]}',
          _ => throw StateError('Unexpected deterministic read'),
        };
      },
      put: (uri, headers, body) async {
        expect(uri.path, '/api/profiles/coder/soul');
        expect(uri.queryParameters['profile'], 'coder');
        expect(headers['If-Match'], revision);
        writes.add({'body': jsonDecode(body), 'revision': headers['If-Match']});
        if (conflict) {
          conflict = false;
          document = '\r\n\t Newer café 東京. \r\n\r\n';
          revision = 'r2';
          throw Conflict();
        }
        document =
            (jsonDecode(body) as Map<String, Object?>)['soul']! as String;
        revision = revision == 'r2' ? 'r3' : 'r2';
        return jsonEncode({
          'soul': malformedAcknowledgement ? 42 : document,
          'revision': revision,
        });
      },
    ),
  );
  Future<void> open(WidgetTester tester) async {
    await channel.connect(baseUrl: 'http://localhost:8642');
    await channel.selectProfile('coder');
    await tester.pumpWidget(app(channel));
    await tester.pumpAndSettle();
  }

  Future<void> reload(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(channel));
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final revision in ['', ' \t\n ']) {
    testWidgets(
      'literal document still requires nonblank revision ${jsonEncode(revision)}',
      (tester) async {
        final f = Fixture('\n\t Inert padded document. \n')
          ..revision = revision;
        addTearDown(f.channel.dispose);
        await f.open(tester);
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        expect(
          find.text('Hermes could not complete that profile change.'),
          findsOneWidget,
        );
        expect(f.writes, isEmpty);
      },
    );
  }
  for (final entry in documents.entries) {
    testWidgets(
      'production editor loads exact ${entry.key} with no-edit save making zero writes',
      (tester) async {
        final f = Fixture(entry.value);
        addTearDown(f.channel.dispose);
        await f.open(tester);
        expect(text(tester), entry.value);
        expect(f.writes, isEmpty);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(f.writes, isEmpty);
        expect(text(tester), entry.value);
      },
    );
    testWidgets(
      'production editor explicit ${entry.key} save and reload preserve exact content',
      (tester) async {
        final f = Fixture('\n\t Inert original. \n\n');
        addTearDown(f.channel.dispose);
        await f.open(tester);
        await tester.enterText(field, entry.value);
        expect(f.writes, isEmpty);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(f.writes, [
          {
            'body': {'soul': entry.value},
            'revision': 'r1',
          },
        ]);
        expect(f.document, entry.value);
        expect(utf8.encode(f.document), utf8.encode(entry.value));
        await f.reload(tester);
        expect(text(tester), entry.value);
        expect(f.reads, 2);
        expect(f.writes, hasLength(1));
      },
    );
  }
  testWidgets(
    'padded conflict reread and explicit retry capture exact newer revision',
    (tester) async {
      final f = Fixture('\n Initial. \n')..conflict = true;
      addTearDown(f.channel.dispose);
      await f.open(tester);
      const draft = '\n\t café 東京 🪽\n  explicit draft. \n\n';
      await tester.enterText(field, draft);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(text(tester), '\r\n\t Newer café 東京. \r\n\r\n');
      expect(f.writes, hasLength(1));
      expect(f.reads, 2);
      expect(find.textContaining('changed elsewhere'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(f.writes, hasLength(1));
      await tester.enterText(field, draft);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(f.writes, [
        {
          'body': {'soul': draft},
          'revision': 'r1',
        },
        {
          'body': {'soul': draft},
          'revision': 'r2',
        },
      ]);
      await f.reload(tester);
      expect(text(tester), draft);
      expect(f.revision, 'r3');
    },
  );
  for (final entry in malformedDocuments.entries) {
    testWidgets(
      'malformed ${entry.key} read cannot admit a fabricated empty editor',
      (tester) async {
        final f = Fixture('inert')
          ..malformed = true
          ..malformedResponse = entry.value;
        addTearDown(f.channel.dispose);
        await f.open(tester);
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        expect(
          find.text('Hermes could not complete that profile change.'),
          findsOneWidget,
        );
        expect(f.writes, isEmpty);
        f.malformed = false;
        f.document = '';
        await tester.tap(find.widgetWithText(TextButton, 'Retry'));
        await tester.pumpAndSettle();
        expect(text(tester), '');
        expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
        expect(f.writes, isEmpty);
      },
    );
  }
  testWidgets(
    'malformed successful acknowledgement surfaces failure without mutation replay',
    (tester) async {
      final f = Fixture('inert')..malformedAcknowledgement = true;
      addTearDown(f.channel.dispose);
      await f.open(tester);
      const draft = '\n Explicit padded draft. \t\n';
      await tester.enterText(field, draft);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.text('Hermes could not complete that profile change.'),
        findsOneWidget,
      );
      expect(text(tester), draft);
      expect(f.writes, hasLength(1));
      expect(f.reads, 1);
      await f.reload(tester);
      expect(text(tester), draft);
      expect(f.writes, hasLength(1));
    },
  );
}
