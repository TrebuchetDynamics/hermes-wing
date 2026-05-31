/// Gateway HTTP header names, values, and status helpers shared by clients and
/// platform transports.
const navivoxGatewayContentTypeHeader = 'Content-Type';

/// JSON media type used for gateway request bodies.
const navivoxGatewayJsonContentType = 'application/json';

/// Builds the common gateway HTTP failure message used by platform transports.
String navivoxGatewayHttpStatusMessage(Object status) {
  return 'Navivox gateway returned HTTP $status';
}
