import '../../../../../protocol/navivox_json.dart';

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
  const SavedSessionWebSocketMetadata._({
    required this.durableUrl,
    required this.isLegacyText,
    required this.isRejectedUrl,
  });

  factory SavedSessionWebSocketMetadata.fromStoredValue(Object? value) {
    final text = navivoxOptionalStringFromJson(value);
    if (text == null) return const SavedSessionWebSocketMetadata.absent();

    final endpoint = SavedSessionWebSocketEndpoint.tryParse(text);
    if (endpoint != null) {
      return SavedSessionWebSocketMetadata.durableEndpoint(endpoint);
    }

    if (_hasExplicitUriScheme(text)) {
      return const SavedSessionWebSocketMetadata.rejectedUrl();
    }

    return SavedSessionWebSocketMetadata.legacyText(text);
  }

  const SavedSessionWebSocketMetadata.absent()
    : this._(durableUrl: null, isLegacyText: false, isRejectedUrl: false);

  SavedSessionWebSocketMetadata.durableEndpoint(
    SavedSessionWebSocketEndpoint endpoint,
  ) : this._(
        durableUrl: endpoint.durableUrl,
        isLegacyText: false,
        isRejectedUrl: false,
      );

  const SavedSessionWebSocketMetadata.legacyText(String value)
    : this._(durableUrl: value, isLegacyText: true, isRejectedUrl: false);

  const SavedSessionWebSocketMetadata.rejectedUrl()
    : this._(durableUrl: null, isLegacyText: false, isRejectedUrl: true);

  final String? durableUrl;
  final bool isLegacyText;
  final bool isRejectedUrl;

  bool get isAbsent => durableUrl == null && !isRejectedUrl;
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

bool _hasExplicitUriScheme(String value) {
  final text = value.trim();
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasScheme) return false;

  // Dart's URI parser treats `host:8765/path` as a URI with scheme `host`.
  // Saved-session metadata also accepts legacy non-URL text, so only discard
  // values that are visibly URL/scheme-shaped rather than host-port-shaped.
  return _hasAuthoritySchemeSeparator(text) || _hasNonPortSchemeSeparator(text);
}

bool _hasAuthoritySchemeSeparator(String value) {
  return value.indexOf('://') > 0;
}

bool _hasNonPortSchemeSeparator(String value) {
  final separator = value.indexOf(':');
  if (separator <= 0 || separator == value.length - 1) return false;
  return !_startsWithAsciiDigit(value, separator + 1);
}

bool _startsWithAsciiDigit(String value, int index) {
  final codeUnit = value.codeUnitAt(index);
  return codeUnit >= 0x30 && codeUnit <= 0x39;
}
