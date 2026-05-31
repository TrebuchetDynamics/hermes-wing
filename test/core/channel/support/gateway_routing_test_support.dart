import 'dart:convert';
import 'dart:io';

const gatewayTestToken = 'nvbx_test_token';

const gormesProfileContact = <String, Object?>{
  'server_id': 'local-gormes',
  'profile_id': 'mineru',
  'display_name': 'Mineru Ops',
  'server_label': 'local',
  'health': 'online',
  'latest_preview': 'Gateway online',
  'latest_preview_kind': 'status',
  'workspace_root_count': 2,
  'workspace_roots_ok': true,
  'workspace_roots_warning': 0,
  'workspace_roots_error': 0,
  'attention_badges': <String>[],
  'mic_available': true,
  'active_turn_state': 'idle',
};

const gormesProfileRoute = <String, Object?>{
  'profile_id': 'mineru',
  'display_name': 'Mineru Ops',
  'workspaces': ['/srv/gormes', '/srv/navivox'],
  'providers': ['openai-codex', 'ollama'],
  'channels': ['navivox', 'telegram'],
};

Map<String, Object?> gatewayRoutingCapabilityDocument() {
  return {
    'object': 'gormes.navivox.capabilities',
    'protocol_version': 'navivox.v1',
    'capabilities': ['profile_contacts', 'profile_routing', 'stream_turns'],
    'auth': {
      'mode': 'pairing_token',
      'headers': ['Authorization: Bearer <token>'],
      'websocket_protocols': ['navivox.v1'],
    },
    'health': {
      'canonical': '/healthz',
      'aliases': ['/healthz'],
      'auth': 'none',
    },
    'endpoints': [
      {
        'method': 'GET',
        'path': '/v1/navivox/capabilities',
        'auth': 'navivox',
        'stability': 'stable',
        'description': 'Capability document',
      },
      {
        'method': 'GET',
        'path': '/v1/navivox/profile-contacts',
        'auth': 'navivox',
        'stability': 'stable',
        'description': 'Profile contacts',
      },
      {
        'method': 'GET',
        'path': '/v1/navivox/profile-routing',
        'auth': 'navivox',
        'stability': 'stable',
        'description': 'Profile routing',
      },
      {
        'method': 'WS',
        'path': '/v1/navivox/stream',
        'auth': 'navivox',
        'stability': 'stable',
        'description': 'Navivox stream',
      },
    ],
    'profile_management': {
      'contacts_endpoint': '/v1/navivox/profile-contacts',
      'routing_endpoint': '/v1/navivox/profile-routing',
      'create_from_seed_endpoint': '/v1/navivox/profile-seed',
      'dashboard_api_exposed': false,
      'supported_actions': ['contact_snapshot'],
      'unsupported_actions': ['direct_dashboard_api_profiles'],
      'profile_contract_parts': ['profile_contacts', 'profile_routing'],
    },
    'attachments': {
      'max_request_bytes': 1048576,
      'opaque_upload_ids': false,
      'raw_local_paths_accepted': false,
      'workspace_file_attach': false,
      'mime_allowlist': <String>[],
      'retention': 'not_accepted',
    },
    'voice': {
      'device_transcribed_text_turns': true,
      'raw_audio_upload': false,
      'voice_profiles_endpoint': '/v1/navivox/voice-profiles',
      'run_records_endpoint': '/v1/navivox/run-records/{run_id_or_session_id}',
      'stt_providers': ['device'],
      'tts_providers': ['server'],
    },
    'streams': {
      'canonical_endpoint': '/v1/navivox/stream',
      'transport': 'websocket',
      'event_kinds': ['session_started', 'assistant_message', 'done'],
      'openai_runs_bridge': false,
    },
  };
}

bool isAuthorizedGatewayRequest(HttpRequest request) {
  return request.headers.value(HttpHeaders.authorizationHeader) ==
      'Bearer $gatewayTestToken';
}

void writeGatewayJson(HttpResponse response, Map<String, Object?> body) {
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  response.close();
}
