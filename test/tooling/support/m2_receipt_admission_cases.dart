part of 'm2_fake_harness.dart';

// Isolated in-process oracle, not an installed issuer or runtime coordinator.
const _attempt = '00000000-0000-4000-8000-000000000001';
const _prior = '00000000-0000-4000-8000-000000000002';
const _current = '00000000-0000-4000-8000-000000000003';

String _envelope(String generation) =>
    M2Validator.envelope(_attempt, generation, [
      for (final (index, error) in [
        'history_admission_unavailable',
        'authoritative_counts_unavailable',
      ].indexed)
        {
          'schema_version': 1,
          'attempt_alias': _attempt,
          'process_generation_alias': generation,
          'sequence': index + 1,
          'elapsed_ms': index,
          'phase': 'availability',
          'status': 'unavailable',
          'error': error,
        },
    ]);

enum _Refusal {
  notAdmitted,
  unavailable,
  invalidEnvelope,
  missingPrior,
  occupied,
}

final class _Slot {
  String? value;
  _Entry? registration;
  int inspections = 0;
  int readbacks = 0;
  int writes = 0;
  int active = 0;
  final trace = <String>[];
  Completer<String?>? readGate;
  Completer<void>? writeGate;
  final writeStarted = Completer<void>();
  bool failWrite = false;

  Future<String?> inspect() async {
    inspections++;
    trace.add('read');
    return readGate == null ? value : await readGate!.future;
  }

  Future<void> write(String encoded) async {
    writes++;
    active++;
    trace.add('write');
    if (!writeStarted.isCompleted) writeStarted.complete();
    try {
      await writeGate?.future;
      if (failWrite) throw StateError('synthetic I/O detail');
      value = encoded;
    } finally {
      active--;
    }
  }
}

// Two wrappers can designate the same physical slot. Registry keys are the
// physical instance plus fixed attempt, never facade identity or generation.
final class _Facade {
  _Facade(this.slot);
  final _Slot slot;
}

final class _Authority {
  int epoch = 0;
  final issued = <_Tuple>{};
  _Tuple issue(
    _Facade facade, {
    bool read = true,
    bool write = true,
    String? prior = _prior,
    String? current,
  }) {
    final tuple = _Tuple(
      this,
      epoch,
      facade.slot,
      prior,
      current ?? _envelope(_current),
      read ? Object() : null,
      write ? Object() : null,
    );
    issued.add(tuple);
    return tuple;
  }

  void revoke() => epoch++;
}

final class _Tuple {
  _Tuple(
    this.authority,
    this.epoch,
    this.storage,
    this.prior,
    this.currentSnapshot,
    this.readRight,
    this.writeRight,
  );
  final _Authority authority;
  final int epoch;
  final _Slot storage;
  final String? prior;
  final String currentSnapshot;
  final Object? readRight;
  final Object? writeRight;
  final schema = 1;
  final operation = 'inspect';
  final attempt = _attempt;
  final current = _current;
  final package = 'com.trebuchetdynamics.hermes.wing.qa';
  final entrypoint = 'integration_test/hermes_m2_observer_main.dart';
  final debug = true;
  final source = Object();
  final artifact = Object();
  final components = Object();
  final plugins = Object();
  final target = Object();
  final ownership = Object();
}

final class _Ack {
  _Ack(this.entry, this.tuple, this.epoch, this.snapshot);
  final _Entry entry;
  final _Tuple tuple;
  final int epoch;
  final String? snapshot;
}

final class _Diagnostic {
  _Diagnostic(this.ack);
  final _Ack ack;
  bool get qualifies => false;
  final unavailable = const {
    'continuation_unavailable',
    'history_admission_unavailable',
    'authoritative_counts_unavailable',
  };
}

final class _Retainer {
  Completer<_Ack>? gate;
  final started = Completer<void>();
  String? snapshot;
  _Ack? proposed;
  int calls = 0;
  Future<_Ack> retain(_Entry entry, String? exact) async {
    calls++;
    snapshot = exact;
    proposed = _Ack(entry, entry.tuple, entry.tuple.epoch, exact);
    if (!started.isCompleted) started.complete();
    return gate == null ? proposed! : await gate!.future;
  }
}

final class _Entry {
  _Entry(this.tuple);
  final _Tuple tuple;
  Future<_Diagnostic>? pending;
  _Diagnostic? diagnostic;
  _Writer? writer;
  bool invalid = false;
  bool consumed = false;
}

enum _Mutation { none, skipRetention, wrapperRegistry, skipEpoch }

final class _Custody {
  _Custody(this.authority, this.retainer, {this.mutation = _Mutation.none});
  final _Authority authority;
  final _Retainer retainer;
  final _Mutation mutation;
  final registry = <Object, _Entry>{};
  final validations = <String>[];
  int writers = 0;
  // No enumeration, deletion, launch, fallback or product operations exist.
  final forbiddenOperations = <String, int>{
    'enumeration': 0,
    'deletion': 0,
    'launch': 0,
    'fallback': 0,
    'product_mutations': 0,
  };

  bool _admitted(_Tuple t) =>
      identical(t.authority, authority) &&
      authority.issued.contains(t) &&
      t.prior != t.current &&
      (mutation == _Mutation.skipEpoch || t.epoch == authority.epoch);
  bool _valid(_Entry e) =>
      !e.invalid &&
      _admitted(e.tuple) &&
      (mutation == _Mutation.wrapperRegistry ||
          identical(e.tuple.storage.registration, e)) &&
      registry.values.any((registered) => identical(registered, e));

  _Entry register(_Tuple t, _Facade facade) {
    final key = mutation == _Mutation.wrapperRegistry ? facade : facade.slot;
    if (!_admitted(t) ||
        !identical(t.storage, facade.slot) ||
        t.readRight == null ||
        registry.containsKey(key) ||
        mutation != _Mutation.wrapperRegistry &&
            facade.slot.registration != null) {
      throw _Refusal.notAdmitted;
    }
    final entry = _Entry(t);
    registry[key] = entry;
    if (mutation != _Mutation.wrapperRegistry) facade.slot.registration = entry;
    return entry;
  }

  void _validate(String snapshot, String generation) {
    validations.add(generation);
    M2Validator.validateEnvelope(snapshot, _attempt, generation);
  }

  Future<_Diagnostic> inspect(_Entry entry) {
    if (!_valid(entry)) return Future.error(_Refusal.notAdmitted);
    return entry.pending ??= _inspect(entry);
  }

  Future<_Diagnostic> _inspect(_Entry e) async {
    try {
      _validate(e.tuple.currentSnapshot, e.tuple.current);
      final prior = await e.tuple.storage.inspect();
      if (!_valid(e)) throw _Refusal.notAdmitted;
      if (e.tuple.prior == null) {
        if (prior != null) throw _Refusal.occupied;
      } else {
        if (prior == null) throw _Refusal.missingPrior;
        _validate(prior, e.tuple.prior!);
      }
      final ack = mutation == _Mutation.skipRetention
          ? _Ack(e, e.tuple, e.tuple.epoch, prior)
          : await retainer.retain(e, prior);
      if (!_valid(e) ||
          !identical(ack, retainer.proposed) &&
              mutation != _Mutation.skipRetention ||
          !identical(ack.entry, e) ||
          !identical(ack.tuple, e.tuple) ||
          ack.epoch != e.tuple.epoch ||
          ack.snapshot != prior) {
        throw _Refusal.unavailable;
      }
      e.tuple.storage.trace.add('retained');
      return e.diagnostic = _Diagnostic(ack);
    } catch (error) {
      e.invalid = true;
      throw error is _Refusal ? error : _Refusal.invalidEnvelope;
    }
  }

  _Writer release(_Entry e, _Ack? ack, _Tuple t) {
    if (!_valid(e) ||
        e.consumed ||
        t.writeRight == null ||
        !identical(t, e.tuple) ||
        ack == null ||
        !identical(ack, e.diagnostic?.ack) ||
        ack.epoch != authority.epoch) {
      throw _Refusal.notAdmitted;
    }
    e.consumed = true;
    writers++;
    e.tuple.storage.trace.add('released');
    return e.writer = _Writer(this, e);
  }
}

final class _Writer implements _M2Sink {
  _Writer(this.custody, this.entry);
  final _Custody custody;
  final _Entry entry;
  void _check() {
    if (!custody._valid(entry) ||
        !identical(entry.writer, this) ||
        !entry.consumed ||
        entry.tuple.writeRight == null) {
      throw _Refusal.notAdmitted;
    }
  }

  @override
  Future<void> write(String envelope) async {
    _check();
    M2Validator.validateEnvelope(envelope, _attempt, _current);
    try {
      await entry.tuple.storage.write(envelope);
      _check();
    } catch (_) {
      entry.invalid = true;
      throw _Refusal.unavailable;
    }
  }

  @override
  Future<String?> read() async {
    _check();
    entry.tuple.storage.readbacks++;
    return entry.tuple.storage.value;
  }
}

final class _Harness {
  _Harness({
    bool write = true,
    String? prior = _prior,
    String? current,
    _Mutation mutation = _Mutation.none,
  }) {
    slot.value = prior == null ? null : ' \n${_envelope(_prior)}\t\r\n';
    facade = _Facade(slot);
    tuple = authority.issue(
      facade,
      write: write,
      prior: prior,
      current: current,
    );
    custody = _Custody(authority, retainer, mutation: mutation);
    entry = custody.register(tuple, facade);
  }
  final authority = _Authority();
  final slot = _Slot();
  final retainer = _Retainer();
  late final _Facade facade;
  late final _Tuple tuple;
  late final _Custody custody;
  late final _Entry entry;
  _M2Journal journal(_Writer writer) =>
      _M2Journal(attempt: _attempt, generation: _current, sink: writer);
}

void _noWriter(_Harness h, {_Ack? ack, _Tuple? tuple}) {
  final before = (
    h.slot.inspections,
    h.slot.readbacks,
    h.slot.writes,
    h.custody.writers,
  );
  expect(
    () => h.custody.release(h.entry, ack, tuple ?? h.tuple),
    throwsA(isA<_Refusal>()),
  );
  expect((
    h.slot.inspections,
    h.slot.readbacks,
    h.slot.writes,
    h.custody.writers,
  ), before);
}

Future<void> _noCompetitor(_Harness h) async {
  final before = (
    h.slot.inspections,
    h.slot.readbacks,
    h.slot.writes,
    h.custody.writers,
  );
  final other = _Facade(h.slot);
  final tuple = h.authority.issue(other);
  expect(() => h.custody.register(tuple, other), throwsA(_Refusal.notAdmitted));
  expect(
    () => h.custody.register(h.tuple, other),
    throwsA(_Refusal.notAdmitted),
  );
  final foreignAuthority = _Authority();
  final competingCustodian = _Custody(foreignAuthority, _Retainer());
  expect(
    () => competingCustodian.register(foreignAuthority.issue(other), other),
    throwsA(_Refusal.notAdmitted),
  );
  expect(competingCustodian.writers, 0);
  // A forged writer and a separate journal must still refuse underlying I/O.
  final forged = _Writer(h.custody, _Entry(tuple));
  await expectLater(
    forged.write(_envelope(_current)),
    throwsA(_Refusal.notAdmitted),
  );
  await expectLater(forged.read(), throwsA(_Refusal.notAdmitted));
  final copiedFacade = _Writer(h.custody, h.entry);
  await expectLater(
    copiedFacade.write(_envelope(_current)),
    throwsA(_Refusal.notAdmitted),
  );
  expect((
    h.slot.inspections,
    h.slot.readbacks,
    h.slot.writes,
    h.custody.writers,
  ), before);
}

void registerM2ReceiptAdmissionTests() {
  test('REG-INJECTION: foreign writer refuses before fake I/O', () async {
    final h = _Harness();
    final diagnostic = await h.custody.inspect(h.entry);
    h.custody.release(h.entry, diagnostic.ack, h.tuple);
    final foreign = _Writer(h.custody, _Entry(h.tuple));
    try {
      await foreign.write(_envelope(_current));
    } on _Refusal catch (error) {
      expect(error, _Refusal.notAdmitted);
      expect((h.slot.writes, h.slot.readbacks), (0, 0));
      return;
    }
    throw StateError('REG-INJECTION foreign writer reached fake I/O');
  });

  test('REG-POSITIVE: exact retention then one released first write', () async {
    final h = _Harness();
    final original = h.slot.value;
    final diagnostic = await h.custody.inspect(h.entry);
    expect(h.retainer.snapshot, original);
    expect((h.slot.inspections, h.slot.readbacks, h.slot.writes), (1, 0, 0));
    final writer = h.custody.release(h.entry, diagnostic.ack, h.tuple);
    final journal = h.journal(writer);
    journal.record(
      M2Phase.availability,
      M2Status.unavailable,
      error: M2Error.historyAdmissionUnavailable,
    );
    expect(await journal.flush(), isTrue);
    expect(h.slot.trace, ['read', 'retained', 'released', 'write']);
    expect((h.slot.inspections, h.slot.readbacks, h.slot.writes), (1, 1, 1));
    expect(h.retainer.snapshot, original);
    expect(h.custody.forbiddenOperations.values, everyElement(0));
  });

  test(
    'OBS-PAIR/REPLAY: independent validation, exact retention, explicit release',
    () async {
      final h = _Harness();
      final original = h.slot.value!;
      final diagnostic = await h.custody.inspect(h.entry);
      expect(h.custody.validations, [_current, _prior]);
      expect(utf8.encode(h.retainer.snapshot!), utf8.encode(original));
      expect((h.slot.inspections, h.slot.writes, h.custody.writers), (1, 0, 0));
      expect(identical(await h.custody.inspect(h.entry), diagnostic), isTrue);
      final writer = h.custody.release(h.entry, diagnostic.ack, h.tuple);
      expect(h.slot.writes, 0);
      _noWriter(h, ack: diagnostic.ack);
      final journal = h.journal(writer);
      journal.record(
        M2Phase.availability,
        M2Status.unavailable,
        error: M2Error.historyAdmissionUnavailable,
      );
      journal.record(
        M2Phase.availability,
        M2Status.unavailable,
        error: M2Error.authoritativeCountsUnavailable,
      );
      expect(await journal.flush(), isTrue);
      expect(h.slot.trace.take(4), ['read', 'retained', 'released', 'write']);
      expect(h.slot.writes, greaterThan(0));
      expect(h.slot.readbacks, 1);
      expect(h.slot.value, isNot(original));
      expect(identical(await h.custody.inspect(h.entry), diagnostic), isTrue);
      expect(h.slot.inspections, 1);
      expect(h.retainer.calls, 1);
      expect(h.retainer.snapshot, original);
      expect(journal.qualifies, isFalse);
      expect(diagnostic.qualifies, isFalse);
      expect(diagnostic.unavailable, {
        'continuation_unavailable',
        'history_admission_unavailable',
        'authoritative_counts_unavailable',
      });
      expect(h.custody.forbiddenOperations.values, everyElement(0));
    },
  );

  test(
    'OBS-REGISTER/READRACE: wrappers share custody throughout one pending read',
    () async {
      final h = _Harness();
      h.slot.readGate = Completer<String?>();
      final pending = h.custody.inspect(h.entry);
      final replay = h.custody.inspect(h.entry);
      expect(identical(pending, replay), isTrue);
      expect((h.slot.inspections, h.slot.writes), (1, 0));
      _noWriter(h);
      await _noCompetitor(h);
      expect(h.retainer.calls, 0);
      h.slot.readGate!.complete(h.slot.value);
      final diagnostic = await pending;
      expect(identical(await replay, diagnostic), isTrue);
      await _noCompetitor(h);
      expect((h.slot.inspections, h.slot.writes, h.custody.writers), (1, 0, 0));
    },
  );

  for (final revoke in [false, true]) {
    test(
      'OBS-READRACE: late ${revoke ? 'revoked' : 'failed'} read is terminal',
      () async {
        final h = _Harness();
        h.slot.readGate = Completer<String?>();
        final pending = h.custody.inspect(h.entry);
        final refused = expectLater(pending, throwsA(isA<_Refusal>()));
        _noWriter(h);
        await _noCompetitor(h);
        if (revoke) {
          h.authority.revoke();
          h.slot.readGate!.complete(h.slot.value);
        } else {
          h.slot.readGate!.completeError(
            StateError('synthetic private detail'),
          );
        }
        await refused;
        expect(h.retainer.calls, 0);
        expect(h.entry.diagnostic, isNull);
        _noWriter(h);
        await _noCompetitor(h);
        await expectLater(
          h.custody.inspect(h.entry),
          throwsA(_Refusal.notAdmitted),
        );
        expect(
          (h.slot.inspections, h.slot.writes, h.custody.writers),
          (1, 0, 0),
        );
      },
    );
  }

  for (final outcome in ['valid', 'revoked', 'wrong', 'failure']) {
    test('OBS-RETAINRACE: $outcome acknowledgement fences release', () async {
      final h = _Harness();
      h.retainer.gate = Completer<_Ack>();
      final pending = h.custody.inspect(h.entry);
      final result = outcome == 'valid'
          ? null
          : expectLater(pending, throwsA(isA<_Refusal>()));
      await h.retainer.started.future;
      expect((h.slot.inspections, h.slot.writes, h.custody.writers), (1, 0, 0));
      final exact = h.retainer.snapshot;
      _noWriter(h, ack: h.retainer.proposed);
      await _noCompetitor(h);
      expect(h.entry.diagnostic, isNull);
      if (outcome == 'revoked') h.authority.revoke();
      if (outcome == 'failure') {
        h.retainer.gate!.completeError(StateError('synthetic private detail'));
      } else {
        h.retainer.gate!.complete(
          outcome == 'wrong'
              ? _Ack(h.entry, h.tuple, h.tuple.epoch, exact)
              : h.retainer.proposed!,
        );
      }
      if (result != null) {
        await result;
        expect(h.entry.diagnostic, isNull);
        _noWriter(h, ack: h.retainer.proposed);
      } else {
        final d = await pending;
        expect(identical(d.ack, h.retainer.proposed), isTrue);
        expect(h.slot.writes, 0);
        h.custody.release(h.entry, d.ack, h.tuple);
        expect(h.custody.writers, 1);
      }
      expect(h.retainer.snapshot, exact);
      expect(h.slot.writes, 0);
      expect(h.slot.inspections, 1);
    });
  }

  test(
    'OBS-RELEASE: wrong, missing, foreign tuple, stale and replayed acknowledgements',
    () async {
      final h = _Harness();
      _noWriter(h);
      final d = await h.custody.inspect(h.entry);
      _noWriter(h);
      _noWriter(h, ack: _Ack(h.entry, h.tuple, h.tuple.epoch, d.ack.snapshot));
      final other = h.authority.issue(h.facade);
      _noWriter(h, ack: d.ack, tuple: other);
      final foreign = _Harness();
      _noWriter(h, ack: (await foreign.custody.inspect(foreign.entry)).ack);
      h.authority.revoke();
      _noWriter(h, ack: d.ack);
      await expectLater(
        h.custody.inspect(h.entry),
        throwsA(_Refusal.notAdmitted),
      );
      await _noCompetitor(h);
      final readOnly = _Harness(write: false);
      final ro = await readOnly.custody.inspect(readOnly.entry);
      _noWriter(readOnly, ack: ro.ack);
    },
  );

  for (final ending in ['success', 'failure', 'revoked', 'invalidated']) {
    test(
      'OBS-TWOWRITERS: $ending cannot transfer ownership during pending A write',
      () async {
        final h = _Harness();
        final d = await h.custody.inspect(h.entry);
        final writer = h.custody.release(h.entry, d.ack, h.tuple);
        final journalA = h.journal(writer);
        final competitorTuple = h.authority.issue(_Facade(h.slot));
        final journalB = h.journal(_Writer(h.custody, _Entry(competitorTuple)));
        h.slot.writeGate = Completer<void>();
        journalA.record(
          M2Phase.availability,
          M2Status.unavailable,
          error: M2Error.historyAdmissionUnavailable,
        );
        await h.slot.writeStarted.future;
        expect((h.slot.active, h.slot.writes, h.custody.writers), (1, 1, 1));
        await _noCompetitor(h);
        journalB.record(
          M2Phase.availability,
          M2Status.unavailable,
          error: M2Error.historyAdmissionUnavailable,
        );
        expect(await journalB.flush(), isFalse);
        _noWriter(h, ack: d.ack);
        expect((h.slot.writes, h.slot.readbacks), (1, 0));
        if (ending == 'failure') h.slot.failWrite = true;
        if (ending == 'revoked') h.authority.revoke();
        if (ending == 'invalidated') h.entry.invalid = true;
        await _noCompetitor(h);
        expect(h.slot.active, 1);
        h.slot.writeGate!.complete();
        expect(await journalA.flush(), ending == 'success');
        expect(h.slot.active, 0);
        expect(h.slot.writes, 1);
        expect(h.slot.readbacks, ending == 'success' ? 1 : 0);
        expect(h.slot.inspections, 1);
        expect(h.custody.writers, 1);
        await _noCompetitor(h);
        _noWriter(h, ack: d.ack);
        expect(await journalB.flush(), isFalse);
      },
    );
  }

  test(
    'prior/current rejection is independent and cannot partially retain',
    () async {
      for (final invalidPrior in [false, true]) {
        final h = _Harness(current: invalidPrior ? null : _envelope(_prior));
        if (invalidPrior) h.slot.value = _envelope(_current);
        final original = h.slot.value;
        await expectLater(
          h.custody.inspect(h.entry),
          throwsA(_Refusal.invalidEnvelope),
        );
        expect(
          h.custody.validations,
          invalidPrior ? [_current, _prior] : [_current],
        );
        expect(h.slot.inspections, invalidPrior ? 1 : 0);
        expect(h.retainer.calls, 0);
        expect(h.slot.value, original);
        _noWriter(h);
      }
    },
  );

  test(
    'fresh empty acknowledgement and occupied refusal never auto-write',
    () async {
      final fresh = _Harness(prior: null);
      final d = await fresh.custody.inspect(fresh.entry);
      expect(d.ack.snapshot, isNull);
      expect(identical(d.ack, fresh.retainer.proposed), isTrue);
      expect((fresh.slot.inspections, fresh.slot.writes), (1, 0));
      fresh.custody.release(fresh.entry, d.ack, fresh.tuple);
      expect(fresh.slot.writes, 0);
      final occupied = _Harness(prior: null)..slot.value = _envelope(_current);
      await expectLater(
        occupied.custody.inspect(occupied.entry),
        throwsA(_Refusal.occupied),
      );
      _noWriter(occupied);
    },
  );

  test(
    'negative discriminator: missing retention is observable, not final-slot equality',
    () async {
      final mutant = _Harness(mutation: _Mutation.skipRetention);
      final d = await mutant.custody.inspect(mutant.entry);
      mutant.custody.release(mutant.entry, d.ack, mutant.tuple);
      expect(mutant.custody.writers, 1);
      // Correct OBS-PAIR requires an independently acknowledged exact snapshot.
      expect(identical(d.ack, mutant.retainer.proposed), isFalse);
      expect(mutant.retainer.calls, 0);
    },
  );

  test(
    'negative discriminator: facade-keyed registry admits a forbidden competitor',
    () {
      final mutant = _Harness(mutation: _Mutation.wrapperRegistry);
      final other = _Facade(mutant.slot);
      final tuple = mutant.authority.issue(other);
      mutant.custody.register(tuple, other);
      expect(mutant.custody.registry.length, 2);
      // Correct OBS-REGISTER rejects this before any second inspection.
      expect(mutant.custody.registry.length == 1, isFalse);
    },
  );

  test(
    'negative discriminator: omitted post-await epoch check returns revoked success',
    () async {
      final mutant = _Harness(mutation: _Mutation.skipEpoch);
      mutant.slot.readGate = Completer<String?>();
      final pending = mutant.custody.inspect(mutant.entry);
      mutant.authority.revoke();
      mutant.slot.readGate!.complete(mutant.slot.value);
      final d = await pending;
      expect(d.ack.epoch == mutant.authority.epoch, isFalse);
      expect(mutant.entry.diagnostic, same(d));
      // Correct OBS-READRACE requires terminal refusal and no diagnostic.
    },
  );
}
