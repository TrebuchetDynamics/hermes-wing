import 'dart:convert';

import '../../../../core/protocol/navivox_endpoint_uri.dart';
import '../../../../core/protocol/navivox_json.dart';
import '../../../../core/protocol/navivox_pairing_descriptor.dart';
import '../../models/connection_import.dart';

part 'candidates/model/candidate.dart';
part 'candidates/ranking/candidate_rank.dart';
part 'candidates/ranking/candidate_selection.dart';
part 'candidates/fields/field_names.dart';
part 'candidates/fields/from_fields.dart';
part 'endpoints/field_normalization/normalized_endpoint_fields.dart';
part 'endpoints/generic_uri/endpoint_uri_identity.dart';
part 'endpoints/copied_url/copied_endpoint_url.dart';
part 'endpoints/generic_uri/generic_endpoint.dart';
part 'shared_text/token_parsing/tokens.dart';
part 'shared_text/endpoints/endpoint_matches.dart';
part 'shared_text/import.dart';
part 'shared_text/descriptors/core_pairing_descriptor.dart';
part 'json/candidate_maps.dart';
part 'shared_text/endpoints/endpoint.dart';
part 'shared_text/endpoints/endpoint_selection.dart';

class ConnectionImportParser {
  const ConnectionImportParser();

  SetupQrImageImport? parsePayload(String payload) {
    final text = payload.trim();
    if (text.isEmpty) return null;

    final jsonResult = _parseQrJsonPayload(text);
    if (jsonResult.isJsonObject) return jsonResult.importValue;

    final copiedUriPayload = _copiedUriPayload(text);
    if (copiedUriPayload != null) {
      return _importFromCopiedUriPayload(copiedUriPayload);
    }

    return _importFromSharedText(text);
  }

  _CopiedUriPayload? _copiedUriPayload(String text) {
    final copiedUrl = _trimCopiedEndpointUrl(text);
    if (_containsCopiedTextSeparator(copiedUrl)) return null;
    if (_hasAttachedTokenLabelAfterCopiedEndpoint(copiedUrl)) return null;
    final uri = Uri.tryParse(copiedUrl);
    if (uri == null || !uri.hasScheme) return null;
    return _CopiedUriPayload(text: copiedUrl, uri: uri);
  }

  _JsonPayloadParseResult _parseQrJsonPayload(String text) {
    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return const _JsonPayloadParseResult.notJsonObject();
    }
    if (decoded is! Map) return const _JsonPayloadParseResult.notJsonObject();

    // JSON object payloads are a structured import contract. If the object does
    // not expose connection fields, do not reinterpret arbitrary JSON string
    // values as prose tokens or copied URLs.
    return _JsonPayloadParseResult.jsonObject(
      _bestImportFromCandidateMaps(_jsonCandidateMaps(decoded)),
    );
  }
}

class _JsonPayloadParseResult {
  const _JsonPayloadParseResult.jsonObject(this.importValue)
    : isJsonObject = true;

  const _JsonPayloadParseResult.notJsonObject()
    : isJsonObject = false,
      importValue = null;

  final bool isJsonObject;
  final SetupQrImageImport? importValue;
}

SetupQrImageImport? parseNavivoxConnectionImportPayload(String payload) =>
    const ConnectionImportParser().parsePayload(payload);

SetupQrImageImport? _importFromCopiedUriPayload(_CopiedUriPayload payload) {
  // A navivox://connect URI is a closed protocol contract: if it is malformed,
  // do not reinterpret its query params as a generic token-only import.
  if (_isCorePairingDescriptorUri(payload.uri)) {
    return _parseCorePairingDescriptorPayload(payload.text) ??
        (_isLegacyNavivoxConnectCompatibilityUri(payload.uri)
            ? _importFromLegacyNavivoxConnectCompatibilityUri(payload.uri)
            : null);
  }
  return _importFromGenericUri(payload.uri);
}

SetupQrImageImport? _importFromLegacyNavivoxConnectCompatibilityUri(Uri uri) {
  return _connectionImportCandidateFromFields(_uriQueryFields(uri))?.toImport();
}

bool _isLegacyNavivoxConnectCompatibilityUri(Uri uri) {
  final query = navivoxFirstNonBlankQueryParameterValues(
    uri.queryParametersAll,
  );
  if (navivoxFirstStringFieldFromJson(query, _webSocketUrlFieldNames) != null) {
    return false;
  }
  if (navivoxFirstStringFieldFromJson(query, const [
        'rest_token',
        'restToken',
      ]) !=
      null) {
    return false;
  }
  return navivoxFirstStringFieldFromJson(query, _baseUrlFieldNames) != null ||
      navivoxFirstStringFieldFromJson(query, const ['token']) != null;
}

class _CopiedUriPayload {
  const _CopiedUriPayload({required this.text, required this.uri});

  final String text;
  final Uri uri;
}

bool _isCorePairingDescriptorUri(Uri uri) =>
    uri.scheme == 'navivox' && uri.host == 'connect';

bool _containsCopiedTextSeparator(String value) =>
    value.codeUnits.any(_isCopiedTextSeparatorCodeUnit);

SetupQrImageImport? _importFromGenericUri(Uri uri) {
  return _connectionImportCandidateFromGenericUri(uri)?.toImport();
}

_ConnectionImportCandidate? _connectionImportCandidateFromGenericUri(Uri uri) {
  final identity = _ConnectionImportEndpointUriIdentity.fromUri(uri);
  if (!identity.isSupported) return null;

  final candidate = _connectionImportCandidateFromFields(
    _genericUriFields(uri, identity: identity),
    fallbackBaseUrl: identity.baseUrl,
  );
  if (candidate != null) return candidate;
  if (identity.kind == _GenericEndpointSchemeKind.http) {
    return _ConnectionImportCandidate(baseUrl: identity.baseUrl);
  }
  return _ConnectionImportCandidate(
    baseUrl: identity.baseUrl,
    webSocketUrl: uri.toString(),
  );
}

// Shared-text imports accept the same generic endpoint schemes as direct URL
// imports. Keeping the regex explicit prevents HTTP-only drift from silently
// dropping websocket endpoints embedded in prose. URI schemes are
// case-insensitive, so match copied prose URLs case-insensitively before Uri
// parsing normalizes the selected candidate.
final _endpointUrlPattern = RegExp(
  r'(?:https?|wss?)://\S+',
  caseSensitive: false,
);
