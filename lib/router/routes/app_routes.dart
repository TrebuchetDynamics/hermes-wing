import 'app_route_location_patterns.dart';

abstract final class AppRoutes {
  static const hermes = '/hermes';
  static const addHermes = '/hermes/add';
  static const office = '/office';
  static const profiles = '/profiles';
  static const soul = '/soul';
  static const agents = profiles;
  static const legacyAgents = '/agents';
  static const providers = '/providers';
  static const tools = '/tools';
  static const schedules = '/tasks';
  static const gateway = '/gateway';
  static const settings = '/settings';
  static const settingsVoice = '/settings/voice';
  static const settingsDiagnostics = '/settings/diagnostics';

  /// One-time pairing enrollment screen reached via an Android connect
  /// intent (`wing://connect?...`); deliberately outside the
  /// authenticated shell since no endpoint is configured yet.
  static const enroll = '/enroll';

  /// Platform-specific local Hermes setup flow for Linux or Android/Termux.
  static const localSetup = '/setup/local';

  static bool isHermesLocation(String location) {
    return AppRouteLocationPattern.hasPathPrefix(
      location: location,
      pathPrefix: hermes,
    );
  }

  static bool isSettingsLocation(String location) {
    return AppRouteLocationPattern.hasPathPrefix(
      location: location,
      pathPrefix: settings,
    );
  }

  static bool isNavigationDestinationLocation({
    required String location,
    required String destinationPath,
  }) {
    return AppRouteLocationPattern.hasPathPrefix(
      location: location,
      pathPrefix: destinationPath,
    );
  }
}
