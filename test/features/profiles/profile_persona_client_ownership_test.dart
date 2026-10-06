import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';

import 'profile_persona_ownership_test.dart' show app, personaCapabilityJson;

void main() {
  for (final fails in [false, true]) {
    testWidgets(
      'production client deferred old-host read $fails is fenced across reconnect',
      (tester) async {
        final pending = <Completer<String>>[];
        final requests = <(String, String, String?)>[];
        final channel = HermesApiChannel(
          clientBuilder: (config) => HermesApiClient(
            config: config,
            get: (uri, headers) async {
              requests.add((
                uri.host,
                uri.path,
                uri.queryParameters['profile'],
              ));
              if (uri.path == '/api/profiles/coder/soul') {
                final gate = Completer<String>();
                pending.add(gate);
                return gate.future;
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
            put: (_, _, _) => throw StateError('No write permitted'),
          ),
        );
        addTearDown(channel.dispose);
        await channel.connect(baseUrl: 'http://localhost:8642');
        await channel.selectProfile('coder');
        await tester.pumpWidget(app(channel));
        await tester.pump();
        expect(pending, hasLength(1));
        // Production connect emits an unavailable state synchronously and captures
        // its own client. The old read may still resolve; UI admission owns fencing.
        await channel.connect(baseUrl: 'http://127.0.0.1:8643');
        await channel.selectProfile('coder');
        await tester.pump();
        await tester.pump();
        expect(pending, hasLength(2));
        pending[1].complete('{"soul":"B authoritative","revision":"B-r1"}');
        await tester.pumpAndSettle();
        if (fails) {
          pending[0].completeError(StateError('synthetic private response'));
        } else {
          pending[0].complete('{"soul":"A stale","revision":"A-r1"}');
        }
        await tester.pumpAndSettle();
        expect(find.text('B authoritative'), findsOneWidget);
        expect(find.text('A stale'), findsNothing);
        expect(find.textContaining('could not complete'), findsNothing);
        expect(requests.where((r) => r.$2.endsWith('/soul')).toList(), [
          ('localhost', '/api/profiles/coder/soul', 'coder'),
          ('127.0.0.1', '/api/profiles/coder/soul', 'coder'),
        ]);
      },
    );
  }
  testWidgets(
    'production write captures exact profile payload and revision while reconnecting',
    (tester) async {
      final writeGate = Completer<String>();
      final puts = <Map<String, Object?>>[];
      var connection = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) {
          final owner = ++connection;
          return HermesApiClient(
            config: config,
            get: (uri, headers) async => switch (uri.path) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => jsonEncode(personaCapabilityJson()),
              '/api/profiles' =>
                '{"data":[{"id":"coder","name":"Coder","revision":"p1"}]}',
              '/api/sessions' => '{"data":[]}',
              '/api/profiles/coder/soul' => jsonEncode({
                'soul': 'Owner $owner',
                'revision': 'r$owner',
              }),
              _ => throw StateError('Unexpected deterministic read'),
            },
            put: (uri, headers, body) {
              puts.add({
                'owner': owner,
                'path': uri.path,
                'profile': uri.queryParameters['profile'],
                'revision': headers['If-Match'],
                'body': jsonDecode(body),
              });
              return writeGate.future;
            },
          );
        },
      );
      addTearDown(channel.dispose);
      await channel.connect(baseUrl: 'http://localhost:8642');
      await channel.selectProfile('coder');
      await tester.pumpWidget(app(channel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Inert A draft');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await channel.connect(baseUrl: 'http://127.0.0.1:8643');
      await channel.selectProfile('coder');
      await tester.pumpAndSettle();
      writeGate.complete('{"soul":"Inert A draft","revision":"saved-A"}');
      await tester.pumpAndSettle();
      expect(find.text('Owner 2'), findsOneWidget);
      expect(puts, [
        {
          'owner': 1,
          'path': '/api/profiles/coder/soul',
          'profile': 'coder',
          'revision': 'r1',
          'body': {'soul': 'Inert A draft'},
        },
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}
