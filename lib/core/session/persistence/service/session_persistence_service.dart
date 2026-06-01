import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/session_text.dart';
import '../contracts/saved_connection_fields.dart';
import '../contracts/saved_session.dart';
import '../contracts/saved_session_fields.dart';
import '../storage/session_preference_keys.dart';

/// Persists non-secret gateway metadata for later reconnect flows.
///
/// Pairing handoff tokens are bootstrap-only and must not be stored here.
/// Silent reconnect remains disabled until a secure durable credential adapter
/// exists for the saved Gateway identity.
class SessionPersistenceService {
  SessionPersistenceService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
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
    await prefs.setString(SessionPreferenceKeys.baseUrl, fields.baseUrl);
    await prefs.remove(SessionPreferenceKeys.legacyToken);
    if (fields.webSocketUrl != null) {
      await prefs.setString(
        SessionPreferenceKeys.webSocketUrl,
        fields.webSocketUrl!,
      );
    } else {
      await prefs.remove(SessionPreferenceKeys.webSocketUrl);
    }
    if (fields.gatewayId != null) {
      await prefs.setString(SessionPreferenceKeys.gatewayId, fields.gatewayId!);
    } else {
      await prefs.remove(SessionPreferenceKeys.gatewayId);
    }
    await prefs.setString(
      SessionPreferenceKeys.lastConnectedAt,
      _clock().toUtc().toIso8601String(),
    );
  }

  /// Load saved connection state. Returns null if no session is saved.
  Future<SavedSession?> loadSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return null;
    final fields = SavedSessionFields.fromStoredValues(
      baseUrl: prefs.getString(SessionPreferenceKeys.baseUrl),
      webSocketUrl: prefs.getString(SessionPreferenceKeys.webSocketUrl),
      gatewayId: prefs.getString(SessionPreferenceKeys.gatewayId),
      lastConnectedAt: prefs.getString(SessionPreferenceKeys.lastConnectedAt),
    );
    if (fields == null) return null;

    return SavedSession(
      baseUrl: fields.baseUrl,
      webSocketUrl: fields.webSocketUrl,
      gatewayId: fields.gatewayId,
      lastConnectedAt: fields.lastConnectedAt,
    );
  }

  /// Remove saved session. Call when user explicitly disconnects,
  /// or when reconnect fails with an expired/revoked credential.
  Future<void> clearSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(SessionPreferenceKeys.baseUrl);
    await prefs.remove(SessionPreferenceKeys.legacyToken);
    await prefs.remove(SessionPreferenceKeys.webSocketUrl);
    await prefs.remove(SessionPreferenceKeys.lastConnectedAt);
    await prefs.remove(SessionPreferenceKeys.gatewayId);
  }

  /// Check if a saved session exists without loading all fields.
  Future<bool> hasSession() async {
    await ensureInitialized();
    final prefs = _prefs;
    if (prefs == null) return false;
    final baseUrl = prefs.getString(SessionPreferenceKeys.baseUrl);
    return isNonBlankSessionText(baseUrl);
  }
}
