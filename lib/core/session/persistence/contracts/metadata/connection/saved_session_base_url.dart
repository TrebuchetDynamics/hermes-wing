import '../../../../../protocol/navivox_endpoint_uri.dart';
import '../../../../../protocol/navivox_json.dart';

import 'saved_session_metadata_projection.dart';
import 'session_uri_text_shape.dart';

/// Reconnect-safe projection for saved HTTP base URL metadata.
///
/// Setup/pairing URLs can include bootstrap-only query parameters, so valid
/// endpoint URLs are reduced to their HTTP origin. URL-shaped values that fail
/// endpoint parsing are rejected instead of being kept as legacy text because
/// they can still carry secrets in query strings or fragments.
class SavedSessionBaseUrlMetadata {
  const SavedSessionBaseUrlMetadata._(this._projection);

  factory SavedSessionBaseUrlMetadata.fromStoredValue(Object? value) {
    final text = navivoxOptionalStringFromJson(value);
    if (text == null) return const SavedSessionBaseUrlMetadata.absent();

    return SavedSessionBaseUrlMetadata._(_projectSavedSessionBaseUrl(text));
  }

  const SavedSessionBaseUrlMetadata.absent()
    : this._(const SavedSessionMetadataProjection.absent());

  SavedSessionBaseUrlMetadata.durableEndpoint(String value)
    : this._(SavedSessionMetadataProjection.durable(value));

  SavedSessionBaseUrlMetadata.legacyText(String value)
    : this._(SavedSessionMetadataProjection.legacy(value));

  const SavedSessionBaseUrlMetadata.rejectedUrl()
    : this._(const SavedSessionMetadataProjection.rejectedUrl());

  final SavedSessionMetadataProjection _projection;

  String? get durableBaseUrl => _projection.durableValue;
  bool get isLegacyText => _projection.isLegacyText;
  bool get isRejectedUrl => _projection.isRejectedUrl;

  bool get isAbsent => _projection.isAbsent;
}

String? durableSavedSessionBaseUrlFromMetadata(Object? value) {
  return SavedSessionBaseUrlMetadata.fromStoredValue(value).durableBaseUrl;
}

SavedSessionMetadataProjection _projectSavedSessionBaseUrl(String text) {
  final baseUrl = _httpBaseUrlFromEndpointText(text);
  if (baseUrl != null) return SavedSessionMetadataProjection.durable(baseUrl);
  if (_looksLikeEndpointUrl(text) || _hasNonDurableLegacyUriState(text)) {
    return const SavedSessionMetadataProjection.rejectedUrl();
  }
  return SavedSessionMetadataProjection.legacy(text);
}

String? _httpBaseUrlFromEndpointText(String value) {
  try {
    return navivoxHttpBaseUrlFromEndpointString(value);
  } on FormatException {
    return null;
  }
}

bool _looksLikeEndpointUrl(String value) {
  return classifySavedSessionUriTextShape(value).isExplicitUriScheme;
}

bool _hasNonDurableLegacyUriState(String value) {
  return SavedSessionUriTextSyntax.parse(value).hasNonDurableUriStateDelimiter;
}
