import '../hermes/client/platform/hermes_api_transport_stub.dart'
    if (dart.library.html) '../hermes/client/platform/hermes_api_transport_web.dart'
    as transport;

class WingLinkTransport {
  WingLinkTransport({String? expectedHostFingerprint})
    : _expectedHostFingerprint = expectedHostFingerprint?.trim() ?? '';

  final String _expectedHostFingerprint;

  Future<String> get(Uri uri, Map<String, String> headers) {
    _validate(uri);
    return transport.defaultGet(uri, headers);
  }

  Future<String> post(Uri uri, Map<String, String> headers, String body) {
    _validate(uri);
    return transport.defaultPost(uri, headers, body);
  }

  Future<String> patch(Uri uri, Map<String, String> headers, String body) {
    _validate(uri);
    return transport.defaultPatch(uri, headers, body);
  }

  Future<String> delete(Uri uri, Map<String, String> headers) {
    _validate(uri);
    return transport.defaultDelete(uri, headers);
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

bool _isLoopback(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '::1';
}
