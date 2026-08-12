import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../channel/hermes_detached_run_store.dart';

/// Persists only opaque run/session handles needed to reconcile work after the
/// Wing process is recreated. No prompt, output, credential, or transcript is
/// stored here; Hermes Agent remains authoritative for lifecycle and history.
class SecureHermesDetachedRunStore implements HermesDetachedRunStore {
  SecureHermesDetachedRunStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _storageKey = 'wing.hermes.detached_runs.v1';
  static const _maximumLeases = 16;

  @override
  Object get coordinationKey => _storageKey;

  final FlutterSecureStorage _secureStorage;

  @override
  Future<List<HermesDetachedRunLease>> load() async {
    final String? encoded;
    encoded = await _secureStorage.read(key: _storageKey);
    if (encoded == null || encoded.isEmpty) return const [];
    final decoded = jsonDecode(encoded);
    if (decoded is! List<Object?>) {
      throw const FormatException('Detached run store must contain a list.');
    }
    final leases = <HermesDetachedRunLease>[];
    for (final row in decoded) {
      if (row is! Map) {
        throw const FormatException('Detached run lease must be an object.');
      }
      leases.add(
        HermesDetachedRunLease.fromJson(
          row.map((key, value) => MapEntry(key.toString(), value)),
        ),
      );
    }
    if (leases.length > _maximumLeases) {
      throw const FormatException('Detached run store capacity exceeded.');
    }
    return leases;
  }

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    if (leases.length > _maximumLeases) {
      throw StateError('Detached run store capacity exceeded.');
    }
    await _secureStorage.write(
      key: _storageKey,
      value: jsonEncode(leases.map((lease) => lease.toJson()).toList()),
    );
  }
}
