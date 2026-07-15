import 'app_route_location_patterns.dart';

abstract final class AppRoutes {
  static const hermes = '/hermes';
  static const agents = '/agents';
  static const providers = '/providers';
  static const settings = '/settings';

  /// One-time pairing enrollment screen reached via an Android connect
  /// intent (`navivox://connect?...`); deliberately outside the
  /// authenticated shell since no endpoint is configured yet.
  static const enroll = '/enroll';

  /// Needle spike evaluation screen; registered only in NEEDLE_SPIKE builds.
  static const needleSpike = '/needle-spike';

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
