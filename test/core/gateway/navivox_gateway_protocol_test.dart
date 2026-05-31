import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';

void main() {
  test('constructs HTTP and WebSocket URLs from one base URL', () {
    final config = NavivoxGatewayConfig.fromBaseUrl(
      'https://gromit.tailnet.test:8765',
      token: 'nvbx_test_token',
    );

    expect(
      config.healthUri.toString(),
      'https://gromit.tailnet.test:8765/healthz',
    );
    expect(
      config.statusUri.toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/status',
    );
    expect(
      config.turnUri.toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/turn',
    );
    expect(
      config.profileContactsUri.toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/profile-contacts',
    );
    expect(
      config
          .memoryOverviewUri(serverId: 'local', profileId: 'mineru')
          .toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/memory/overview?server_id=local&profile_id=mineru',
    );
    expect(
      config
          .memorySearchUri(
            serverId: 'local',
            profileId: 'mineru',
            query: 'agent memory',
            type: NavivoxMemoryType.memoryItems,
            limit: 10,
          )
          .toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/memory/search?server_id=local&profile_id=mineru&q=agent+memory&type=memory_items&limit=10',
    );
    expect(
      config
          .memoryDetailUri(
            serverId: 'local',
            profileId: 'mineru',
            id: 'mem-1',
            type: NavivoxMemoryType.memoryItems,
          )
          .toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/memory/detail?server_id=local&profile_id=mineru&id=mem-1&type=memory_items',
    );
    expect(
      config.memoryActionUri.toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/memory/action',
    );
    expect(
      config.sessionUri('s/1').toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/sessions/s%2F1',
    );
    expect(
      config.runRecordUri('run 1').toString(),
      'https://gromit.tailnet.test:8765/v1/navivox/run-records/run%201',
    );
    expect(
      config.streamUri.toString(),
      'wss://gromit.tailnet.test:8765/v1/navivox/stream',
    );
    expect(config.headers, {'Authorization': 'Bearer nvbx_test_token'});
  });

  test('builds shared gateway auth header and websocket protocols', () {
    final headers = {
      navivoxGatewayAuthorizationHeader: navivoxGatewayBearerAuthorization(
        ' nvbx:test ',
      ),
    };

    expect(headers, {'Authorization': 'Bearer nvbx:test'});
    expect(
      navivoxGatewayBearerToken({'authorization': 'Bearer nvbx:test'}),
      'nvbx:test',
    );
    expect(navivoxGatewayWebSocketProtocols(headers), [
      navivoxWebSocketProtocol,
      '${navivoxWebSocketTokenProtocolPrefix}bnZieDp0ZXN0',
    ]);
    expect(navivoxGatewayWebSocketProtocols(const {}), [
      navivoxWebSocketProtocol,
    ]);
    expect(navivoxGatewayContentTypeHeader, 'Content-Type');
    expect(navivoxGatewayJsonContentType, 'application/json');
    expect(
      navivoxGatewayHttpStatusMessage(503),
      'Navivox gateway returned HTTP 503',
    );
  });

  test('parses Gormes pairing descriptor into gateway config', () {
    final descriptor = NavivoxPairingDescriptor.parse(
      'navivox://connect?'
      'base_url=http%3A%2F%2F127.0.0.1%3A8765&'
      'websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fv1%2Fnavivox%2Fstream&'
      'auth_mode=pairing_token&'
      'exposure_mode=local&'
      'token_required=true&'
      'rest_token=setup-secret-token',
    );

    expect(descriptor.baseUri.toString(), 'http://127.0.0.1:8765');
    expect(
      descriptor.webSocketUri.toString(),
      'ws://127.0.0.1:8765/v1/navivox/stream',
    );
    expect(descriptor.authMode, 'pairing_token');
    expect(descriptor.exposureMode, 'local');
    expect(descriptor.tokenRequired, isTrue);
    expect(descriptor.token, 'setup-secret-token');

    final config = descriptor.toGatewayConfig();
    expect(config.baseUri.toString(), 'http://127.0.0.1:8765');
    expect(config.streamUri.toString(), descriptor.webSocketUri.toString());
    expect(config.headers, {'Authorization': 'Bearer setup-secret-token'});
  });

  test('parses optional Gormes routing defaults from pairing descriptor', () {
    final descriptor = NavivoxPairingDescriptor.parse(
      'navivox://connect?'
      'base_url=http%3A%2F%2F127.0.0.1%3A8765&'
      'websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fv1%2Fnavivox%2Fstream&'
      'auth_mode=pairing_token&'
      'exposure_mode=local&'
      'token_required=true&'
      'rest_token=setup-secret-token&'
      'server_id=local&'
      'profile_id=mineru&'
      'workspace_id=gormes-agent&'
      'provider_id=openai-codex&'
      'channel_ids=telegram%2Cnavivox%2Cdiscord',
    );

    expect(descriptor.serverId, 'local');
    expect(descriptor.profileId, 'mineru');
    expect(descriptor.workspaceId, 'gormes-agent');
    expect(descriptor.providerId, 'openai-codex');
    expect(descriptor.channelIds, ['telegram', 'navivox', 'discord']);
  });

  test('preserves explicit pairing websocket URL in gateway config', () {
    final descriptor = NavivoxPairingDescriptor.parse(
      'navivox://connect?'
      'base_url=https%3A%2F%2Fgateway.example%3A8765&'
      'websocket_url=wss%3A%2F%2Fstream.example%3A9443%2Fcustom%2Fnavivox%2Fstream&'
      'auth_mode=pairing_token&'
      'token_required=true&'
      'rest_token=setup-secret-token',
    );

    final config = descriptor.toGatewayConfig();

    expect(config.baseUri.toString(), 'https://gateway.example:8765');
    expect(
      config.streamUri.toString(),
      'wss://stream.example:9443/custom/navivox/stream',
    );
    expect(config.headers, {'Authorization': 'Bearer setup-secret-token'});
  });

  test('derives base URI from websocket-only pairing descriptor', () {
    final descriptor = NavivoxPairingDescriptor.parse(
      'navivox://connect?'
      'websocket_url=wss%3A%2F%2Fgateway.example%3A8765%2Fv1%2Fnavivox%2Fstream&'
      'auth_mode=pairing_token&'
      'token_required=true&'
      'rest_token=setup-secret-token',
    );

    expect(descriptor.baseUri.toString(), 'https://gateway.example:8765');
    expect(
      descriptor.webSocketUri.toString(),
      'wss://gateway.example:8765/v1/navivox/stream',
    );
    expect(
      descriptor.toGatewayConfig().baseUri.toString(),
      'https://gateway.example:8765',
    );
  });

  test('builds typed gateway messages', () {
    final start = NavivoxGatewayMessage.startTurn(
      requestId: 'req-1',
      sessionId: 's-1',
      text: 'hello',
    );
    expect(start.body['type'], 'start_turn');
    expect(start.body['request_id'], 'req-1');
    expect(start.body['session_id'], 's-1');
    expect(start.body['text'], 'hello');

    final ping = NavivoxGatewayMessage.ping(requestId: 'req-ping');
    expect(jsonEncode(ping.body), '{"type":"ping","request_id":"req-ping"}');
  });

  test('parses typed gateway events', () {
    final event = NavivoxGatewayEvent.fromJson({
      'type': 'tool_call_finished',
      'request_id': 'req-2',
      'session_id': 's-2',
      'tool_name': 'read_file',
      'tool_call_id': 'tool-1',
      'status': 'ok',
    });

    expect(event.type, 'tool_call_finished');
    expect(event.requestId, 'req-2');
    expect(event.sessionId, 's-2');
    expect(event.toolName, 'read_file');
    expect(event.toolCallId, 'tool-1');
    expect(event.status, 'ok');
    expect(event.isError, isFalse);
  });

  test('parses safety and approval event fields', () {
    final warning = NavivoxGatewayEvent.fromJson({
      'type': 'safety_warning',
      'request_id': 'req-safe',
      'session_id': 's-safe',
      'safety_id': 'safe-1',
      'severity': 'high',
      'message': 'Shell command wants to modify files',
      'risk': 'Writes may change the workspace',
    });
    expect(warning.safetyId, 'safe-1');
    expect(warning.severity, 'high');
    expect(warning.message, 'Shell command wants to modify files');
    expect(warning.risk, 'Writes may change the workspace');

    final approval = NavivoxGatewayEvent.fromJson({
      'type': 'approval_required',
      'request_id': 'req-safe',
      'session_id': 's-safe',
      'approval_id': 'approval-1',
      'tool_call_id': 'call-shell',
      'message': 'Approve shell.run?',
      'risk': 'Command can edit files',
    });
    expect(approval.approvalId, 'approval-1');
    expect(approval.toolCallId, 'call-shell');
    expect(approval.message, 'Approve shell.run?');
    expect(approval.risk, 'Command can edit files');
  });

  test('client sends auth headers and decodes status capabilities', () async {
    final seen = <Uri, Map<String, String>>{};
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      get: (uri, headers) async {
        seen[uri] = headers;
        return jsonEncode({
          'enabled': true,
          'protocol_version': 'navivox.v1',
          'websocket_protocols': ['navivox.v1'],
          'capabilities': ['profile_contacts', 'stream_turns', 'turn_control'],
          'capabilities_url': '/v1/navivox/capabilities',
          'gateway_id': 'gw_123',
          'sessions': 2,
          'ws_connections': 1,
        });
      },
    );

    final status = await client.gatewayStatus();

    expect(status.enabled, isTrue);
    expect(status.protocolVersion, 'navivox.v1');
    expect(status.websocketProtocols, ['navivox.v1']);
    expect(status.supports('capability_document'), isFalse);
    expect(status.supports('profile_contacts'), isTrue);
    expect(status.supports('turn_control'), isTrue);
    expect(status.sessionCount, 2);
    expect(status.webSocketConnectionCount, 1);
    expect(status.capabilitiesUrl, '/v1/navivox/capabilities');
    expect(status.gatewayId, 'gw_123');
    expect(status.hasGatewayIdentity, isTrue);
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/status',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
  });

  test('client decodes Navivox capability document', () async {
    final seen = <Uri, Map<String, String>>{};
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      get: (uri, headers) async {
        seen[uri] = headers;
        return jsonEncode({
          'object': 'gormes.navivox.capabilities',
          'protocol_version': 'navivox.v1',
          'capabilities': ['profile_contacts', 'profile_seed'],
          'auth': {
            'mode': 'pairing_token',
            'headers': ['Authorization: Bearer <token>'],
            'websocket_protocols': [
              'navivox.v1',
              'gormes.navivox.token.<base64url-token>',
            ],
          },
          'health': {
            'canonical': '/healthz',
            'aliases': ['/healthz'],
          },
          'endpoints': [
            {
              'method': 'GET',
              'path': '/v1/navivox/capabilities',
              'auth': 'navivox',
              'stability': 'stable',
              'description': 'Versioned Navivox capability document',
            },
            {
              'method': 'POST',
              'path': '/v1/navivox/profile-seed',
              'auth': 'navivox',
              'stability': 'stable',
              'description': 'Draft or apply a profile from operator text',
            },
          ],
          'profile_management': {
            'contacts_endpoint': '/v1/navivox/profile-contacts',
            'routing_endpoint': '/v1/navivox/profile-routing',
            'create_from_seed_endpoint': '/v1/navivox/profile-seed',
            'dashboard_api_exposed': false,
            'supported_actions': ['contact_snapshot', 'create_from_seed'],
            'unsupported_actions': ['direct_dashboard_api_profiles'],
            'profile_contract_parts': [
              'profile_contacts',
              'profile_routing',
              'voice_profiles',
            ],
          },
          'attachments': {
            'max_request_bytes': 1048576,
            'opaque_upload_ids': false,
            'raw_local_paths_accepted': false,
            'workspace_file_attach': false,
            'mime_allowlist': [],
            'retention': 'not_accepted',
          },
          'voice': {
            'device_transcribed_text_turns': true,
            'raw_audio_upload': false,
            'voice_profiles_endpoint': '/v1/navivox/voice-profiles',
            'run_records_endpoint':
                '/v1/navivox/run-records/{run_id_or_session_id}',
            'stt_providers': ['device'],
            'tts_providers': ['server'],
          },
          'streams': {
            'canonical_endpoint': '/v1/navivox/stream',
            'transport': 'websocket',
            'event_kinds': ['profile_contact_update', 'done'],
            'openai_runs_bridge': false,
          },
          'durable_reconnect': {
            'supported': true,
            'issue_endpoint': '/v1/navivox/device-credentials',
            'auth_methods': ['device_key_challenge'],
            'platforms': ['android'],
            'effective_security': 'loopback',
          },
        });
      },
    );

    final capabilities = await client.capabilities();

    expect(capabilities.object, 'gormes.navivox.capabilities');
    expect(capabilities.protocolVersion, 'navivox.v1');
    expect(capabilities.supports('profile_seed'), isTrue);
    expect(capabilities.auth.mode, 'pairing_token');
    expect(capabilities.auth.headers, ['Authorization: Bearer <token>']);
    expect(capabilities.auth.webSocketProtocols, [
      'navivox.v1',
      'gormes.navivox.token.<base64url-token>',
    ]);
    expect(capabilities.healthAliases, ['/healthz']);
    expect(
      capabilities.advertisesEndpoint('POST', '/v1/navivox/profile-seed'),
      isTrue,
    );
    expect(
      capabilities.endpoints.last.description,
      'Draft or apply a profile from operator text',
    );
    expect(capabilities.profileManagement.dashboardApiExposed, isFalse);
    expect(
      capabilities.profileManagement.supportsAction('create_from_seed'),
      isTrue,
    );
    expect(capabilities.profileManagement.profileContractParts, [
      'profile_contacts',
      'profile_routing',
      'voice_profiles',
    ]);
    expect(capabilities.attachments.uploadsAvailable, isFalse);
    expect(capabilities.attachments.retention, 'not_accepted');
    expect(capabilities.voice.deviceTranscribedTextTurns, isTrue);
    expect(capabilities.voice.rawAudioUpload, isFalse);
    expect(
      capabilities.voice.runRecordsEndpoint,
      '/v1/navivox/run-records/{run_id_or_session_id}',
    );
    expect(capabilities.streams.canonicalEndpoint, '/v1/navivox/stream');
    expect(capabilities.streams.transport, 'websocket');
    expect(capabilities.streams.eventKinds, ['profile_contact_update', 'done']);
    expect(capabilities.streams.openAiRunsBridge, isFalse);
    expect(capabilities.durableReconnect.supported, isTrue);
    expect(
      capabilities.durableReconnect.issueEndpoint,
      '/v1/navivox/device-credentials',
    );
    expect(capabilities.durableReconnect.authMethods, ['device_key_challenge']);
    expect(capabilities.durableReconnect.platforms, ['android']);
    expect(capabilities.durableReconnect.effectiveSecurity, 'loopback');
    expect(
      capabilities.durableReconnect.readinessKind,
      ReconnectReadinessKind.available,
    );
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/capabilities',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
  });

  test(
    'client reads and validates voice profiles without secret payloads',
    () async {
      final seenGet = <Uri, Map<String, String>>{};
      final seenPost = <Uri, ({Map<String, String> headers, String body})>{};
      final config = NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      );
      final client = NavivoxGatewayClient(
        config: config,
        get: (uri, headers) async {
          seenGet[uri] = headers;
          return jsonEncode({
            'action': 'voice_profiles.get',
            'provider_matrix': {
              'stt': ['local', 'whisper'],
              'tts': ['openai', 'piper'],
            },
            'profiles': [
              {
                'profile_id': 'mineru',
                'display_name': 'Mineru Builder',
                'voice_profile': {
                  'stt_provider': 'local',
                  'tts_provider': 'openai',
                  'voice_id': 'alloy',
                  'language_policy': 'match_user_language',
                  'fallback_voice': 'text_only',
                },
                'credential_status_refs': {
                  'stt': {
                    'configured': true,
                    'required': true,
                    'status': 'configured',
                    'source': 'profile_voice_profile.stt_credential',
                  },
                  'tts': {
                    'configured': false,
                    'required': true,
                    'status': 'missing',
                  },
                },
                'valid': true,
              },
            ],
          });
        },
        post: (uri, headers, body) async {
          seenPost[uri] = (headers: headers, body: body);
          return jsonEncode({
            'action': 'voice_profiles.validate',
            'provider_matrix': {
              'stt': ['local', 'whisper'],
              'tts': ['openai', 'piper'],
            },
            'valid': true,
            'validation': {
              'profile_id': 'mineru',
              'voice_profile': {
                'stt_provider': 'local',
                'tts_provider': 'piper',
                'voice_id': 'amy',
                'language_policy': 'match_user_language',
                'fallback_voice': 'text_only',
              },
              'valid': true,
            },
          });
        },
      );

      final profiles = await client.voiceProfiles();
      final validation = await client.validateVoiceProfile(
        profileId: ' mineru ',
        voiceProfile: const NavivoxProfileVoiceProfile(
          sttProvider: ' local ',
          ttsProvider: ' piper ',
          voiceId: ' amy ',
          languagePolicy: ' match_user_language ',
          fallbackVoice: ' text_only ',
        ),
      );

      expect(
        config.voiceProfilesUri.toString(),
        'http://127.0.0.1:8765/v1/navivox/voice-profiles',
      );
      expect(
        config.voiceProfilesValidateUri.toString(),
        'http://127.0.0.1:8765/v1/navivox/voice-profiles/validate',
      );
      expect(profiles.profiles.single.profileId, 'mineru');
      expect(profiles.profiles.single.voiceProfile.ttsProvider, 'openai');
      expect(
        profiles.profiles.single.credentialStatusRefs['stt']?.configured,
        isTrue,
      );
      expect(profiles.providerMatrix.ttsProviders, ['openai', 'piper']);
      expect(validation.valid, isTrue);
      expect(validation.validation?.voiceProfile.voiceId, 'amy');
      expect(
        seenGet.keys.single.toString(),
        'http://127.0.0.1:8765/v1/navivox/voice-profiles',
      );
      expect(seenGet.values.single['Authorization'], 'Bearer nvbx_test_token');
      expect(
        seenPost.keys.single.toString(),
        'http://127.0.0.1:8765/v1/navivox/voice-profiles/validate',
      );
      expect(jsonDecode(seenPost.values.single.body), {
        'profile_id': 'mineru',
        'voice_profile': {
          'stt_provider': 'local',
          'tts_provider': 'piper',
          'voice_id': 'amy',
          'language_policy': 'match_user_language',
          'fallback_voice': 'text_only',
        },
      });
      expect(seenPost.values.single.body, isNot(contains('credential')));
      expect(seenPost.values.single.body, isNot(contains('secret')));
    },
  );

  test(
    'client reads validates and applies safe config admin with redacted results',
    () async {
      final seenGet = <Uri, Map<String, String>>{};
      final seenPost = <Uri, ({Map<String, String> headers, String body})>{};
      final config = NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      );
      final client = NavivoxGatewayClient(
        config: config,
        get: (uri, headers) async {
          seenGet[uri] = headers;
          if (uri.path.endsWith('/schema')) {
            return jsonEncode({
              'action': 'config.schema',
              'fields': [
                {
                  'key': 'navivox.port',
                  'type': 'int',
                  'title': 'Port',
                  'reload': 'restart_or_reload',
                },
                {
                  'key': 'navivox.token',
                  'type': 'secret',
                  'title': 'Pairing/static token',
                  'secret': true,
                  'actions': ['set', 'rotate', 'delete', 'test'],
                  'reload': 'restart_or_reload',
                },
              ],
            });
          }
          return jsonEncode({
            'action': 'config.get',
            'values': [
              {
                'key': 'navivox.port',
                'type': 'int',
                'value': 8765,
                'secret': false,
              },
              {
                'key': 'navivox.token',
                'type': 'secret',
                'secret': true,
                'secret_status': 'set',
                'source': 'env:GORMES_NAVIVOX_TOKEN',
              },
            ],
          });
        },
        post: (uri, headers, body) async {
          seenPost[uri] = (headers: headers, body: body);
          if (uri.path.endsWith('/apply')) {
            return jsonEncode({
              'action': 'config.apply',
              'valid': true,
              'applied': true,
              'reload_applied': true,
              'pending_restart': false,
              'changes': [
                {
                  'key': 'navivox.port',
                  'type': 'int',
                  'before': 8765,
                  'after': 8766,
                },
                {
                  'key': 'navivox.token',
                  'type': 'secret',
                  'secret': true,
                  'before_redacted': true,
                  'after_redacted': true,
                  'secret_status': 'set',
                },
              ],
            });
          }
          return jsonEncode({
            'action': uri.path.endsWith('/diff')
                ? 'config.diff'
                : 'config.validate',
            'valid': true,
            'changes': [
              {
                'key': 'navivox.port',
                'type': 'int',
                'before': 8765,
                'after': 8766,
              },
            ],
          });
        },
      );

      final schema = await client.configAdminSchema();
      final values = await client.configAdminValues();
      final validation = await client.validateConfigAdmin([
        const NavivoxConfigAdminChange(key: ' navivox.port ', value: 8766),
      ]);
      final diff = await client.diffConfigAdmin([
        const NavivoxConfigAdminChange(key: 'navivox.port', value: 8766),
      ]);
      final applied = await client.applyConfigAdmin([
        const NavivoxConfigAdminChange(key: 'navivox.port', value: 8766),
        const NavivoxConfigAdminChange(
          key: 'navivox.token',
          value: 'new-secret-token',
        ),
      ]);

      expect(
        config.configAdminUri.toString(),
        'http://127.0.0.1:8765/v1/navivox/config-admin',
      );
      expect(
        config.configAdminSchemaUri.toString(),
        'http://127.0.0.1:8765/v1/navivox/config-admin/schema',
      );
      expect(
        config.configAdminDiffUri.toString(),
        'http://127.0.0.1:8765/v1/navivox/config-admin/diff',
      );
      expect(
        config.configAdminValidateUri.toString(),
        'http://127.0.0.1:8765/v1/navivox/config-admin/validate',
      );
      expect(
        config.configAdminApplyUri.toString(),
        'http://127.0.0.1:8765/v1/navivox/config-admin/apply',
      );
      expect(schema.fields.last.secret, isTrue);
      expect(schema.fields.last.actions, ['set', 'rotate', 'delete', 'test']);
      expect(values.values.last.value, isNull);
      expect(values.values.last.secretStatus, 'set');
      expect(values.values.last.source, 'env:GORMES_NAVIVOX_TOKEN');
      expect(validation.valid, isTrue);
      expect(diff.changes.single.after, 8766);
      expect(applied.applied, isTrue);
      expect(applied.reloadApplied, isTrue);
      expect(applied.changes.last.afterRedacted, isTrue);
      expect(applied.snapshot.toString(), isNot(contains('new-secret-token')));
      expect(
        seenGet.keys.map((uri) => uri.toString()),
        containsAll([
          'http://127.0.0.1:8765/v1/navivox/config-admin/schema',
          'http://127.0.0.1:8765/v1/navivox/config-admin',
        ]),
      );
      expect(
        seenPost[config.configAdminValidateUri]?.body,
        jsonEncode({
          'changes': [
            {'key': 'navivox.port', 'value': '8766'},
          ],
        }),
      );
      expect(
        seenPost[config.configAdminApplyUri]?.body,
        contains('new-secret-token'),
      );
      expect(
        seenPost.values.every(
          (entry) => entry.headers['Authorization'] == 'Bearer nvbx_test_token',
        ),
        isTrue,
      );
    },
  );

  test('client decodes session snapshots and run records', () async {
    final seen = <Uri>[];
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      get: (uri, headers) async {
        seen.add(uri);
        expect(headers['Authorization'], 'Bearer nvbx_test_token');
        if (uri.path == '/v1/navivox/sessions') {
          return jsonEncode({
            'sessions': [
              {
                'session_id': 's-1',
                'last_request_id': 'req-1',
                'profile_server': 'local',
                'profile_id': 'mineru',
                'created_at': '2026-05-24T10:00:00Z',
                'updated_at': '2026-05-24T10:01:00Z',
                'subscribers': 2,
              },
              {'session_id': ''},
            ],
          });
        }
        if (uri.toString().endsWith('/v1/navivox/sessions/s%2F1')) {
          return jsonEncode({
            'session': {
              'session_id': 's/1',
              'profile_id': 'ops',
              'created_at': '2026-05-24T11:00:00Z',
              'updated_at': '2026-05-24T11:00:30Z',
            },
          });
        }
        if (uri.toString().endsWith('/v1/navivox/run-records/run%201')) {
          return jsonEncode({
            'run_record': {
              'run_id': 'run 1',
              'session_id': 's/1',
              'status': 'completed',
              'created_at': '2026-05-24T11:00:00Z',
              'updated_at': '2026-05-24T11:01:00Z',
              'completed_at': '2026-05-24T11:01:00Z',
              'provider_usage': {'status': 'available', 'total_tokens': 12},
            },
          });
        }
        throw StateError('unexpected uri $uri');
      },
    );

    final sessions = await client.sessions();
    final session = await client.session('s/1');
    final record = await client.runRecord('run 1');

    expect(sessions, hasLength(1));
    expect(sessions.single.sessionId, 's-1');
    expect(sessions.single.lastRequestId, 'req-1');
    expect(sessions.single.profileServer, 'local');
    expect(sessions.single.profileId, 'mineru');
    expect(sessions.single.subscribers, 2);
    expect(
      sessions.single.createdAt?.toUtc().toIso8601String(),
      startsWith('2026-05-24T10:00:00.000Z'),
    );
    expect(session.sessionId, 's/1');
    expect(session.profileId, 'ops');
    expect(record.runId, 'run 1');
    expect(record.sessionId, 's/1');
    expect(record.status, 'completed');
    expect(record.completedAt, isNotNull);
    expect((record.raw['provider_usage'] as Map)['total_tokens'], 12);
    expect(seen.map((uri) => uri.toString()), [
      'http://127.0.0.1:8765/v1/navivox/sessions',
      'http://127.0.0.1:8765/v1/navivox/sessions/s%2F1',
      'http://127.0.0.1:8765/v1/navivox/run-records/run%201',
    ]);
  });

  test('client omits blank profile seed workspace roots', () async {
    String? body;
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl('http://127.0.0.1:8765'),
      post: (uri, headers, requestBody) async {
        body = requestBody;
        return jsonEncode({
          'action': 'profile_seed_draft',
          'status': 'draft',
          'draft': {'profile_id': 'mineru'},
        });
      },
    );

    final result = await client.profileSeed(
      seed: ' mineru ',
      workspaceRoots: [' ', '\t'],
    );

    expect(result.isDraft, isTrue);
    expect(jsonDecode(body!), {'seed': 'mineru'});
  });

  test(
    'client posts profile seed drafts and applies explicit workspaces',
    () async {
      final seen = <Uri, ({Map<String, String> headers, String body})>{};
      final client = NavivoxGatewayClient(
        config: NavivoxGatewayConfig.fromBaseUrl(
          'http://127.0.0.1:8765',
          token: 'nvbx_test_token',
        ),
        post: (uri, headers, body) async {
          seen[uri] = (headers: headers, body: body);
          return jsonEncode({
            'action': 'profile_seed_applied',
            'status': 'applied',
            'applied': true,
            'profile_id': 'work-mineru-repo',
            'root': '.../work-mineru-repo',
            'workspace_count': 1,
            'draft': {
              'profile_id': 'work-mineru-repo',
              'generation_source': 'template',
            },
            'contact': {
              'profile_id': 'work-mineru-repo',
              'display_name': 'Work Mineru Repo',
            },
          });
        },
      );

      final result = await client.profileSeed(
        seed: ' work on mineru repo ',
        apply: true,
        workspaceRoots: [' /repo/mineru ', ''],
      );

      expect(result.isApplied, isTrue);
      expect(result.profileId, 'work-mineru-repo');
      expect(result.root, '.../work-mineru-repo');
      expect(result.workspaceCount, 1);
      expect(result.draft['generation_source'], 'template');
      expect(result.contact['display_name'], 'Work Mineru Repo');
      expect(
        seen.keys.single.toString(),
        'http://127.0.0.1:8765/v1/navivox/profile-seed',
      );
      expect(
        seen.values.single.headers['Authorization'],
        'Bearer nvbx_test_token',
      );
      expect(seen.values.single.headers['Content-Type'], 'application/json');
      expect(jsonDecode(seen.values.single.body), {
        'seed': 'work on mineru repo',
        'apply': true,
        'workspace_roots': ['/repo/mineru'],
      });
    },
  );

  test('client decodes authenticated profile routing report', () async {
    final seen = <Uri, Map<String, String>>{};
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      get: (uri, headers) async {
        seen[uri] = headers;
        return jsonEncode({
          'profiles': [
            {
              'profile_id': 'mineru',
              'display_name': 'Mineru Ops',
              'workspaces': ['/srv/gormes', '/srv/navivox'],
              'providers': ['openai-codex', 'ollama'],
              'channels': ['navivox', 'telegram'],
            },
          ],
        });
      },
    );

    final routing = await client.profileRouting();

    expect(routing.profiles, hasLength(1));
    final profile = routing.profiles.single;
    expect(profile.profileId, 'mineru');
    expect(profile.displayName, 'Mineru Ops');
    expect(profile.workspaces, ['/srv/gormes', '/srv/navivox']);
    expect(profile.providers, ['openai-codex', 'ollama']);
    expect(profile.channels, ['navivox', 'telegram']);
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/profile-routing',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
  });

  test(
    'client decodes authenticated memory overview with safe DB label',
    () async {
      final seen = <Uri, Map<String, String>>{};
      final client = NavivoxGatewayClient(
        config: NavivoxGatewayConfig.fromBaseUrl(
          'http://127.0.0.1:8765',
          token: 'nvbx_test_token',
        ),
        get: (uri, headers) async {
          seen[uri] = headers;
          return jsonEncode({
            'profile_id': 'mineru',
            'workspace_id': 'gormes',
            'database_path': '/home/xel/.gormes/profiles/mineru/memory.db',
            'health': 'active',
            'last_updated_at': '2026-05-21T15:28:18.000Z',
            'counts': {
              'turns': 120,
              'memory_items': 12,
              'observations': 34,
              'conclusions': 5,
              'session_summaries': 7,
              'entities': 18,
              'relationships': 21,
            },
          });
        },
      );

      final overview = await client.memoryOverview(
        serverId: 'local',
        profileId: 'mineru',
      );

      expect(overview.profileId, 'mineru');
      expect(overview.workspaceId, 'gormes');
      expect(overview.health, NavivoxMemoryHealth.active);
      expect(overview.totalTurns, 120);
      expect(overview.activeMemoryItems, 12);
      expect(overview.databaseLabel, '~/.gormes/profiles/mineru/memory.db');
      expect(overview.databaseLabel, isNot(contains('/home/xel')));
      expect(
        seen.keys.single.toString(),
        'http://127.0.0.1:8765/v1/navivox/memory/overview?server_id=local&profile_id=mineru',
      );
      expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
    },
  );

  test('client decodes authenticated memory search results', () async {
    final seen = <Uri, Map<String, String>>{};
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      get: (uri, headers) async {
        seen[uri] = headers;
        return jsonEncode({
          'items': [
            {
              'id': 'mem-1',
              'type': 'memory_items',
              'snippet': 'Mineru uses Goncho memory for workspace recall.',
              'timestamp': '2026-05-21T15:30:00Z',
              'session_id': 's-1',
              'peer_id': 'mineru',
              'status': 'current',
              'tags': ['workspace', 'recall'],
              'score': 0.92,
            },
          ],
          'next_page_token': 'cursor-2',
        });
      },
    );

    final result = await client.memorySearch(
      serverId: 'local',
      profileId: 'mineru',
      query: 'Goncho memory',
      type: NavivoxMemoryType.memoryItems,
      limit: 10,
    );

    expect(result.items, hasLength(1));
    expect(result.items.single.id, 'mem-1');
    expect(result.items.single.type, NavivoxMemoryType.memoryItems);
    expect(result.items.single.snippet, contains('Goncho memory'));
    expect(result.items.single.tags, ['workspace', 'recall']);
    expect(result.nextPageToken, 'cursor-2');
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/memory/search?server_id=local&profile_id=mineru&q=Goncho+memory&type=memory_items&limit=10',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
  });

  test('client decodes authenticated memory detail safely', () async {
    final seen = <Uri, Map<String, String>>{};
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      get: (uri, headers) async {
        seen[uri] = headers;
        return jsonEncode({
          'id': 'mem-1',
          'type': 'memory_items',
          'content': 'Mineru uses Goncho memory for workspace recall.',
          'source': 'goncho_memory_items',
          'session_id': 's-1',
          'peer_id': 'mineru',
          'created_at': '2026-05-21T15:30:00Z',
          'status': 'current',
          'tags': ['workspace'],
          'provenance': 'derived from reviewed session s-1',
          'linked_entities': ['Mineru', 'Goncho'],
          'linked_relationships': ['Mineru RELATED_TO Goncho'],
        });
      },
    );

    final detail = await client.memoryDetail(
      serverId: 'local',
      profileId: 'mineru',
      id: 'mem-1',
      type: NavivoxMemoryType.memoryItems,
    );

    expect(detail.id, 'mem-1');
    expect(detail.type, NavivoxMemoryType.memoryItems);
    expect(detail.content, contains('workspace recall'));
    expect(detail.provenance, contains('reviewed session'));
    expect(detail.linkedEntities, ['Mineru', 'Goncho']);
    expect(detail.linkedRelationships, ['Mineru RELATED_TO Goncho']);
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/memory/detail?server_id=local&profile_id=mineru&id=mem-1&type=memory_items',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
  });

  test('client sends authenticated memory management actions safely', () async {
    final seen = <Uri, Map<String, String>>{};
    final bodies = <Map<String, Object?>>[];
    final client = NavivoxGatewayClient(
      config: NavivoxGatewayConfig.fromBaseUrl(
        'http://127.0.0.1:8765',
        token: 'nvbx_test_token',
      ),
      post: (uri, headers, body) async {
        seen[uri] = headers;
        bodies.add(Map<String, Object?>.from(jsonDecode(body) as Map));
        return jsonEncode({
          'accepted': true,
          'action': 'add_correction',
          'message': 'Correction added without mutating raw memory.',
          'raw_source_preserved': true,
        });
      },
    );

    final result = await client.memoryAction(
      serverId: 'local',
      profileId: 'mineru',
      id: 'mem-1',
      type: NavivoxMemoryType.memoryItems,
      action: NavivoxMemoryActionType.addCorrection,
      correction: 'Use Mineru profile memory only.',
    );

    expect(result.accepted, isTrue);
    expect(result.action, NavivoxMemoryActionType.addCorrection);
    expect(result.rawSourcePreserved, isTrue);
    expect(result.message, 'Correction added without mutating raw memory.');
    expect(
      seen.keys.single.toString(),
      'http://127.0.0.1:8765/v1/navivox/memory/action',
    );
    expect(seen.values.single['Authorization'], 'Bearer nvbx_test_token');
    expect(seen.values.single['Content-Type'], 'application/json');
    expect(bodies.single, {
      'server_id': 'local',
      'profile_id': 'mineru',
      'id': 'mem-1',
      'type': 'memory_items',
      'action': 'add_correction',
      'correction': 'Use Mineru profile memory only.',
    });
  });

  test(
    'client decodes WebSocket event stream and exposes bounded backoff',
    () async {
      final client = NavivoxGatewayClient(
        config: NavivoxGatewayConfig.fromBaseUrl('http://127.0.0.1:8765'),
      );
      final stream = Stream<dynamic>.fromIterable([
        '{"type":"pong","request_id":"req-ping"}',
        {'type': 'error', 'code': 'bad_request', 'message': 'Invalid JSON'},
      ]);

      final events = await client.decodeEvents(stream).toList();

      expect(events.first.type, 'pong');
      expect(events.first.requestId, 'req-ping');
      expect(events.last.isError, isTrue);
      expect(events.last.code, 'bad_request');
      expect(client.reconnectDelay(0), const Duration(milliseconds: 250));
      expect(client.reconnectDelay(10), const Duration(seconds: 16));
    },
  );
}
