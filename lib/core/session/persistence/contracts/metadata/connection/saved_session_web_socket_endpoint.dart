import '../../../../../protocol/navivox_json.dart';

import 'saved_session_metadata_projection.dart';
import 'saved_session_metadata_value_projection.dart';
import 'session_uri_text_shape.dart';

/// Reconnect-safe projection for a saved websocket endpoint.
///
/// Saved session metadata may keep the websocket path because deployments can
/// mount the stream outside the default Navivox route. It must not keep
/// userinfo, query parameters, or fragments because those fields can contain
/// one-time pairing credentials.
class SavedSessionWebSocketEndpoint {
  const SavedSessionWebSocketEndpoint._(this.uri);

  static SavedSessionWebSocketEndpoint? tryParse(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'ws' && scheme != 'wss') return null;
    return SavedSessionWebSocketEndpoint._(
      Uri(
        scheme: scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path,
      ),
    );
  }

  final Uri uri;

  String get durableUrl => uri.toString();
}

/// Classification for websocket-shaped metadata loaded from saved sessions.
///
/// This makes the persistence decision replayable: callers can see whether a
/// value became a durable endpoint, a compatibility legacy value, or a removal
/// because the text looked like an unsafe URL carrying bootstrap-only state.
class SavedSessionWebSocketMetadata {
  const SavedSessionWebSocketMetadata._(this._projection);

  factory SavedSessionWebSocketMetadata.fromStoredValue(Object? value) {
    final text = navivoxOptionalStringFromJson(value);
    if (text == null) return const SavedSessionWebSocketMetadata.absent();

    return SavedSessionWebSocketMetadata._(_projectSavedSessionWebSocket(text));
  }

  const SavedSessionWebSocketMetadata.absent()
    : this._(const SavedSessionMetadataProjection.absent());

  SavedSessionWebSocketMetadata.durableEndpoint(
    SavedSessionWebSocketEndpoint endpoint,
  ) : this._(SavedSessionMetadataProjection.durable(endpoint.durableUrl));

  SavedSessionWebSocketMetadata.legacyText(String value)
    : this._(SavedSessionMetadataProjection.legacy(value));

  const SavedSessionWebSocketMetadata.rejectedUrl()
    : this._(const SavedSessionMetadataProjection.rejectedUrl());

  final SavedSessionMetadataProjection _projection;

  String? get durableUrl => _projection.durableValue;
  bool get isLegacyText => _projection.isLegacyText;
  bool get isRejectedUrl => _projection.isRejectedUrl;

  bool get isAbsent => _projection.isAbsent;
}

/// Returns websocket metadata that is safe to persist for reconnect.
///
/// Blank values are absent. Valid `ws`/`wss` endpoints are reduced to durable
/// identity fields. Values with another explicit URI scheme are discarded
/// rather than preserved as legacy text because URL-shaped metadata can carry
/// bootstrap credentials in query strings or fragments.
String? durableSavedSessionWebSocketUrlFromMetadata(Object? value) {
  return SavedSessionWebSocketMetadata.fromStoredValue(value).durableUrl;
}

SavedSessionMetadataProjection _projectSavedSessionWebSocket(String text) {
  return projectSavedSessionMetadataValue(
    text: text,
    durableValueFromText: _durableWebSocketUrlFromText,
    isUnsafeUriShape: _isUnsafeSavedSessionWebSocketShape,
  );
}

String? _durableWebSocketUrlFromText(String text) {
  return SavedSessionWebSocketEndpoint.tryParse(text)?.durableUrl;
}

bool _isUnsafeSavedSessionWebSocketShape(String value) {
  return classifySavedSessionWebSocketTextShape(value).isExplicitUriScheme ||
      SavedSessionUriTextSyntax.parse(value).hasNonDurableUriStateDelimiter;
}

/// Replayable shape classification for saved websocket metadata text.
///
/// This separates the persistence safety decision from Dart's URI parser quirks:
/// `host:8765/path` and `[::1]:8765/stream` are legacy endpoint-like text, while
/// `scheme:value` and `scheme://authority` are explicit URI shapes that may
/// carry bootstrap-only state and should not be preserved as compatibility text.
typedef SavedSessionWebSocketTextShape = SavedSessionUriTextShape;

SavedSessionWebSocketTextShape classifySavedSessionWebSocketTextShape(
  String value,
) {
  final text = value.trim();
  if (text.isEmpty) return SavedSessionWebSocketTextShape.none;

  return classifySavedSessionUriTextShape(text);
}
