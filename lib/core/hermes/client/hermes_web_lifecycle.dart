part of 'hermes_web_read_client.dart';

/// Submission receipts are not turn-completion receipts.
enum HermesWebSubmission { idle, submitting, accepted, uncertain, terminal }

enum HermesWebApprovalChoice { once, deny }

final class HermesWebRecovery {
  const HermesWebRecovery({
    required this.profile,
    required this.origin,
    required this.runtimeSessionId,
    required this.storedSessionId,
    required this.epoch,
    required this.sequence,
    required this.uncertain,
  });
  final String profile, runtimeSessionId, storedSessionId, epoch;
  final Uri origin;
  final int sequence;
  final bool uncertain;
}

/// Ephemeral projection onto Wing's existing turn model, not a session store.
/// Only accessible by explicit qualification opt-in on the loopback read client.
/// Gateway channel, product enrollment and Wing Link are deliberately untouched.
final class HermesWebLifecycle {
  HermesWebLifecycle._(this._connection);
  final HermesWebReadConnection _connection;
  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  String get profile => _connection._profile;
  HermesWebProductAuthorization get productAuthorization =>
      HermesWebProductAuthorization.unsupportedAuthorization;
  String? _runtime, _stored;
  String? get runtimeSessionId => _runtime;
  String? get storedSessionId => _stored;
  int _selection = 0, _sequence = 0, _turn = 0;
  bool _selecting = false, _reconcile = false, _cancelRequested = false;
  bool _running = false;
  HermesWebSubmission _submission = HermesWebSubmission.idle;
  HermesWebSubmission get submission => _submission;
  bool get needsReconciliation => _reconcile;
  bool _eventReplaySupported = true;
  bool get eventReplaySupported => _eventReplaySupported;
  final List<HermesChatTurn> _turns = [];
  List<HermesChatTurn> get turns => List.unmodifiable(_turns);
  final Map<String, String> _approvals = {}; // queue ID -> server request ID
  Set<String> get approvalRequestIds => Set.unmodifiable(_approvals.keys);
  bool get canSubmit =>
      !_connection._closed &&
      _runtime != null &&
      !_selecting &&
      !_reconcile &&
      !_running &&
      _submission != HermesWebSubmission.uncertain &&
      _submission != HermesWebSubmission.submitting;

  HermesWebRecovery get recovery => HermesWebRecovery(
    profile: profile,
    origin: _connection._origin,
    runtimeSessionId: _runtime ?? _identityFailure(),
    storedSessionId: _stored ?? _identityFailure(),
    epoch: _connection.replayEpoch,
    sequence: _sequence,
    uncertain:
        _submission == HermesWebSubmission.uncertain ||
        _submission == HermesWebSubmission.submitting,
  );

  Never _identityFailure() =>
      throw const HermesWebReadException(HermesWebFailureKind.identity);
  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void _current(int selection) {
    _connection._current();
    if (_connection._closed || selection != _selection) {
      throw const HermesWebReadException(HermesWebFailureKind.stale);
    }
  }

  Map<String, Object> _scope() => {
    'profile': profile,
    'session_id': _runtime ?? _identityFailure(),
  };

  /// Clean draft only: no cwd, seeding, model or caller-selected RPC parameters.
  Future<void> createSession() => _select(create: true);

  /// Agentless watch resume avoids implicit crash continuation in qualification.
  /// A later explicit submit upgrades the session on the server.
  Future<void> resumeSession(String storedSessionId) =>
      _select(stored: storedSessionId);

  Future<void> _select({bool create = false, String? stored}) async {
    if (_selecting) {
      throw const HermesWebReadException(HermesWebFailureKind.busy);
    }
    if (!create) HermesWebReadClient._validateIdentity(stored!);
    final selection = ++_selection;
    _selecting = true;
    _runtime = null;
    _stored = null;
    _sequence = 0;
    _approvals.clear();
    _turns.clear();
    _running = false;
    _submission = HermesWebSubmission.idle;
    _reconcile = true;
    _notify();
    try {
      final result = await _connection._read(
        create ? 'session.create' : 'session.resume',
        create
            ? {'profile': profile}
            : {'profile': profile, 'session_id': stored!, 'lazy': true},
      );
      _current(selection);
      final runtime = webString(result['session_id'], maximum: 128);
      final durable = webString(
        result['stored_session_id'] ?? stored,
        maximum: 128,
      );
      HermesWebReadClient._validateIdentity(runtime);
      HermesWebReadClient._validateIdentity(durable);
      if (!create) webIdentity(durable, stored!);
      final info = webObject(result['info']);
      if (info.containsKey('profile_name')) {
        webIdentity(info['profile_name'], profile);
      }
      _runtime = runtime;
      _stored = durable;
      _running = result['running'] == true || result['queued'] == true;
      await _canonical(selection);
      // Establish a replay barrier after canonical history; never append already
      // persisted deltas on top of history. Replay is advisory, not durability.
      final replaySafe = await _replay(selection, lastSeen: 0);
      _reconcile = _running || !replaySafe;
    } finally {
      if (selection == _selection) {
        _selecting = false;
        _notify();
      }
    }
  }

  Future<void> _canonical(int selection) async {
    final result = await _connection._read('session.history', _scope());
    _current(selection);
    webInteger(result['count']);
    final rows = webRows(result['messages'], 500);
    final projection = <HermesChatTurn>[];
    final ids = <String>{};
    for (var i = 0; i < rows.length; i++) {
      final row = webObject(rows[i]);
      final role = webString(row['role'], maximum: 32);
      final author = switch (role) {
        'user' => HermesTurnAuthor.user,
        'assistant' => HermesTurnAuthor.assistant,
        'system' || 'tool' => HermesTurnAuthor.system,
        _ => webMalformed(),
      };
      final rawId = row['row_id'];
      final id = rawId == null
          ? 'history-$i'
          : 'row-${webInteger(rawId, maximum: 9007199254740991)}';
      if (!ids.add(id)) webMalformed();
      final text = row['text'] ?? row['content'] ?? '';
      // Only the text projection is supported; never stringify arbitrary JSON.
      projection.add(
        HermesChatTurn(
          id: id,
          sessionId: _stored!,
          author: author,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          text: webString(text, maximum: 262144),
        ),
      );
    }
    _turns
      ..clear()
      ..addAll(projection);
  }

  /// Explicit recovery; never submits, creates a replacement, or replays a write.
  Future<void> recover(HermesWebRecovery checkpoint) async {
    webIdentity(checkpoint.profile, profile);
    webIdentity(checkpoint.origin, _connection._origin);
    if (checkpoint.sequence < 0 || checkpoint.sequence > 9007199254740991) {
      webMalformed();
    }
    await resumeSession(checkpoint.storedSessionId);
    if (checkpoint.uncertain) _submission = HermesWebSubmission.uncertain;
    // Runtime IDs and epochs can change. Only use a cursor on the exact live
    // runtime and process that assigned it. Canonical history was read regardless.
    if (_runtime == checkpoint.runtimeSessionId &&
        _connection.replayEpoch == checkpoint.epoch) {
      if (!await _replay(_selection, lastSeen: checkpoint.sequence)) {
        _reconcile = true;
      }
    }
    _notify();
  }

  Future<void> reconcileActiveSession() async {
    final uncertain = _submission == HermesWebSubmission.uncertain;
    final stored = _stored ?? _identityFailure();
    await resumeSession(stored);
    if (uncertain) _submission = HermesWebSubmission.uncertain;
    _notify();
  }

  Future<bool> _replay(int selection, {required int lastSeen}) async {
    Map<String, dynamic> result;
    try {
      result = await _connection._read('session.events.since', {
        ..._scope(),
        'last_seen': lastSeen,
      });
    } on HermesWebReadException catch (error) {
      if (error.kind == HermesWebFailureKind.rpc && error.rpcCode == -32601) {
        // Explicit unsupported replay: canonical history still exists, but no
        // claim of resumable streaming or approval recovery is made.
        _eventReplaySupported = false;
        _reconcile = true;
        return false;
      }
      rethrow;
    }
    _current(selection);
    final epoch = webString(result['epoch'], maximum: 128);
    final latest = webInteger(result['latest_seq'], maximum: 9007199254740991);
    final events = webRows(result['events'], 512);
    webIdentity(webInteger(result['count'], maximum: 512), events.length);
    if (result['truncated'] is! bool) webMalformed();
    var previous = lastSeen;
    for (final raw in events) {
      final event = webObject(raw);
      webIdentity(event['session_id'], _runtime!);
      final seq = webInteger(event['seq'], maximum: 9007199254740991);
      if (seq <= previous || seq > latest) webMalformed();
      previous = seq;
      webString(event['type'], maximum: 128);
    }
    _approvals.clear();
    for (final request in webRows(result['open_requests'], 32)) {
      _serverRequest(webObject(request), replay: true);
    }
    if (epoch != _connection.replayEpoch ||
        result['truncated'] == true ||
        latest < lastSeen) {
      _reconcile = true;
      await _canonical(selection);
      _sequence = epoch == _connection.replayEpoch ? latest : 0;
      return epoch == _connection.replayEpoch;
    }
    _sequence = latest;
    return true;
  }

  Future<void> submitText(String text) async {
    if (!canSubmit) {
      throw const HermesWebReadException(HermesWebFailureKind.busy);
    }
    if (text.trim().isEmpty || text.length > 65536) webMalformed();
    final selection = _selection;
    if (_turns.length > 498) {
      throw const HermesWebReadException(HermesWebFailureKind.oversized);
    }
    _cancelRequested = false;
    _running = true;
    _submission = HermesWebSubmission.submitting;
    _turn++;

    _turns.add(
      HermesChatTurn(
        id: 'local-user-$_turn',
        sessionId: _stored!,
        author: HermesTurnAuthor.user,
        createdAt: DateTime.now().toUtc(),
        text: text,
      ),
    );
    _notify();
    try {
      final receipt = await _connection._read('prompt.submit', {
        ..._scope(),
        'text': text,
      });
      _current(selection);
      if (!{
        'streaming',
        'queued',
        'steered',
        'redirected',
      }.contains(receipt['status'])) {
        webMalformed();
      }
      if (_submission == HermesWebSubmission.submitting) {
        _submission = HermesWebSubmission.accepted;
      }
      _notify();
    } catch (_) {
      if (selection == _selection &&
          _submission != HermesWebSubmission.terminal) {
        _submission = HermesWebSubmission.uncertain;
        _reconcile = true;
        _notify();
      }
      rethrow;
    }
  }

  /// The server interrupt receipt is not completion, and a closed socket is not
  /// cancellation. Replacement submissions remain disabled until reconciliation.
  Future<bool> interrupt() async {
    final selection = _selection;
    final scope = _scope();
    _cancelRequested = true;
    _reconcile = true;
    _notify();
    final receipt = await _connection._read('session.interrupt', scope);
    _current(selection);
    return receipt['status'] == 'interrupted';
  }

  Future<void> respondToApproval(
    String requestId,
    HermesWebApprovalChoice choice,
  ) async {
    final selection = _selection;
    if (!_approvals.containsKey(requestId) || _selecting) _identityFailure();
    final receipt = await _connection._read('approval.respond', {
      ..._scope(),
      'request_id': requestId,
      'choice': choice.name,
      'all': false,
    });
    _current(selection);
    if (receipt['resolved'] != 1) _identityFailure();
    _approvals.remove(requestId);
    _notify();
  }

  void _notification(Map<String, dynamic> frame) {
    if (frame['method'] == 'event' && !frame.containsKey('id')) {
      final event = webObject(frame['params']);
      if (event['type'] == 'gateway.ready') webMalformed();
      _event(event);
    } else if (frame['method'] == 'request.cancel' &&
        !frame.containsKey('id')) {
      final params = webObject(frame['params']);
      final id = webString(params['id'], maximum: 128);
      _approvals.removeWhere((_, value) => value == id);
      _notify();
    } else if (frame.containsKey('id') && frame['method'] is String) {
      _serverRequest(frame);
    } else {
      webMalformed();
    }
  }

  void _serverRequest(Map<String, dynamic> frame, {bool replay = false}) {
    final id = webString(frame['id'], maximum: 128);
    final params = webObject(frame['params']);
    if (frame['method'] != 'approval' ||
        params['session_id'] != _runtime ||
        (_selecting && !replay)) {
      // Unsupported interactive operations must not hang the server or default
      // to an affirmative response. Never echo raw request content.
      _connection._socket.add(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': id,
          'error': {
            'code': -32601,
            'message': 'Unsupported internal operation',
          },
        }),
      );
      return;
    }
    if (params.containsKey('profile')) webIdentity(params['profile'], profile);
    final queueId = webString(params['request_id'], maximum: 128);
    if (queueId.isEmpty || id.isEmpty || _approvals.length >= 32) {
      webMalformed();
    }
    if (_approvals.containsKey(queueId) && _approvals[queueId] != id) {
      webMalformed();
    }
    _approvals[queueId] = id;
    _notify();
  }

  void _event(Map<String, dynamic> event) {
    final type = webString(event['type'], maximum: 128);
    if (event['session_id'] != _runtime || _runtime == null || _selecting) {
      return;
    }
    if (event.containsKey('profile') && event['profile'] != profile) return;
    final seq = webInteger(event['seq'], maximum: 9007199254740991);
    if (seq <= _sequence) return;
    if (seq != _sequence + 1) {
      _reconcile = true;
      _notify();
      return;
    }
    _sequence = seq;
    if (!_running) return; // No server turn ID: never attach to another turn.
    final payload = event['payload'] == null
        ? <String, dynamic>{}
        : webObject(event['payload']);
    if (type == 'error') {
      _reconcile = true;
      _notify();
      return;
    }
    if (type == 'message.complete') {
      final status = payload['status'] ?? 'complete';
      if (!{'complete', 'error', 'interrupted'}.contains(status)) {
        webMalformed();
      }
      _assistant(
        text: status == 'error'
            ? ''
            : webString(payload['text'] ?? '', maximum: 262144),
        replace: true,
        status: status == 'complete'
            ? HermesTurnStatus.completed
            : HermesTurnStatus.failed,
      );
      _submission = HermesWebSubmission.terminal;
      _running = false;
      _reconcile = true;
    } else if (!_cancelRequested && !_reconcile) {
      switch (type) {
        case 'message.delta':
          _assistant(text: webString(payload['text'], maximum: 65536));
        case 'reasoning.delta':
        case 'thinking.delta':
        case 'reasoning.available':
          _assistant(
            text: webString(payload['text'], maximum: 65536),
            kind: HermesTurnKind.reasoning,
            replace: type == 'reasoning.available',
          );
        case 'tool.start':
        case 'tool.complete':
          final toolId = webString(payload['tool_id'], maximum: 128);
          final name = webString(payload['name'], maximum: 128);
          final id = 'local-tool-$_turn-$toolId';
          final index = _turns.indexWhere((t) => t.id == id);
          final turn = HermesChatTurn(
            id: id,
            sessionId: _stored!,
            author: HermesTurnAuthor.assistant,
            createdAt: DateTime.now().toUtc(),
            kind: HermesTurnKind.toolCall,
            status: type == 'tool.start'
                ? HermesTurnStatus.streaming
                : HermesTurnStatus.completed,
            toolCall: HermesToolCall(
              name: name,
              status: type == 'tool.start' ? 'running' : 'completed',
            ),
          );
          if (index < 0) {
            _turns.add(turn);
          } else {
            _turns[index] = turn;
          }
        default:
          break; // Unknown domain events never become UI state.
      }
    }
    if (_turns.length > 500) {
      throw const HermesWebReadException(HermesWebFailureKind.oversized);
    }
    _notify();
  }

  void _assistant({
    required String text,
    bool replace = false,
    HermesTurnKind kind = HermesTurnKind.text,
    HermesTurnStatus status = HermesTurnStatus.streaming,
  }) {
    final id = 'local-assistant-$_turn-${kind.name}';
    final index = _turns.indexWhere((t) => t.id == id);
    final previous = index < 0 ? null : _turns[index];
    final body = replace ? text : '${previous?.text ?? ''}$text';
    if (body.length > 262144) {
      throw const HermesWebReadException(HermesWebFailureKind.oversized);
    }
    final turn = HermesChatTurn(
      id: id,
      sessionId: _stored!,
      author: HermesTurnAuthor.assistant,
      createdAt: previous?.createdAt ?? DateTime.now().toUtc(),
      kind: kind,
      status: status,
      text: body,
    );
    if (index < 0) {
      _turns.add(turn);
    } else {
      _turns[index] = turn;
    }
  }

  void _disconnected() {
    if (_submission == HermesWebSubmission.submitting ||
        _submission == HermesWebSubmission.accepted) {
      _submission = HermesWebSubmission.uncertain;
    }
    _selection++;
    _approvals.clear();
    _reconcile = true;
    _notify();
    unawaited(_changes.close());
  }
}
