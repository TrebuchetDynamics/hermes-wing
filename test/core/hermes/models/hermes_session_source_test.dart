import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';

void main() {
  test('missing source never invents API provenance', () {
    expect(HermesSession.fromJson({'id': 'session'}).source, isEmpty);
    expect(
      HermesSession.fromJson({'id': 'session', 'source': 'telegram'}).source,
      'telegram',
    );
  });
}
