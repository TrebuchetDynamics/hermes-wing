import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/shared/connection_import_parser.dart';

void main() {
  test(
    'parses camelCase core pairing descriptor fields from shared imports',
    () {
      final result = parseNavivoxConnectionImportPayload(
        'navivox://connect?'
        'baseUrl=https%3A%2F%2Fgateway.example%2Fsetup&'
        'websocketUrl=wss%3A%2F%2Fgateway.example%2Fv1%2Fnavivox%2Fstream&'
        'tokenRequired=true&'
        'restToken=setup-secret-token&'
        'serverId=local&'
        'profileId=mineru',
      );

      expect(result, isNotNull);
      expect(result!.baseUrl, 'https://gateway.example');
      expect(result.webSocketUrl, 'wss://gateway.example/v1/navivox/stream');
      expect(result.token, 'setup-secret-token');
      expect(result.serverId, 'local');
      expect(result.profileId, 'mineru');
    },
  );

  test('does not let an earlier docs token outrank a later connection URL', () {
    final result = parseNavivoxConnectionImportPayload(
      'Read https://docs.example/reset?token=nvbx_docs first. Then open '
      'https://gateway.example/connect to pair Navivox.',
    );

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.token, isNull);
  });

  test('prefers connection-route URL over docs URL with following token', () {
    final result = parseNavivoxConnectionImportPayload(
      'Read https://docs.example/setup then token: nvbx_docs. Then open '
      'https://gateway.example/pair to pair Navivox.',
    );

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.token, isNull);
  });

  test(
    'keeps connection-route precedence above stale docs token proximity',
    () {
      final result = parseNavivoxConnectionImportPayload(
        'Read https://docs.example/setup. Token: nvbx_docs. Then open '
        'https://gateway.example/connection to pair Navivox.',
      );

      expect(result, isNotNull);
      expect(result!.baseUrl, 'https://gateway.example');
      expect(result.token, isNull);
    },
  );

  test('treats connection-route signal as a path segment only', () {
    final result = parseNavivoxConnectionImportPayload(
      'Read https://connect-docs.example/setup?token=nvbx_docs. Then open '
      'https://gateway.example/setup. Token: nvbx_pairing',
    );

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.token, 'nvbx_pairing');
  });

  test('parses copied core pairing descriptor scheme case-insensitively', () {
    final result = parseNavivoxConnectionImportPayload(
      'NaviVox://CONNECT?'
      'baseUrl=https%3A%2F%2Fgateway.example%2Fsetup&'
      'websocketUrl=wss%3A%2F%2Fgateway.example%2Fv1%2Fnavivox%2Fstream&'
      'restToken=setup-secret-token',
    );

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.webSocketUrl, 'wss://gateway.example/v1/navivox/stream');
    expect(result.token, 'setup-secret-token');
  });

  test('rejects copied URL tokens from unsupported endpoint schemes', () {
    final result = parseNavivoxConnectionImportPayload(
      'ftp://gateway.example/connect?token=nvbx_unsupported',
    );

    expect(result, isNull);
  });

  test('rejects malformed endpoint ports before reading query tokens', () {
    final copiedUrl = parseNavivoxConnectionImportPayload(
      'http://127.0.0.1:99999/connect?token=nvbx_bad',
    );
    final sharedText = parseNavivoxConnectionImportPayload(
      'Open http://127.0.0.1:99999/connect?token=nvbx_bad to pair.',
    );

    expect(copiedUrl, isNull);
    expect(sharedText, isNull);
  });

  test('does not let metadata-only JSON entries outrank explicit entries', () {
    final result = parseNavivoxConnectionImportPayload('''
{
  "base_url": "https://default.example",
  "token": "nvbx_default",
  "entries": [
    {"server_id": "metadata-only", "profile_id": "demo"},
    {"base_url": "https://gateway.example", "token": "nvbx_pairing"}
  ]
}
''');

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.token, 'nvbx_pairing');
    expect(result.serverId, isNull);
    expect(result.profileId, isNull);
  });

  test('binds a trailing token only to the selected endpoint window', () {
    final result = parseNavivoxConnectionImportPayload(
      'Token: nvbx_old https://docs.example/help. Then open '
      'https://gateway.example/connect. Token: nvbx_pairing',
    );

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.token, 'nvbx_pairing');
  });

  test('does not borrow a leading token for later endpoints', () {
    final result = parseNavivoxConnectionImportPayload(
      'Token: nvbx_old https://docs.example/help. Then open '
      'https://gateway.example/connect.',
    );

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.token, isNull);
  });

  test('does not borrow a token from a later endpoint window', () {
    final result = parseNavivoxConnectionImportPayload(
      'Open https://gateway.example/connect?server_id=srv. Then read '
      'https://docs.example/help Token: nvbx_docs.',
    );

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.serverId, 'srv');
    expect(result.token, isNull);
  });

  test('does not split tokens at an embedded endpoint boundary', () {
    final result = parseNavivoxConnectionImportPayload(
      'Token: nvbx_stalehttps://gateway.example/connect has setup steps.',
    );

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.token, isNull);
  });

  test('does not split navivox tokens out of larger words', () {
    final result = parseNavivoxConnectionImportPayload(
      'Open https://gateway.example/connect. Internal id: usernvbx_stale.',
    );

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://gateway.example');
    expect(result.token, isNull);
  });

  test('does not reinterpret metadata-only JSON as shared-text tokens', () {
    final result = parseNavivoxConnectionImportPayload(
      '{"profile_id":"nvbx_profile_id","server_id":"srv"}',
    );

    expect(result, isNull);
  });
}
