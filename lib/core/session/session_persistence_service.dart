import 'package:shared_preferences/shared_preferences.dart';

/// Persists and restores gateway connection state so Navivox can reconnect
/// without requiring the user to re-pair every session.
///
/// Token is saved for reconnection but treated as a durable session credential,
/// not a one-time QR/temp token. If reconnect fails with the saved token,
/// [clearSession] can remove stale credentials and route back to setup.
class SessionPersistenceService {
  static const _keyBaseUrl = 'navivox.session.base_url';
  static const _keyWebSocketUrl = 'navivox.session.websocket_url';
  static const _keyToken = 'navivox.session.token';
  static const _keyLastConnectedAt = 'navivox.session.last_connected_at';
  static const _keyGatewayId = 'navivox.session.gateway_id';

  SharedPreferences? _prefs;

  Future<void> ensureInitialized() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // SharedPreferences not available (e.g. test without mock).
    }
  }

  /// Save a successful gateway connection for reconnection on next app start.
  Future<void> saveConnection({
    required String baseUrl,
    String? token,
    String? webSocketUrl,
    String? gatewayId,
  }) async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_keyBaseUrl, baseUrl.trim());
    if (token != null && token.trim().isNotEmpty) {
      await prefs.setString(_keyToken, token.trim());
    }
    if (webSocketUrl != null && webSocketUrl.trim().isNotEmpty) {
      await prefs.setString(_keyWebSocketUrl, webSocketUrl.trim());
    }
    if (gatewayId != null && gatewayId.trim().isNotEmpty) {
      await prefs.setString(_keyGatewayId, gatewayId.trim());
    }
    await prefs.setString(
      _keyLastConnectedAt,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Load saved connection state. Returns null if no session is saved.
  Future<SavedSession?> loadSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return null;
    final baseUrl = prefs.getString(_keyBaseUrl);
    if (baseUrl == null || baseUrl.trim().isEmpty) return null;

    return SavedSession(
      baseUrl: baseUrl.trim(),
      token: _nullableString(prefs.getString(_keyToken)),
      webSocketUrl: _nullableString(prefs.getString(_keyWebSocketUrl)),
      gatewayId: _nullableString(prefs.getString(_keyGatewayId)),
      lastConnectedAt: _parseDateTime(prefs.getString(_keyLastConnectedAt)),
    );
  }

  /// Remove saved session. Call when user explicitly disconnects,
  /// or when reconnect fails with an expired/revoked credential.
  Future<void> clearSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_keyBaseUrl);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyWebSocketUrl);
    await prefs.remove(_keyLastConnectedAt);
    await prefs.remove(_keyGatewayId);
  }

  /// Check if a saved session exists without loading all fields.
  Future<bool> hasSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return false;
    final baseUrl = prefs.getString(_keyBaseUrl);
    return baseUrl != null && baseUrl.trim().isNotEmpty;
  }

  DateTime? _parseDateTime(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String? _nullableString(String? value) {
    final text = value?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}

class SavedSession {
  const SavedSession({
    required this.baseUrl,
    this.token,
    this.webSocketUrl,
    this.gatewayId,
    this.lastConnectedAt,
  });

  final String baseUrl;
  final String? token;
  final String? webSocketUrl;
  final String? gatewayId;
  final DateTime? lastConnectedAt;

  /// Whether the session is stale (no recent connection).
  bool get isStale {
    if (lastConnectedAt == null) return true;
    return DateTime.now().toUtc().difference(lastConnectedAt!).inDays > 7;
  }

  /// Whether the session has a stored auth token.
  bool get hasAuthToken => token != null && token!.trim().isNotEmpty;
}
