import 'saved_session_metadata_projection.dart';

/// Projects one already-normalized saved-session metadata text value.
///
/// The data flow is intentionally explicit and shared by reconnect metadata
/// fields: try to derive durable reconnect metadata first, reject URL-shaped or
/// legacy-shaped values that can carry bootstrap-only state, otherwise preserve
/// the trimmed legacy value for compatibility.
typedef DurableSavedSessionMetadataParser = String? Function(String text);

typedef SavedSessionMetadataSafetyCheck = bool Function(String text);

SavedSessionMetadataProjection projectSavedSessionMetadataValue({
  required String text,
  required DurableSavedSessionMetadataParser durableValueFromText,
  required SavedSessionMetadataSafetyCheck isUnsafeUriShape,
}) {
  assert(text.isNotEmpty, 'saved-session metadata text must be normalized');

  final durableValue = durableValueFromText(text);
  if (durableValue != null) {
    return SavedSessionMetadataProjection.durable(durableValue);
  }
  if (isUnsafeUriShape(text)) {
    return const SavedSessionMetadataProjection.rejectedUrl();
  }
  return SavedSessionMetadataProjection.legacy(text);
}
