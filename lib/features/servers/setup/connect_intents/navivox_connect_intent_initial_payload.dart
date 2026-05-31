class NavivoxInitialConnectIntentPayloadCache {
  Object? _payload;
  bool _hasPayload = false;

  bool get hasPayload => _hasPayload;

  /// Caches the first platform payload observed before [take].
  ///
  /// Android initial intents are one-shot: repeated availability probes can
  /// return `null` after the first probe consumes the real payload. Treat the
  /// cache as a replay buffer and keep the earliest unconsumed result.
  void remember(Object? payload) {
    if (_hasPayload) return;
    _payload = payload;
    _hasPayload = true;
  }

  Object? take() {
    final payload = _payload;
    _payload = null;
    _hasPayload = false;
    return payload;
  }
}
