import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/hermes_api.dart';

Map<String, Object?> _page(String session, List<String> owners) => {
  'object': 'list',
  'session_id': session,
  'data': [
    for (var i = 0; i < owners.length; i++)
      {
        'id': 'message_$i',
        'session_id': owners[i],
        'role': 'assistant',
        'content': 'Synthetic history',
      },
  ],
};

HermesApiClient _client(
  Map<String, Object?> page, {
  Map<String, Map<String, Object?>> metadata = const {},
  Map<String, String> resolutions = const {},
  bool granted = true,
  List<Uri>? reads,
  String requestedId = 'tip',
}) => HermesApiClient(
  config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
  get: (uri, headers) async {
    reads?.add(uri);
    if (uri.path == '/v1/capabilities') {
      return jsonEncode({
        'object': 'hermes.api_server.capabilities',
        'schema_version': 1,
        'profile_context': {
          'type': 'query',
          'name': 'profile',
          'required': true,
          'default_profile_id': 'default',
        },
        'auth': {
          'type': 'bearer',
          'required': true,
          'granted_scopes': <String>[],
        },
        'endpoints': {
          'session': {
            'method': 'GET',
            'path': '/api/sessions/{session_id}',
            if (!granted) 'required_scopes': ['metadata:read'],
          },
          'session_messages': {
            'method': 'GET',
            'path': '/api/sessions/{session_id}/messages',
          },
        },
      });
    }
    final id = uri.pathSegments[2];
    if (uri.path.endsWith('/messages')) {
      if (id == requestedId && uri.queryParameters['limit'] == '500') {
        return jsonEncode(page);
      }
      return jsonEncode(_page(resolutions[id] ?? id, const []));
    }
    return jsonEncode({
      'object': 'hermes.session',
      'session': {'id': id, ...?metadata[id]},
    });
  },
);

void main() {
  test(
    'old requested handle accepts only verified resolved compression tip',
    () async {
      final page = await _client(
        _page('tip', ['root', 'tip']),
        requestedId: 'root',
        metadata: {
          'tip': {'parent_session_id': 'root'},
          'root': {'end_reason': 'compression'},
        },
        resolutions: {'root': 'tip'},
      ).sessionMessagesPage('root');
      expect(page.sessionId, 'tip');
      expect(page.messages.map((row) => row.sessionId), ['root', 'tip']);
    },
  );

  for (final parent in <Object>[' root ', 1, '', 'root\n']) {
    test(
      'malformed parent cannot be normalized into lineage: $parent',
      () async {
        await expectLater(
          _client(
            _page('tip', ['root']),
            metadata: {
              'tip': {'parent_session_id': parent},
              'root': {'end_reason': 'compression'},
            },
            resolutions: {'root': 'tip'},
          ).sessionMessagesPage('tip'),
          throwsA(isA<FormatException>()),
        );
      },
    );
  }

  test('exact envelope and rows retain baseline pagination', () async {
    final reads = <Uri>[];
    final page = await _client(
      _page('tip', ['tip']),
      reads: reads,
    ).sessionMessagesPage('tip');
    expect(page.messages.single.sessionId, 'tip');
    expect(page.nextOffset, 1);
    expect(page.hasMore, isFalse);
    expect(reads, hasLength(1));
  });

  for (final entry in <String, Map<String, Object?>>{
    'foreign envelope with exact rows': _page('foreign', ['tip']),
    'foreign rows with exact envelope': _page('tip', ['foreign']),
    'empty foreign envelope': _page('foreign', []),
    'missing envelope': {
      ..._page('tip', ['tip']),
    }..remove('session_id'),
    'numeric envelope': {
      ..._page('tip', ['tip']),
      'session_id': 1,
    },
    'missing row owner': {
      ..._page('tip', []),
      'data': [
        {'id': 'message', 'role': 'assistant', 'content': 'Synthetic'},
      ],
    },
    'non-map row': {
      ..._page('tip', []),
      'data': [null],
    },
    'wrong list object': {..._page('tip', []), 'object': 'unrelated'},
    'malformed rows': {..._page('tip', []), 'data': {}},
    'oversized page including foreign tail': _page('tip', [
      ...List.filled(500, 'tip'),
      'foreign',
    ]),
    'untrusted lineage claim': {
      ..._page('tip', ['foreign']),
      '_lineage_ids': ['foreign', 'tip'],
    },
  }.entries) {
    test('rejects ${entry.key}', () async {
      await expectLater(
        _client(entry.value).sessionMessagesPage('tip'),
        throwsA(isA<FormatException>()),
      );
    });
  }

  test('accepts verified multi-hop compression ancestors', () async {
    final reads = <Uri>[];
    final page = await _client(
      _page('tip', ['root', 'middle', 'tip']),
      metadata: {
        'tip': {'parent_session_id': 'middle'},
        'middle': {'parent_session_id': 'root', 'end_reason': 'compression'},
        'root': {'end_reason': 'compression'},
      },
      resolutions: {'middle': 'tip', 'root': 'tip'},
      reads: reads,
    ).sessionMessagesPage('tip');
    expect(page.messages.map((row) => row.sessionId), [
      'root',
      'middle',
      'tip',
    ]);
    expect(
      reads.where(
        (uri) =>
            uri.path.endsWith('/messages') &&
            uri.queryParameters['limit'] == '1',
      ),
      hasLength(2),
    );
  });

  test(
    'branch with compression-ended parent is not an ancestor grant',
    () async {
      await expectLater(
        _client(
          _page('tip', ['root']),
          metadata: {
            'tip': {'parent_session_id': 'root'},
            'root': {'end_reason': 'compression'},
          },
          resolutions: {'root': 'other_tip'},
        ).sessionMessagesPage('tip'),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('non-compression parent cannot grant history', () async {
    await expectLater(
      _client(
        _page('tip', ['root']),
        metadata: {
          'tip': {'parent_session_id': 'root'},
          'root': {'end_reason': 'branched'},
        },
        resolutions: {'root': 'tip'},
      ).sessionMessagesPage('tip'),
      throwsA(isA<FormatException>()),
    );
  });

  test('lineage lookup respects metadata grants', () async {
    final reads = <Uri>[];
    await expectLater(
      _client(
        _page('tip', ['root']),
        granted: false,
        reads: reads,
      ).sessionMessagesPage('tip'),
      throwsA(isA<FormatException>()),
    );
    expect(
      reads.where(
        (uri) =>
            !uri.path.endsWith('/messages') && uri.path != '/v1/capabilities',
      ),
      isEmpty,
    );
  });

  test(
    'all lineage evidence remains on the requested origin and profile',
    () async {
      final reads = <Uri>[];
      await _client(
        _page('tip', ['root']),
        metadata: {
          'tip': {'parent_session_id': 'root'},
          'root': {'end_reason': 'compression'},
        },
        resolutions: {'root': 'tip'},
        reads: reads,
      ).sessionMessagesPage('tip', profile: 'synthetic-profile');
      expect(
        reads.map((uri) => uri.origin),
        everyElement('http://127.0.0.1:8642'),
      );
      expect(
        reads
            .where((uri) => uri.path != '/v1/capabilities')
            .map((uri) => uri.queryParameters['profile']),
        everyElement('synthetic-profile'),
      );
    },
  );

  test('replacement metadata identity cannot prove lineage', () async {
    await expectLater(
      _client(
        _page('tip', ['root']),
        metadata: {
          'tip': {'id': 'replacement', 'parent_session_id': 'root'},
          'root': {'end_reason': 'compression'},
        },
        resolutions: {'root': 'tip'},
      ).sessionMessagesPage('tip'),
      throwsA(isA<FormatException>()),
    );
  });

  test('cyclic lineage fails closed', () async {
    await expectLater(
      _client(
        _page('tip', ['foreign']),
        metadata: {
          'tip': {'parent_session_id': 'middle', 'end_reason': 'compression'},
          'middle': {'parent_session_id': 'tip', 'end_reason': 'compression'},
        },
        resolutions: {'middle': 'tip'},
      ).sessionMessagesPage('tip'),
      throwsA(isA<FormatException>()),
    );
  });
}
