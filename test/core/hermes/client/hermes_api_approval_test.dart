import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/hermes_api.dart';

void main() {
  for (final decision in ['once', 'deny']) {
    test('run approval sends native exact request_id for $decision', () async {
      final posts = <Map<String, Object?>>[];
      final client = HermesApiClient(
        config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
        post: (uri, headers, body) async {
          expect(uri.path, '/v1/runs/run_native/approval');
          expect(uri.queryParameters['profile'], 'coder');
          posts.add(jsonDecode(body) as Map<String, Object?>);
          return '{}';
        },
      );
      await client.respondApproval(
        runId: 'run_native',
        approvalId: ' native_request ',
        decision: decision,
        profile: 'coder',
      );
      expect(posts, [
        {'request_id': 'native_request', 'choice': decision},
      ]);
    });
  }
  test('genuinely idless legacy run approval omits request_id', () async {
    Map<String, Object?>? answer;
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl('http://127.0.0.1:8642'),
      post: (uri, headers, body) async {
        answer = jsonDecode(body) as Map<String, Object?>;
        return '{}';
      },
    );
    await client.respondApproval(
      runId: 'run_legacy',
      approvalId: '',
      decision: 'deny',
    );
    expect(answer, {'choice': 'deny'});
  });
}
