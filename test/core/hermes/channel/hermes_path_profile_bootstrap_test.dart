import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';

void main() {
  test(
    'path profile wins over listener default on connect and deliberate reconnect',
    () async {
      final reads = <Uri>[];
      var mutations = 0;
      final channel = HermesApiChannel(
        clientBuilder: (config) => HermesApiClient(
          config: config,
          get: (uri, headers) async {
            reads.add(uri);
            expect(uri.path, startsWith('/p/worker/'));
            expect(uri.queryParameters.containsKey('profile'), isFalse);
            return switch (uri.path.substring('/p/worker'.length)) {
              '/health' => '{"status":"ok"}',
              '/v1/capabilities' => jsonEncode({
                'schema_version': 1,
                'profile_context': {
                  'type': 'query',
                  'name': 'profile',
                  'required': true,
                  'default_profile_id': 'default',
                },
                'endpoints': {},
              }),
              '/api/sessions' => '{"data":[]}',
              _ => throw StateError('Unexpected read'),
            };
          },
          post: (_, _, _) async {
            mutations++;
            throw StateError('Unexpected mutation');
          },
        ),
      );
      addTearDown(channel.dispose);
      for (final port in [45678, 45679]) {
        await channel.connect(baseUrl: 'http://127.0.0.1:$port/p/worker');
        expect(channel.state.status, HermesConnectionStatus.connected);
        expect(channel.state.selectedProfileId, 'worker');
        expect(channel.state.activeSessionId, isNull);
        await channel.disconnect();
      }
      expect(reads.length, 6);
      expect(mutations, 0);
    },
  );
}
