/// Native: inject the platform system-browser launcher, then call login().
/// Persist returned tokens only with SecureGatewayTokenStore. Cancellation
/// invalidates in-flight work; refresh() never replays a data-plane request.
library;

export 'gateway_auth_models.dart';
export 'native_gateway_auth_stub.dart'
    if (dart.library.io) 'native_gateway_auth_io.dart';
