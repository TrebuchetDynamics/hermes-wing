import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_web_read_client.dart';
import 'package:wing/core/hermes/client/hermes_session_history_export.dart';

import '../support/fixture_server.dart';

Map<String, dynamic> page(int offset, int count) => {
  'profile': 'default',
  'session_id': 'resolved-tip',
  'messages': List.generate(
    count,
    (i) => <String, dynamic>{
      'id': offset + i,
      'session_id': i.isEven ? 'ancestor' : 'resolved-tip',
      'role': 'tool',
      'content': [
        {'text': '日本語 😀 <script>inert</script>'},
      ],
      'tool_calls': [
        {'id': 'call-${offset + i}'},
      ],
      'display_kind': 'hidden',
    },
  ),
  'pagination': {
    'limit': 500,
    'offset': offset,
    'order': 'oldest',
    'returned': count,
  },
};

void main() {
  test(
    'final UTF-8 cap includes multibyte title and wrapper, not just rows',
    () async {
      const limit = 4 * 1024 * 1024;
      final rows = List.generate(
        2500,
        (i) => <String, dynamic>{
          'id': i,
          'session_id': 'ancestor',
          'content': 'x' * 1600,
        },
      );
      final initial = utf8.encode(jsonEncode(rows)).length;
      rows.last['content'] =
          '${rows.last['content']}${'x' * (limit - 200 + 2 - initial)}';
      HermesSessionHistoryExportAttempt prepare(String? title) =>
          HermesSessionHistoryExportAttempt(
            sessionId: 'requested',
            title: title,
            isCurrent: () => true,
            readPage: (offset) async => HermesWebRawHistoryPage.fromJson(
              {
                'session_id': 'tip',
                'profile': 'default',
                'messages': rows.skip(offset).take(500).toList(),
                'pagination': {
                  'limit': 500,
                  'offset': offset,
                  'order': 'oldest',
                  'returned': offset == 2500 ? 0 : 500,
                },
              },
              'default',
              offset: offset,
            ),
          );
      final small = await prepare(null).collect();
      expect(utf8.encode(small).length, lessThanOrEqualTo(limit));
      final large = prepare('日' * 100);
      await expectLater(
        large.collect(),
        throwsA(
          isA<HermesWebReadException>().having(
            (e) => e.kind,
            'kind',
            HermesWebFailureKind.oversized,
          ),
        ),
      );
      expect(large.isCurrent, isFalse);
    },
  );

  for (final count in [0, 499, 500, 501, 1000]) {
    test(
      'raw $count rows include terminal page and exact private JSON wrapper',
      () async {
        final server = await bindHermesFixtureServer();
        final offsets = <int>[];
        server.listen((request) async {
          expect(request.method, 'GET');
          expect(
            request.headers.value('Authorization'),
            'Bearer synthetic-auth',
          );
          expect(request.uri.path, '/api/sessions/requested/messages');
          expect(request.uri.queryParameters, {
            'profile': 'default',
            'limit': '500',
            'offset': '${offsets.length * 500}',
            'order': 'oldest',
            'include_compacted': 'true',
          });
          final offset = int.parse(request.uri.queryParameters['offset']!);
          offsets.add(offset);
          request.response.write(
            jsonEncode(page(offset, (count - offset).clamp(0, 500))),
          );
          await request.response.close();
        });
        final client = HermesWebReadClient.forLocalReads(
          origin: Uri.parse('http://127.0.0.1:${server.port}'),
          credential: 'synthetic-auth',
          profile: 'default',
        );
        try {
          final attempt = client.beginHistoryExport(
            'requested',
            title: 'Captured 日本語',
            isCurrent: () => true,
          );
          final progress = <int>[];
          final json =
              jsonDecode(await attempt.collect(onProgress: progress.add))
                  as Map;
          expect(offsets, [for (var i = 0; i <= count ~/ 500; i++) i * 500]);
          expect(progress.last, count);
          expect(json.keys.toSet(), {
            'exported_at',
            'session_id',
            'title',
            'session',
            'message_count',
            'messages',
          });
          expect(DateTime.tryParse(json['exported_at'] as String), isNotNull);
          expect(json['session_id'], 'requested');
          expect(json['title'], 'Captured 日本語');
          expect(json['session'], isNull);
          expect(json['message_count'], count);
          final rows = json['messages'] as List;
          expect(rows, hasLength(count));
          if (count > 0) {
            expect(rows.first, (page(0, 1)['messages'] as List).first);
          }
        } finally {
          client.disconnect();
          await server.close(force: true);
        }
      },
    );
  }

  for (final defect in [
    'profile',
    'tip',
    'missing',
    'offset',
    'order',
    'limit',
    'returned',
    'nonInteger',
    'rowOwner',
    'rowId',
    'missingEnvelope',
    'duplicate',
    'auth',
    'redirect',
    'network',
    'responseLimit',
    'finalLimit',
    'cancel',
    'owner',
    'disconnect',
  ]) {
    test(
      '$defect discards paged attempt; explicit retry starts at zero',
      () async {
        final server = await bindHermesFixtureServer();
        var broken = true;
        var current = true;
        final offsets = <int>[];
        late HermesSessionHistoryExportAttempt attempt;
        late HermesWebReadClient client;
        server.listen((request) async {
          final offset = int.parse(request.uri.queryParameters['offset']!);
          offsets.add(offset);
          final json = page(offset, broken ? 500 : 0);
          if (broken && offset > 0) {
            final pagination = json['pagination'] as Map;
            switch (defect) {
              case 'profile':
                json['profile'] = 'other';
              case 'tip':
                json['session_id'] = 'other-tip';
              case 'missing':
                json.remove('pagination');
              case 'offset':
                pagination['offset'] = 0;
              case 'order':
                pagination['order'] = 'latest';
              case 'limit':
                pagination['limit'] = 499;
              case 'returned':
                pagination['returned'] = 0;
              case 'nonInteger':
                pagination['returned'] = 500.0;
              case 'rowOwner':
                (json['messages'] as List)[0]['session_id'] = null;
              case 'rowId':
                (json['messages'] as List)[0]['id'] = 'invalid';
              case 'missingEnvelope':
                json.remove('session_id');
              case 'duplicate':
                (json['messages'] as List)[0] =
                    (page(0, 1)['messages'] as List)[0];
              case 'auth':
                request.response.statusCode = 401;
              case 'redirect':
                request.response.statusCode = 302;
                request.response.headers.set('location', '/unexpected');
              case 'network':
                request.response.statusCode = 503;
              case 'responseLimit':
                json['extra'] = 'x' * (1 << 20);
              case 'finalLimit':
                for (final row in json['messages'] as List) {
                  row['content'] = '日' * 500;
                }
              case 'cancel':
                attempt.cancel();
              case 'owner':
                current = false;
              case 'disconnect':
                client.disconnect();
            }
          }
          request.response.write(jsonEncode(json));
          await request.response.close();
        });
        client = HermesWebReadClient.forLocalReads(
          origin: Uri.parse('http://127.0.0.1:${server.port}'),
          credential: 'synthetic-auth',
          profile: 'default',
        );
        try {
          attempt = client.beginHistoryExport(
            'requested',
            title: null,
            isCurrent: () => current,
          );
          final kind = switch (defect) {
            'profile' ||
            'tip' ||
            'offset' ||
            'order' ||
            'limit' ||
            'returned' => HermesWebFailureKind.identity,
            'auth' => HermesWebFailureKind.authentication,
            'redirect' => HermesWebFailureKind.redirect,
            'network' => HermesWebFailureKind.network,
            'responseLimit' || 'finalLimit' => HermesWebFailureKind.oversized,
            'cancel' || 'owner' || 'disconnect' => HermesWebFailureKind.stale,
            _ => HermesWebFailureKind.malformed,
          };
          await expectLater(
            attempt.collect(),
            throwsA(
              isA<HermesWebReadException>().having((e) => e.kind, 'kind', kind),
            ),
          );
          expect(attempt.isCurrent, isFalse);
          broken = false;
          current = true;
          if (defect != 'disconnect') {
            final retry = client.beginHistoryExport(
              'requested',
              title: null,
              isCurrent: () => current,
            );
            expect(
              (jsonDecode(await retry.collect()) as Map)['message_count'],
              0,
            );
            expect(offsets.last, 0);
          }
        } finally {
          client.disconnect();
          await server.close(force: true);
        }
      },
    );
  }
}
