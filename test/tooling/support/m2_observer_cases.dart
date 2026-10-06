part of 'm2_fake_harness.dart';

const alias = '00000000-0000-4000-8000-000000000001';
const generation = '00000000-0000-4000-8000-000000000002';

class _MemorySink implements _M2Sink {
  String? value;
  bool fail = false;
  Completer<void>? gate;
  int active = 0;
  int maximumActive = 0;
  bool failRead = false;
  @override
  Future<void> write(String envelope) async {
    active++;
    if (active > maximumActive) maximumActive = active;
    try {
      if (fail) throw StateError('synthetic sink failure');
      await gate?.future;
      value = envelope;
    } finally {
      active--;
    }
  }

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('synthetic read failure');
    return value;
  }
}

class _Delegate implements HermesDetachedRunStore {
  final Object key = Object();
  List<HermesDetachedRunLease> leases = [];
  List<HermesDetachedRunLease>? received;
  Completer<void>? gate;
  Object? failure;
  @override
  Object get coordinationKey => key;
  @override
  Future<List<HermesDetachedRunLease>> load() async {
    if (failure != null) throw failure!;
    return leases;
  }

  @override
  Future<void> save(List<HermesDetachedRunLease> leases) async {
    received = leases;
    await gate?.future;
    if (failure != null) throw failure!;
    this.leases = leases;
  }
}

void registerM2ObserverTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MemorySink sink;
  late _M2Journal journal;
  late _Delegate delegate;
  late _M2StoreObserver observer;
  setUp(() {
    sink = _MemorySink();
    journal = _M2Journal(attempt: alias, generation: generation, sink: sink);
    delegate = _Delegate();
    observer = _M2StoreObserver(delegate: delegate, journal: journal);
  });

  test(
    'delayed delegate preserves identities and cannot acknowledge early',
    () async {
      delegate.gate = Completer<void>();
      final leases = <HermesDetachedRunLease>[];
      final pending = observer.save(leases);
      expect(identical(observer.coordinationKey, delegate.key), isTrue);
      expect(identical(delegate.received, leases), isTrue);
      expect(journal.events, isEmpty);
      delegate.gate!.complete();
      await pending;
      expect(journal.events.single['store_write_ack'], isTrue);
      expect(identical(await observer.load(), delegate.leases), isTrue);
      expect(await journal.flush(), isTrue);
      expect(journal.qualifies, isFalse);
    },
  );

  test(
    'same delegated error survives sink failure for load and save',
    () async {
      final error = StateError('synthetic delegate failure');
      delegate.failure = error;
      sink.fail = true;
      await expectLater(observer.save([]), throwsA(same(error)));
      await expectLater(observer.load(), throwsA(same(error)));
      expect(journal.events.every((e) => e['status'] == 'failure'), isTrue);
      expect(await journal.flush(), isFalse);
      expect(journal.valid, isFalse);
    },
  );

  test(
    'sink failure does not turn successful product save into failure',
    () async {
      sink.fail = true;
      await observer.save([]);
      expect(await journal.flush(), isFalse);
      expect(delegate.leases, isEmpty);
    },
  );

  test('sink commits serialize and readback cannot repair loss', () async {
    sink.gate = Completer<void>();
    await observer.save([]);
    await observer.load();
    await Future<void>.delayed(Duration.zero);
    expect(sink.maximumActive, 1);
    sink.gate!.complete();
    expect(await journal.flush(), isTrue);
    sink.value = null;
    expect(await journal.flush(), isFalse);
  });

  test(
    'extra fields, arbitrary strings, mixed attempts and sequence gaps fail',
    () {
      final event = journal.event(
        M2Phase.storeLoad,
        M2Status.success,
        flags: {'store_load_ack': true},
      );
      for (final change in <Map<String, Object?>>[
        {'body': 'forbidden'},
        {'error': 'arbitrary'},
        {'sequence': 2},
        {'attempt_alias': generation},
        {'elapsed_ms': -1},
        {'process_generation_alias': alias},
        {'run_alias': 'raw-id'},
        {
          'client_attempt_counts': {'extra': 0},
        },
      ]) {
        final validator = M2Validator(attempt: alias, generation: generation);
        expect(
          () => validator.accept({...event, ...change}),
          throwsFormatException,
        );
      }
      final validator = M2Validator(attempt: alias, generation: generation);
      validator.accept(event);
      expect(() => validator.accept(event), throwsFormatException);
    },
  );

  test('128 records are bounded, 129 invalidates without sampling', () async {
    for (var i = 0; i < 128; i++) {
      journal.record(
        M2Phase.storeLoad,
        M2Status.success,
        flags: {'store_load_ack': true},
      );
    }
    expect(journal.events.length, 128);
    journal.record(
      M2Phase.storeLoad,
      M2Status.success,
      flags: {'store_load_ack': true},
    );
    expect(journal.valid, isFalse);
    expect(journal.events.length, 128);
    expect(await journal.flush(), isFalse);
  });

  test(
    'qualification and pre-removal history remain explicitly unavailable',
    () async {
      observer.start();
      expect(await journal.flush(), isTrue);
      expect(
        journal.events.map((e) => e['error']),
        contains('authoritative_counts_unavailable'),
      );
      expect(
        journal.events.map((e) => e['error']),
        contains('history_admission_unavailable'),
      );
      expect(journal.qualifies, isFalse);
    },
  );

  HermesDetachedRunLease lease({
    String? profile = 'synthetic-profile',
    String run = 'synthetic-run',
  }) => HermesDetachedRunLease(
    baseUrl: 'https://hermes.example',
    profileId: profile,
    sessionId: 'synthetic-session',
    runId: run,
    createdAt: DateTime.utc(2026),
  );
  const state = HermesChannelState(
    status: HermesConnectionStatus.connected,
    connectedBaseUrl: 'https://hermes.example',
    selectedProfileId: 'synthetic-profile',
    activeSessionId: 'synthetic-session',
  );

  test(
    'removal acknowledges only after delegated save; never settlement',
    () async {
      final channel = Object();
      final owner = lease();
      final fence = observer.bind(owner, channel);
      observer.observeState(
        state,
        channel,
        generation: generation,
        fence: fence,
      );
      await observer.save([owner]);
      delegate.gate = Completer<void>();
      final removal = observer.save([]);
      expect(
        journal.events.any((e) => e['store_removal_ack'] == true),
        isFalse,
      );
      delegate.gate!.complete();
      await removal;
      expect(
        journal.events.where((e) => e['store_removal_ack'] == true).length,
        1,
      );
      expect(journal.events.any((e) => e['phase'] == 'settlement'), isFalse);
      expect(await journal.flush(), isTrue);
    },
  );

  test(
    'missing or foreign lease owner refuses without altering delegate',
    () async {
      expect(observer.bind(lease(profile: null), Object()), -1);
      expect(journal.valid, isFalse);
      final fresh = _M2Journal(
        attempt: alias,
        generation: generation,
        sink: _MemorySink(),
      );
      final wrapper = _M2StoreObserver(delegate: delegate, journal: fresh);
      wrapper.bind(lease(), Object());
      final foreign = [lease(profile: 'foreign')];
      await wrapper.save(foreign);
      expect(identical(delegate.received, foreign), isTrue);
      expect(fresh.valid, isFalse);
    },
  );

  test(
    'changed channel, owner, stale generation and observation fence refuse',
    () {
      for (var control = 0; control < 4; control++) {
        final fresh = _M2Journal(
          attempt: alias,
          generation: generation,
          sink: _MemorySink(),
        );
        final wrapper = _M2StoreObserver(delegate: delegate, journal: fresh);
        final channel = Object();
        final fence = wrapper.bind(lease(), channel);
        wrapper.observeState(
          control == 1 ? state.copyWith(activeSessionId: 'foreign') : state,
          control == 0 ? Object() : channel,
          generation: control == 2 ? alias : generation,
          fence: control == 3 ? fence + 1 : fence,
        );
        expect(fresh.valid, isFalse);
        wrapper.observeState(
          state,
          channel,
          generation: generation,
          fence: fence,
        );
        expect(fresh.events, isEmpty);
      }
    },
  );

  Map<String, Object?> fixture(
    int sequence,
    String phase, {
    String? message,
    Map<String, Object?> flags = const {},
  }) => {
    'schema_version': 1,
    'attempt_alias': alias,
    'process_generation_alias': generation,
    'sequence': sequence,
    'elapsed_ms': sequence,
    'phase': phase,
    'status': 'fixture',
    for (final key in M2Validator.owners) key: alias,
    'exact_owner': true,
    'message_alias': ?message,
    ...flags,
  };
  test(
    'synthetic canonical order rejects missing, duplicate and early settlement',
    () {
      final digest = List.filled(64, 'a').join();
      final validator = M2Validator(
        attempt: alias,
        generation: generation,
        expectedUserAlias: alias,
        expectedAssistantAlias: generation,
        syntheticExpectedDigest: digest,
      );
      expect(
        () => validator.accept({
          ...fixture(1, 'settlement'),
          'status': 'success',
        }),
        throwsFormatException,
      );
      expect(
        () => validator.accept(
          fixture(1, 'history_assistant', message: generation),
        ),
        throwsFormatException,
      );
      expect(
        () => validator.accept(fixture(1, 'history_user', message: generation)),
        throwsFormatException,
      );
      validator.accept(fixture(1, 'history_user', message: alias));
      expect(
        () => validator.accept(fixture(2, 'history_user', message: alias)),
        throwsFormatException,
      );
      expect(
        () => validator.accept(fixture(2, 'history_assistant', message: alias)),
        throwsFormatException,
      );
      validator.accept(fixture(2, 'history_assistant', message: generation));
      expect(
        () => validator.accept(
          fixture(
            3,
            'canonical',
            flags: {
              'history_match': true,
              'order_match': false,
              'synthetic_result_match': true,
              'synthetic_expected_digest': digest,
            },
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => validator.accept(
          fixture(
            3,
            'canonical',
            flags: {
              'history_match': true,
              'order_match': true,
              'synthetic_result_match': false,
              'synthetic_expected_digest': digest,
            },
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => validator.accept(
          fixture(
            3,
            'canonical',
            flags: {
              'history_match': true,
              'order_match': true,
              'synthetic_result_match': true,
              'synthetic_expected_digest': List.filled(64, 'b').join(),
            },
          ),
        ),
        throwsFormatException,
      );
      validator.accept(
        fixture(
          3,
          'canonical',
          flags: {
            'history_match': true,
            'order_match': true,
            'synthetic_result_match': true,
            'synthetic_expected_digest': digest,
          },
        ),
      );
      validator.accept({...fixture(4, 'settlement'), 'status': 'success'});
      // This validates synthetic ordering only, never production history admission.
      expect(journal.qualifies, isFalse);
    },
  );

  for (final phase in ['history_user', 'history_assistant', 'canonical']) {
    for (final status in ['failure', 'unavailable']) {
      test('$status $phase cannot advance admission state', () {
        final digest = List.filled(64, 'a').join();
        final validator = M2Validator(
          attempt: alias,
          generation: generation,
          expectedUserAlias: alias,
          expectedAssistantAlias: generation,
          syntheticExpectedDigest: digest,
        );
        final ordered = [
          fixture(1, 'history_user', message: alias),
          fixture(2, 'history_assistant', message: generation),
          fixture(
            3,
            'canonical',
            flags: {
              'history_match': true,
              'order_match': true,
              'synthetic_result_match': true,
              'synthetic_expected_digest': digest,
            },
          ),
          {...fixture(4, 'settlement'), 'status': 'success'},
        ];
        final index = ordered.indexWhere((row) => row['phase'] == phase);
        for (final row in ordered.take(index)) {
          validator.accept(row);
        }
        final rejected = {
          ...ordered[index],
          'status': status,
          'error': status == 'failure'
              ? 'delegate_failure'
              : 'history_admission_unavailable',
        };
        expect(() => validator.accept(rejected), throwsFormatException);
        // Reuse the unconsumed sequence: rejection must not set user,
        // assistant or canonical admission even when every match flag is true.
        expect(
          () =>
              validator.accept({...ordered[index + 1], 'sequence': index + 1}),
          throwsFormatException,
        );
        validator.accept({...ordered[index], 'status': 'success'});
        for (final row in ordered.skip(index + 1)) {
          validator.accept(row);
        }
        expect(journal.qualifies, isFalse);
      });
    }
  }

  test('whole UTF8 envelope including wrappers fails above 64 KiB', () {
    final validator = M2Validator(attempt: alias, generation: generation);
    final rows = <Map<String, Object?>>[];
    var overflow = false;
    for (var i = 1; i <= 128; i++) {
      final row = fixture(
        i,
        'canonical',
        flags: {
          for (final key in M2Validator.digests)
            key: List.filled(64, 'a').join(),
          for (final key in M2Validator.aliases)
            if (!{
              'attempt_alias',
              'process_generation_alias',
              'ledger_epoch_alias',
            }.contains(key))
              key: alias,
          'history_match': true,
          'order_match': true,
          'synthetic_result_match': true,
        },
      );
      row['phase'] = 'state';
      final candidate = [...rows, row];
      final bytes = utf8
          .encode(M2Validator.envelope(alias, generation, candidate))
          .length;
      if (bytes <= 65536) {
        validator.accept(row);
        rows.add(row);
      } else {
        expect(() => validator.accept(row), throwsFormatException);
        overflow = true;
        break;
      }
    }
    expect(overflow, isTrue);
  });

  test(
    'unknown authority, second submission and recovery mutations cannot qualify',
    () {
      for (final flags in <Map<String, Object?>>[
        {
          'authoritative_accepted_counts': {
            for (final key in M2Validator.counters) key: 0,
          },
        },
        {
          'authoritative_rejected_counts': {
            for (final key in M2Validator.counters) key: 0,
          },
        },
        {'complete_coverage': true},
        {
          'client_attempt_counts': {
            for (final key in M2Validator.counters)
              key: key == 'deliberate_submission' ? 2 : 0,
          },
        },
        for (final mutation in M2Validator.counters)
          {
            'phase_delta_counts': {
              for (final key in M2Validator.counters)
                key: key == mutation ? 1 : 0,
            },
          },
      ]) {
        final validator = M2Validator(attempt: alias, generation: generation);
        expect(
          () => validator.accept(fixture(1, 'state', flags: flags)),
          throwsFormatException,
        );
      }
    },
  );

  test('exact 64 KiB inclusive limit and envelope fields are strict', () {
    final row = journal.event(
      M2Phase.storeLoad,
      M2Status.success,
      flags: {'store_load_ack': true},
    );
    final encoded = M2Validator.envelope(alias, generation, [row]);
    final padding = List.filled(
      65536 - utf8.encode(encoded).length,
      ' ',
    ).join();
    M2Validator.validateEnvelope(encoded + padding, alias, generation);
    expect(
      () =>
          M2Validator.validateEnvelope('$encoded$padding ', alias, generation),
      throwsFormatException,
    );
    final decoded = jsonDecode(encoded) as Map<String, Object?>;
    expect(
      () => M2Validator.validateEnvelope(
        jsonEncode({...decoded, 'path': 'forbidden'}),
        alias,
        generation,
      ),
      throwsFormatException,
    );
    expect(
      () => M2Validator.validateEnvelope(encoded, alias, alias),
      throwsFormatException,
    );
  });

  test('immutable nested counters and irreversible invalidation', () async {
    final counts = {for (final key in M2Validator.counters) key: 0};
    journal.record(
      M2Phase.availability,
      M2Status.fixture,
      flags: {'client_attempt_counts': counts},
    );
    counts['deliberate_submission'] = 2;
    final saved = journal.events.single['client_attempt_counts'] as Map;
    expect(saved['deliberate_submission'], 0);
    expect(() => saved['deliberate_submission'] = 2, throwsUnsupportedError);
    expect(await journal.flush(), isTrue);
    journal.valid = false;
    journal.valid = true;
    expect(journal.valid, isFalse);
  });

  test(
    'sink read failure invalidates load acknowledgement, not product load',
    () async {
      final result = await observer.load();
      expect(identical(result, delegate.leases), isTrue);
      sink.failRead = true;
      expect(await journal.flush(), isFalse);
      expect(journal.qualifies, isFalse);
    },
  );

  test(
    'changed aliases, missing owner and regressed monotonic time reject',
    () {
      final validator = M2Validator(attempt: alias, generation: generation);
      validator.accept(fixture(1, 'state'));
      final missing = fixture(2, 'state')..remove('run_alias');
      for (final row in [
        missing,
        fixture(2, 'state', flags: {'run_alias': generation}),
        fixture(2, 'state', flags: {'elapsed_ms': 0}),
        fixture(2, 'state', flags: {'sequence': 4}),
        fixture(2, 'state', flags: {'elapsed_ms': M2Validator.maxInteger + 1}),
        fixture(2, 'state', flags: {'exact_owner': 'true'}),
      ]) {
        expect(() => validator.accept(row), throwsFormatException);
      }
    },
  );
}
