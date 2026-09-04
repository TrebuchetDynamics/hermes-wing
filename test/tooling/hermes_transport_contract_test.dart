import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web Hermes transport rejects browser-followed redirects', () {
    final source = File(
      'lib/core/hermes/client/platform/hermes_api_transport_web.dart',
    ).readAsStringSync();

    expect(source, contains('request.responseURL'));
    expect(source, contains('_matchesRequestUrl'));
    expect(source, contains('Hermes API redirects are not supported'));
  });
}
