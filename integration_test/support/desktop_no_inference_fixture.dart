import 'dart:async';
import 'dart:convert';

import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/client/hermes_api_config.dart';
import 'package:wing/core/hermes/client/hermes_api_transport.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';

final class SyntheticReadDenial implements HermesApiStatusException {
  const SyntheticReadDenial(this.statusCode);
  @override
  final int statusCode;
  @override
  String toString() => 'Synthetic HTTP $statusCode read denial';
}

/// Synthetic read authority only. No sockets, credentials or provider adapters.
class DesktopNoInferenceFixture {
  static const origin = 'https://example.invalid';
  static const profile = 'synthetic-qa';
  static const session = 'synthetic-history';
  final requests = <Map<String, Object?>>[];
  Completer<String>? held;
  bool failHistory = false;
  int? deniedHistoryStatus;
  int? deniedBootstrapStatus;
  final deniedReads = <Map<String, Object?>>[];
  bool wrongOwner = false;
  int mutationAttempts = 0;

  String history(String id) => jsonEncode({
    'object': 'list',
    'session_id': wrongOwner ? 'other-session' : id,
    'data': [
      {
        'id': 'synthetic-message-$id',
        'session_id': wrongOwner ? 'other-session' : id,
        'role': 'assistant',
        'content': 'Synthetic history $id',
      },
    ],
    'pagination': {'limit': 500, 'offset': 0, 'order': 'latest', 'returned': 1},
  });

  Future<String> get(Uri uri, Map<String, String> headers) async {
    if (uri.origin != origin || headers.containsKey('Authorization')) {
      throw StateError('Only credential-free synthetic reads permitted');
    }
    if (requests.length >= 256) throw StateError('Read receipt bound exceeded');
    requests.add({
      'method': 'GET',
      'path': uri.path,
      'query': uri.queryParameters,
    });
    if (uri.path == '/health') return '{"status":"ok"}';
    if (uri.path == '/v1/capabilities' && deniedBootstrapStatus != null) {
      deniedReads.add({
        'status': deniedBootstrapStatus,
        'path': uri.path,
        'profile': uri.queryParameters['profile'],
      });
      throw SyntheticReadDenial(deniedBootstrapStatus!);
    }
    if (uri.path == '/v1/capabilities') {
      return jsonEncode({
        'schema_version': 1,
        'profile_context': {
          'type': 'query',
          'name': 'profile',
          'required': true,
          'default_profile_id': 'default',
        },
        'auth': {
          'type': 'bearer',
          'required': false,
          'granted_scopes': ['profiles:read', 'sessions:read'],
        },
        'features': <String, bool>{},
        'endpoints': {
          for (final entry in {
            'profiles': '/api/profiles',
            'sessions': '/api/sessions',
            'session': '/api/sessions/{session_id}',
            'session_messages': '/api/sessions/{session_id}/messages',
          }.entries)
            entry.key: {
              'method': 'GET',
              'path': entry.value,
              'required_scopes': [
                entry.key == 'profiles' ? 'profiles:read' : 'sessions:read',
              ],
              'profile_scoped': entry.key != 'profiles',
            },
        },
      });
    }
    if (uri.path == '/api/profiles') {
      return jsonEncode({
        'data': [
          {'id': profile, 'name': 'Synthetic QA', 'revision': 'qa-1'},
        ],
      });
    }
    if (!{'default', profile}.contains(uri.queryParameters['profile'])) {
      throw StateError('Explicit synthetic owner required');
    }
    Map<String, Object> row(String id) => {
      'id': id,
      'source': 'api_server',
      'title': id,
      'profile_id': profile,
      'message_count': 1,
    };
    if (uri.path == '/api/sessions') {
      return jsonEncode({
        'data': [row('synthetic-first'), row(session)],
      });
    }
    for (final id in ['synthetic-first', session]) {
      if (uri.path == '/api/sessions/$id') return jsonEncode(row(id));
      if (uri.path == '/api/sessions/$id/messages') {
        if (id == session && deniedHistoryStatus != null) {
          deniedReads.add({
            'status': deniedHistoryStatus,
            'path': uri.path,
            'profile': uri.queryParameters['profile'],
          });
          throw SyntheticReadDenial(deniedHistoryStatus!);
        }
        if (id == session && held != null) {
          final gate = held!;
          held = null;
          return gate.future;
        }
        if (id == session && failHistory) {
          throw StateError('Synthetic read failure');
        }
        return history(id);
      }
    }
    throw StateError('Unexpected synthetic read route');
  }

  void deny() {
    mutationAttempts++;
  }

  HermesApiClient client(HermesApiConfig config) => HermesApiClient(
    config: config,
    get: get,
    post: (uri, headers, body) {
      deny();
      return unsupportedHermesApiPost(uri, headers, body);
    },
    patch: (uri, headers, body) {
      deny();
      return unsupportedHermesApiPatch(uri, headers, body);
    },
    put: (uri, headers, body) {
      deny();
      return unsupportedHermesApiPut(uri, headers, body);
    },
    delete: (uri, headers) {
      deny();
      return unsupportedHermesApiDelete(uri, headers);
    },
    postStream: (uri, headers, body) {
      deny();
      return unsupportedHermesApiPostStream(uri, headers, body);
    },
    getStream: unsupportedHermesApiGetStream,
  );
}

class DesktopNoInferenceStore extends EmptyHermesEndpointStore {
  const DesktopNoInferenceStore();
  @override
  Future<List<HermesEndpointConfig>> loadProfiles() async => [
    const HermesEndpointConfig(
      id: 'synthetic-endpoint',
      label: 'Synthetic QA',
      baseUrl: DesktopNoInferenceFixture.origin,
    ),
  ];
}
