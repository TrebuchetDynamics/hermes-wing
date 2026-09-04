import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_health.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/diagnostics/hermes_diagnostics_export.dart';

/// Runs [text] through the export by way of a session title, which is the
/// shortest operator-controlled path into the diagnostics document.
String exportWithTitle(String text) => hermesDiagnosticsExport(
  HermesChannelState(
    status: HermesConnectionStatus.connected,
    sessions: [HermesSession(id: 's1', source: 'api', title: text)],
    activeSessionId: 's1',
  ),
);

/// Runs [values] through the model inventory, a second redacted path.
String exportWithModels(List<String> values) => hermesDiagnosticsExport(
  HermesChannelState(status: HermesConnectionStatus.connected, models: values),
);

void main() {
  group('credential headers', () {
    test('a bearer token is redacted', () {
      final out = exportWithTitle('Bearer abc123tokenvalue');
      expect(out, isNot(contains('abc123tokenvalue')));
      expect(out, contains('Bearer [redacted]'));
    });

    test('bearer redaction ignores case', () {
      expect(
        exportWithTitle('bEaReR abc123tokenvalue'),
        isNot(contains('abc123tokenvalue')),
      );
    });

    test('an authorization header value is redacted', () {
      expect(
        exportWithTitle('Authorization: abc123tokenvalue'),
        isNot(contains('abc123tokenvalue')),
      );
    });

    test('basic auth is redacted', () {
      expect(
        exportWithTitle('Authorization: Basic dXNlcjpwYXNz'),
        isNot(contains('dXNlcjpwYXNz')),
      );
    });

    test('a bare Basic credential is redacted without a header name', () {
      final out = exportWithTitle('Basic dXNlcjpwYXNz');
      expect(out, isNot(contains('dXNlcjpwYXNz')));
      expect(out, contains('Basic [redacted]'));
    });

    test('cookie and api-key headers are redacted', () {
      for (final header in [
        'Cookie: session=abc123tokenvalue',
        'Set-Cookie: session=abc123tokenvalue',
        'X-API-Key: abc123tokenvalue',
        'X-Auth-Token: abc123tokenvalue',
      ]) {
        expect(
          exportWithTitle(header),
          isNot(contains('abc123tokenvalue')),
          reason: header,
        );
      }
    });
  });

  group('provider token shapes', () {
    test('known vendor token prefixes are redacted', () {
      final cases = {
        'sk-abcdefghijklmnop': 'sk-',
        'ghp_abcdefghijklmnopqrstuvwxyz01': 'ghp_',
        'xoxb-abcdefghijklmnopqrstuvwxyz': 'xox',
      };
      for (final entry in cases.entries) {
        expect(
          exportWithTitle('token is ${entry.key}'),
          isNot(contains(entry.key)),
          reason: entry.key,
        );
      }
    });

    test('a JWT is redacted', () {
      const jwt = 'eyJhbGciOiJIUzI1.eyJzdWIiOiIxMjM0.SflKxwRJSMeKKF2QT4';
      expect(exportWithTitle(jwt), isNot(contains(jwt)));
    });
  });

  group('labelled secrets', () {
    test('key-value secrets are redacted whatever the label', () {
      for (final label in [
        'api_key',
        'api-key',
        'auth_token',
        'token',
        'password',
        'passwd',
        'pwd',
        'credential',
      ]) {
        expect(
          exportWithTitle('$label=abc123tokenvalue'),
          isNot(contains('abc123tokenvalue')),
          reason: label,
        );
      }
    });

    test('a colon separator redacts too', () {
      expect(
        exportWithTitle('password: abc123tokenvalue'),
        isNot(contains('abc123tokenvalue')),
      );
    });
  });

  group('embedded credentials and paths', () {
    test('a Wing pairing handoff code is excluded from diagnostics', () {
      const syntheticCode = 'synthetic-once-only-marker';
      final out = exportWithTitle(
        'wing://connect?origin=https%3A%2F%2Fhermes.example'
        '&code=$syntheticCode',
      );

      expect(out, isNot(contains(syntheticCode)));
      expect(out, contains('code=[redacted]'));
    });

    test('URL userinfo is redacted', () {
      expect(
        exportWithTitle('https://user:hunter2@hermes.example'),
        isNot(contains('hunter2')),
      );
    });

    test('local filesystem paths are redacted', () {
      for (final path in [
        '/home/operator/secrets.txt',
        '/Users/operator/secrets.txt',
        r'C:\Users\operator\secrets.txt',
      ]) {
        expect(
          exportWithTitle(path),
          isNot(contains('operator')),
          reason: path,
        );
      }
    });
  });

  group('redaction applies on every path', () {
    test('the model inventory is redacted, not only session titles', () {
      expect(
        exportWithModels(['Bearer abc123tokenvalue']),
        isNot(contains('abc123tokenvalue')),
      );
    });

    test('long text is truncated after redaction, never before', () {
      final out = exportWithTitle('${'x' * 200} Bearer abc123tokenvalue');
      expect(out, isNot(contains('abc123tokenvalue')));
    });
  });

  group('non-secret content survives', () {
    test('an ordinary title is preserved', () {
      expect(exportWithTitle('Deploy review'), contains('Deploy review'));
    });

    test('the document always states its exclusions', () {
      final out = exportWithTitle('plain');
      for (final line in [
        'Secrets: excluded',
        'Raw logs: excluded',
        'Tool payloads: excluded',
        'Transcripts: excluded',
        'Local paths: excluded',
      ]) {
        expect(out, contains(line), reason: line);
      }
    });
  });

  group('health section', () {
    String exportWithHealth(HermesHealthStatus health) =>
        hermesDiagnosticsExport(
          HermesChannelState(
            status: HermesConnectionStatus.connected,
            detailedHealth: health,
          ),
        );

    test('reported health is rendered and redacted', () {
      final out = exportWithHealth(
        const HermesHealthStatus(
          status: 'ok',
          platform: 'linux',
          version: '0.7.3',
          gatewayState: 'running',
          activeAgents: 2,
        ),
      );

      expect(out, contains('Health status: ok'));
      expect(out, contains('Platform: linux'));
      expect(out, contains('Version: 0.7.3'));
      expect(out, contains('Gateway state: running'));
      expect(out, contains('Active agents: 2'));
    });

    test('absent health fields render as unknown, not as null', () {
      final out = exportWithHealth(
        const HermesHealthStatus(status: 'degraded', platform: 'linux'),
      );

      expect(out, contains('Version: unknown'));
      expect(out, contains('Gateway state: unknown'));
      expect(out, isNot(contains('null')));
    });

    test('a secret leaked into a health field is redacted', () {
      final out = exportWithHealth(
        const HermesHealthStatus(
          status: 'ok',
          platform: 'Bearer abc123tokenvalue',
        ),
      );

      expect(out, isNot(contains('abc123tokenvalue')));
    });
  });
}
