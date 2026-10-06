import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/hermes_web_reads.dart';
import '../models/hermes_chat_turn.dart';
import '../shared/hermes_api_http.dart';

export '../models/hermes_web_reads.dart';

part 'hermes_web_read_rpc.dart';
part 'hermes_web_lifecycle.dart';

/// Internal Linux/VM qualification transport. Not exported by hermes_api.dart,
/// registered with Riverpod, or usable as a product channel. Loopback-only until
/// credential authority and remote/platform transport are separately reviewed.
final class HermesWebReadClient {
  HermesWebReadClient.forQualification({
    required Uri origin,
    required String? credential,
    required String profile,
    this.timeout = const Duration(seconds: 10),
  }) : _origin = origin,
       _credential = credential,
       _profile = profile {
    if (origin.scheme != 'http' ||
        !{'127.0.0.1', '::1'}.contains(origin.host) ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw const HermesWebReadException(HermesWebFailureKind.identity);
    }
    _validateIdentity(profile);
    if (credential != null &&
        (credential.isEmpty ||
            credential.length > 8192 ||
            credential.contains(RegExp(r'[\r\n]')))) {
      throw const HermesWebReadException(HermesWebFailureKind.authentication);
    }
    if (timeout <= Duration.zero || timeout > const Duration(seconds: 30)) {
      throw const HermesWebReadException(HermesWebFailureKind.timeout);
    }
  }

  static const maximumBytes = 1 << 20;
  final Uri _origin;
  final String? _credential;
  final String _profile;
  final Duration timeout;
  int _generation = 0;
  bool _closed = false;
  final Set<HttpClient> _http = {};
  HermesWebReadConnection? _connection;

  HermesWebProductAuthorization get productAuthorization =>
      HermesWebProductAuthorization.unsupportedAuthorization;

  void disconnect() {
    _closed = true;
    _generation++;
    _connection?._stop(
      const HermesWebReadException(HermesWebFailureKind.disconnected),
    );
    _connection = null;
    for (final client in _http) {
      client.close(force: true);
    }
    _http.clear();
  }

  void _current(int generation) {
    if (_closed || generation != _generation) {
      throw const HermesWebReadException(HermesWebFailureKind.stale);
    }
  }

  static void _validateIdentity(String identity) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$').hasMatch(identity)) {
      throw const HermesWebReadException(HermesWebFailureKind.identity);
    }
  }

  Map<String, String> _page(int limit, int offset, {int maximum = 100}) {
    if (limit < 1 || limit > maximum || offset < 0 || offset > 1000000) {
      webMalformed();
    }
    return {'profile': _profile, 'limit': '$limit', 'offset': '$offset'};
  }

  Future<HermesWebSessionPage> sessions({
    int limit = 50,
    int offset = 0,
  }) async {
    final json = await _request('/api/sessions', query: _page(limit, offset));
    return HermesWebSessionPage.fromJson(
      json,
      _profile,
      limit: limit,
      offset: offset,
    );
  }

  Future<HermesWebHistoryPage> history(
    String session, {
    int limit = 500,
    int offset = 0,
    String order = 'latest',
  }) async {
    _validateIdentity(session);
    if (order != 'latest' && order != 'oldest') webMalformed();
    final json = await _request(
      '/api/sessions/$session/messages',
      query: {..._page(limit, offset, maximum: 500), 'order': order},
    );
    return HermesWebHistoryPage.fromJson(
      json,
      _profile,
      session,
      limit: limit,
      offset: offset,
      order: order,
    );
  }

  Future<HermesWebReadConnection> connectReads() => _connect();

  /// Explicit internal opt-in. Never registered as a product HermesChannel.
  Future<HermesWebLifecycle> connectLifecycleForQualification() async {
    final connection = await _connect(lifecycle: true);
    final adapter = connection._lifecycle!;
    await connection._read('client.capabilities', {'server_requests': true});
    return adapter;
  }

  Future<HermesWebReadConnection> _connect({bool lifecycle = false}) async {
    _current(_generation);
    final generation = ++_generation;
    _connection?._stop(
      const HermesWebReadException(HermesWebFailureKind.stale),
    );
    _connection = null;
    final ticketJson = await _request('/api/auth/ws-ticket', ticket: true);
    _current(generation);
    final ticket = webString(ticketJson['ticket'], maximum: 512);
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(ticket)) webMalformed();
    final ttl = webInteger(ticketJson['ttl_seconds'], maximum: 60);
    if (ttl == 0) webMalformed();
    final http = HttpClient()..connectionTimeout = timeout;
    http.findProxy = (_) => 'DIRECT';
    _http.add(http);
    WebSocket? socket;
    var attached = false;
    try {
      socket =
          await WebSocket.connect(
                _origin.replace(scheme: 'ws', path: '/api/ws').toString(),
                protocols: [
                  'hermes-gateway-v1',
                  'hermes-gateway-ticket.$ticket',
                ],
                compression: CompressionOptions.compressionOff,
                customClient: _WebUpgradeClient(http),
              )
              .then((ws) {
                if (_closed || generation != _generation) {
                  unawaited(ws.close());
                  throw const HermesWebReadException(
                    HermesWebFailureKind.stale,
                  );
                }
                return ws;
              })
              .timeout(timeout);
      _current(generation);
      if (socket.protocol != 'hermes-gateway-v1') webMalformed();
      final connection = HermesWebReadConnection._(
        socket,
        _origin,
        _profile,
        timeout,
        () => _current(generation),
      );
      _connection = connection;
      if (lifecycle) connection._lifecycle = HermesWebLifecycle._(connection);
      await connection._ready.future.timeout(timeout);
      _current(generation);
      attached = true;
      return connection;
    } on HermesWebReadException {
      rethrow;
    } on TimeoutException {
      throw const HermesWebReadException(HermesWebFailureKind.timeout);
    } on WebSocketException catch (error) {
      _current(generation);
      final status = error.httpStatusCode;
      throw HermesWebReadException(
        status != null && status >= 300 && status < 400
            ? HermesWebFailureKind.redirect
            : status == 401 || status == 403
            ? HermesWebFailureKind.authentication
            : HermesWebFailureKind.network,
      );
    } catch (_) {
      _current(generation);
      throw const HermesWebReadException(HermesWebFailureKind.network);
    } finally {
      _http.remove(http);
      http.close(force: true);
      if (!attached) {
        if (socket != null) unawaited(socket.close());
        if (generation == _generation) {
          _connection?._stop(
            const HermesWebReadException(HermesWebFailureKind.disconnected),
          );
          _connection = null;
        }
      }
    }
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    Map<String, String>? query,
    bool ticket = false,
  }) async {
    final generation = _generation;
    _current(generation);
    if (_http.length >= 8) {
      throw const HermesWebReadException(HermesWebFailureKind.busy);
    }
    final client = HttpClient()..connectionTimeout = timeout;
    client.findProxy = (_) => 'DIRECT';
    _http.add(client);
    try {
      return await (() async {
        final request = await client.openUrl(
          ticket ? 'POST' : 'GET',
          _origin.replace(path: path, queryParameters: query),
        );
        request.followRedirects = false;
        request.headers.set(hermesApiAcceptHeader, hermesApiJsonContentType);
        final credential = _credential;
        if (credential != null) {
          request.headers.set(
            hermesApiAuthorizationHeader,
            hermesApiBearerAuthorization(credential),
          );
        }
        if (ticket) {
          request.headers.contentType = ContentType.json;
          request.write('{}');
        }
        final response = await request.close();
        if (response.statusCode >= 300 && response.statusCode < 400) {
          throw const HermesWebReadException(HermesWebFailureKind.redirect);
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const HermesWebReadException(
            HermesWebFailureKind.authentication,
          );
        }
        if (response.statusCode == 404) {
          throw const HermesWebReadException(HermesWebFailureKind.notFound);
        }
        if (response.statusCode != 200) {
          throw const HermesWebReadException(HermesWebFailureKind.network);
        }
        if (response.contentLength > maximumBytes) {
          throw const HermesWebReadException(HermesWebFailureKind.oversized);
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > maximumBytes) {
            throw const HermesWebReadException(HermesWebFailureKind.oversized);
          }
          bytes.addAll(chunk);
        }
        _current(generation);
        return webObject(jsonDecode(utf8.decode(bytes)));
      })().timeout(timeout);
    } on HermesWebReadException {
      rethrow;
    } on TimeoutException {
      throw const HermesWebReadException(HermesWebFailureKind.timeout);
    } on FormatException {
      throw const HermesWebReadException(HermesWebFailureKind.malformed);
    } catch (_) {
      _current(generation);
      throw const HermesWebReadException(HermesWebFailureKind.network);
    } finally {
      _http.remove(client);
      client.close(force: true);
    }
  }
}
