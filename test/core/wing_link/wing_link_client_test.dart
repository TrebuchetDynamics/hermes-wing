import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';

void main() {
  test('starts bounded setup and polls its operation', () async {
    final requests = <String>[];
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      post: (uri, headers, body) async {
        requests.add('POST ${uri.path} $body');
        return '{"protocol_version":1,"operation_id":"op_setup"}';
      },
      get: (uri, headers) async {
        requests.add('GET ${uri.path}');
        return '{"protocol_version":1,"operation_id":"op_setup","phase":"gateway","message":"Starting Hermes gateway","percent":96}';
      },
    );

    final operationId = await client.startSetup();
    final operation = await client.getOperation(operationId);

    expect(operationId, 'op_setup');
    expect(operation.phase, 'gateway');
    expect(operation.percent, 96);
    expect(operation.terminal, isFalse);
    expect(requests, ['POST /v1/setup {}', 'GET /v1/operations/op_setup']);
  });

  test('rejects unsafe operation identifiers before transport', () async {
    var requested = false;
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (uri, headers) async {
        requested = true;
        return '{}';
      },
    );

    await expectLater(
      client.getOperation('../profiles'),
      throwsA(isA<WingLinkException>()),
    );
    expect(requested, isFalse);
  });

  test('pending credential verification reads host status only', () async {
    final requestedPaths = <String>[];
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (uri, headers) async {
        requestedPaths.add(uri.path);
        return '{"status":"ok"}';
      },
    );

    await client.verifyPendingCredential();

    expect(requestedPaths, ['/v1/status']);
  });

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

  test('CRUDs custom providers with revision guards', () async {
    final requests = <String>[];
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (uri, headers) async {
        requests.add('GET ${uri.path} ${uri.queryParameters['profile']}');
        return '{"providers":[{"id":"acme","base_url":"https://api.example/v1","model":"v1","revision":"rev-1"}]}';
      },
      post: (uri, headers, body) async {
        requests.add(
          'POST ${uri.path} ${uri.queryParameters['profile']} $body',
        );
        return '{"provider":{"id":"new","base_url":"https://new.example/v1","model":"m","revision":"rev-2"}}';
      },
      patch: (uri, headers, body) async {
        requests.add(
          'PATCH ${uri.path} ${uri.queryParameters['profile']} $body',
        );
        return '{"provider":{"id":"acme","base_url":"https://new.example/v1","model":"v2","revision":"rev-3"}}';
      },
      delete: (uri, headers) async {
        requests.add(
          'DELETE ${uri.path} ${uri.queryParameters['profile']} ${headers['If-Match']}',
        );
        return '{}';
      },
    );

    final listed = await client.listProviders(profile: 'default');
    final created = await client.createProvider(
      profile: 'default',
      id: 'new',
      baseUrl: 'https://new.example/v1',
      model: 'm',
    );
    final updated = await client.updateProvider(
      profile: 'default',
      id: 'acme',
      baseUrl: 'https://new.example/v1',
      model: 'v2',
      revision: 'rev-1',
    );
    await client.deleteProvider(
      profile: 'default',
      id: 'acme',
      revision: 'rev-3',
    );

    expect(listed.single.id, 'acme');
    expect(created.id, 'new');
    expect(updated.model, 'v2');
    expect(requests.first, 'GET /v1/providers default');
    expect(requests[1], contains('"id":"new"'));
    expect(requests[2], contains('"revision":"rev-1"'));
    expect(requests.last, 'DELETE /v1/providers/acme default rev-3');
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
