import 'package:shared_preferences/shared_preferences.dart';

import '../../protocol/navivox_json.dart';
import '../shared/session_text.dart';
import 'saved_connection_fields.dart';

/// Persists non-secret gateway metadata for later reconnect flows.
///
/// Pairing handoff tokens are bootstrap-only and must not be stored here.
/// Silent reconnect remains disabled until a secure durable credential adapter
/// exists for the saved Gateway identity.
class SessionPersistenceService {
  static const _keyBaseUrl = 'navivox.session.base_url';
  static const _keyWebSocketUrl = 'navivox.session.websocket_url';
  static const _legacyKeyToken = 'navivox.session.token';
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

  /// Save non-secret gateway metadata after a successful gateway connection.
  Future<void> saveConnection({
    required String baseUrl,
    String? webSocketUrl,
    String? gatewayId,
  }) async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return;
    final fields = SavedConnectionFields.fromInput(
      baseUrl: baseUrl,
      webSocketUrl: webSocketUrl,
      gatewayId: gatewayId,
    );
    await prefs.setString(_keyBaseUrl, fields.baseUrl);
    await prefs.remove(_legacyKeyToken);
    if (fields.webSocketUrl != null) {
      await prefs.setString(_keyWebSocketUrl, fields.webSocketUrl!);
    } else {
      await prefs.remove(_keyWebSocketUrl);
    }
    if (fields.gatewayId != null) {
      await prefs.setString(_keyGatewayId, fields.gatewayId!);
    } else {
      await prefs.remove(_keyGatewayId);
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
    final baseUrl = navivoxOptionalStringFromJson(prefs.getString(_keyBaseUrl));
    if (baseUrl == null) return null;

    return SavedSession(
      baseUrl: baseUrl,
      webSocketUrl: navivoxOptionalStringFromJson(
        prefs.getString(_keyWebSocketUrl),
      ),
      gatewayId: navivoxOptionalStringFromJson(prefs.getString(_keyGatewayId)),
      lastConnectedAt: navivoxDateTimeFromJson(
        prefs.getString(_keyLastConnectedAt),
      ),
    );
  }

  /// Remove saved session. Call when user explicitly disconnects,
  /// or when reconnect fails with an expired/revoked credential.
  Future<void> clearSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_keyBaseUrl);
    await prefs.remove(_legacyKeyToken);
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
    return isNonBlankSessionText(baseUrl);
  }
}

class SavedSession {
  const SavedSession({
    required this.baseUrl,
    this.webSocketUrl,
    this.gatewayId,
    this.lastConnectedAt,
  });

  final String baseUrl;
  final String? webSocketUrl;
  final String? gatewayId;
  final DateTime? lastConnectedAt;

  /// Whether the session is stale (no recent connection).
  bool get isStale {
    if (lastConnectedAt == null) return true;
    return DateTime.now().toUtc().difference(lastConnectedAt!).inDays > 7;
  }

  /// Whether this metadata can currently perform silent reconnect.
  ///
  /// This remains false until a secure durable credential adapter exists.
  bool get canAttemptReconnect => false;
}
