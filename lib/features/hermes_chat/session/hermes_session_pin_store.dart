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

  Future<void> load() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      final stored =
          (await SharedPreferences.getInstance()).getStringList(_key) ??
          const <String>[];
      _entries
        ..clear()
        ..addAll(stored.where(_isValidToken).take(_maxEntries));
      notifyListeners();
    } catch (_) {
      _entries.clear();
    }
  }

  bool isPinned(GatewayContactId contactId, String sessionId) {
    final token = _token(contactId, sessionId);
    return token != null && _entries.contains(token);
  }

  Future<void> toggle(GatewayContactId contactId, String sessionId) async {
    await _loadFuture;
    final token = _token(contactId, sessionId);
    if (token == null) return;
    if (!_entries.remove(token)) {
      _entries.add(token);
      while (_entries.length > _maxEntries) {
        _entries.remove(_entries.first);
      }
    }
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setStringList(
        _key,
        _entries.toList(growable: false),
      );
    } catch (_) {
      // Pinning is a local convenience; keep the in-memory state usable when
      // platform preference storage is unavailable.
    }
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
