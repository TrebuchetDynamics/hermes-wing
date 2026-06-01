export 'durable_reconnect_readiness_contract.dart';

import '../../protocol/navivox_json.dart';
import '../shared/navivox_gateway_constants.dart';
import '../shared/navivox_gateway_json.dart';
import '../shared/navivox_gateway_membership.dart';
import 'durable_reconnect_readiness_contract.dart';
import 'navivox_gateway_capability_support.dart';

/// Status response from the Navivox gateway health/status endpoint.
class NavivoxGatewayStatus {
  const NavivoxGatewayStatus({
    required this.enabled,
    required this.protocolVersion,
    required this.websocketProtocols,
    required this.capabilities,
    required this.sessionCount,
    required this.webSocketConnectionCount,
    this.capabilitiesUrl,
    this.gatewayId,
  });

  factory NavivoxGatewayStatus.fromJson(Map<String, Object?> json) {
    return NavivoxGatewayStatus(
      enabled: navivoxGatewayBoolField(json, 'enabled'),
      protocolVersion: navivoxStringFromJson(
        json['protocol_version'],
        fallback: navivoxWebSocketProtocol,
      ),
      websocketProtocols: navivoxStringListFromJson(
        json['websocket_protocols'],
      ),
      capabilities: navivoxStringListFromJson(json['capabilities']),
      sessionCount: navivoxIntFromJson(json['sessions']),
      webSocketConnectionCount: navivoxIntFromJson(json['ws_connections']),
      capabilitiesUrl: navivoxOptionalStringFromJson(json['capabilities_url']),
      gatewayId: navivoxOptionalStringFromJson(json['gateway_id']),
    );
  }

  final bool enabled;
  final String protocolVersion;
  final List<String> websocketProtocols;
  final List<String> capabilities;
  final int sessionCount;
  final int webSocketConnectionCount;
  final String? capabilitiesUrl;
  final String? gatewayId;

  bool get hasGatewayIdentity => navivoxGatewayHasText(gatewayId);

  bool supports(String capability) {
    return navivoxGatewaySupportsCapability(capabilities, capability);
  }
}

/// Parsed capability document from the gateway.
class NavivoxCapabilityDocument {
  const NavivoxCapabilityDocument({
    required this.object,
    required this.protocolVersion,
    required this.capabilities,
    required this.auth,
    required this.healthAliases,
    required this.endpoints,
    required this.profileManagement,
    required this.attachments,
    required this.voice,
    required this.streams,
    required this.durableReconnect,
  });

  factory NavivoxCapabilityDocument.fromJson(Map<String, Object?> json) {
    return NavivoxCapabilityDocument(
      object: navivoxStringFieldFromJson(json, 'object'),
      protocolVersion: navivoxStringFieldFromJson(json, 'protocol_version'),
      capabilities: navivoxStringListFromJson(json['capabilities']),
      auth: navivoxGatewayObjectFromField(
        json,
        'auth',
        NavivoxCapabilityAuth.fromJson,
      ),
      healthAliases: navivoxStringListFromJson(
        navivoxMapFieldFromJson(json, 'health')['aliases'],
      ),
      endpoints: navivoxGatewayObjectListFromJson(
        json['endpoints'],
        NavivoxCapabilityEndpoint.fromJson,
      ),
      profileManagement: navivoxGatewayObjectFromField(
        json,
        'profile_management',
        NavivoxProfileManagementCapability.fromJson,
      ),
      attachments: navivoxGatewayObjectFromField(
        json,
        'attachments',
        NavivoxAttachmentCapability.fromJson,
      ),
      voice: navivoxGatewayObjectFromField(
        json,
        'voice',
        NavivoxVoiceProtocolCapability.fromJson,
      ),
      streams: navivoxGatewayObjectFromField(
        json,
        'streams',
        NavivoxStreamCapability.fromJson,
      ),
      durableReconnect: navivoxGatewayObjectFromField(
        json,
        'durable_reconnect',
        NavivoxDurableReconnectCapability.fromJson,
      ),
    );
  }

  final String object;
  final String protocolVersion;
  final List<String> capabilities;
  final NavivoxCapabilityAuth auth;
  final List<String> healthAliases;
  final List<NavivoxCapabilityEndpoint> endpoints;
  final NavivoxProfileManagementCapability profileManagement;
  final NavivoxAttachmentCapability attachments;
  final NavivoxVoiceProtocolCapability voice;
  final NavivoxStreamCapability streams;
  final NavivoxDurableReconnectCapability durableReconnect;

  bool supports(String capability) {
    return navivoxGatewaySupportsCapability(capabilities, capability);
  }

  bool advertisesEndpoint(String method, String path) {
    return endpoints.any(
      (endpoint) => endpoint.method == method && endpoint.path == path,
    );
  }
}

class NavivoxDurableReconnectCapability {
  const NavivoxDurableReconnectCapability({
    required this.supported,
    required this.issueEndpoint,
    required this.authMethods,
    required this.platforms,
    required this.effectiveSecurity,
    required this.blockedReason,
  });

  factory NavivoxDurableReconnectCapability.fromJson(
    Map<String, Object?> json,
  ) {
    return NavivoxDurableReconnectCapability(
      supported: navivoxGatewayBoolField(json, 'supported'),
      issueEndpoint: navivoxStringFieldFromJson(json, 'issue_endpoint'),
      authMethods: navivoxStringListFromJson(json['auth_methods']),
      platforms: navivoxStringListFromJson(json['platforms']),
      effectiveSecurity: navivoxStringFieldFromJson(json, 'effective_security'),
      blockedReason: navivoxStringFieldFromJson(json, 'blocked_reason'),
    );
  }

  final bool supported;
  final String issueEndpoint;
  final List<String> authMethods;
  final List<String> platforms;
  final String effectiveSecurity;
  final String blockedReason;

  DurableReconnectReadinessContract get readinessContract =>
      DurableReconnectReadinessContract(
        supported: supported,
        issueEndpoint: issueEndpoint,
        authMethods: authMethods,
        platforms: platforms,
        effectiveSecurity: effectiveSecurity,
        blockedReason: blockedReason,
      );

  List<String> get missingIssueContractFields =>
      readinessContract.missingIssueContractFields;

  String? get readinessRecoveryMessage => readinessContract.recoveryMessage;

  ReconnectReadinessKind get readinessKind => readinessContract.kind;
}

class NavivoxCapabilityAuth {
  const NavivoxCapabilityAuth({
    required this.mode,
    required this.headers,
    required this.webSocketProtocols,
  });

  factory NavivoxCapabilityAuth.fromJson(Map<String, Object?> json) {
    return NavivoxCapabilityAuth(
      mode: navivoxStringFieldFromJson(json, 'mode'),
      headers: navivoxStringListFromJson(json['headers']),
      webSocketProtocols: navivoxStringListFromJson(
        json['websocket_protocols'],
      ),
    );
  }

  final String mode;
  final List<String> headers;
  final List<String> webSocketProtocols;
}

class NavivoxCapabilityEndpoint {
  const NavivoxCapabilityEndpoint({
    required this.method,
    required this.path,
    required this.auth,
    required this.stability,
    required this.description,
  });

  factory NavivoxCapabilityEndpoint.fromJson(Map<String, Object?> json) {
    return NavivoxCapabilityEndpoint(
      method: navivoxStringFieldFromJson(json, 'method'),
      path: navivoxStringFieldFromJson(json, 'path'),
      auth: navivoxStringFieldFromJson(json, 'auth'),
      stability: navivoxStringFieldFromJson(json, 'stability'),
      description: navivoxStringFieldFromJson(json, 'description'),
    );
  }

  final String method;
  final String path;
  final String auth;
  final String stability;
  final String description;
}

class NavivoxStreamCapability {
  const NavivoxStreamCapability({
    required this.canonicalEndpoint,
    required this.transport,
    required this.eventKinds,
    required this.openAiRunsBridge,
  });

  factory NavivoxStreamCapability.fromJson(Map<String, Object?> json) {
    return NavivoxStreamCapability(
      canonicalEndpoint: navivoxStringFieldFromJson(json, 'canonical_endpoint'),
      transport: navivoxStringFieldFromJson(json, 'transport'),
      eventKinds: navivoxStringListFromJson(json['event_kinds']),
      openAiRunsBridge: navivoxGatewayBoolField(json, 'openai_runs_bridge'),
    );
  }

  final String canonicalEndpoint;
  final String transport;
  final List<String> eventKinds;
  final bool openAiRunsBridge;
}

class NavivoxProfileManagementCapability {
  const NavivoxProfileManagementCapability({
    required this.contactsEndpoint,
    required this.routingEndpoint,
    required this.createFromSeedEndpoint,
    required this.dashboardApiExposed,
    required this.supportedActions,
    required this.unsupportedActions,
    required this.profileContractParts,
  });

  factory NavivoxProfileManagementCapability.fromJson(
    Map<String, Object?> json,
  ) {
    return NavivoxProfileManagementCapability(
      contactsEndpoint: navivoxStringFieldFromJson(json, 'contacts_endpoint'),
      routingEndpoint: navivoxStringFieldFromJson(json, 'routing_endpoint'),
      createFromSeedEndpoint: navivoxStringFieldFromJson(
        json,
        'create_from_seed_endpoint',
      ),
      dashboardApiExposed: navivoxGatewayBoolField(
        json,
        'dashboard_api_exposed',
      ),
      supportedActions: navivoxStringListFromJson(json['supported_actions']),
      unsupportedActions: navivoxStringListFromJson(
        json['unsupported_actions'],
      ),
      profileContractParts: navivoxStringListFromJson(
        json['profile_contract_parts'],
      ),
    );
  }

  final String contactsEndpoint;
  final String routingEndpoint;
  final String createFromSeedEndpoint;
  final bool dashboardApiExposed;
  final List<String> supportedActions;
  final List<String> unsupportedActions;
  final List<String> profileContractParts;

  bool supportsAction(String action) {
    return navivoxGatewayContainsAdvertisedToken(supportedActions, action);
  }
}

class NavivoxAttachmentCapability {
  const NavivoxAttachmentCapability({
    required this.maxRequestBytes,
    required this.opaqueUploadIds,
    required this.rawLocalPathsAccepted,
    required this.workspaceFileAttach,
    required this.mimeAllowlist,
    required this.retention,
  });

  factory NavivoxAttachmentCapability.fromJson(Map<String, Object?> json) {
    return NavivoxAttachmentCapability(
      maxRequestBytes: navivoxIntFromJson(json['max_request_bytes']),
      opaqueUploadIds: navivoxGatewayBoolField(json, 'opaque_upload_ids'),
      rawLocalPathsAccepted: navivoxGatewayBoolField(
        json,
        'raw_local_paths_accepted',
      ),
      workspaceFileAttach: navivoxGatewayBoolField(
        json,
        'workspace_file_attach',
      ),
      mimeAllowlist: navivoxStringListFromJson(json['mime_allowlist']),
      retention: navivoxStringFieldFromJson(json, 'retention'),
    );
  }

  final int maxRequestBytes;
  final bool opaqueUploadIds;
  final bool rawLocalPathsAccepted;
  final bool workspaceFileAttach;
  final List<String> mimeAllowlist;
  final String retention;

  bool get uploadsAvailable =>
      opaqueUploadIds && !rawLocalPathsAccepted && mimeAllowlist.isNotEmpty;
}

class NavivoxVoiceProtocolCapability {
  const NavivoxVoiceProtocolCapability({
    required this.deviceTranscribedTextTurns,
    required this.rawAudioUpload,
    required this.voiceProfilesEndpoint,
    required this.runRecordsEndpoint,
    required this.sttProviders,
    required this.ttsProviders,
  });

  factory NavivoxVoiceProtocolCapability.fromJson(Map<String, Object?> json) {
    return NavivoxVoiceProtocolCapability(
      deviceTranscribedTextTurns: navivoxGatewayBoolField(
        json,
        'device_transcribed_text_turns',
      ),
      rawAudioUpload: navivoxGatewayBoolField(json, 'raw_audio_upload'),
      voiceProfilesEndpoint: navivoxStringFieldFromJson(
        json,
        'voice_profiles_endpoint',
      ),
      runRecordsEndpoint: navivoxStringFieldFromJson(
        json,
        'run_records_endpoint',
      ),
      sttProviders: navivoxStringListFromJson(json['stt_providers']),
      ttsProviders: navivoxStringListFromJson(json['tts_providers']),
    );
  }

  final bool deviceTranscribedTextTurns;
  final bool rawAudioUpload;
  final String voiceProfilesEndpoint;
  final String runRecordsEndpoint;
  final List<String> sttProviders;
  final List<String> ttsProviders;
}
