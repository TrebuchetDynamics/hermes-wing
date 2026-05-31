import '../connection_import_parser.dart';

void main() {
  parsesValidCorePairingDescriptor();
  preservesRepeatedCorePairingQueryValues();
  preservesLegacyNavivoxConnectCompatibilityPayload();
  parsesGenericTokenUrlOutsideCoreDescriptorProtocol();
  preservesGenericUrlMetadataWhenBaseUrlComesFromUrlOrigin();
  preservesGenericUrlRepeatedQueryValuesAfterBlankCopyArtifacts();
  preservesTokenFromJsonWebSocketUrlQuery();
  preservesTokenFromJsonBaseUrlQuery();
  preservesMetadataFromUrlEmbeddedInSharedText();
  preservesWebSocketUrlEmbeddedInSharedText();
  parsesUppercaseSchemeUrlEmbeddedInSharedText();
  prefersEmbeddedUrlTokenOverEarlierStaleSharedTextToken();
  prefersTokenAfterSelectedEmbeddedUrlOverEarlierStaleSharedTextToken();
  prefersNearestLeadingTokenBeforeSelectedEmbeddedUrl();
  readsEarliestLabeledSharedTextTokenAfterSelectedUrl();
  prefersRicherEmbeddedUrlOverEarlierUnrelatedUrl();
  prefersLaterSharedTextUrlWhenTokenBelongsToThatUrl();
  prefersConnectionPathOverEarlierEqualRankMetadataUrl();
  doesNotBorrowTokenFromLaterSharedTextUrlWindow();
  doesNotBorrowTokenFromEarlierSharedTextUrlWindow();
  doesNotLetLabelBeforeLaterSharedTextUrlConsumeThatUrlAsToken();
  doesNotUseUrlAfterSharedTextTokenLabelAsToken();
  doesNotTreatSingleUrlAfterSharedTextTokenLabelAsToken();
  preservesGenericWebSocketUrlImports();
  prefersCompleteJsonEntryOverEarlierPartialCandidate();
  prefersRicherJsonEntryOverEarlierMinimallyCompleteCandidate();
  preservesFirstJsonEntryWhenCandidatesHaveEqualRank();
  doesNotPreferIncompleteMetadataEntryOverCompleteConnectionEntry();
  appliesTopLevelJsonConnectionDefaultsToEntries();
  prefersEntryOverrideWhenTopLevelJsonDefaultIsAlsoImportable();
  prefersEntryAliasOverrideOverTopLevelJsonDefaultAlias();
  doesNotLetBlankJsonEntryAliasInheritTopLevelDefaultAlias();
  doesNotLetCaseVariantBlankJsonEntryAliasInheritTopLevelDefaultAlias();
  doesNotLetMetadataOnlyJsonEntryStealDefaultCredentialsFromConcreteEntry();
  parsesSharedTextTokenWithSpacedSeparator();
  doesNotTreatTokenSuffixInDifferentLabelAsSharedTextToken();
  parsesSharedTextTokenWrappedInQuotes();
  parsesSharedTextTokenWrappedInBackticks();
  parsesSharedTextTokenWrappedInAngleBrackets();
  stripsSentenceTrailingPeriodFromSharedTextUrl();
  parsesSharedTextTokenAfterAttachedUrlPunctuation();
  stripsTrailingPunctuationFromPlainCopiedUrl();
  stripsAngleBracketFromPlainCopiedUrl();
  stripsBacktickFromPlainCopiedUrl();
  rejectsPunctuationOnlySharedTextToken();
  stripsAngleBracketFromSharedTextUrl();
  stripsBacktickFromSharedTextUrl();
  preservesBalancedParenthesesInSharedTextUrlPath();
  preservesBalancedParenthesesAtCopiedWebSocketUrlEnd();
  trimsOnlyUnmatchedTrailingParenthesisFromCopiedWebSocketUrl();
  rejectsMalformedCorePairingDescriptorBeforeGenericFallback();
  parsesValidCorePairingDescriptorEmbeddedInSharedText();
  parsesLaterValidCorePairingDescriptorAfterMalformedSharedTextDescriptor();
  rejectsSharedTextMalformedCoreDescriptorBeforeTokenFallback();
  doesNotBorrowTokenFromMalformedCoreDescriptorBeforeGenericSharedTextUrl();
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

void preservesRepeatedCorePairingQueryValues() {
  final result = parseNavivoxConnectionImportPayload(
    'navivox://connect?websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fws&websocket_url=&rest_token=nvbx_ok&rest_token=',
  );

  _expect(
    result != null,
    'core pairing descriptor with repeated blank copy artifacts should parse',
  );
  _expect(
    result!.webSocketUrl == 'ws://127.0.0.1:8765/ws',
    'first nonblank repeated websocket_url wins',
  );
  _expect(result.token == 'nvbx_ok', 'first nonblank repeated rest_token wins');
}

void preservesLegacyNavivoxConnectCompatibilityPayload() {
  final result = parseNavivoxConnectionImportPayload(
    'navivox://connect?base_url=http%3A%2F%2F10.0.2.2%3A8765&token=nvbx_uri_token',
  );

  _expect(
    result != null,
    'legacy navivox://connect compatibility payload should parse',
  );
  _expect(
    result!.baseUrl == 'http://10.0.2.2:8765',
    'legacy base_url should be preserved',
  );
  _expect(result.token == 'nvbx_uri_token', 'legacy token should be preserved');
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

void preservesTokenFromJsonWebSocketUrlQuery() {
  final result = parseNavivoxConnectionImportPayload(
    '{"websocket_url":"wss://gateway.example/navivox/ws?token=nvbx_json"}',
  );

  _expect(
    result != null,
    'JSON websocket_url imports with query credentials should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'JSON websocket_url should still derive the HTTP baseUrl',
  );
  _expect(
    result.webSocketUrl == 'wss://gateway.example/navivox/ws?token=nvbx_json',
    'JSON websocket_url should preserve the full websocket endpoint',
  );
  _expect(
    result.token == 'nvbx_json',
    'JSON websocket_url query token should not be dropped',
  );
}

void preservesTokenFromJsonBaseUrlQuery() {
  final result = parseNavivoxConnectionImportPayload(
    '{"base_url":"https://gateway.example/connect?token=nvbx_json_base"}',
  );

  _expect(
    result != null,
    'JSON base_url imports with query credentials should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'JSON base_url should normalize to the endpoint origin',
  );
  _expect(
    result.token == 'nvbx_json_base',
    'JSON base_url query token should not be dropped',
  );
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

void preservesWebSocketUrlEmbeddedInSharedText() {
  final result = parseNavivoxConnectionImportPayload(
    'Open wss://gateway.example/navivox/ws?token=nvbx_shared to finish setup.',
  );

  _expect(result != null, 'embedded websocket URL import should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'embedded websocket URL should derive HTTP baseUrl',
  );
  _expect(
    result.webSocketUrl == 'wss://gateway.example/navivox/ws?token=nvbx_shared',
    'embedded websocket URL should be preserved',
  );
  _expect(result.token == 'nvbx_shared', 'embedded websocket token preserved');
}

void parsesUppercaseSchemeUrlEmbeddedInSharedText() {
  final result = parseNavivoxConnectionImportPayload(
    'Open HTTPS://gateway.example/connect?token=nvbx_shared to finish setup.',
  );

  _expect(
    result != null,
    'embedded URLs should parse even when the copied scheme is uppercase',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'uppercase URL schemes should normalize to the endpoint origin',
  );
  _expect(
    result.token == 'nvbx_shared',
    'uppercase URL schemes should still preserve query credentials',
  );
}

void prefersEmbeddedUrlTokenOverEarlierStaleSharedTextToken() {
  final result = parseNavivoxConnectionImportPayload(
    'Previous token: nvbx_stale should be ignored. Open '
    'https://gateway.example/connect?token=nvbx_fresh to finish setup.',
  );

  _expect(
    result != null,
    'shared text with stale and fresh tokens should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'embedded connection URL should provide the baseUrl',
  );
  _expect(
    result.token == 'nvbx_fresh',
    'token from the selected embedded URL should beat earlier stale prose tokens',
  );
}

void prefersTokenAfterSelectedEmbeddedUrlOverEarlierStaleSharedTextToken() {
  final result = parseNavivoxConnectionImportPayload(
    'Previous token: nvbx_stale should be ignored. Open '
    'https://gateway.example/connect then use Token: nvbx_fresh.',
  );

  _expect(
    result != null,
    'shared text with stale and fresh prose tokens should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'embedded connection URL should provide the baseUrl',
  );
  _expect(
    result.token == 'nvbx_fresh',
    'token after the selected embedded URL should beat earlier stale prose tokens',
  );
}

void prefersNearestLeadingTokenBeforeSelectedEmbeddedUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'Previous token: nvbx_stale. Use Token: nvbx_fresh with '
    'https://gateway.example/connect.',
  );

  _expect(
    result != null,
    'shared text with multiple leading tokens should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'embedded connection URL should provide the baseUrl',
  );
  _expect(
    result.token == 'nvbx_fresh',
    'the closest leading token before the selected URL should win over older stale tokens',
  );
}

void readsEarliestLabeledSharedTextTokenAfterSelectedUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'Open https://gateway.example/connect then use Token: nvbx_fresh. '
    'Ignore later Pairing token: nvbx_stale.',
  );

  _expect(
    result != null,
    'shared text with multiple labeled tokens should parse',
  );
  _expect(
    result!.token == 'nvbx_fresh',
    'the earliest labeled token after the selected URL should win regardless of label spelling',
  );
}

void prefersRicherEmbeddedUrlOverEarlierUnrelatedUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'See https://docs.example/help first, then open '
    'https://gateway.example/connect?token=nvbx_embedded&server_id=srv.',
  );

  _expect(result != null, 'shared text with multiple URLs should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'richer embedded connection URL should beat earlier unrelated URL',
  );
  _expect(result.token == 'nvbx_embedded', 'embedded URL token is preserved');
  _expect(result.serverId == 'srv', 'embedded URL metadata is preserved');
}

void prefersLaterSharedTextUrlWhenTokenBelongsToThatUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'Read https://docs.example/setup first. Then open '
    'https://gateway.example/connect and use Token: nvbx_fresh.',
  );

  _expect(
    result != null,
    'shared text with multiple bare URLs and one token should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'token after a later bare URL should bind to that URL, not an earlier docs URL',
  );
  _expect(result.token == 'nvbx_fresh', 'following token should be preserved');
}

void prefersConnectionPathOverEarlierEqualRankMetadataUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'Read https://docs.example/setup?server_id=docs first. Then open '
    'https://gateway.example/connect?server_id=srv.',
  );

  _expect(
    result != null,
    'shared text with equal-rank metadata URLs should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'a connection-path metadata URL should beat an earlier documentation URL with the same field score',
  );
  _expect(
    result.serverId == 'srv',
    'metadata should come from the selected connection-path URL',
  );
}

void doesNotBorrowTokenFromLaterSharedTextUrlWindow() {
  final result = parseNavivoxConnectionImportPayload(
    'Open https://gateway.example/connect?server_id=srv. Then read '
    'https://docs.example/help Token: nvbx_docs.',
  );

  _expect(
    result != null,
    'shared text with multiple URLs and a later unrelated token should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'richer selected endpoint should keep its baseUrl',
  );
  _expect(
    result.serverId == 'srv',
    'richer selected endpoint metadata should be preserved',
  );
  _expect(
    result.token == null,
    'a token after a different later URL must not be borrowed by the selected endpoint',
  );
}

void doesNotBorrowTokenFromEarlierSharedTextUrlWindow() {
  final result = parseNavivoxConnectionImportPayload(
    'Read https://docs.example/setup Token: nvbx_docs. Then open '
    'https://gateway.example/connect?server_id=srv.',
  );

  _expect(
    result != null,
    'shared text with an earlier URL token and later richer endpoint should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'richer selected endpoint should keep its baseUrl',
  );
  _expect(
    result.serverId == 'srv',
    'richer selected endpoint metadata should be preserved',
  );
  _expect(
    result.token == null,
    'a token after a different earlier URL must not be borrowed by the selected endpoint',
  );
}

void doesNotLetLabelBeforeLaterSharedTextUrlConsumeThatUrlAsToken() {
  final result = parseNavivoxConnectionImportPayload(
    'Read https://docs.example/setup first. Token:\n'
    'https://gateway.example/connect then use Token: nvbx_fresh.',
  );

  _expect(
    result != null,
    'shared text with a dangling token label before a later URL should parse',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'a token label before a later URL must not bind that later URL to the earlier endpoint',
  );
  _expect(
    result.token == 'nvbx_fresh',
    'the selected later endpoint should keep its following token',
  );
}

void doesNotUseUrlAfterSharedTextTokenLabelAsToken() {
  final result = parseNavivoxConnectionImportPayload(
    'Open https://gateway.example/connect. Token:\n'
    'https://docs.example/reset has troubleshooting steps.',
  );

  _expect(
    result != null,
    'shared text with a URL after a token label should still parse the endpoint',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'the selected endpoint URL should still provide the baseUrl',
  );
  _expect(
    result.token == null,
    'a URL after a token label is prose/navigation, not a pairing token',
  );
}

void doesNotTreatSingleUrlAfterSharedTextTokenLabelAsToken() {
  final result = parseNavivoxConnectionImportPayload(
    'Token:\nhttps://gateway.example/connect has setup steps.',
  );

  _expect(
    result != null,
    'shared text with a URL after a dangling token label should still parse the endpoint',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'the URL after a dangling token label should provide only the baseUrl',
  );
  _expect(
    result.token == null,
    'a single URL after a token label is prose/navigation, not a pairing token',
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

void preservesFirstJsonEntryWhenCandidatesHaveEqualRank() {
  final result = parseNavivoxConnectionImportPayload(
    '{"entries":[{"base_url":"https://gateway.example","token":"nvbx_first"},{"base_url":"https://gateway.example","token":"nvbx_second"}]}',
  );

  _expect(result != null, 'JSON entries should parse');
  _expect(
    result!.token == 'nvbx_first',
    'equal-rank JSON candidates should keep source order instead of letting a later equivalent entry replace provenance',
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

void prefersEntryAliasOverrideOverTopLevelJsonDefaultAlias() {
  final result = parseNavivoxConnectionImportPayload(
    '{"base_url":"https://default.example","token":"nvbx_stale_default","entries":[{"baseUrl":"https://gateway.example","pairingToken":"nvbx_fresh_entry"}]}',
  );

  _expect(result != null, 'JSON entry aliases should parse with defaults');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'entry base URL alias should override top-level default base URL aliases',
  );
  _expect(
    result.token == 'nvbx_fresh_entry',
    'entry token alias should override top-level default token aliases',
  );
}

void doesNotLetBlankJsonEntryAliasInheritTopLevelDefaultAlias() {
  final result = parseNavivoxConnectionImportPayload(
    '{"token":"nvbx_default","entries":[{"base_url":"https://gateway.example","token":""},{"base_url":"https://fallback.example","token":"nvbx_fallback"}]}',
  );

  _expect(result != null, 'JSON entries with blank aliases should parse');
  _expect(
    result!.baseUrl == 'https://fallback.example',
    'a blank entry token alias must block inherited top-level token provenance instead of manufacturing a complete connection',
  );
  _expect(
    result.token == 'nvbx_fallback',
    'later explicit credentials should beat an entry whose token alias is blank',
  );
}

void doesNotLetCaseVariantBlankJsonEntryAliasInheritTopLevelDefaultAlias() {
  final result = parseNavivoxConnectionImportPayload(
    '{"rest_token":"nvbx_default","entries":[{"base_url":"https://gateway.example","REST_TOKEN":""},{"base_url":"https://fallback.example","token":"nvbx_fallback"}]}',
  );

  _expect(
    result != null,
    'JSON entries with case-variant blank aliases should parse',
  );
  _expect(
    result!.baseUrl == 'https://fallback.example',
    'a case-variant blank entry token alias must block inherited top-level token provenance instead of manufacturing a complete connection',
  );
  _expect(
    result.token == 'nvbx_fallback',
    'later explicit credentials should beat an entry whose case-variant token alias is blank',
  );
}

void doesNotLetMetadataOnlyJsonEntryStealDefaultCredentialsFromConcreteEntry() {
  final result = parseNavivoxConnectionImportPayload(
    '{"base_url":"https://default.example","token":"nvbx_default","entries":[{"base_url":"https://gateway.example","token":"nvbx_entry"},{"server_id":"srv","profile_id":"profile"}]}',
  );

  _expect(result != null, 'JSON entries with top-level defaults should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'metadata-only entries must not pair inherited default credentials ahead of an explicit connection entry',
  );
  _expect(
    result.token == 'nvbx_entry',
    'explicit entry credentials should keep their token provenance',
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

void doesNotTreatTokenSuffixInDifferentLabelAsSharedTextToken() {
  final result = parseNavivoxConnectionImportPayload(
    'Server: https://gateway.example/connect\nnotoken: stale_secret',
  );

  _expect(result != null, 'shared text URL should still parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'shared text URL origin should provide baseUrl',
  );
  _expect(
    result.token == null,
    'token labels must not match the token suffix inside a different field name',
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

void parsesSharedTextTokenWrappedInBackticks() {
  final result = parseNavivoxConnectionImportPayload(
    'Server: https://gateway.example/connect\nToken: `shared_secret`',
  );

  _expect(result != null, 'backtick-wrapped shared text token should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'backtick-wrapped token shared text URL origin should provide baseUrl',
  );
  _expect(
    result.token == 'shared_secret',
    'token labels should allow markdown code delimiters around tokens',
  );
}

void parsesSharedTextTokenWrappedInAngleBrackets() {
  final result = parseNavivoxConnectionImportPayload(
    'Server: https://gateway.example/connect\nToken: <shared_secret>',
  );

  _expect(result != null, 'angle-bracketed shared text token should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'angle-bracketed token shared text URL origin should provide baseUrl',
  );
  _expect(
    result.token == 'shared_secret',
    'token labels should allow copied angle delimiters around tokens',
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

void parsesSharedTextTokenAfterAttachedUrlPunctuation() {
  final result = parseNavivoxConnectionImportPayload(
    'Server: https://gateway.example,Token: shared_secret',
  );

  _expect(result != null, 'shared text import should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'attached sentence punctuation after a copied URL should not become part of the baseUrl',
  );
  _expect(
    result.token == 'shared_secret',
    'token labels immediately after URL punctuation should keep their provenance window',
  );
}

void stripsTrailingPunctuationFromPlainCopiedUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'https://gateway.example/connect?token=nvbx_shared.',
  );

  _expect(result != null, 'plain copied URL import should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'plain copied URL should keep the endpoint origin',
  );
  _expect(
    result.token == 'nvbx_shared',
    'sentence punctuation after a plain copied URL should not become part of the token',
  );
}

void stripsAngleBracketFromPlainCopiedUrl() {
  final result = parseNavivoxConnectionImportPayload(
    '<https://gateway.example/connect?token=nvbx_shared>',
  );

  _expect(result != null, 'angle-bracketed plain copied URL should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'leading angle bracket before a plain copied URL should not affect the baseUrl',
  );
  _expect(
    result.token == 'nvbx_shared',
    'angle brackets around a plain copied URL should not become part of the token',
  );
}

void stripsBacktickFromPlainCopiedUrl() {
  final result = parseNavivoxConnectionImportPayload(
    '`https://gateway.example/connect?token=nvbx_shared`',
  );

  _expect(result != null, 'backtick-delimited plain copied URL should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'leading backtick before a plain copied URL should not affect the baseUrl',
  );
  _expect(
    result.token == 'nvbx_shared',
    'backticks around a plain copied URL should not become part of the token',
  );
}

void rejectsPunctuationOnlySharedTextToken() {
  final result = parseNavivoxConnectionImportPayload('token: .');

  _expect(
    result == null,
    'punctuation-only shared-text token must not produce an empty token import',
  );
}

void stripsAngleBracketFromSharedTextUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'Open <https://gateway.example/connect?token=nvbx_shared> to finish setup.',
  );

  _expect(result != null, 'angle-bracketed shared URL should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'angle bracket after copied URL should not affect the baseUrl',
  );
  _expect(
    result.token == 'nvbx_shared',
    'angle bracket after copied URL should not become part of the token',
  );
}

void stripsBacktickFromSharedTextUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'Run `https://gateway.example/connect?token=nvbx_shared` to finish setup.',
  );

  _expect(result != null, 'backtick-delimited shared URL should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'backtick after copied URL should not affect the baseUrl',
  );
  _expect(
    result.token == 'nvbx_shared',
    'backtick after copied URL should not become part of the token',
  );
}

void preservesBalancedParenthesesInSharedTextUrlPath() {
  final result = parseNavivoxConnectionImportPayload(
    'Open https://gateway.example/connect(invite)?token=nvbx_shared to finish setup.',
  );

  _expect(result != null, 'shared URL with balanced parentheses should parse');
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'balanced URL parentheses should not make the URL candidate malformed',
  );
  _expect(
    result.token == 'nvbx_shared',
    'balanced URL parentheses should not truncate the query token',
  );
}

void preservesBalancedParenthesesAtCopiedWebSocketUrlEnd() {
  final result = parseNavivoxConnectionImportPayload(
    'wss://gateway.example/navivox/ws(invite)',
  );

  _expect(
    result != null,
    'copied websocket URLs ending in balanced parentheses should parse',
  );
  _expect(
    result!.webSocketUrl == 'wss://gateway.example/navivox/ws(invite)',
    'balanced URL path parentheses at the end are part of the copied endpoint, not wrapper punctuation',
  );
}

void trimsOnlyUnmatchedTrailingParenthesisFromCopiedWebSocketUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'wss://gateway.example/navivox/ws(invite))',
  );

  _expect(
    result != null,
    'copied websocket URLs with one extra wrapper parenthesis should parse',
  );
  _expect(
    result!.webSocketUrl == 'wss://gateway.example/navivox/ws(invite)',
    'only the unmatched trailing wrapper parenthesis should be trimmed',
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

void parsesValidCorePairingDescriptorEmbeddedInSharedText() {
  final result = parseNavivoxConnectionImportPayload(
    'Open navivox://connect?websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fws&rest_token=nvbx_shared&server_id=srv to pair.',
  );

  _expect(
    result != null,
    'valid navivox://connect descriptors embedded in shared text should parse',
  );
  _expect(
    result!.baseUrl == 'http://127.0.0.1:8765',
    'embedded descriptor baseUrl should derive from websocket_url',
  );
  _expect(result.token == 'nvbx_shared', 'embedded descriptor token preserved');
  _expect(result.serverId == 'srv', 'embedded descriptor metadata preserved');
}

void parsesLaterValidCorePairingDescriptorAfterMalformedSharedTextDescriptor() {
  final result = parseNavivoxConnectionImportPayload(
    'Ignore stale navivox://connect?rest_token=nvbx_stale and open '
    'navivox://connect?websocket_url=ws%3A%2F%2F127.0.0.1%3A8765%2Fws&rest_token=nvbx_fresh&server_id=srv to pair.',
  );

  _expect(
    result != null,
    'a later valid navivox://connect descriptor should not be dropped after an earlier malformed descriptor',
  );
  _expect(
    result!.baseUrl == 'http://127.0.0.1:8765',
    'later valid descriptor should provide the baseUrl',
  );
  _expect(
    result.token == 'nvbx_fresh',
    'later valid descriptor should provide the token',
  );
  _expect(result.serverId == 'srv', 'later descriptor metadata preserved');
}

void rejectsSharedTextMalformedCoreDescriptorBeforeTokenFallback() {
  final result = parseNavivoxConnectionImportPayload(
    'Open navivox://connect?rest_token=nvbx_token_only to pair.',
  );

  _expect(
    result == null,
    'malformed navivox://connect descriptors embedded in shared text must be rejected instead of falling back to a token-only prose import',
  );
}

void doesNotBorrowTokenFromMalformedCoreDescriptorBeforeGenericSharedTextUrl() {
  final result = parseNavivoxConnectionImportPayload(
    'Ignore stale navivox://connect?rest_token=nvbx_stale and open '
    'https://gateway.example/connect to pair.',
  );

  _expect(
    result != null,
    'a generic shared-text URL should still parse beside a malformed core descriptor',
  );
  _expect(
    result!.baseUrl == 'https://gateway.example',
    'the generic shared-text URL should provide the baseUrl',
  );
  _expect(
    result.token == null,
    'tokens from a malformed navivox://connect descriptor must not be borrowed by a generic shared-text URL',
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
