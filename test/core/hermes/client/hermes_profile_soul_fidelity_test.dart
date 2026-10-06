import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/hermes_api.dart';
import 'package:wing/core/protocol/wing_json.dart';

const documents = {
  'spaces and tabs': ' \t  Inert document.  \t ',
  'blank lines': '\n\nInert document.\n\n',
  'whitespace only': ' \t\n\n\t ',
  'empty': '',
  'Unicode': '\n  café 東京 🪽 e\u0301\n\t ',
  'CRLF': '\r\n\t Inert\r\n  document. \r\n\r\n',
};

const malformedDocuments = <String, Map<String, Object?>>{
  'missing': {},
  'null': {'soul': null},
  'number': {'soul': 42},
  'bool': {'soul': false},
  'map': {
    'soul': {'text': 'not a document'},
  },
  'list': {
    'soul': ['not a document'],
  },
  'dashboard schema': {'content': '', 'exists': true},
};

void main() {
  for (final entry in documents.entries) {
    test('SOUL model preserves literal ${entry.key}', () {
      final decoded = HermesProfileSoul.fromJson({
        'soul': entry.value,
        'revision': ' r1 ',
      });
      expect(decoded.soul, entry.value);
      expect(utf8.encode(decoded.soul), utf8.encode(entry.value));
      expect(decoded.revision, 'r1');
    });
    test(
      'SOUL client GET and PUT acknowledgement preserve ${entry.key}',
      () async {
        final client = HermesApiClient(
          config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
          get: (uri, _) async {
            expect(uri.path, '/api/profiles/coder/soul');
            expect(uri.queryParameters, {'profile': 'coder'});
            return jsonEncode({'soul': entry.value, 'revision': 'r1'});
          },
          put: (uri, headers, body) async {
            expect(uri.path, '/api/profiles/coder/soul');
            expect(uri.queryParameters, {'profile': 'coder'});
            expect(headers['If-Match'], 'r1');
            expect(body, jsonEncode({'soul': entry.value}));
            // Acknowledged content must come from the response, not a local echo.
            return jsonEncode({
              'soul': '\n${entry.value}\t ',
              'revision': 'r2',
            });
          },
        );
        final read = await client.readProfileSoul('coder');
        expect(read.soul, entry.value);
        final saved = await client.writeProfileSoul(
          profileId: 'coder',
          soul: entry.value,
          revision: read.revision,
        );
        expect(saved.soul, '\n${entry.value}\t ');
        expect(utf8.encode(saved.soul), utf8.encode('\n${entry.value}\t '));
        expect(saved.revision, 'r2');
      },
    );
  }
  for (final entry in malformedDocuments.entries) {
    test('SOUL model rejects ${entry.key} without content in error', () {
      expect(
        () => HermesProfileSoul.fromJson({...entry.value, 'revision': 'r1'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.toString(),
            'safe error',
            'FormatException: Invalid persona document.',
          ),
        ),
      );
    });
    test(
      'SOUL client rejects malformed ${entry.key} GET and successful PUT',
      () async {
        final response = jsonEncode({...entry.value, 'revision': 'r1'});
        final client = HermesApiClient(
          config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
          get: (_, _) async => response,
          put: (_, _, _) async => response,
        );
        await expectLater(
          client.readProfileSoul('coder'),
          throwsFormatException,
        );
        await expectLater(
          client.writeProfileSoul(
            profileId: 'coder',
            soul: 'Explicit inert draft',
            revision: 'r1',
          ),
          throwsFormatException,
        );
      },
    );
  }
  test(
    'content fix leaves metadata coercion and missing revision unchanged',
    () {
      expect(wingStringFromJson(' \t name \n ', fallback: ''), 'name');
      expect(wingStringFromJson(42, fallback: ''), '42');
      expect(
        HermesProfile.fromJson({'id': ' coder ', 'revision': ' p1 '}).id,
        'coder',
      );
      expect(HermesProfileSoul.fromJson({'soul': ''}).revision, '');
      expect(
        HermesProfileSoul.fromJson({'soul': '', 'revision': ' \t '}).revision,
        '',
      );
    },
  );
}
