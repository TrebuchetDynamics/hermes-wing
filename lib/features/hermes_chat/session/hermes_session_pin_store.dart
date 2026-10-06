import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gateways/gateway_contact.dart';

/// Local-only session pin state. Hermes Agent remains authoritative for the
/// sessions themselves; Wing persists only bounded opaque identifiers.
class HermesSessionPinStore extends ChangeNotifier {
  static const _key = 'wing.hermes.pinned_sessions.v1';
  static const _maxEntries = 256;
  static const _maxIdentifierLength = 256;

  final LinkedHashSet<String> _entries = LinkedHashSet<String>();
  Future<void>? _loadFuture;
  Future<void>? _writeFuture;
  int _writeRevision = 0;
  bool _disposed = false;

  Future<void> load() {
    if (_disposed) return Future<void>.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      final stored =
          (await SharedPreferences.getInstance()).getStringList(_key) ??
          const <String>[];
      if (_disposed) return;
      _entries
        ..clear()
        ..addAll(stored.where(_isValidToken).take(_maxEntries));
      notifyListeners();
    } catch (_) {
      if (_disposed) return;
      _entries.clear();
    }
  }

  bool isPinned(GatewayContactId contactId, String sessionId) {
    final token = _token(contactId, sessionId);
    return token != null && _entries.contains(token);
  }

  Future<void> toggle(GatewayContactId contactId, String sessionId) async {
    if (_disposed) return;
    await _loadFuture;
    if (_disposed) return;
    final token = _token(contactId, sessionId);
    if (token == null) return;
    if (!_entries.remove(token)) {
      _entries.add(token);
      while (_entries.length > _maxEntries) {
        _entries.remove(_entries.first);
      }
    }
    _writeRevision++;
    notifyListeners();
    await (_writeFuture ??= _persist());
  }

  Future<void> _persist() async {
    try {
      while (!_disposed) {
        var revision = _writeRevision;
        try {
          final preferences = await SharedPreferences.getInstance();
          // Fence new writes, not platform writes that have already started.
          if (_disposed) return;
          revision = _writeRevision;
          await preferences.setStringList(
            _key,
            _entries.toList(growable: false),
          );
        } catch (_) {
          // Keep local state usable; retry only for a newer deliberate choice.
        }
        if (revision == _writeRevision) return;
        // Coalesce waiting choices into one bounded snapshot, never parallel
        // commits or an unbounded queue of per-toggle persistence operations.
      }
    } finally {
      _writeFuture = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _loadFuture = null;
    _entries.clear();
    super.dispose();
  }

  static String? _token(GatewayContactId contactId, String sessionId) {
    final values = [contactId.gatewayId, contactId.profileId, sessionId];
    if (values.any(
      (value) => value.isEmpty || value.length > _maxIdentifierLength,
    )) {
      return null;
    }
    return jsonEncode(values);
  }

  static bool _isValidToken(String token) {
    if (token.length > (_maxIdentifierLength * 3) + 16) return false;
    try {
      final decoded = jsonDecode(token);
      return decoded is List &&
          decoded.length == 3 &&
          decoded.every(
            (value) =>
                value is String &&
                value.isNotEmpty &&
                value.length <= _maxIdentifierLength,
          );
    } catch (_) {
      return false;
    }
  }
}
