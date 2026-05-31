import '../connection_import_parser.dart';

void main() {
  parsesValidCorePairingDescriptor();
  parsesGenericTokenUrlOutsideCoreDescriptorProtocol();
  preservesGenericUrlMetadataWhenBaseUrlComesFromUrlOrigin();
  preservesGenericWebSocketUrlImports();
  prefersCompleteJsonEntryOverEarlierPartialCandidate();
  parsesSharedTextTokenWithSpacedSeparator();
  rejectsMalformedCorePairingDescriptorBeforeGenericFallback();
  rejectsCorePairingDescriptorWithHttpWebSocketUrl();
  rejectsCorePairingDescriptorWithNonHttpBaseUrl();
}

void parsesValidCorePairingDescriptor() {
  final result = parseNavivoxConnectionImportPayload(
    'navivox://connect?websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fws&rest_token=nvbx_ok&server_id=srv&profile_id=profile',
  );

  _expect(result != null, 'valid navivox://connect descriptor should parse');
  _expect(
    result!.baseUrl == 'http://127.0.0.1:8765',
    'baseUrl derived from websocket_url',
  );
  _expect(
    result.webSocketUrl == 'ws://127.0.0.1:8765/ws',
    'webSocketUrl preserved',
  );
  _expect(result.token == 'nvbx_ok', 'rest_token preserved');
  _expect(result.serverId == 'srv', 'server_id preserved');
  _expect(result.profileId == 'profile', 'profile_id preserved');
}

void parsesGenericTokenUrlOutsideCoreDescriptorProtocol() {
  final result = parseNavivoxConnectionImportPayload(
    'https://gateway.example/connect?token=nvbx_generic',
  );

  _expect(result != null, 'generic URL import should still parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'generic URL baseUrl normalized',
  );
  _expect(result.token == 'nvbx_generic', 'generic token preserved');
}

void preservesGenericUrlMetadataWhenBaseUrlComesFromUrlOrigin() {
  final result = parseNavivoxConnectionImportPayload(
    'https://gateway.example/connect?server_id=srv&profile_id=profile',
  );

  _expect(result != null, 'generic URL metadata import should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'URL origin provides baseUrl',
  );
  _expect(result.serverId == 'srv', 'server_id should be preserved');
  _expect(result.profileId == 'profile', 'profile_id should be preserved');
}

void preservesGenericWebSocketUrlImports() {
  final result = parseNavivoxConnectionImportPayload(
    'wss://gateway.example/navivox/ws?token=nvbx_generic',
  );

  _expect(result != null, 'generic websocket URL import should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'generic websocket URL should derive HTTP baseUrl',
  );
  _expect(
    result.webSocketUrl ==
        'wss://gateway.example/navivox/ws?token=nvbx_generic',
    'generic websocket URL should be preserved',
  );
  _expect(result.token == 'nvbx_generic', 'generic websocket token preserved');
}

void prefersCompleteJsonEntryOverEarlierPartialCandidate() {
  final result = parseNavivoxConnectionImportPayload(
    '{"entries":[{"token":"nvbx_token_only"},{"base_url":"https://gateway.example","token":"nvbx_complete","server_id":"srv"}]}',
  );

  _expect(result != null, 'JSON entries should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'later complete entries should not be hidden by earlier partial candidates',
  );
  _expect(
    result.token == 'nvbx_complete',
    'complete entry token should be preserved',
  );
  _expect(result.serverId == 'srv', 'complete entry metadata should be kept');
}

void parsesSharedTextTokenWithSpacedSeparator() {
  final result = parseNavivoxConnectionImportPayload(
    'Server: https://gateway.example/connect\nToken = shared_secret',
  );

  _expect(result != null, 'shared text import should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'shared text URL origin should provide baseUrl',
  );
  _expect(
    result.token == 'shared_secret',
    'token labels should allow spaces before separators',
  );
}

void rejectsMalformedCorePairingDescriptorBeforeGenericFallback() {
  final result = parseNavivoxConnectionImportPayload(
    'navivox://connect?rest_token=nvbx_token_only',
  );

  _expect(
    result == null,
    'malformed navivox://connect descriptors must be rejected instead of '
    'falling back to a token-only generic import',
  );
}

void rejectsCorePairingDescriptorWithHttpWebSocketUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'navivox://connect?websocket_url=https%3A%2F%2Fgateway.example%2Fws&rest_token=nvbx_ok',
  );

  _expect(
    result == null,
    'core pairing websocket_url must be a ws/wss endpoint, not an HTTP URL',
  );
}

void rejectsCorePairingDescriptorWithNonHttpBaseUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'navivox://connect?websocket_url=ws%3A%2F%2Fgateway.example%2Fws&base_url=ftp%3A%2F%2Fgateway.example&rest_token=nvbx_ok',
  );

  _expect(
    result == null,
    'core pairing base_url must be an HTTP(S) endpoint, not an arbitrary URI',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
