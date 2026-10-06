import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';

import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

const target = GatewayContactSelection(
  contactId: GatewayContactId(gatewayId: 'alpha', profileId: 'coder'),
  sessionId: 'older-A',
);

class RecordingSelectionCache extends FakeGatewayContactCache {
  final saved = <GatewayContactSelection>[];
  @override
  Future<void> saveSelection(
    GatewayContactSelection selection, {
    bool Function()? canWrite,
  }) async {
    if (!(canWrite?.call() ?? true)) return;
    saved.add(selection);
    await super.saveSelection(selection, canWrite: canWrite);
  }
}

class RestorationHarness {
  RestorationHarness({this.loaded = false}) {
    cache.selection = target;
    channel = HermesApiChannel(
      clientBuilder: (config) => HermesApiClient(
        config: config,
        get: (uri, headers) async {
          reads.add(uri);
          expect(
            headers['Authorization'],
            uri.host == 'beta.example'
                ? 'Bearer synthetic-beta'
                : 'Bearer synthetic-agent',
          );
          final profile = uri.queryParameters['profile'];
          final intercepted = await onRead?.call(uri);
          if (intercepted != null) return intercepted;
          switch (uri.path) {
            case '/health':
              return '{"status":"ok"}';
            case '/v1/capabilities':
              final document = <String, Object?>{
                'schema_version': 1,
                'profile_context': {
                  'type': 'query',
                  'name': 'profile',
                  'required': true,
                  'default_profile_id': 'default',
                },
                'auth': {
                  'granted_scopes': ['sessions:read'],
                },
                'endpoints': {
                  'session': {
                    'method': 'GET',
                    'path': '/api/sessions/{session_id}',
                    'required_scopes': ['sessions:read'],
                  },
                  'session_messages': {
                    'method': 'GET',
                    'path': '/api/sessions/{session_id}/messages',
                    'required_scopes': ['sessions:read'],
                  },
                },
              };
              configureCapabilities?.call(document);
              return jsonEncode(document);
            case '/api/sessions':
              return jsonEncode({
                'data': [
                  {'id': 'newer-B', 'source': 'api_server'},
                  if (loaded) {'id': 'older-A', 'source': 'api_server'},
                ],
                'pagination': {
                  'offset': 0,
                  'limit': 50,
                  'has_more': true,
                  'next_offset': 50,
                },
              });
            case '/api/sessions/older-A':
              expect(profile, isNotNull);
              return '{"object":"hermes.session","session":{"id":"older-A","source":"api_server"}}';
            case '/api/sessions/older-A/messages':
              expect(profile, isNotNull);
              expect(uri.queryParameters['limit'], '500');
              expect(uri.queryParameters['order'], 'latest');
              return '{"object":"list","session_id":"older-A","data":[{"id":"canonical-A","session_id":"older-A","role":"assistant","content":"Canonical older A"}]}';
            case '/api/sessions/newer-B/messages':
              return '{"object":"list","session_id":"newer-B","data":[{"id":"canonical-B","session_id":"newer-B","role":"assistant","content":"Canonical newer B"}]}';
            default:
              throw StateError('Unexpected synthetic read');
          }
        },
        post: (uri, headers, body) async {
          mutations.add(uri);
          throw StateError('Restoration must never mutate');
        },
      ),
    );
    directory = HermesGatewayDirectory(
      store: FakeHermesEndpointStore(
        profiles: const [
          HermesEndpointConfig(
            id: 'alpha',
            baseUrl: 'https://alpha.example',
            apiKey: 'synthetic-agent',
          ),
          HermesEndpointConfig(
            id: 'beta',
            baseUrl: 'https://beta.example',
            apiKey: 'synthetic-beta',
          ),
        ],
      ),
      cache: cache,
      loader: FakeGatewaySummaryLoader({
        'alpha': gatewaySummary(['default', 'coder']),
        'beta': gatewaySummary(['default', 'coder']),
      }),
      activeChannel: channel,
    );
  }
  final bool loaded;
  final cache = RecordingSelectionCache();
  final reads = <Uri>[];
  final mutations = <Uri>[];
  Future<String?> Function(Uri)? onRead;
  void Function(Map<String, Object?>)? configureCapabilities;
  bool disposed = false;
  late final HermesApiChannel channel;
  late final HermesGatewayDirectory directory;
  void dispose() {
    if (!disposed) directory.dispose();
    channel.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final loaded in [false, true]) {
    test(
      'startup restores exact older A (already loaded=$loaded) without B persistence',
      () async {
        final h = RestorationHarness(loaded: loaded);
        addTearDown(h.dispose);
        await h.directory.start();
        expect(h.channel.state.activeSessionId, 'older-A');
        expect(h.channel.state.selectedProfileId, 'coder');
        expect(h.channel.state.activeMessages.single.id, 'canonical-A');
        expect(
          h.reads
              .where((uri) => uri.path.startsWith('/api/sessions/older-A'))
              .every((uri) => uri.queryParameters['profile'] == 'coder'),
          isTrue,
        );
        expect(h.cache.selection!.sessionId, 'older-A');
        expect(
          h.cache.saved.map((s) => s.sessionId),
          isNot(contains('newer-B')),
        );
        expect(
          h.reads.where((u) => u.path == '/api/sessions/older-A').length,
          loaded ? 0 : 1,
        );
        expect(h.mutations, isEmpty);
      },
    );
  }
}
