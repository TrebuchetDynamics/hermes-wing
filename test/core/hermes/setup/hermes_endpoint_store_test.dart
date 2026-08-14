import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';

void main() {
  test('hermesPublicEndpointBaseUrl strips copied URL secret material', () {
    expect(
      hermesPublicEndpointBaseUrl(
        ' http://user:secret@example.com:8642/path?api_key=secret#frag ',
      ),
      'http://example.com:8642',
    );
  });

  test('hermesPublicEndpointBaseUrl preserves IPv6 public origins', () {
    expect(
      hermesPublicEndpointBaseUrl('https://[::1]:8642/api/sessions?token=x'),
      'https://[::1]:8642',
    );
  });

  test('hermesPublicEndpointBaseUrl preserves a multiplex profile prefix', () {
    expect(
      hermesPublicEndpointBaseUrl(
        'https://hermes.example/p/sidon/?token=secret#private',
      ),
      'https://hermes.example/p/sidon',
    );
  });

  test('Hermes API endpoints remain under the multiplex profile prefix', () {
    final config = HermesApiConfig.fromBaseUrl(
      'https://hermes.example/p/sidon',
    );

    expect(
      config.capabilitiesUri.toString(),
      'https://hermes.example/p/sidon/v1/capabilities',
    );
    expect(
      config.sessionsUri.toString(),
      'https://hermes.example/p/sidon/api/sessions',
    );
  });

  test('hermesPublicEndpointBaseUrl leaves malformed setup text trim-only', () {
    expect(hermesPublicEndpointBaseUrl('  not a url  '), 'not a url');
  });
}
