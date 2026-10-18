import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/managed_ssh.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';

void main() {
  ManagedSshConfig config([String? profile]) => ManagedSshConfig(
    host: 'example.invalid',
    username: 'tester',
    agentPort: 8642,
    agentProfile: profile,
  );
  test(
    'explicit profile scopes every API endpoint without changing TCP target',
    () {
      final target = config('hermes-wing');
      final uri = target.forwardedAgentUri(12345);
      expect(uri.toString(), 'http://127.0.0.1:12345/p/hermes-wing');
      expect(target.agentPort, 8642);
      final api = HermesApiConfig.fromBaseUrl(uri.toString());
      expect(api.pathProfileId, 'hermes-wing');
      for (final endpoint in [
        api.healthUri,
        api.capabilitiesUri,
        api.sessionsUri,
        api.runsUri,
        api.sessionMessagesUri('exact-session'),
      ]) {
        expect(endpoint.path, startsWith('/p/hermes-wing/'));
      }
      expect(
        config().forwardedAgentUri(12345).toString(),
        'http://127.0.0.1:12345',
      );
    },
  );
  test(
    'profile accepts only a bounded literal ID, never URLs or path syntax',
    () {
      for (final invalid in [
        '',
        '../x',
        '/p/demo',
        'https://example.invalid',
        'demo/other',
        'demo?x=1',
        'demo#x',
        '%64emo',
        'Demo',
        ' demo',
        'demo\n',
        'a' * 65,
        '_demo',
        'demo.name',
      ]) {
        expect(() => config(invalid), throwsA(isA<ManagedSshException>()));
      }
      for (final valid in ['default', 'a', '0', 'demo_1', 'a' * 64]) {
        expect(config(valid).agentProfile, valid);
      }
      expect(
        config('private-profile').toString(),
        isNot(contains('private-profile')),
      );
    },
  );
}
