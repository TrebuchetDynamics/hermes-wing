import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_router.dart';

import '../../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import 'linux_test_isolation.dart';

final class ManagementConflict implements HermesApiStatusException {
  @override
  int get statusCode => 412;
}

/// Only HTTP is replaced. Channel policy, decoding, directory and routing are real.
/// Unhandled requests fail closed; no socket or provider operation can be issued.
class ManagementFixture {
  ManagementFixture({this.authority = 'advertised'});

  final String authority;
  final requests =
      <({String method, Uri uri, String? revision, Object? body})>[];
  final failures = <String>{};
  Completer<String>? pendingWrite;
  bool conflict = false;
  bool created = false;
  bool configured = true;
  bool hostileHealth = false;
  String name = 'Coder';
  String profileRevision = 'p1';
  String soul = 'Synthetic persona';
  String soulRevision = 's1';
  String skill = 'synthetic-skill';
  String modelRevision = 'm1';
  final auxiliary = <Map<String, String>>[];
  late final channel = HermesApiChannel(
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, headers) => respond('GET', uri, headers: headers),
      post: (uri, headers, body) =>
          respond('POST', uri, headers: headers, body: body),
      put: (uri, headers, body) =>
          respond('PUT', uri, headers: headers, body: body),
      patch: (uri, headers, body) =>
          respond('PATCH', uri, headers: headers, body: body),
      delete: (uri, headers) => respond('DELETE', uri, headers: headers),
    ),
  );
  late ProviderContainer container;
  late GoRouter router;

  Map<String, Object?> get provider => {
    'slug': 'synthetic', 'label': 'Synthetic provider', 'auth_type': 'api_key',
    'env_vars': ['SYNTHETIC_API_KEY'], 'configured': configured,
    if (configured) 'key_hint': '····0001',
    'api_key':
        'synthetic-stored-secret', // Hostile unknown field, not valid readback.
  };
  Map<String, Object?> get assignment => {
    'active': {'provider': 'synthetic', 'model': 'synthetic-model'},
    'revision': modelRevision,
    'auxiliary': auxiliary,
  };
  Map<String, Object?> get catalog => {
    'providers': {
      'synthetic': {
        'models': [
          {'id': 'synthetic-model'},
          {'id': 'synthetic-alternate'},
        ],
      },
    },
  };
  Map<String, Object?> get capabilities => {
    'schema_version': 1,
    'profile_context': {
      'type': 'query',
      'name': 'profile',
      'required': true,
      'default_profile_id': 'default',
    },
    'auth': {
      'type': 'bearer',
      'required': true,
      'granted_scopes': [
        'profiles:read',
        if (authority != 'denied') ...[
          'providers:read',
          'models:read',
          'tasks:read',
          'tools:read',
          'health:read',
          if (authority != 'read-only') ...[
            'profiles:write',
            'providers:write',
            'models:write',
          ],
        ],
      ],
    },
    'endpoints': {
      'profiles': {
        'method': 'GET',
        'path': '/api/profiles',
        'required_scopes': ['profiles:read'],
      },
      if (authority != 'missing')
        for (final op in [
          ('profile_create', 'POST', '/api/profiles', 'profiles:write'),
          ('profile_update', 'PATCH', '/api/profiles/{name}', 'profiles:write'),
          (
            'profile_delete',
            'DELETE',
            '/api/profiles/{name}',
            'profiles:write',
          ),
          ('profile_soul', 'GET', '/api/profiles/{name}/soul', 'profiles:read'),
          (
            'profile_soul_update',
            'PUT',
            '/api/profiles/{name}/soul',
            'profiles:write',
          ),
          ('providers', 'GET', '/api/providers', 'providers:read'),
          (
            'provider_credential_set',
            'PUT',
            '/api/providers/{slug}/credential',
            'providers:write',
          ),
          (
            'provider_credential_delete',
            'DELETE',
            '/api/providers/{slug}/credential',
            'providers:write',
          ),
          (
            'provider_credential_validate',
            'POST',
            '/api/providers/{slug}/credential/validate',
            'providers:write',
          ),
          ('models', 'GET', '/api/models', 'models:read'),
          ('models_refresh', 'POST', '/api/models/refresh', 'models:write'),
          (
            'models_assignment',
            'PUT',
            '/api/models/assignment',
            'models:write',
          ),
          ('skills', 'GET', '/v1/skills', 'tools:read'),
          ('toolsets', 'GET', '/v1/toolsets', 'tools:read'),
          ('jobs', 'GET', '/api/jobs', 'tasks:read'),
          ('health_detailed', 'GET', '/health/detailed', 'health:read'),
        ])
          op.$1: {
            'method': op.$2,
            'path': op.$3,
            'required_scopes': [op.$4],
            'profile_scoped': op.$1 != 'health_detailed',
          },
    },
  };

  Future<String> respond(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final payload = body == null ? null : jsonDecode(body);
    requests.add((
      method: method,
      uri: uri,
      revision: headers?['If-Match'],
      body: payload,
    ));
    final key = '$method ${uri.path}';
    if (failures.contains(key)) {
      throw StateError(
        'synthetic-private-failure token=hidden /home/example/private',
      );
    }
    if (method != 'GET' && pendingWrite != null) return pendingWrite!.future;
    if (method == 'GET') {
      return jsonEncode(switch (uri.path) {
        '/health' => {'status': 'ok'},
        '/v1/capabilities' => capabilities,
        '/api/profiles' => {
          'data': [
            {'id': 'coder', 'name': name, 'revision': profileRevision},
            {'id': 'other', 'name': 'Other', 'revision': 'o1'},
            {'id': 'default', 'name': 'Default', 'revision': 'd1'},
            if (created) {'id': 'created', 'name': 'created', 'revision': 'c1'},
          ],
        },
        '/api/sessions' => {'data': []},
        '/api/profiles/coder/soul' => {'soul': soul, 'revision': soulRevision},
        '/api/profiles/created/soul' => {'soul': '', 'revision': 'c1'},
        '/api/profiles/other/soul' => {
          'soul': 'Synthetic other persona',
          'revision': 'o1',
        },
        '/api/profiles/default/soul' => {
          'soul': 'Synthetic default persona',
          'revision': 'd1',
        },
        '/api/providers' => {
          'data': [
            provider,
            {
              'slug': 'oauth',
              'label': 'Host sign-in',
              'auth_type': 'oauth',
              'configured': false,
            },
          ],
        },
        '/api/models' => {'catalog': catalog, ...assignment},
        '/v1/skills' => {
          'data': [
            {'name': skill, 'description': 'Synthetic skill'},
          ],
        },
        '/v1/toolsets' => {
          'data': [
            {
              'name': 'synthetic-tools',
              'enabled': true,
              'tools': ['synthetic-read'],
            },
          ],
        },
        '/api/jobs' => {
          'jobs': [
            {
              'id': 'synthetic-job',
              'name': 'Synthetic routine',
              'enabled': true,
              'schedule': '0 9 * * *',
            },
          ],
        },
        '/health/detailed' => {
          'status': 'ok',
          'model': 'synthetic-model',
          'version': hostileHealth
              ? 'Synthetic diagnostic Bearer diagnostic-credential /home/example/diagnostic-private ${'x' * 500}'
              : 'synthetic-fixture',
          'platform': hostileHealth
              ? 'hermes-agent https://diagnostic-user:diagnostic-password@example.invalid'
              : 'hermes-agent',
        },
        _ => throw StateError('Unhandled fixture read: $key'),
      });
    }
    switch (key) {
      case 'PUT /api/profiles/coder/soul':
        if (conflict) throw ManagementConflict();
        expect(headers?['If-Match'], soulRevision);
        soul = (payload as Map)['soul'] as String;
        soulRevision = 's3';
        return jsonEncode({'soul': soul, 'revision': soulRevision});
      case 'POST /api/profiles':
        created = true;
        return '{"id":"created","name":"created","revision":"c1"}';
      case 'PATCH /api/profiles/coder':
        expect(headers?['If-Match'], profileRevision);
        name = (payload as Map)['name'] as String;
        profileRevision = 'p2';
        return jsonEncode({
          'id': 'coder',
          'name': name,
          'revision': profileRevision,
        });
      case 'DELETE /api/profiles/created':
        expect(headers?['If-Match'], 'c1');
        created = false;
        return '{"id":"created","deleted":true}';
      case 'PUT /api/providers/synthetic/credential':
        configured = true;
        return jsonEncode({'data': provider});
      case 'DELETE /api/providers/synthetic/credential':
        configured = false;
        return jsonEncode({'data': provider});
      case 'POST /api/providers/synthetic/credential/validate':
        return '{"ok":true,"detail":"Synthetic accepted token=redact-me /home/example/private"}';
      case 'POST /api/models/refresh':
        return jsonEncode({'catalog': catalog});
      case 'PUT /api/models/assignment':
        expect(headers?['If-Match'], modelRevision);
        final values = payload as Map;
        if (values['scope'] == 'auxiliary') {
          auxiliary.add({
            for (final k in ['task', 'provider', 'model'])
              k: values[k] as String,
          });
        }
        modelRevision = 'm${int.parse(modelRevision.substring(1)) + 1}';
        return jsonEncode(assignment);
      default:
        throw StateError('Unhandled fixture mutation: $key');
    }
  }

  Future<void> open(WidgetTester tester, String route) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await channel.connect(baseUrl: 'http://localhost:8642');
    await channel.selectProfile('coder');
    container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(
          FakeHermesEndpointStore(profiles: const []),
        ),
      ],
    );
    router = container.read(routerProvider)..go(route);
    addTearDown(channel.dispose);
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String route) async {
    router.go(route);
    await tester.pumpAndSettle();
  }

  int get writes => requests.where((r) => r.method != 'GET').length;
  Map<String, int> get counts {
    final result = {'writes': writes};
    for (final r in requests) {
      result.update(
        '${r.method} ${r.uri.path}',
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }
    return result;
  }
}

Finder managementKey(String value) => find.byKey(ValueKey(value));
Future<void> managementTap(WidgetTester tester, Finder control) async {
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  await tester.tap(control);
  await tester.pumpAndSettle();
}

/// Nothing is published until every journey has reached its terminal assertions.
class ManagementCases {
  final rows = <Map<String, Object?>>[];
  late String root;

  void requireIsolation() {
    if (!Platform.isLinux) throw StateError('Linux GTK required');
    root = requireLinuxTestRoot('wing-linux-qualification-');
    for (final entry in {
      'HOME': 'home',
      'XDG_DATA_HOME': 'data',
      'XDG_CACHE_HOME': 'cache',
    }.entries) {
      if (Platform.environment[entry.key] != '$root/${entry.value}') {
        throw StateError('Isolated state required');
      }
    }
  }

  void record(
    String id,
    List<String> features,
    List<String> routes,
    ManagementFixture f, {
    int owners = 1,
    String? unsupported,
    Map<String, int>? counts,
  }) {
    rows.add({
      'id': 'management.$id',
      'feature_ids': features,
      'route_ids': routes,
      'backend': 'synthetic-transport-production-api-channel',
      'input': 'framework-with-mock-text-input',
      'storage': 'mock-preferences-and-endpoint-store',
      'status': unsupported == null ? 'pass' : 'unsupported',
      if (unsupported != null) ...{
        'skip_reason': unsupported,
        'negative_assertion': true,
      },
      'native_pid': pid,
      'owner_count': owners,
      'operation_counts': counts ?? f.counts,
    });
  }

  Future<void> publish(WidgetTester tester) async {
    await tester.runAsync(() async {
      final partial = File('$root/feature-cases.json.partial');
      await partial.writeAsString(
        jsonEncode({'schema': 1, 'cases': rows}),
        flush: true,
      );
      await partial.rename('$root/feature-cases.json');
      // The driver must observe the still-live GTK PID, not infer it from a log.
      await Future<void>.delayed(const Duration(seconds: 1));
    });
  }
}
