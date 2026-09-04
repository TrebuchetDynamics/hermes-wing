import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/enrollment/models/hermes_enrollment_payload.dart';

void main() {
  test('extracts one pairing URI from explicit shared text', () {
    final payload = HermesEnrollmentPayload.parseExplicitHandoff(
      'Pair this phone:\n'
      'wing://connect?origin=https%3A%2F%2Fhermes.example&code=once',
    );

    expect(payload.origin, Uri.parse('https://hermes.example'));
    expect(payload.code, 'once');
  });

  test('trims only allowed wrappers around a standalone pairing URI', () {
    final payload = HermesEnrollmentPayload.parseExplicitHandoff(
      'Open <"wing://connect?origin=https%3A%2F%2Fhermes.example&code=once">',
    );

    expect(payload.code, 'once');
  });

  test('rejects shared text containing two pairing URIs', () {
    expect(
      () => HermesEnrollmentPayload.parseExplicitHandoff(
        'wing://connect?origin=https%3A%2F%2Fa.example&code=a '
        'wing://connect?origin=https%3A%2F%2Fb.example&code=b',
      ),
      throwsFormatException,
    );
  });

  test('rejects oversized shared text before URI parsing', () {
    expect(
      () => HermesEnrollmentPayload.parseExplicitHandoff('x' * 4097),
      throwsFormatException,
    );
  });

  test('rejects a pairing URI embedded inside another token', () {
    expect(
      () => HermesEnrollmentPayload.parseExplicitHandoff(
        'prefixwing://connect?origin=https%3A%2F%2Fa.example&code=a',
      ),
      throwsFormatException,
    );
  });

  test('accepts only wing connect payload with HTTPS origin and code', () {
    final payload = HermesEnrollmentPayload.parse(
      'wing://connect?origin=https%3A%2F%2Fhermes.example&code=one-time',
    );
    expect(payload.origin, Uri.parse('https://hermes.example'));
    expect(payload.code, 'one-time');
  });

  test('accepts a same-host one-time CLI broker', () {
    final payload = HermesEnrollmentPayload.parse(
      'wing://connect?origin=https%3A%2F%2Fhermes.example%3A8642'
      '&broker=https%3A%2F%2Fhermes.example%3A45123&code=one-time',
    );
    expect(payload.origin, Uri.parse('https://hermes.example:8642'));
    expect(payload.brokerOrigin, Uri.parse('https://hermes.example:45123'));
  });

  test('rejects a broker on a different host', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=https%3A%2F%2Fhermes.example'
        '&broker=https%3A%2F%2Fevil.example&code=one-time',
      ),
      throwsFormatException,
    );
  });

  test('accepts a same-host Wing Link control origin with a host pin', () {
    final payload = HermesEnrollmentPayload.parse(
      'wing://connect?origin=https%3A%2F%2Fhermes.example%3A8642'
      '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time'
      '&protocol_generation=2'
      '&host_fingerprint=sha256%2FAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    );
    expect(payload.wingLinkOrigin, Uri.parse('https://hermes.example:8654'));
    expect(
      payload.wingLinkHostFingerprint,
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    );
  });

  test('rejects remote Wing Link HTTPS without a host pin', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=https%3A%2F%2Fhermes.example%3A8642'
        '&control=https%3A%2F%2Fhermes.example%3A8654&code=one-time'
        '&protocol_generation=2',
      ),
      throwsFormatException,
    );
  });

  test('rejects a Wing Link control origin on a different host', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=https%3A%2F%2Fhermes.example'
        '&control=https%3A%2F%2Fevil.example%3A8654&code=one-time',
      ),
      throwsFormatException,
    );
  });

  test('rejects duplicate security-sensitive query parameters', () {
    const fields = [
      'origin',
      'broker',
      'control',
      'protocol_generation',
      'host_fingerprint',
      'code',
    ];
    const values = {
      'origin': 'https%3A%2F%2Fhermes.example',
      'broker': 'https%3A%2F%2Fhermes.example',
      'control': 'https%3A%2F%2Fhermes.example',
      'protocol_generation': '1',
      'host_fingerprint':
          'sha256%2FAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      'code': 'one-time',
    };
    final query = values.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    for (final field in fields) {
      expect(
        () => HermesEnrollmentPayload.parse(
          'wing://connect?$query&$field=${values[field]}',
        ),
        throwsFormatException,
        reason: field,
      );
    }
  });

  test('rejects bearer token query parameters', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=https%3A%2F%2Fhermes.example&token=secret',
      ),
      throwsFormatException,
    );
  });

  test('rejects a fragment', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=https%3A%2F%2Fhermes.example&code=one-time#frag',
      ),
      throwsFormatException,
    );
  });

  test('rejects userinfo on the connect payload itself', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://user@connect?origin=https%3A%2F%2Fhermes.example&code=one-time',
      ),
      throwsFormatException,
    );
  });

  test('rejects userinfo embedded in the origin', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=https%3A%2F%2Fuser%3Apass%40hermes.example&code=one-time',
      ),
      throwsFormatException,
    );
  });

  test('rejects a non-HTTP(S) origin scheme', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=ftp%3A%2F%2Fhermes.example&code=one-time',
      ),
      throwsFormatException,
    );
  });

  test('rejects an unknown connect host', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://pair?origin=https%3A%2F%2Fhermes.example&code=one-time',
      ),
      throwsFormatException,
    );
  });

  test('rejects a blank code', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=https%3A%2F%2Fhermes.example&code=',
      ),
      throwsFormatException,
    );
  });

  test('rejects an oversized code', () {
    final oversized = 'a' * 200;
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=https%3A%2F%2Fhermes.example&code=$oversized',
      ),
      throwsFormatException,
    );
  });

  test('rejects a missing origin', () {
    expect(
      () => HermesEnrollmentPayload.parse('wing://connect?code=one-time'),
      throwsFormatException,
    );
  });

  test('rejects a malformed payload URI', () {
    expect(
      () => HermesEnrollmentPayload.parse('not a uri at all::::'),
      throwsFormatException,
    );
  });

  test('rejects a plaintext remote origin without explicit confirmation', () {
    expect(
      () => HermesEnrollmentPayload.parse(
        'wing://connect?origin=http%3A%2F%2Fhermes.example&code=one-time',
      ),
      throwsA(isA<HermesEnrollmentCleartextOriginRequired>()),
    );
  });

  test('accepts a plaintext remote origin once explicitly confirmed', () {
    final payload = HermesEnrollmentPayload.parse(
      'wing://connect?origin=http%3A%2F%2Fhermes.example&code=one-time',
      cleartextOriginConfirmed: true,
    );
    expect(payload.origin, Uri.parse('http://hermes.example'));
    expect(payload.code, 'one-time');
  });

  test('accepts a plaintext loopback origin without confirmation', () {
    final payload = HermesEnrollmentPayload.parse(
      'wing://connect?origin=http%3A%2F%2F127.0.0.1%3A8642&code=one-time',
    );
    expect(payload.origin, Uri.parse('http://127.0.0.1:8642'));
  });

  test('strips path, query, and port normalization noise from the origin', () {
    final payload = HermesEnrollmentPayload.parse(
      'wing://connect?origin=https%3A%2F%2Fhermes.example%3A8642%2Fsetup%3Fold%3D1&code=one-time',
    );
    expect(payload.origin, Uri.parse('https://hermes.example:8642'));
  });
}
