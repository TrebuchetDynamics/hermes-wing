part of 'hermes_web_read_client.dart';

/// Fixed internal qualification operations, never a generic RPC bridge.
final class HermesWebReadConnection {
  HermesWebReadConnection._(
    this._socket,
    this._origin,
    this._profile,
    this._timeout,
    this._current,
  ) {
    _subscription = _socket.listen(
      _frame,
      onError: (Object _) =>
          _stop(const HermesWebReadException(HermesWebFailureKind.network)),
      onDone: () => _stop(
        const HermesWebReadException(HermesWebFailureKind.disconnected),
      ),
    );
  }
  final WebSocket _socket;
  final Uri _origin;
  final String _profile;
  final Duration _timeout;
  final void Function() _current;
  late final StreamSubscription<dynamic> _subscription;
  final Completer<void> _ready = Completer<void>();
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final Map<int, Timer> _timers = {};
  bool _closed = false;
  int _nextId = 0;
  String _epoch = '';
  String get replayEpoch => _epoch;
  HermesWebLifecycle? _lifecycle;

  Future<bool> ping() async {
    final result = await _read('gateway.ping', {'profile': _profile});
    if (result['ok'] != true) webMalformed();
    return true;
  }

  /// The inspected RPC summary has no returned profile; these IDs are only
  /// handshake evidence, never a second authoritative inventory or cache.
  Future<List<String>> sessionIds({int limit = 50}) async {
    if (limit < 1 || limit > 100) webMalformed();
    final result = await _read('session.list', {
      'profile': _profile,
      'limit': limit,
    });
    return List.unmodifiable(
      webRows(result['sessions'], limit).map((row) {
        final object = webObject(row);
        if (object.containsKey('profile')) {
          webIdentity(object['profile'], _profile);
        }
        final id = webString(object['id'], maximum: 128);
        if (id.isEmpty) webMalformed();
        return id;
      }),
    );
  }

  Future<Map<String, dynamic>> _read(
    String method,
    Map<String, Object> params,
  ) {
    _current();
    if (_closed || !_ready.isCompleted) {
      throw const HermesWebReadException(HermesWebFailureKind.disconnected);
    }
    if (_pending.length >= 8 || _nextId >= 2147483647) {
      throw const HermesWebReadException(HermesWebFailureKind.busy);
    }
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _timers[id] = Timer(
      _timeout,
      () => _stop(const HermesWebReadException(HermesWebFailureKind.timeout)),
    );
    try {
      _socket.add(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': id,
          'method': method,
          'params': params,
        }),
      );
    } catch (_) {
      _stop(const HermesWebReadException(HermesWebFailureKind.network));
    }
    return completer.future;
  }

  void _frame(dynamic raw) {
    if (_closed) return;
    try {
      _current();
      if (raw is! String) webMalformed();
      if (raw.length > HermesWebReadClient.maximumBytes ||
          utf8.encode(raw).length > HermesWebReadClient.maximumBytes) {
        throw const HermesWebReadException(HermesWebFailureKind.oversized);
      }
      final frame = webObject(jsonDecode(raw));
      webIdentity(frame['jsonrpc'], '2.0');
      if (!_ready.isCompleted) {
        if (frame.containsKey('id') || frame['method'] != 'event') {
          webMalformed();
        }
        final params = webObject(frame['params']);
        webIdentity(params['type'], 'gateway.ready');
        final payload = webObject(params['payload']);
        if (payload['change_events'] is! bool ||
            payload['heartbeat'] is! bool) {
          webMalformed();
        }
        _epoch = webString(payload['replay_epoch'], maximum: 128);
        if (_epoch.isEmpty) webMalformed();
        _ready.complete();
        return;
      }
      if (_lifecycle != null && frame.containsKey('method')) {
        _lifecycle!._notification(frame);
        return;
      }
      if (!frame.containsKey('id')) {
        if (frame['method'] != 'event') webMalformed();
        final params = webObject(frame['params']);
        webString(params['type'], maximum: 128);
        if (params['type'] == 'gateway.ready') webMalformed();
        // No subscriptions, replay, mutations or Agent-domain event state.
        return;
      }
      final id = webInteger(frame['id'], maximum: 2147483647);
      final pending = _pending[id];
      if (pending == null ||
          frame.containsKey('method') ||
          frame.containsKey('result') == frame.containsKey('error')) {
        webMalformed();
      }
      if (frame.containsKey('error')) {
        final error = webObject(frame['error']);
        final code = error['code'];
        if (code is! int || code.abs() > 2147483647) webMalformed();
        _pending.remove(id);
        _timers.remove(id)?.cancel();
        // Never propagate raw error messages/data, which may contain secrets.
        pending.completeError(
          HermesWebReadException(HermesWebFailureKind.rpc, rpcCode: code),
        );
      } else {
        final result = webObject(frame['result']);
        _pending.remove(id);
        _timers.remove(id)?.cancel();
        pending.complete(result);
      }
    } on HermesWebReadException catch (error) {
      _stop(error);
    } catch (_) {
      _stop(const HermesWebReadException(HermesWebFailureKind.malformed));
    }
  }

  void _stop(HermesWebReadException error) {
    if (_closed) return;
    _closed = true;
    _lifecycle?._disconnected();
    if (!_ready.isCompleted) _ready.completeError(error);
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    for (final pending in _pending.values) {
      pending.completeError(error);
    }
    _pending.clear();
    unawaited(_subscription.cancel());
    unawaited(_socket.close());
  }
}

// WebSocket.connect only uses openUrl. Disable redirects before sending the
// single-use ticket; do not broaden this wrapper into a general HTTP seam.
final class _WebUpgradeClient implements HttpClient {
  _WebUpgradeClient(this._client);
  final HttpClient _client;
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = await _client.openUrl(method, url);
    request.followRedirects = false;
    return request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unsupported native web upgrade operation');
}
