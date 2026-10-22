import 'gateway_auth_models.dart';

/// Browser builds must use their browser authentication path, not loopback.
class NativeGatewayAuth {
  NativeGatewayAuth({
    required Uri origin,
    required Future<bool> Function(Uri) launchBrowser,
    bool allowLoopbackHttpForTests = false,
    Duration timeout = const Duration(minutes: 5),
    Duration requestTimeout = const Duration(seconds: 15),
  }) : origin = validateGatewayOrigin(origin);
  final Uri origin;
  Future<List<GatewayAuthProvider>> discoverProviders() async =>
      throw const GatewayAuthException('native_login_unavailable');
  Future<GatewayTokenSet> login({String? provider}) async =>
      throw const GatewayAuthException('native_login_unavailable');
  Future<GatewayTokenSet> refresh(GatewayTokenSet tokens) async =>
      throw const GatewayAuthException('native_login_unavailable');
  Future<void> cancel() async {}
}
