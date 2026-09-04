/// Hermes API HTTP header names, values, and status helpers.
const hermesApiAuthorizationHeader = 'Authorization';
const hermesApiContentTypeHeader = 'Content-Type';
const hermesApiAcceptHeader = 'Accept';
const hermesApiIfMatchHeader = 'If-Match';
const hermesApiJsonContentType = 'application/json';
const hermesApiEventStreamContentType = 'text/event-stream';

abstract interface class HermesApiStatusException implements Exception {
  int get statusCode;
}

enum HermesApiTransportFailureKind { network, tls, timeout }

final class HermesApiTransportException implements Exception {
  const HermesApiTransportException(this.kind);

  final HermesApiTransportFailureKind kind;

  @override
  String toString() => switch (kind) {
    HermesApiTransportFailureKind.network =>
      'Hermes API network connection failed',
    HermesApiTransportFailureKind.tls => 'Hermes API secure connection failed',
    HermesApiTransportFailureKind.timeout => 'Hermes API request timed out',
  };
}

String hermesApiBearerAuthorization(String apiKey) {
  final trimmed = apiKey.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(apiKey, 'apiKey', 'must not be blank');
  }
  return 'Bearer $trimmed';
}

bool hermesApiIsSuccessStatus(int statusCode) {
  return statusCode >= 200 && statusCode < 300;
}

String hermesApiHttpStatusMessage(Object status) {
  if (status == 401 || status == 403) {
    return 'Hermes API rejected the request credentials';
  }
  if (status == 429) {
    return 'Hermes API is temporarily rate limiting requests';
  }
  return 'Hermes API returned HTTP $status';
}
