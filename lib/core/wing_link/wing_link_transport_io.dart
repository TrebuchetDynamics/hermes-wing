import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'wing_link_http.dart';

class WingLinkTransport {
  WingLinkTransport({String? expectedHostFingerprint})
    : _expectedHostFingerprint = expectedHostFingerprint?.trim() ?? '' {
    if (_expectedHostFingerprint.isNotEmpty &&
        !_fingerprintPattern.hasMatch(_expectedHostFingerprint)) {
      throw ArgumentError.value(
        expectedHostFingerprint,
        'expectedHostFingerprint',
        'must be a SHA-256 SPKI fingerprint',
      );
    }
  }

  static final RegExp _fingerprintPattern = RegExp(
    r'^sha256/[A-Za-z0-9_-]{43}$',
  );
  static const int _maximumResponseBytes = 1024 * 1024;

  final String _expectedHostFingerprint;

  Future<String> get(Uri uri, Map<String, String> headers) =>
      _request('GET', uri, headers, null);

  Future<String> post(Uri uri, Map<String, String> headers, String body) =>
      _request('POST', uri, headers, body);

  Future<String> patch(Uri uri, Map<String, String> headers, String body) =>
      _request('PATCH', uri, headers, body);

  Future<String> delete(Uri uri, Map<String, String> headers) =>
      _request('DELETE', uri, headers, null);

  Future<String> _request(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) async {
    _validateOrigin(uri);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..connectionFactory = _connect;
    try {
      final request = await client.openUrl(method, uri);
      request.followRedirects = false;
      headers.forEach(request.headers.set);
      if (body != null) request.write(body);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (uri.scheme == 'https') {
        final certificate = response.certificate;
        if (certificate == null ||
            wingLinkCertificateFingerprint(certificate) !=
                _expectedHostFingerprint) {
          await response.drain<void>();
          throw const HandshakeException('Wing Link host identity changed');
        }
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > _maximumResponseBytes) {
          throw const FormatException('Wing Link response exceeded its bound');
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WingLinkHttpException(response.statusCode);
      }
      return utf8.decode(bytes);
    } finally {
      client.close(force: true);
    }
  }

  Future<ConnectionTask<Socket>> _connect(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  ) async {
    if (proxyHost != null || proxyPort != null) {
      throw const HandshakeException('Wing Link does not use HTTP proxies');
    }
    if (uri.scheme == 'http') {
      return Socket.startConnect(uri.host, uri.port);
    }
    final task = await SecureSocket.startConnect(
      uri.host,
      uri.port,
      onBadCertificate: _matchesFingerprint,
    );
    return ConnectionTask.fromSocket<Socket>(
      task.socket.then<Socket>((socket) {
        final certificate = socket.peerCertificate;
        if (certificate == null || !_matchesFingerprint(certificate)) {
          socket.destroy();
          throw const HandshakeException('Wing Link host identity changed');
        }
        return socket;
      }),
      task.cancel,
    );
  }

  bool _matchesFingerprint(X509Certificate certificate) {
    try {
      return wingLinkCertificateFingerprint(certificate) ==
          _expectedHostFingerprint;
    } on FormatException {
      return false;
    }
  }

  void _validateOrigin(Uri uri) {
    if (uri.scheme == 'http') {
      if (!_isLoopback(uri.host)) {
        throw const HandshakeException(
          'Wing Link requires HTTPS outside loopback',
        );
      }
      return;
    }
    if (uri.scheme != 'https') {
      throw const HandshakeException('Wing Link requires HTTP or HTTPS');
    }
    if (_expectedHostFingerprint.isEmpty) {
      throw const HandshakeException('Wing Link host identity is not pinned');
    }
  }
}

String wingLinkCertificateFingerprint(X509Certificate certificate) {
  final spki = _subjectPublicKeyInfo(certificate.der);
  return 'sha256/${base64Url.encode(sha256.convert(spki).bytes).replaceAll('=', '')}';
}

Uint8List _subjectPublicKeyInfo(Uint8List certificate) {
  final outer = _readElement(certificate, 0);
  if (outer.tag != 0x30 || outer.end != certificate.length) {
    throw const FormatException('Invalid X.509 certificate');
  }
  final tbs = _readElement(certificate, outer.contentStart);
  if (tbs.tag != 0x30) {
    throw const FormatException('Invalid X.509 certificate');
  }
  var offset = tbs.contentStart;
  var element = _readElement(certificate, offset);
  if (element.tag == 0xa0) {
    offset = element.end;
  }
  // serialNumber, signature, issuer, validity, subject.
  for (var index = 0; index < 5; index++) {
    element = _readElement(certificate, offset);
    offset = element.end;
  }
  final spki = _readElement(certificate, offset);
  if (spki.tag != 0x30 || spki.end > tbs.end) {
    throw const FormatException('Invalid X.509 subject public key info');
  }
  return Uint8List.sublistView(certificate, spki.start, spki.end);
}

_DerElement _readElement(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 2 > bytes.length) {
    throw const FormatException('Invalid DER element');
  }
  final start = offset;
  final tag = bytes[offset++];
  final firstLength = bytes[offset++];
  var length = 0;
  if (firstLength & 0x80 == 0) {
    length = firstLength;
  } else {
    final count = firstLength & 0x7f;
    if (count == 0 || count > 4 || offset + count > bytes.length) {
      throw const FormatException('Invalid DER length');
    }
    for (var index = 0; index < count; index++) {
      length = (length << 8) | bytes[offset++];
    }
  }
  final end = offset + length;
  if (end < offset || end > bytes.length) {
    throw const FormatException('Invalid DER bounds');
  }
  return _DerElement(start: start, tag: tag, contentStart: offset, end: end);
}

class _DerElement {
  const _DerElement({
    required this.start,
    required this.tag,
    required this.contentStart,
    required this.end,
  });

  final int start;
  final int tag;
  final int contentStart;
  final int end;
}

bool _isLoopback(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'localhost' ||
      normalized == '127.0.0.1' ||
      normalized == '::1';
}
