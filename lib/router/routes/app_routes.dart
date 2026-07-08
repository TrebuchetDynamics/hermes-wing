import 'app_route_location_patterns.dart';

abstract final class AppRoutes {
  static const hermes = '/hermes';
  static const settings = '/settings';

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
