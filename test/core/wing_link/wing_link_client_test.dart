import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';

void main() {
  test('lists Wing Link profiles with the independent control token', () async {
    late Uri requestedUri;
    late Map<String, String> requestedHeaders;
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (uri, headers) async {
        requestedUri = uri;
        requestedHeaders = headers;
        return jsonEncode({
          'profiles': [
            {
              'id': 'link',
              'name': 'link',
              'revision': 'rev-1',
              'topology_revision': 'top-1',
              'source': 'api',
              'gateway_state': 'unknown',
              'actions': {
                'rename': {'revision': 'rev-1'},
                'delete': {'revision': 'rev-1'},
              },
            },
          ],
        });
      },
    );

    final profiles = await client.listProfiles();

    expect(requestedUri, Uri.parse('https://hermes.example:8654/v1/profiles'));
    expect(requestedHeaders['Authorization'], 'Bearer wlc-secret');
    expect(profiles.single.id, 'link');
    expect(profiles.single.source, 'api');
    expect(profiles.single.gatewayState, 'unknown');
    expect(profiles.single.revision, 'top-1');
    expect(profiles.single.renameRevision, 'rev-1');
    expect(profiles.single.canRename, isTrue);
    expect(profiles.single.canDelete, isTrue);
  });

  test(
    'acknowledges before profile mutations and sends revision guards',
    () async {
      final requests = <String>[];
      final client = WingLinkClient(
        origin: Uri.parse('https://hermes.example:8654'),
        token: 'wlc-secret',
        post: (uri, headers, body) async {
          requests.add('POST ${uri.path} $body');
          if (uri.path.endsWith('/ack')) return '{}';
          return '{"profile":{"id":"qa","name":"qa","revision":"rev-1"}}';
        },
        patch: (uri, headers, body) async {
          requests.add('PATCH ${uri.path} $body');
          return '{"profile":{"id":"qa2","name":"qa2","revision":"rev-2"}}';
        },
        delete: (uri, headers) async {
          requests.add('DELETE ${uri.path} ${headers['If-Match']}');
          return '{}';
        },
      );

      await client.acknowledgeCredential('cred_1');
      await client.createProfile(name: 'qa', cloneFrom: 'default');
      await client.renameProfile(id: 'qa', name: 'qa2', revision: 'rev-1');
      await client.deleteProfile(id: 'qa2', revision: 'rev-2');

      expect(requests.first, 'POST /v1/auth/credentials/cred_1/ack {}');
      expect(requests[1], contains('"clone_from":"default"'));
      expect(requests[2], contains('"revision":"rev-1"'));
      expect(requests.last, 'DELETE /v1/profiles/qa2 rev-2');
    },
  );
}
