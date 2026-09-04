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

    test('Wing pairing codes use exact fields and preserve punctuation', () {
      final firstCode = ['first', 'synthetic', 'marker'].join('-');
      final secondCode = ['second', 'synthetic', 'marker'].join('-');
      final safe = wingRedactSensitiveText(
        '(WING://CONNECT?code=$firstCode'
        '&promo-code=E42&note=x.code=E42&%63ode=$secondCode), continue',
      );

      expect(safe, isNot(contains(firstCode)));
      expect(safe, isNot(contains(secondCode)));
      expect(
        safe,
        '(WING://CONNECT?code=[redacted]'
        '&promo-code=E42&note=x.code=E42&%63ode=[redacted]), continue',
      );
      expect(
        wingRedactSensitiveText(
          'wing://connect?code=$firstCode.'
          'wing://connect?origin=local&code=$secondCode; continue',
        ),
        'wing://connect?code=[redacted].'
        'wing://connect?origin=local&code=[redacted]; continue',
      );
      expect(
        wingRedactSensitiveText(
          'wing://connect?origin=https://hermes.example&code=$firstCode',
        ),
        'wing://connect?origin=https://hermes.example&code=[redacted]',
      );
      expect(
        wingRedactSensitiveText(
          'wing://connect?note=alpha:beta&code=$secondCode',
        ),
        'wing://connect?note=alpha:beta&code=[redacted]',
      );
      for (final unrelated in [
        'https://example.test/status?code=E42',
        'swing://connect?code=E42',
        'notwing://connect?code=E43',
        'x-wing://connect?code=E44',
        'x.wing://connect?code=E45',
      ]) {
        expect(wingRedactSensitiveText(unrelated), unrelated);
      }

      final adjacentCode = ['real', 'adjacent', 'marker'].join('-');
      for (final prefix in [
        'x.wing://connect?code=E47.',
        'swing://connect?code=E48.',
        'wing://connect?code=%ZZ.',
        'wing://connect?code=.',
      ]) {
        final safeAdjacent = wingRedactSensitiveText(
          '$prefix'
          'wing://connect?code=$adjacentCode',
        );
        expect(safeAdjacent, isNot(contains(adjacentCode)));
        expect(safeAdjacent, contains('wing://connect?code=[redacted]'));
      }
      for (final suffix in [
        'x.wing://connect?code=E49',
        'swing://connect?code=E50',
      ]) {
        expect(
          wingRedactSensitiveText('wing://connect?code=$adjacentCode.$suffix'),
          'wing://connect?code=[redacted].$suffix',
        );
      }
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

  group('leaked tool payloads', () {
    test('replaces a leaked tool wrapper without exposing its body', () {
      final safe = wingRedactSensitiveText(
        'Before <some_tool>{"command":"cat /home/operator/key",'
        '"token":"abc123value"}</some_tool> after',
      );

      expect(safe, 'Before [tool activity hidden] after');
    });

    test('fails closed while a leaked tool wrapper is still streaming', () {
      final safe = wingRedactSensitiveText(
        'Before <some_tool>{"command":"unfinished',
      );

      expect(safe, 'Before [tool activity hidden]');
    });
  });

  group('host media delivery tokens', () {
    test('replaces an explicit MEDIA token without exposing its source', () {
      final safe = wingRedactSensitiveText(
        'Here it is:\nMEDIA:"/home/operator/My Preview.png"\nDone.',
      );

      expect(safe, 'Here it is:\n[media not delivered]\nDone.');
    });

    test('recognizes cross-platform host audio paths outside code', () {
      expect(
        wingContainsHostAudioReference(
          r'Audio created at C:\Users\operator\voice reply.wav.',
        ),
        isTrue,
      );
      expect(
        wingContainsHostAudioReference(
          r'Audio created at \\host\share\voice reply.mp3.',
        ),
        isTrue,
      );
      expect(
        wingContainsHostAudioReference('Audio created at ~/voice/reply.ogg.'),
        isTrue,
      );
      expect(
        wingContainsHostAudioReference(
          'Audio created at /srv/hermes/reply.mp3.',
        ),
        isTrue,
      );
      expect(
        wingContainsHostAudioReference(
          'Example:\n```text\n/tmp/example.wav\n```',
        ),
        isFalse,
      );
      expect(
        wingContainsHostAudioReference(
          'Listen at https://example.test/etc/reply.mp3',
        ),
        isFalse,
      );
      expect(
        wingContainsHostAudioReference('Audio at file:///tmp/reply.mp3'),
        isTrue,
      );
      expect(wingContainsHostAudioReference('/tmp/report.pdf'), isFalse);
    });

    test('recognizes only labelled absolute artifact paths', () {
      expect(
        wingContainsHostArtifactReference(
          'Done.\nSaved to: `/tmp/final report.pdf`',
        ),
        isTrue,
      );
      expect(
        wingContainsHostArtifactReference(
          'Done.\nSaved to: `~/reports/final.pdf`',
        ),
        isTrue,
      );
      expect(
        wingContainsHostArtifactReference(
          'Done.\nSaved to: `/opt/hermes/final.pdf`',
        ),
        isTrue,
      );
      expect(
        wingContainsHostArtifactReference(
          'File: https://example.test/etc/report.pdf',
        ),
        isFalse,
      );
      expect(
        wingContainsHostArtifactReference('File: file:///etc/report.pdf'),
        isTrue,
      );
      expect(
        wingContainsHostArtifactReference('Output: relative/report.pdf'),
        isFalse,
      );
      expect(
        wingContainsHostArtifactReference('Run `/tmp/report.pdf` to inspect.'),
        isFalse,
      );
      expect(
        wingContainsHostArtifactReference(
          'Example:\n```text\nFile: `/tmp/report.pdf`\n```',
        ),
        isFalse,
      );
    });
  });

  group('local paths, which are excluded data', () {
    test('ordinary HTTPS paths are preserved', () {
      const text =
          'Docs: https://example.test/etc/setup and '
          'https://example.test/home/start';

      expect(wingRedactSensitiveText(text), text);
    });

    test('file URLs remain fail-closed local paths', () {
      expect(
        wingRedactSensitiveText('created file:///etc/hermes/config.toml'),
        'created [redacted-path]',
      );
    });

    test('a posix home path is redacted', () {
      expect(
        wingRedactSensitiveText('missing /home/operator/.hermes/config.yaml'),
        isNot(contains('/home/operator')),
      );
    });

    test('common system-root paths are redacted', () {
      for (final path in [
        '/root/.hermes/config.yaml',
        '/opt/hermes/output.json',
        '/srv/hermes/report.pdf',
        '/etc/hermes/config.toml',
      ]) {
        expect(
          wingRedactSensitiveText('missing $path'),
          'missing [redacted-path]',
          reason: path,
        );
      }
    });

    test('a tilde home path is redacted', () {
      expect(
        wingRedactSensitiveText('missing ~/.hermes/config.yaml'),
        isNot(contains('~/.hermes')),
      );
    });

    test('a temporary tool artifact path is redacted', () {
      expect(
        wingRedactSensitiveText('created /tmp/sidon_audio_reply.wav'),
        isNot(contains('/tmp/sidon_audio_reply.wav')),
      );
    });

    test('quoted host paths with spaces are fully redacted', () {
      expect(
        wingRedactSensitiveText('missing "/home/John Doe/private/config.yaml"'),
        'missing [redacted-path]',
      );
      expect(
        wingRedactSensitiveText(r'File: `C:\Users\Jane Doe\report.pdf`'),
        'File: [redacted-path]',
      );
    });

    test('a windows drive path is redacted', () {
      expect(
        wingRedactSensitiveText(r'missing C:\Users\operator\hermes.yaml'),
        isNot(contains(r'C:\Users')),
      );
    });

    test('a windows drive path with forward slashes is redacted', () {
      expect(
        wingRedactSensitiveText('missing C:/Users/operator/hermes.yaml'),
        'missing [redacted-path]',
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
