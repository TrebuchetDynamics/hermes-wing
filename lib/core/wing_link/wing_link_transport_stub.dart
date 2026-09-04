import '../hermes/client/platform/hermes_api_transport_stub.dart'
    if (dart.library.html) '../hermes/client/platform/hermes_api_transport_web.dart'
    as transport;
import '../hermes/shared/hermes_api_http.dart';
import 'wing_link_http.dart';

class WingLinkTransport {
  WingLinkTransport({String? expectedHostFingerprint})
    : _expectedHostFingerprint = expectedHostFingerprint?.trim() ?? '';

  final String _expectedHostFingerprint;

  Future<String> get(Uri uri, Map<String, String> headers) async {
    _validate(uri);
    return _translateStatus(() => transport.defaultGet(uri, headers));
  }

  Future<String> post(Uri uri, Map<String, String> headers, String body) async {
    _validate(uri);
    return _translateStatus(() => transport.defaultPost(uri, headers, body));
  }

  Future<String> patch(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    _validate(uri);
    return _translateStatus(() => transport.defaultPatch(uri, headers, body));
  }

  Future<String> delete(Uri uri, Map<String, String> headers) async {
    _validate(uri);
    return _translateStatus(() => transport.defaultDelete(uri, headers));
  }

  void _validate(Uri uri) {
    if (uri.scheme != 'https' && !_isLoopback(uri.host)) {
      throw StateError('Wing Link requires HTTPS outside loopback');
    }
    // Browsers enforce their platform trust store and do not expose peer SPKI.
    // A pin may be retained for identity display, but never bypasses browser TLS.
    if (uri.scheme == 'https' &&
        !_isLoopback(uri.host) &&
        _expectedHostFingerprint.isEmpty) {
      throw StateError('Wing Link host identity is not pinned');
    }
  }
}

Future<String> _translateStatus(Future<String> Function() request) async {
  try {
    return await request();
  } on HermesApiStatusException catch (error) {
    throw WingLinkHttpException(error.statusCode);
  }
}

bool _isLoopback(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '::1';
}
