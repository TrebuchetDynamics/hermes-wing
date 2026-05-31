import '../connection_import_parser.dart';

void main() {
  parsesValidCorePairingDescriptor();
  parsesGenericTokenUrlOutsideCoreDescriptorProtocol();
  preservesGenericUrlMetadataWhenBaseUrlComesFromUrlOrigin();
  preservesGenericUrlRepeatedQueryValuesAfterBlankCopyArtifacts();
  preservesMetadataFromUrlEmbeddedInSharedText();
  preservesGenericWebSocketUrlImports();
  prefersCompleteJsonEntryOverEarlierPartialCandidate();
  prefersRicherJsonEntryOverEarlierMinimallyCompleteCandidate();
  doesNotPreferIncompleteMetadataEntryOverCompleteConnectionEntry();
  appliesTopLevelJsonConnectionDefaultsToEntries();
  prefersEntryOverrideWhenTopLevelJsonDefaultIsAlsoImportable();
  parsesSharedTextTokenWithSpacedSeparator();
  parsesSharedTextTokenWrappedInQuotes();
  stripsSentenceTrailingPeriodFromSharedTextUrl();
  rejectsMalformedCorePairingDescriptorBeforeGenericFallback();
  rejectsCorePairingDescriptorWithHttpWebSocketUrl();
  rejectsCorePairingDescriptorWithNonHttpBaseUrl();
  doesNotTreatInvalidJsonWebSocketUrlAsBaseUrl();
  doesNotTreatUnsupportedJsonBaseUrlSchemeAsBaseUrl();
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

void preservesGenericUrlRepeatedQueryValuesAfterBlankCopyArtifacts() {
  final result = parseNavivoxConnectionImportPayload(
    'https://gateway.example/connect?token=nvbx_ok&token=&server_id=srv',
  );

  _expect(
    result != null,
    'generic URL with repeated query fields should parse',
  );
  _expect(result!.token == 'nvbx_ok', 'first nonblank repeated token wins');
  _expect(result.serverId == 'srv', 'metadata beside repeated fields is kept');
}

void preservesMetadataFromUrlEmbeddedInSharedText() {
  final result = parseNavivoxConnectionImportPayload(
    'Open https://gateway.example/connect?server_id=srv&profile_id=profile to finish setup.',
  );

  _expect(result != null, 'embedded generic URL import should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'embedded generic URL origin should provide baseUrl',
  );
  _expect(
    result.serverId == 'srv',
    'embedded generic URL server_id should be preserved',
  );
  _expect(
    result.profileId == 'profile',
    'embedded generic URL profile_id should be preserved',
  );
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

void prefersRicherJsonEntryOverEarlierMinimallyCompleteCandidate() {
  final result = parseNavivoxConnectionImportPayload(
    '{"entries":[{"base_url":"https://gateway.example","token":"nvbx_minimal"},{"base_url":"https://gateway.example","token":"nvbx_richer","server_id":"srv","profile_id":"profile"}]}',
  );

  _expect(result != null, 'JSON entries should parse');
  _expect(
    result!.token == 'nvbx_richer',
    'later richer complete entry should not be hidden by earlier minimal complete entry',
  );
  _expect(result.serverId == 'srv', 'richer server_id should be preserved');
  _expect(
    result.profileId == 'profile',
    'richer profile_id should be preserved',
  );
}

void doesNotPreferIncompleteMetadataEntryOverCompleteConnectionEntry() {
  final result = parseNavivoxConnectionImportPayload(
    '{"entries":[{"base_url":"https://gateway.example","token":"nvbx_complete"},{"base_url":"https://gateway.example","websocket_url":"wss://gateway.example/ws","server_id":"srv","profile_id":"profile"}]}',
  );

  _expect(result != null, 'JSON entries should parse');
  _expect(
    result!.token == 'nvbx_complete',
    'complete baseUrl+token candidates must outrank metadata-rich incomplete candidates',
  );
}

void appliesTopLevelJsonConnectionDefaultsToEntries() {
  final result = parseNavivoxConnectionImportPayload(
    '{"base_url":"https://gateway.example","entries":[{"token":"nvbx_entry","server_id":"srv","profile_id":"profile"}]}',
  );

  _expect(result != null, 'JSON entries should parse with top-level defaults');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'entry import should inherit top-level base_url',
  );
  _expect(result.token == 'nvbx_entry', 'entry token should be preserved');
  _expect(result.serverId == 'srv', 'entry server_id should be preserved');
  _expect(
    result.profileId == 'profile',
    'entry profile_id should be preserved',
  );
}

void prefersEntryOverrideWhenTopLevelJsonDefaultIsAlsoImportable() {
  final result = parseNavivoxConnectionImportPayload(
    '{"base_url":"https://gateway.example","token":"nvbx_stale_default","entries":[{"token":"nvbx_fresh_entry"}]}',
  );

  _expect(result != null, 'JSON entry with importable defaults should parse');
  _expect(
    result!.token == 'nvbx_fresh_entry',
    'nonblank entry fields should override equally complete top-level defaults',
  );
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

void parsesSharedTextTokenWrappedInQuotes() {
  final result = parseNavivoxConnectionImportPayload(
    'Server: https://gateway.example/connect\nToken: "shared_secret"',
  );

  _expect(result != null, 'quoted shared text import should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'quoted shared text URL origin should provide baseUrl',
  );
  _expect(
    result.token == 'shared_secret',
    'token labels should allow copied quote delimiters around tokens',
  );
}

void stripsSentenceTrailingPeriodFromSharedTextUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'Server: https://gateway.example. Token: shared_secret',
  );

  _expect(result != null, 'shared sentence import should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'sentence punctuation after a copied URL should not become part of the baseUrl',
  );
  _expect(result.token == 'shared_secret', 'shared text token should parse');
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

void doesNotTreatInvalidJsonWebSocketUrlAsBaseUrl() {
  final result = parseNavivoxConnectionImportPayload(
    '{"websocket_url":"https://gateway.example/ws","token":"nvbx_token"}',
  );

  _expect(result != null, 'token-only JSON import should still parse');
  _expect(result!.token == 'nvbx_token', 'token should be preserved');
  _expect(
    result.webSocketUrl == null,
    'HTTP websocket_url values are not valid websocket endpoints',
  );
  _expect(
    result.baseUrl == null,
    'invalid websocket_url values must not be promoted to a baseUrl',
  );
}

void doesNotTreatUnsupportedJsonBaseUrlSchemeAsBaseUrl() {
  final result = parseNavivoxConnectionImportPayload(
    '{"base_url":"ftp://gateway.example","token":"nvbx_token"}',
  );

  _expect(result != null, 'token-only JSON import should still parse');
  _expect(result!.token == 'nvbx_token', 'token should be preserved');
  _expect(
    result.baseUrl == null,
    'unsupported base_url schemes must not be promoted to a connection baseUrl',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
