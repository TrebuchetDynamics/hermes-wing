import 'dart:io';

import '../../../core/hermes/shared/hermes_api_http.dart';

HermesApiTransportFailureKind? enrollmentTransportFailure(Object error) {
  if (error is HandshakeException || error is TlsException) {
    return HermesApiTransportFailureKind.tls;
  }
  if (error is SocketException) return HermesApiTransportFailureKind.network;
  return null;
}
