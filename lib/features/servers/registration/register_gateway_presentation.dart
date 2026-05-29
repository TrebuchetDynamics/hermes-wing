import 'gateway_connection_presentation.dart';

class RegisterGatewayPresentation {
  const RegisterGatewayPresentation({this.testing = false});

  final bool testing;

  String get title => 'Register gateway';

  String get instructions =>
      'Run `gormes navivox connect-info --json` on the server, then enter its base URL and auth token here.';

  String get gatewayLabelFieldLabel => 'Gateway label';
  String get gatewayLabelHelperText =>
      'Screen-reader friendly name for this device.';

  String get baseUrlFieldLabel => 'Base URL';
  String get baseUrlHintText => 'http://127.0.0.1:7319';

  String get tokenFieldLabel => 'Auth token (optional)';
  String get tokenHelperText => 'Stored by the gateway connection layer only.';

  String get testButtonLabel => testing ? 'Testing' : 'Test connection';

  String get boundaryTitle => 'Current boundary';
  String get boundarySubtitle =>
      'This test connects the current session now; persistent multi-gateway connection storage is the next protocol slice.';

  String? validateBaseUrl(String? value) =>
      const GatewayConnectionPresentation().validateBaseUrl(value);

  GatewayConnectionRequest connectRequest({
    required String baseUrl,
    required String token,
  }) => const GatewayConnectionPresentation().connectRequest(
    baseUrl: baseUrl,
    token: token,
  );

  String connectionPassedMessage(GatewayConnectionRequest request) =>
      'Connection test passed for ${request.baseUrl}';

  String connectionFailedMessage(Object error) =>
      'Connection test failed: $error';
}
