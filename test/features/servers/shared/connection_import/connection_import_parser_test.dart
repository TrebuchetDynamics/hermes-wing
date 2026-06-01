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

  test('rejects copied URL tokens from unsupported endpoint schemes', () {
    final result = parseNavivoxConnectionImportPayload(
      'ftp://gateway.example/connect?token=nvbx_unsupported',
    );

    expect(result, isNull);
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
}
