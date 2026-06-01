import 'session_staleness.dart';

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
  bool get isStale => isStaleAt(DateTime.now());

  bool isStaleAt(DateTime now) =>
      isSavedSessionStale(lastConnectedAt: lastConnectedAt, now: now);

  /// Whether this metadata can currently perform silent reconnect.
  ///
  /// This remains false until a secure durable credential adapter exists.
  bool get canAttemptReconnect => false;
}
