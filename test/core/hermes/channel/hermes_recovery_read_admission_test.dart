import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/channel/hermes_detached_run_store.dart';
import 'package:wing/core/hermes/hermes_api.dart';

const _origin = 'http://127.0.0.1:8642';

final class _Store implements HermesDetachedRunStore {
  _Store({
    String origin = _origin,
    String? profile,
    String session = 'session_a',
  }) : leases = [
         HermesDetachedRunLease(
           runId: 'run_a',
           sessionId: session,
           baseUrl: origin,
           profileId: profile,
           createdAt: DateTime.utc(2026),
         ),
       ];

  List<HermesDetachedRunLease> leases;
  @override
  Object get coordinationKey => this;
  @override
  Future<List<HermesDetachedRunLease>> load() async => List.of(leases);
  @override
  Future<void> save(List<HermesDetachedRunLease> value) async {
    leases = List.of(value);
  }
}

final class _Fixture {
  _Fixture(
    this.store, {
    this.outcome = 'completed',
    this.statusAllowed = true,
    this.historyAllowed = true,
    this.pagination = false,
    this.historyDeclaration = 'exact',
    this.historyGranted = false,
  });
  final _Store store;
  String outcome;
  final bool statusAllowed;
  final bool historyAllowed;
  final bool pagination;
  final String historyDeclaration;
  final bool historyGranted;
  int mutations = 0;
  int streams = 0;
  int statusReads = 0;
  int historyReads = 0;
  final statusEntered = Completer<void>();
  final historyEntered = Completer<void>();
  final lineageEntered = Completer<void>();
  final release = Completer<void>();

  Map<String, Object?> _history(String session) => {
    'object': 'list',
    'session_id': session,
    'data': [
      {
        'id': session == 'session_b' ? 'message_b' : 'message_a',
        'session_id': session,
        'role': 'assistant',
        'content': session == 'session_b'
            ? 'Synthetic foreign history'
            : 'Synthetic canonical history',
      },
    ],
    'pagination': {'limit': 500, 'offset': 0, 'order': 'latest', 'returned': 1},
  };

  late final channel = HermesApiChannel(
    detachedRunStore: store,
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, headers) async {
        expect(uri.origin, _origin);
        expect(uri.queryParameters.containsKey('profile'), isFalse);
        switch (uri.path) {
          case '/health':
            return '{"status":"ok"}';
          case '/v1/capabilities':
            return jsonEncode({
              'object': 'hermes.api_server.capabilities',
              'schema_version': historyDeclaration == 'schema' ? 2 : 1,
              'auth': {
                'type': 'bearer',
                'required': true,
                'granted_scopes': [if (historyGranted) 'history:read'],
              },
              'features': {'run_status': true, 'session_chat_streaming': true},
              'endpoints': {
                'session': {
                  'method': 'GET',
                  'path': '/api/sessions/{session_id}',
                },
                'session_chat_stream': {
                  'method': 'POST',
                  'path': '/api/sessions/{session_id}/chat/stream',
                },
                if (historyDeclaration != 'omitted')
                  'session_messages': {
                    'method': historyDeclaration == 'method' ? 'POST' : 'GET',
                    'path': historyDeclaration == 'path'
                        ? '/api/sessions/{session_id}/other'
                        : '/api/sessions/{session_id}/messages',
                    if (!historyAllowed || historyGranted)
                      'required_scopes': ['history:read'],
                    if (historyDeclaration == 'profile') 'profile_scoped': true,
                  },
                'run_status': {
                  'method': 'GET',
                  'path': '/v1/runs/{run_id}',
                  if (!statusAllowed) 'required_scopes': ['runs:read'],
                },
              },
            });
          case '/api/sessions':
            return '{"object":"list","data":[{"id":"session_a"}]}';
          case '/api/sessions/session_a':
            return '{"object":"hermes.session","session":{"id":"session_a","parent_session_id":"root"}}';
          case '/api/sessions/root':
            return '{"object":"hermes.session","session":{"id":"root","end_reason":"compression"}}';
          case '/api/sessions/root/messages':
            if (outcome == 'late-lineage') {
              if (!lineageEntered.isCompleted) lineageEntered.complete();
              await release.future;
            }
            return jsonEncode({..._history('session_a'), 'data': []});
          case '/v1/runs/run_a':
            statusReads++;
            if (!statusEntered.isCompleted) statusEntered.complete();
            if (outcome == 'late-status') await release.future;
            if (outcome == 'absent' || outcome == 'foreign-404') {
              throw StateError('Hermes API returned HTTP 404.');
            }
            if (outcome == 'denied') {
              throw StateError('Hermes API returned HTTP 403.');
            }
            return jsonEncode({
              'run_id': outcome == 'wrong-run' ? 'run_b' : 'run_a',
              'session_id': outcome == 'wrong-session'
                  ? 'session_b'
                  : 'session_a',
              'status': 'completed',
              'output': 'Synthetic status output is not canonical history',
            });
          case '/api/sessions/session_a/messages':
            historyReads++;
            expect(uri.queryParameters['limit'], '500');
            final offset = int.parse(uri.queryParameters['offset']!);
            if (!pagination) expect(offset, 0);
            expect(uri.queryParameters['order'], 'latest');
            if (!historyEntered.isCompleted) historyEntered.complete();
            if (outcome == 'late-history') await release.future;
            if (outcome == 'history-denied' || outcome == 'history-absent') {
              throw StateError(
                'Hermes API returned HTTP ${outcome == 'history-denied' ? 403 : 404}.',
              );
            }
            final page = _history(
              outcome == 'wrong-history' ? 'session_b' : 'session_a',
            );
            if (outcome == 'wrong-envelope') page['session_id'] = 'session_b';
            if (outcome == 'wrong-row') {
              (page['data'] as List)
                      .cast<Map<String, Object?>>()
                      .single['session_id'] =
                  'session_b';
            }
            if (outcome == 'compression' || outcome == 'late-lineage') {
              (page['data'] as List)
                      .cast<Map<String, Object?>>()
                      .single['session_id'] =
                  'root';
            }
            if (pagination) {
              page['pagination'] = {
                'limit': 1,
                'offset': offset,
                'order': 'latest',
              };
              if (offset > 0) {
                final row = (page['data'] as List)
                    .cast<Map<String, Object?>>()
                    .single;
                row['id'] = 'older_message';
                row['content'] = 'Synthetic earlier history';
              }
            }
            return jsonEncode(page);
          default:
            throw StateError('Unexpected synthetic read');
        }
      },
      post: (uri, headers, body) async {
        mutations++;
        throw StateError('Recovery must not POST');
      },
      patch: (uri, headers, body) async {
        mutations++;
        throw StateError('Recovery must not PATCH');
      },
      delete: (uri, headers) async {
        mutations++;
        throw StateError('Recovery must not DELETE');
      },
      put: (uri, headers, body) async {
        mutations++;
        throw StateError('Recovery must not PUT');
      },
      postStream: (uri, headers, body) {
        mutations++;
        return const Stream.empty();
      },
      getStream: (uri, headers) {
        streams++;
        return const Stream.empty();
      },
    ),
  );
}

void main() {
  test(
    'verified compression ancestor settles terminal lease without replay',
    () async {
      final fixture = _Fixture(_Store(), outcome: 'compression');
      addTearDown(fixture.channel.dispose);
      await fixture.channel.connect(baseUrl: _origin);
      expect(fixture.channel.state.status, HermesConnectionStatus.connected);
      expect(fixture.store.leases, isEmpty);
      expect(
        fixture.channel.state.activeMessages.single.sessionId,
        'session_a',
      );
      expect(fixture.channel.state.activeMessages.single.id, 'message_a');
      expect(fixture.mutations, 0);
      expect(fixture.streams, 0);
    },
  );

  test(
    'replacement connection during lineage proof retains durable lease',
    () async {
      final fixture = _Fixture(_Store(), outcome: 'late-lineage');
      addTearDown(fixture.channel.dispose);
      final connecting = fixture.channel.connect(baseUrl: _origin);
      await fixture.lineageEntered.future;
      await fixture.channel.disconnect();
      fixture.release.complete();
      await connecting;
      expect(fixture.store.leases.single.runId, 'run_a');
      expect(fixture.channel.state.messages, isEmpty);
      expect(fixture.mutations, 0);
      expect(fixture.streams, 0);
    },
  );
  for (final outcome in ['wrong-envelope', 'wrong-row']) {
    test(
      '$outcome retains durable ownership and later exact history settles',
      () async {
        final store = _Store();
        final original = store.leases.single.toJson();
        final first = _Fixture(store, outcome: outcome);
        await first.channel.connect(baseUrl: _origin);
        expect(first.channel.state.status, HermesConnectionStatus.error);
        expect(first.channel.state.messages, isEmpty);
        expect(first.channel.state.messageHistoryNextOffsets, isEmpty);
        expect(store.leases.single.toJson(), original);
        await expectLater(
          first.channel.sendText('Synthetic duplicate'),
          throwsStateError,
        );
        expect(first.mutations, 0);
        expect(first.streams, 0);
        first.channel.dispose();
        final second = _Fixture(store);
        addTearDown(second.channel.dispose);
        await second.channel.connect(baseUrl: _origin);
        expect(store.leases, isEmpty);
        expect(second.channel.state.activeMessages.single.id, 'message_a');
        expect(second.mutations, 0);
        expect(second.streams, 0);
      },
    );
  }

  for (final outcome in ['wrong-envelope', 'wrong-row']) {
    test(
      'earlier $outcome preserves good transcript and pagination then retries',
      () async {
        final store = _Store()..leases.clear();
        final fixture = _Fixture(store, pagination: true);
        addTearDown(fixture.channel.dispose);
        await fixture.channel.connect(baseUrl: _origin);
        final before = fixture.channel.state.activeMessages;
        final offsets = fixture.channel.state.messageHistoryNextOffsets;
        fixture.outcome = outcome;
        await fixture.channel.loadEarlierMessages();
        expect(fixture.channel.state.activeMessages, before);
        expect(fixture.channel.state.messageHistoryNextOffsets, offsets);
        expect(fixture.channel.state.sessionsLoadingEarlierMessages, isEmpty);
        expect(fixture.channel.state.errorMessage, isNotNull);
        fixture.outcome = 'completed';
        await fixture.channel.loadEarlierMessages();
        expect(fixture.channel.state.messageHistoryNextOffsets['session_a'], 2);
        expect(fixture.channel.state.errorMessage, isNull);
        expect(fixture.mutations, 0);
        expect(fixture.streams, 0);
      },
    );
  }

  for (final outcome in [
    'completed',
    'absent',
    'foreign-404',
    'denied',
    'wrong-run',
    'wrong-session',
    'history-denied',
    'history-absent',
    'wrong-history',
  ]) {
    test('recovery read admission characterizes $outcome', () async {
      final store = _Store();
      final originalLease = store.leases.single.toJson();
      final fixture = _Fixture(store, outcome: outcome);
      addTearDown(fixture.channel.dispose);
      await fixture.channel.connect(baseUrl: _origin);
      final cleared = outcome == 'completed';
      expect(store.leases.isEmpty, cleared);
      if (outcome == 'absent' ||
          outcome == 'foreign-404' ||
          outcome == 'wrong-history') {
        expect(store.leases.single.toJson(), originalLease);
        if (outcome == 'wrong-history') {
          expect(fixture.channel.state.status, HermesConnectionStatus.error);
        } else {
          expect(fixture.channel.state.hasUnreconciledRun, isTrue);
        }
        await expectLater(
          fixture.channel.sendText('Synthetic duplicate attempt'),
          outcome == 'wrong-history'
              ? throwsStateError
              : throwsA(
                  isA<StateError>().having(
                    (error) => error.message,
                    'unresolved owner refusal',
                    'Hermes run is still active. Reconnect later before retrying.',
                  ),
                ),
        );
      }
      expect(fixture.statusReads, 1);
      expect(
        fixture.historyReads,
        [
              'completed',
              'wrong-history',
              'history-denied',
              'history-absent',
            ].contains(outcome)
            ? 2
            : 1,
      );
      expect(fixture.mutations, 0);
      expect(fixture.streams, 0);
      if (outcome.startsWith('history-') || outcome == 'wrong-history') {
        expect(store.leases.single.runId, 'run_a');
        expect(fixture.channel.state.activeMessages, isEmpty);
      } else {
        expect(fixture.channel.state.hasUnreconciledRun, !cleared);
        expect(
          fixture.channel.state.activeMessages.single.text,
          outcome == 'wrong-history'
              ? 'Synthetic foreign history'
              : 'Synthetic canonical history',
        );
        expect(
          fixture.channel.state.activeMessages.single.id,
          outcome == 'wrong-history' ? 'message_b' : 'message_a',
        );
        expect(
          fixture.channel.state.activeMessages.single.sessionId,
          'session_a',
        );
      }
      expect(
        fixture.channel.state.activeMessages.any(
          (turn) => turn.text.contains('status output'),
        ),
        isFalse,
      );
    });
  }

  for (final outcome in ['absent', 'foreign-404']) {
    test('$outcome retains ownership through retry and recreation', () async {
      final store = _Store();
      final originalLease = store.leases.single.toJson();
      final first = _Fixture(store, outcome: outcome);
      var firstDisposed = false;
      addTearDown(() {
        if (!firstDisposed) first.channel.dispose();
      });
      await first.channel.connect(baseUrl: _origin);
      await first.channel.selectSession('session_a');
      expect(store.leases.single.toJson(), originalLease);
      expect(first.channel.state.hasUnreconciledRun, isTrue);
      expect(first.statusReads, 2);
      expect(first.mutations, 0);
      expect(first.streams, 0);
      first.channel.dispose();
      firstDisposed = true;

      final second = _Fixture(store, outcome: outcome);
      addTearDown(second.channel.dispose);
      await second.channel.connect(baseUrl: _origin);
      expect(store.leases.single.toJson(), originalLease);
      expect(second.channel.state.hasUnreconciledRun, isTrue);
      await expectLater(
        second.channel.sendText('Synthetic duplicate attempt'),
        throwsStateError,
      );
      expect(second.mutations, 0);
      expect(second.streams, 0);

      second.outcome = 'completed';
      await second.channel.selectSession('session_a');
      expect(store.leases, isEmpty);
      expect(second.channel.state.hasUnreconciledRun, isFalse);
      expect(second.channel.state.activeMessages.single.id, 'message_a');
      expect(second.channel.state.activeMessages.single.sessionId, 'session_a');
      expect(
        second.channel.state.activeMessages.single.text,
        'Synthetic canonical history',
      );
      expect(second.statusReads, 2);
      expect(second.historyReads, 3);
      expect(second.mutations, 0);
      expect(second.streams, 0);
    });
  }

  test('ungranted status read retains lease without status I/O', () async {
    final fixture = _Fixture(_Store(), statusAllowed: false);
    addTearDown(fixture.channel.dispose);
    await fixture.channel.connect(baseUrl: _origin);
    expect(fixture.statusReads, 0);
    expect(fixture.store.leases.single.runId, 'run_a');
    expect(fixture.channel.state.hasUnreconciledRun, isTrue);
    expect(fixture.mutations, 0);
  });

  test(
    'ungranted history refuses hydration and retains durable Send protection',
    () async {
      final fixture = _Fixture(_Store(), historyAllowed: false);
      addTearDown(fixture.channel.dispose);
      await fixture.channel.connect(baseUrl: _origin);
      expect(fixture.historyReads, 0);
      expect(fixture.store.leases.single.runId, 'run_a');
      expect(fixture.channel.state.messages, isEmpty);
      expect(fixture.channel.state.messageHistoryNextOffsets, isEmpty);
      expect(fixture.channel.state.status, HermesConnectionStatus.error);
      await expectLater(
        fixture.channel.sendText('Synthetic duplicate attempt'),
        throwsStateError,
      );
      expect(fixture.mutations, 0);
      expect(fixture.streams, 0);
    },
  );

  for (final declaration in ['method', 'path', 'schema', 'profile']) {
    test('declared history $declaration refuses bootstrap I/O', () async {
      final fixture = _Fixture(_Store(), historyDeclaration: declaration);
      addTearDown(fixture.channel.dispose);
      await fixture.channel.connect(baseUrl: _origin);
      expect(fixture.historyReads, 0);
      expect(fixture.store.leases.single.runId, 'run_a');
      expect(fixture.channel.state.messages, isEmpty);
      expect(fixture.channel.state.status, HermesConnectionStatus.error);
      expect(fixture.mutations, 0);
    });
  }

  test('history denial survives recreation until an authorized read', () async {
    final store = _Store();
    final original = store.leases.single.toJson();
    for (var attempt = 0; attempt < 2; attempt++) {
      final denied = _Fixture(store, historyAllowed: false);
      try {
        await denied.channel.connect(baseUrl: _origin);
        expect(store.leases.single.toJson(), original);
        expect(denied.channel.state.hasUnreconciledRun, isTrue);
        expect(denied.channel.state.messages, isEmpty);
        await expectLater(
          denied.channel.sendText('Synthetic duplicate attempt'),
          throwsStateError,
        );
        expect(denied.historyReads, 0);
        expect(denied.mutations, 0);
        expect(denied.streams, 0);
      } finally {
        denied.channel.dispose();
      }
    }
    final allowed = _Fixture(
      store,
      historyGranted: true,
      outcome: 'compression',
    );
    addTearDown(allowed.channel.dispose);
    await allowed.channel.connect(baseUrl: _origin);
    expect(store.leases, isEmpty);
    expect(allowed.channel.state.hasUnreconciledRun, isFalse);
    expect(allowed.channel.state.activeMessages.single.id, 'message_a');
    expect(allowed.mutations, 0);
    expect(allowed.streams, 0);
  });

  for (final declaration in ['exact', 'omitted']) {
    test('supported $declaration history hydrates and paginates', () async {
      final fixture = _Fixture(
        _Store(),
        historyGranted: declaration == 'exact',
        historyDeclaration: declaration,
        pagination: true,
      );
      addTearDown(fixture.channel.dispose);
      await fixture.channel.connect(baseUrl: _origin);
      expect(fixture.store.leases, isEmpty);
      expect(fixture.channel.state.activeMessages.single.id, 'message_a');
      await fixture.channel.loadEarlierMessages();
      expect(fixture.channel.state.activeMessages.first.id, 'older_message');
      expect(fixture.channel.state.messageHistoryNextOffsets['session_a'], 2);
      expect(fixture.historyReads, 3);
      expect(fixture.mutations, 0);
    });
  }

  test('current history denial fences selection and pagination', () async {
    final fixture = _Fixture(_Store()..leases.clear(), pagination: true);
    addTearDown(fixture.channel.dispose);
    await fixture.channel.connect(baseUrl: _origin);
    final before = fixture.channel.state.activeMessages;
    final offsets = fixture.channel.state.messageHistoryNextOffsets;
    fixture.channel.state.capabilities!.endpoints['session_messages'] =
        const HermesEndpointCapability(
          method: 'GET',
          path: '/api/sessions/{session_id}/messages',
          requiredScopes: ['history:read'],
        );
    await expectLater(
      fixture.channel.selectSession('session_a'),
      throwsStateError,
    );
    await fixture.channel.loadEarlierMessages();
    expect(fixture.historyReads, 1);
    expect(fixture.channel.state.activeMessages, before);
    expect(fixture.channel.state.messageHistoryNextOffsets, offsets);
    expect(fixture.channel.state.sessionsLoadingEarlierMessages, isEmpty);
    expect(fixture.channel.state.errorMessage, isNotNull);
    expect(fixture.mutations, 0);
  });

  for (final dimension in ['origin', 'profile', 'session']) {
    test('replacement $dimension never reads or settles old lease', () async {
      final store = _Store(
        origin: dimension == 'origin' ? 'http://127.0.0.1:8643' : _origin,
        profile: dimension == 'profile' ? 'profile_b' : null,
        session: dimension == 'session' ? 'session_b' : 'session_a',
      );
      final fixture = _Fixture(store);
      addTearDown(fixture.channel.dispose);
      await fixture.channel.connect(baseUrl: _origin);
      expect(fixture.statusReads, 0);
      expect(store.leases.single.runId, 'run_a');
      expect(fixture.mutations, 0);
    });
  }

  for (final outcome in ['late-status', 'late-history']) {
    test('replacement connection rejects $outcome settlement', () async {
      final fixture = _Fixture(_Store(), outcome: outcome);
      addTearDown(fixture.channel.dispose);
      final connecting = fixture.channel.connect(baseUrl: _origin);
      await (outcome == 'late-status'
          ? fixture.statusEntered.future
          : fixture.historyEntered.future);
      await fixture.channel.disconnect();
      fixture.release.complete();
      await connecting;
      expect(fixture.store.leases.single.runId, 'run_a');
      expect(fixture.channel.state.activeMessages, isEmpty);
      expect(fixture.mutations, 0);
    });
  }
}
