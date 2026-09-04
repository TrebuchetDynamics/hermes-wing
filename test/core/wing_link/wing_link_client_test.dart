import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';

int _approvalExpiry({Duration offset = const Duration(minutes: 5)}) =>
    DateTime.now().add(offset).millisecondsSinceEpoch ~/ 1000;

void main() {
  test('negotiates current and previous Wing Link generations', () async {
    late Map<String, String> requestedHeaders;
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (uri, headers) async {
        requestedHeaders = headers;
        expect(uri.path, '/meta');
        return jsonEncode({
          'protocol_generation': 2,
          'minimum_protocol_generation': 1,
          'supported_protocol_generations': [1, 2],
          'version': '0.2.0',
          'host_fingerprint': 'sha256/test-pin',
          'capabilities': ['device.self.read', 'future.unknown'],
        });
      },
    );

    final metadata = await client.getMetadata();

    expect(metadata.protocolGeneration, 2);
    expect(metadata.supportedProtocolGenerations, [1, 2]);
    expect(metadata.capabilities, contains('future.unknown'));
    expect(requestedHeaders['Wing-Protocol'], '2');
  });

  test(
    'rejects servers outside the N minus one compatibility window',
    () async {
      final client = WingLinkClient(
        origin: Uri.parse('https://hermes.example:8654'),
        token: 'wlc-secret',
        get: (_, _) async => jsonEncode({
          'protocol_generation': 4,
          'minimum_protocol_generation': 3,
          'supported_protocol_generations': [3, 4],
          'version': 'future',
          'host_fingerprint': 'sha256/future',
          'capabilities': <String>[],
        }),
      );

      await expectLater(
        client.getMetadata(),
        throwsA(isA<WingLinkUpgradeRequired>()),
      );
    },
  );

  test('maps typed HTTP 426 metadata responses to upgrade recovery', () async {
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-test-token',
      get: (_, _) async => throw const WingLinkHttpException(426),
    );

    await expectLater(
      client.getMetadata(),
      throwsA(isA<WingLinkUpgradeRequired>()),
    );
  });

  test('lists opaque directory roots without accepting host paths', () async {
    late Uri requested;
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (uri, headers) async {
        requested = uri;
        return jsonEncode({
          'directories': [
            {'handle': 'dirh_AAAAAAAAAAAAAAAAAAAAAA', 'name': 'repository'},
          ],
        });
      },
    );

    final roots = await client.listDirectoryRoots();

    expect(requested.path, '/v2/directories');
    expect(roots.single.name, 'repository');
    expect(roots.single.handle, startsWith('dirh_'));
  });

  test('lists child directories with only the bounded opaque query', () async {
    late Uri requested;
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (uri, headers) async {
        requested = uri;
        return jsonEncode({
          'directories': [
            {'handle': 'dirh_BBBBBBBBBBBBBBBBBBBBBB', 'name': 'src'},
          ],
          'next_offset': 50,
        });
      },
    );

    final page = await client.listChildDirectories(
      handle: 'dirh_AAAAAAAAAAAAAAAAAAAAAA',
      offset: 0,
      limit: 50,
    );

    expect(
      requested.path,
      '/v2/directories/dirh_AAAAAAAAAAAAAAAAAAAAAA/children',
    );
    expect(requested.queryParameters, {'offset': '0', 'limit': '50'});
    expect(page.directories.single.name, 'src');
    expect(page.nextOffset, 50);
  });

  test('directory models enforce wire bounds and reject path fields', () async {
    String handle(int index) => 'dirh_${index.toString().padLeft(22, 'A')}';
    final maxName = '${List.filled(127, 'é').join()}a';
    final oversizedName = List.filled(128, 'é').join();

    Future<Object?> load(
      Map<String, Object?> payload, {
      bool children = false,
    }) async {
      final client = WingLinkClient(
        origin: Uri.parse('https://hermes.example:8654'),
        token: 'wlc-secret',
        get: (_, _) async => jsonEncode(payload),
      );
      return children
          ? client.listChildDirectories(handle: handle(0))
          : client.listDirectoryRoots();
    }

    final rootBoundary =
        await load({
              'directories': [
                for (var index = 0; index < 32; index++)
                  {'handle': handle(index), 'name': maxName},
              ],
            })
            as List<WingLinkDirectory>;
    expect(rootBoundary, hasLength(32));
    expect(utf8.encode(rootBoundary.first.name), hasLength(255));
    expect(
      WingLinkDirectory.fromJson({
        'handle': 'dirh_${List.filled(92, 'A').join()}',
        'name': maxName,
      }).handle,
      hasLength(97),
    );

    final childBoundary =
        await load({
              'directories': [
                for (var index = 0; index < 100; index++)
                  {'handle': handle(index), 'name': 'child-$index'},
              ],
              'next_offset': 1000,
            }, children: true)
            as WingLinkDirectoryPage;
    expect(childBoundary.directories, hasLength(100));
    expect(childBoundary.nextOffset, 1000);

    for (final invalid in <({Map<String, Object?> payload, bool children})>[
      (
        payload: {
          'directories': [
            {
              'handle': handle(1),
              'name': 'repository',
              'path': '/private/root',
            },
          ],
        },
        children: false,
      ),
      (
        payload: {
          'directories': [
            {'handle': 'dirh_bad', 'name': 'repository'},
          ],
        },
        children: false,
      ),
      (
        payload: {
          'directories': [
            {
              'handle': 'dirh_${List.filled(21, 'A').join()}',
              'name': 'repository',
            },
          ],
        },
        children: false,
      ),
      (
        payload: {
          'directories': [
            {
              'handle': 'dirh_${List.filled(93, 'A').join()}',
              'name': 'repository',
            },
          ],
        },
        children: false,
      ),
      (
        payload: {
          'directories': [
            {'handle': handle(1), 'name': ''},
          ],
        },
        children: false,
      ),
      (
        payload: {
          'directories': [
            {'handle': handle(1), 'name': 'private\\folder'},
          ],
        },
        children: false,
      ),
      (
        payload: {
          'directories': [
            {'handle': handle(1), 'name': 'private\u0000folder'},
          ],
        },
        children: false,
      ),
      (
        payload: {
          'directories': [
            {'handle': handle(1), 'name': '../private'},
          ],
        },
        children: false,
      ),
      (
        payload: {
          'directories': [
            {'handle': handle(1), 'name': oversizedName},
          ],
        },
        children: false,
      ),
      (
        payload: {
          'directories': [
            for (var index = 0; index < 33; index++)
              {'handle': handle(index), 'name': 'root-$index'},
          ],
        },
        children: false,
      ),
      (payload: {'directories': const [], 'next_offset': 1}, children: false),
      (
        payload: {'directories': const [], 'path': '/private/root'},
        children: false,
      ),
      (
        payload: {
          'directories': [
            for (var index = 0; index < 101; index++)
              {'handle': handle(index), 'name': 'child-$index'},
          ],
        },
        children: true,
      ),
      (payload: {'directories': const [], 'next_offset': 1001}, children: true),
      (payload: {'directories': const [], 'next_offset': null}, children: true),
    ]) {
      await expectLater(
        load(invalid.payload, children: invalid.children),
        throwsA(isA<WingLinkException>()),
      );
    }
  });

  test('rejects invalid directory requests before transport', () async {
    var requested = false;
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (_, _) async {
        requested = true;
        return '{}';
      },
    );

    for (final request in [
      () => client.listChildDirectories(handle: 'dirh_bad'),
      () => client.listChildDirectories(
        handle: 'dirh_AAAAAAAAAAAAAAAAAAAAAA',
        offset: -1,
      ),
      () => client.listChildDirectories(
        handle: 'dirh_AAAAAAAAAAAAAAAAAAAAAA',
        offset: 1001,
      ),
      () => client.listChildDirectories(
        handle: 'dirh_AAAAAAAAAAAAAAAAAAAAAA',
        limit: 0,
      ),
      () => client.listChildDirectories(
        handle: 'dirh_AAAAAAAAAAAAAAAAAAAAAA',
        limit: 101,
      ),
    ]) {
      await expectLater(request(), throwsA(isA<WingLinkException>()));
    }
    expect(requested, isFalse);
  });

  test('starts bounded setup and polls its operation', () async {
    final requests = <String>[];
    late Map<String, String> setupHeaders;
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      post: (uri, headers, body) async {
        setupHeaders = headers;
        requests.add('POST ${uri.path} $body');
        return '{"protocol_version":1,"operation_id":"op_setup"}';
      },
      get: (uri, headers) async {
        requests.add('GET ${uri.path}');
        return '{"protocol_version":1,"operation_id":"op_setup","phase":"gateway","message":"Starting Hermes gateway","percent":96}';
      },
    );

    final operationId = await client.startSetup(idempotencyKey: 'setup-test-1');
    final operation = await client.getOperation(operationId);

    expect(operationId, 'op_setup');
    expect(operation.phase, 'gateway');
    expect(operation.percent, 96);
    expect(operation.terminal, isFalse);
    expect(setupHeaders['Idempotency-Key'], 'setup-test-1');
    expect(requests, ['POST /v1/setup {}', 'GET /v1/operations/op_setup']);
  });

  test('surfaces host approval with a retryable idempotency key', () async {
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      post: (uri, headers, body) async => jsonEncode({
        'protocol_version': 2,
        'operation_id': 'op_pending',
        'approval_id': 'appr_pending',
        'expires_at': _approvalExpiry(),
        'error': {'code': 'approval_required'},
      }),
    );

    await expectLater(
      client.startSetup(idempotencyKey: 'setup-retry-1'),
      throwsA(
        isA<WingLinkApprovalRequired>()
            .having((error) => error.approvalId, 'approvalId', 'appr_pending')
            .having((error) => error.operationId, 'operationId', 'op_pending')
            .having(
              (error) => error.idempotencyKey,
              'idempotencyKey',
              'setup-retry-1',
            ),
      ),
    );
  });

  test('rejects past and far-future approval expiry values', () async {
    for (final expiry in [
      _approvalExpiry(offset: const Duration(seconds: -1)),
      _approvalExpiry(offset: const Duration(minutes: 6)),
    ]) {
      final client = WingLinkClient(
        origin: Uri.parse('https://hermes.example:8654'),
        token: 'wlc-secret',
        post: (_, _, _) async => jsonEncode({
          'protocol_version': 2,
          'operation_id': 'op_pending',
          'approval_id': 'appr_pending',
          'expires_at': expiry,
          'error': {'code': 'approval_required'},
        }),
      );
      await expectLater(
        client.startSetup(idempotencyKey: 'setup-retry-expiry'),
        throwsA(
          isA<WingLinkException>().having(
            (error) => error.message,
            'message',
            contains('invalid approval data'),
          ),
        ),
      );
    }
  });

  test('destructive profile approval preserves exact retry key', () async {
    late Map<String, String> sentHeaders;
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      delete: (uri, headers) async {
        sentHeaders = headers;
        return jsonEncode({
          'protocol_version': 2,
          'operation_id': 'op_delete',
          'approval_id': 'appr_delete',
          'expires_at': _approvalExpiry(),
          'error': {'code': 'approval_required'},
        });
      },
    );

    await expectLater(
      client.deleteProfile(
        id: 'qa',
        revision: 'rev-1',
        idempotencyKey: 'delete-retry-1',
      ),
      throwsA(
        isA<WingLinkApprovalRequired>().having(
          (error) => error.idempotencyKey,
          'idempotencyKey',
          'delete-retry-1',
        ),
      ),
    );
    expect(sentHeaders['If-Match'], 'rev-1');
    expect(sentHeaders['Idempotency-Key'], 'delete-retry-1');
  });

  test('delete accepts only a committed successful terminal replay', () async {
    final success = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      delete: (_, _) async => jsonEncode({
        'operation_id': 'op_delete_replay',
        'replayed': true,
        'operation': {
          'operation_id': 'op_delete_replay',
          'phase': 'committed',
          'percent': 100,
          'terminal': true,
        },
      }),
    );
    await success.deleteProfile(id: 'qa', revision: 'rev-1');

    for (final phase in ['failed', 'cancelled']) {
      final failed = WingLinkClient(
        origin: Uri.parse('https://hermes.example:8654'),
        token: 'wlc-secret',
        delete: (_, _) async => jsonEncode({
          'operation_id': 'op_delete_replay',
          'replayed': true,
          'operation': {
            'operation_id': 'op_delete_replay',
            'phase': phase,
            'percent': 100,
            'terminal': true,
            'error_code': 'operation_$phase',
          },
        }),
      );
      await expectLater(
        failed.deleteProfile(id: 'qa', revision: 'rev-1'),
        throwsA(
          isA<WingLinkException>().having(
            (error) => error.message,
            'message',
            contains('deletion failed'),
          ),
        ),
      );
    }
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

  test('inspects and self-revokes only the current device', () async {
    final requested = <String>[];
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (uri, headers) async {
        requested.add('GET ${uri.path}');
        return jsonEncode({
          'device_id': 'cred_phone',
          'name': 'Pixel 9',
          'scopes': ['device:self:read', 'device:self:revoke'],
          'created_at': '2026-08-24T12:00:00Z',
          'last_used_at': '2026-08-24T12:05:00Z',
          'legacy': false,
        });
      },
      delete: (uri, headers) async {
        requested.add('DELETE ${uri.path}');
        return '';
      },
    );

    final device = await client.getCurrentDevice();
    await client.revokeCurrentDevice();

    expect(device.id, 'cred_phone');
    expect(device.name, 'Pixel 9');
    expect(device.scopes, contains('device:self:revoke'));
    expect(requested, ['GET /v2/devices/self', 'DELETE /v2/devices/self']);
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
              'skills_count': -1,
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
    expect(profiles.single.skillsCount, 0);
    expect(profiles.single.renameRevision, 'rev-1');
    expect(profiles.single.canRename, isTrue);
    expect(profiles.single.canDelete, isTrue);
  });

  test('rejects a malformed profile row instead of hiding it', () async {
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      get: (uri, headers) async => '{"profiles":[{"id":"valid"},"broken"]}',
    );

    await expectLater(client.listProfiles(), throwsA(isA<WingLinkException>()));
  });

  test('profile mutation exposes a typed stale-revision failure', () async {
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-secret',
      patch: (_, _, _) async => throw const WingLinkHttpException(412),
    );

    await expectLater(
      client.renameProfile(id: 'qa', name: 'qa2', revision: 'rev-1'),
      throwsA(isA<WingLinkPreconditionFailed>()),
    );
  });

  test('does not infer a stale revision from arbitrary error text', () async {
    const original = WingLinkException('Wing Link HTTP 412');
    final client = WingLinkClient(
      origin: Uri.parse('https://hermes.example:8654'),
      token: 'wlc-test-token',
      patch: (_, _, _) async => throw original,
    );

    await expectLater(
      client.renameProfile(id: 'qa', name: 'qa2', revision: 'rev-1'),
      throwsA(same(original)),
    );
  });

  test(
    'profile-create replay normalizes the expected authoritative ID',
    () async {
      var posts = 0;
      var gets = 0;
      final client = WingLinkClient(
        origin: Uri.parse('https://hermes.example:8654'),
        token: 'wlc-secret',
        post: (_, headers, body) async {
          posts++;
          expect(headers['Idempotency-Key'], 'profile-create-response-loss');
          expect(
            jsonDecode(body),
            allOf([
              containsPair('name', ' ReadyQA '),
              containsPair('provider_api_key', 'write-only-provider-secret'),
            ]),
          );
          return jsonEncode({
            'protocol_version': 2,
            'operation_id': 'op_profile_create',
            'replayed': true,
            'operation': {
              'protocol_version': 2,
              'operation_id': 'op_profile_create',
              'phase': 'committed',
              'message': 'Committed',
              'percent': 100,
              'terminal': true,
            },
          });
        },
        get: (uri, headers) async {
          gets++;
          expect(uri.path, '/v1/profiles');
          return '{"profiles":[{"id":"readyqa","name":"readyqa","revision":"rev-1","source":"cli","gateway_state":"running"}]}';
        },
      );

      final profile = await client.createProfile(
        name: ' ReadyQA ',
        provider: 'openrouter',
        model: 'openai/gpt-5.2',
        providerApiKey: 'write-only-provider-secret',
        idempotencyKey: 'profile-create-response-loss',
      );

      expect(profile.id, 'readyqa');
      expect((posts, gets), (1, 1));
    },
  );

  test(
    'profile-create replay fails without the exact authoritative profile',
    () async {
      final client = WingLinkClient(
        origin: Uri.parse('https://hermes.example:8654'),
        token: 'wlc-secret',
        post: (_, _, _) async => jsonEncode({
          'protocol_version': 2,
          'operation_id': 'op_profile_create',
          'replayed': true,
          'operation': {
            'operation_id': 'op_profile_create',
            'phase': 'committed',
            'percent': 100,
            'terminal': true,
          },
        }),
        get: (_, _) async => '{"profiles":[{"id":"other","name":"other"}]}',
      );

      await expectLater(
        client.createProfile(
          name: 'readyqa',
          idempotencyKey: 'profile-create-missing',
        ),
        throwsA(
          isA<WingLinkException>().having(
            (error) => error.message,
            'message',
            contains('could not reconcile'),
          ),
        ),
      );
    },
  );

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
      await client.createProfile(
        name: 'qa',
        cloneFrom: 'default',
        description: 'Physical lifecycle profile',
        provider: 'openrouter',
        model: 'openai/gpt-5.2',
        providerApiKey: 'write-only-provider-secret',
      );
      await client.renameProfile(id: 'qa', name: 'qa2', revision: 'rev-1');
      await client.deleteProfile(id: 'qa2', revision: 'rev-2');

      expect(requests.first, 'POST /v1/auth/credentials/cred_1/ack {}');
      expect(
        requests[1],
        allOf([
          contains('"clone_from":"default"'),
          contains('"description":"Physical lifecycle profile"'),
          contains('"provider":"openrouter"'),
          contains('"model":"openai/gpt-5.2"'),
          contains('"provider_api_key":"write-only-provider-secret"'),
        ]),
      );
      expect(
        requests[2],
        allOf([
          contains('"revision":"rev-1"'),
          isNot(contains('"description"')),
          isNot(contains('"provider"')),
          isNot(contains('"model"')),
          isNot(contains('"provider_api_key"')),
        ]),
      );
      expect(requests.last, 'DELETE /v1/profiles/qa2 rev-2');
    },
  );
}
