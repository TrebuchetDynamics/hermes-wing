part of 'm2_fake_harness.dart';

String _wire(Enum value) => value.name.replaceAllMapped(
  RegExp('[A-Z]'),
  (m) => '_${m[0]!.toLowerCase()}',
);

abstract interface class _M2Sink {
  Future<void> write(String envelope);
  Future<String?> read();
}

final class _M2Journal {
  _M2Journal({
    required this.attempt,
    required this.generation,
    required this.sink,
  }) : _validator = M2Validator(attempt: attempt, generation: generation);
  final String attempt;
  final String generation;
  final _M2Sink sink;
  final M2Validator _validator;
  final Stopwatch _clock = Stopwatch()..start();
  final List<Map<String, Object?>> _events = [];
  Future<void>? _worker;
  bool _valid = true;
  bool get valid => _valid;
  // Evidence invalidation is irreversible for this attempt.
  set valid(bool value) {
    if (!value) _valid = false;
  }

  bool get qualifies => false;
  List<Map<String, Object?>> get events => List.unmodifiable(_events);
  Map<String, Object?> event(
    M2Phase phase,
    M2Status status, {
    M2Error? error,
    Map<String, Object?> flags = const {},
  }) => {
    ...flags,
    'schema_version': 1,
    'attempt_alias': attempt,
    'process_generation_alias': generation,
    'sequence': _events.length + 1,
    'elapsed_ms': _clock.elapsedMilliseconds,
    'phase': _wire(phase),
    'status': status.name,
    if (error != null) 'error': _wire(error),
  };
  void record(
    M2Phase phase,
    M2Status status, {
    M2Error? error,
    Map<String, Object?> flags = const {},
  }) {
    if (!valid) return;
    try {
      // Freeze nested metadata before asynchronous sink use.
      final row = Map<String, Object?>.from(
        jsonDecode(jsonEncode(event(phase, status, error: error, flags: flags)))
            as Map,
      );
      _validator.accept(row);
      _events.add(M2Validator.freeze(row));
      _worker ??= _commit();
    } catch (_) {
      valid = false;
    }
  }

  String get _encoded => M2Validator.envelope(attempt, generation, _events);
  // One in-flight snapshot and one bounded pending envelope, <=128 KiB total.
  // Snapshots coalesce, never events: every successful final readback contains all
  // contiguous records. No unbounded chain of queued futures or payloads.
  Future<void> _commit() async {
    try {
      var written = -1;
      while (valid && written != _events.length) {
        written = _events.length;
        final payload = _encoded;
        await sink.write(payload);
      }
    } catch (_) {
      valid = false;
    } finally {
      _worker = null;
    }
  }

  Future<bool> flush() async {
    await _worker;
    if (!valid) return false;
    try {
      final expected = _encoded;
      final readback = await sink.read();
      if (readback != expected || _encoded != expected || _worker != null) {
        valid = false;
        return false;
      }
      M2Validator.validateEnvelope(readback!, attempt, generation);
      return true;
    } catch (_) {
      valid = false;
      return false;
    }
  }
}

/// Product tuples exist only in memory and are never hashed or serialized.
final class _M2StoreObserver implements HermesDetachedRunStore {
  _M2StoreObserver({required this.delegate, required this.journal});
  final HermesDetachedRunStore delegate;
  final _M2Journal journal;
  HermesDetachedRunLease? _owner;
  Object? _channel;
  int _fence = 0;
  bool _invalidOwner = false;
  Map<String, Object?> _aliases = {};
  bool _present = false;
  List<HermesDetachedRunLease> _candidates = const [];
  int get fence => _fence;
  @override
  Object get coordinationKey => delegate.coordinationKey;
  void start() {
    journal.record(
      M2Phase.availability,
      M2Status.unavailable,
      error: M2Error.authoritativeCountsUnavailable,
    );
    journal.record(
      M2Phase.availability,
      M2Status.unavailable,
      error: M2Error.historyAdmissionUnavailable,
    );
  }

  int bind(HermesDetachedRunLease owner, Object channel) {
    if (_owner != null ||
        [
          owner.baseUrl,
          owner.profileId,
          owner.sessionId,
          owner.runId,
        ].any((v) => v == null || v.trim().isEmpty)) {
      journal.valid = false;
      return -1;
    }
    _owner = owner;
    _channel = channel;
    _present = _candidates.any(_same);
    _candidates = const [];
    _aliases = {
      for (final key in M2Validator.owners) key: m2RandomAlias(),
      'exact_owner': true,
    };
    return ++_fence;
  }

  bool _same(HermesDetachedRunLease lease) =>
      lease.baseUrl == _owner?.baseUrl &&
      lease.profileId == _owner?.profileId &&
      lease.sessionId == _owner?.sessionId &&
      lease.runId == _owner?.runId;
  void observeState(
    HermesChannelState state,
    Object channel, {
    required String generation,
    required int fence,
  }) {
    if (_owner == null) {
      if (generation != journal.generation || fence != _fence) {
        journal.valid = false;
        return;
      }
      final matches = _candidates
          .where(
            (lease) =>
                lease.baseUrl == state.connectedBaseUrl &&
                lease.profileId == state.selectedProfileId &&
                lease.sessionId == state.activeSessionId &&
                lease.profileId?.isNotEmpty == true &&
                lease.runId.isNotEmpty &&
                lease.sessionId.isNotEmpty &&
                state.isConnected &&
                !state.isSelectingProfile,
          )
          .toList();
      if (matches.length != 1) return;
      bind(matches.single, channel);
      fence = _fence;
    }
    if (_invalidOwner ||
        !identical(channel, _channel) ||
        generation != journal.generation ||
        fence != _fence ||
        state.connectedBaseUrl != _owner!.baseUrl ||
        state.selectedProfileId != _owner!.profileId ||
        state.activeSessionId != _owner!.sessionId ||
        !state.isConnected ||
        state.isSelectingProfile) {
      _invalidOwner = true;
      _fence++;
      journal.valid = false;
      return;
    }
    journal.record(M2Phase.state, M2Status.success, flags: _aliases);
    // Public state cannot witness internal history admission before lease removal.
    // In particular, activeMessages and hasUnreconciledRun are NOT that witness.
  }

  @override
  Future<List<HermesDetachedRunLease>> load() async {
    final List<HermesDetachedRunLease> result;
    try {
      result = await delegate.load();
    } catch (_) {
      journal.record(
        M2Phase.storeLoad,
        M2Status.failure,
        error: M2Error.delegateFailure,
      );
      rethrow;
    }
    _observeLeases(result, loaded: true);
    return result;
  }

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    try {
      await delegate.save(leases);
    } catch (_) {
      journal.record(
        M2Phase.storeWrite,
        M2Status.failure,
        error: M2Error.delegateFailure,
      );
      rethrow;
    }
    _observeLeases(leases, loaded: false);
  }

  void _observeLeases(
    List<HermesDetachedRunLease> leases, {
    required bool loaded,
  }) {
    journal.record(
      loaded ? M2Phase.storeLoad : M2Phase.storeWrite,
      M2Status.success,
      flags: {loaded ? 'store_load_ack' : 'store_write_ack': true},
    );
    if (_owner == null) {
      if (leases.length > 16) {
        journal.valid = false;
      } else {
        _candidates = List.of(leases);
      }
      return;
    }
    if (_invalidOwner) return;
    final present = leases.any(_same);
    if (leases.any((l) => l.runId == _owner!.runId && !_same(l))) {
      journal.valid = false;
      _invalidOwner = true;
      return;
    }
    if (!loaded && _present && !present) {
      journal.record(
        M2Phase.storeRemoval,
        M2Status.success,
        flags: {..._aliases, 'store_removal_ack': true},
      );
      journal.record(
        M2Phase.availability,
        M2Status.unavailable,
        error: M2Error.historyAdmissionUnavailable,
      );
    }
    _present = present;
  }
}
