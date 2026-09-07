part of '../hermes_api_channel.dart';

extension _CapabilitiesExtension on HermesApiChannel {
  void _requireScopedEndpoint(
    String name,
    String method,
    String path,
    String scope,
    String action,
  ) {
    final capabilities = _state.capabilities;
    final endpoint = capabilities?.endpoints[name];
    if (capabilities == null ||
        !capabilities.supportsSchema ||
        endpoint == null ||
        !capabilities.advertisesScopedEndpoint(name, method, path, scope)) {
      throw StateError('Hermes did not advertise support to $action.');
    }
    if (!capabilities.auth.allows(scope) ||
        !endpoint.requiredScopes.every(capabilities.auth.allows)) {
      throw StateError('This device is not authorized to $action.');
    }
  }
}
