import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/setup/hermes_gateway_invite.dart';
import 'package:wing/core/hermes/client/hermes_web_read_client.dart';

void main() {
  test('QR round trip includes only origin and exact profile', () {
    final invite = HermesGatewayInvite(
      origin: Uri.parse('https://gateway.example.invalid:9443'),
      profile: 'my_bot',
    );
    final encoded = invite.encode();
    expect(jsonDecode(encoded), {
      'type': 'hermes-wing-gateway',
      'version': 1,
      'origin': 'https://gateway.example.invalid:9443',
      'profile': 'my_bot',
    });
    expect(HermesGatewayInvite.decode(encoded).profile, 'my_bot');
  });

  test('credential and legacy QR payloads rejected without echo', () {
    final valid =
        jsonDecode(
              HermesGatewayInvite(
                origin: Uri.parse('https://example.invalid'),
                profile: 'default',
              ).encode(),
            )
            as Map<String, dynamic>;
    for (final input in [
      'wing://pair?token=synthetic-secret',
      jsonEncode({...valid, 'token': 'synthetic-secret'}),
      jsonEncode({
        ...valid,
        'origin': 'https://user:synthetic-secret@example.invalid',
      }),
      jsonEncode({
        ...valid,
        'origin': 'https://example.invalid/?key=synthetic-secret',
      }),
      jsonEncode({...valid, 'origin': 'http://example.invalid'}),
      jsonEncode({...valid, 'origin': 'https://example.invalid/p/other'}),
      jsonEncode({...valid, 'profile': '../other'}),
      'x' * 2049,
    ]) {
      expect(
        () => HermesGatewayInvite.decode(input),
        throwsA(
          predicate(
            (Object e) =>
                e is FormatException &&
                !e.toString().contains('synthetic-secret'),
          ),
        ),
      );
    }
  });

  test('remote native reader keeps HTTPS gate separate from old loopback', () {
    for (final url in [
      'http://example.invalid',
      'https://example.invalid/path',
      'https://example.invalid/?token=x',
      'https://user:pass@example.invalid',
    ]) {
      expect(
        () => HermesWebReadClient.forRemoteGateway(
          origin: Uri.parse(url),
          credential: 'synthetic-token',
          profile: 'default',
        ),
        throwsA(isA<Exception>()),
      );
    }
    expect(
      () => HermesWebReadClient.forLocalReads(
        origin: Uri.parse('https://example.invalid'),
        credential: 'synthetic-token',
        profile: 'default',
      ),
      throwsA(isA<Exception>()),
    );
    final reader = HermesWebReadClient.forRemoteGateway(
      origin: Uri.parse('https://example.invalid'),
      credential: 'synthetic-token',
      profile: 'default',
    );
    final selected = reader.forProfile('demo');
    expect(selected.remoteGateway, isTrue);
    selected.disconnect();
    reader.disconnect();
  });
}
