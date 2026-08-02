import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/security/wing_redaction.dart';

/// The Hermes channel, the chat surfaces, and the diagnostics export all route
/// through this one function. These cases are the union of what the three
/// hand-maintained copies used to cover individually, so a pattern lost here
/// can no longer leak from just one of them.
void main() {
  group('credentials', () {
    test('a bare bearer token is redacted', () {
      final safe = wingRedactSensitiveText('401 for Bearer abc123tokenvalue');
      expect(safe, isNot(contains('abc123tokenvalue')));
      expect(safe, contains('Bearer [redacted]'));
    });

    test('an authorization header keeps its name and loses its value', () {
      final safe = wingRedactSensitiveText(
        'Authorization: Bearer abc123tokenvalue',
      );
      expect(safe, isNot(contains('abc123tokenvalue')));
      expect(safe.toLowerCase(), contains('authorization'));
    });

    test('basic auth is redacted', () {
      expect(
        wingRedactSensitiveText('Basic dXNlcjpwYXNz'),
        isNot(contains('dXNlcjpwYXNz')),
      );
    });

    test('credential headers are redacted', () {
      final safe = wingRedactSensitiveText(
        'Cookie: sid=secretcookie; X-API-Key: keyvalue123',
      );
      expect(safe, isNot(contains('secretcookie')));
      expect(safe, isNot(contains('keyvalue123')));
    });

    test('key/value pairs keep the key and lose the value', () {
      final safe = wingRedactSensitiveText(
        'token=abc123value password: hunter2value',
      );
      expect(safe, isNot(contains('abc123value')));
      expect(safe, isNot(contains('hunter2value')));
      expect(safe, contains('token'));
    });

    test('url userinfo is redacted', () {
      expect(
        wingRedactSensitiveText('https://user:secretpass@example.test/path'),
        isNot(contains('secretpass')),
      );
    });

    test('provider token shapes are redacted', () {
      // Split so these fixtures never appear as contiguous token literals in
      // source, which secret scanners flag; the same convention as the channel
      // connection tests.
      final safe = wingRedactSensitiveText(
        'sk-1234567890abcdef '
        'ghp_'
        'abcdefghijklmnopqrstuvwxyz123456 '
        'xoxb-'
        '123456789012-abcdefabcdefabcdef '
        'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signaturevalue',
      );
      expect(safe, contains('sk-[redacted]'));
      expect(safe, contains('ghp_[redacted]'));
      expect(safe, contains('xox-[redacted]'));
      expect(safe, contains('[redacted-jwt]'));
    });
  });

  group('local paths, which are excluded data', () {
    test('a posix home path is redacted', () {
      expect(
        wingRedactSensitiveText('missing /home/operator/.hermes/config.yaml'),
        isNot(contains('/home/operator')),
      );
    });

    test('a windows drive path is redacted', () {
      expect(
        wingRedactSensitiveText(r'missing C:\Users\operator\hermes.yaml'),
        isNot(contains(r'C:\Users')),
      );
    });

    test('a unc path is redacted', () {
      expect(
        wingRedactSensitiveText(r'missing \\host\share\hermes.yaml'),
        isNot(contains(r'\\host')),
      );
    });
  });

  group('preview bounding', () {
    test('redacts before truncating, so no secret survives the cut', () {
      final safe = wingRedactedPreview(
        'Bearer abc123tokenvalue ${'padding ' * 40}',
        maxLength: 40,
      );
      expect(safe, isNot(contains('abc123tokenvalue')));
      expect(safe.length, lessThanOrEqualTo(41));
      expect(safe, endsWith('…'));
    });

    test('short text is returned without an ellipsis', () {
      expect(wingRedactedPreview('all clear', maxLength: 40), 'all clear');
    });
  });
}
