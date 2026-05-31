abstract final class RouteParameters {
  static const serverId = 'serverId';
  static const profileId = 'profileId';
  static const configSection = 'section';
}

abstract final class AppRoutes {
  static const setup = '/setup';
  static const chats = '/chats';
  static const chatThread =
      '/chats/:${RouteParameters.serverId}/:${RouteParameters.profileId}';
  static const servers = '/servers';
  static const memory = '/memory';
  static const agents = '/agents';
  static const config = '/config';
  static const configSection = '/config/:${RouteParameters.configSection}';
  static const settings = '/settings';

  static String chatLocation({
    required String serverId,
    required String profileId,
  }) {
    return '$chats/${Uri.encodeComponent(serverId)}/'
        '${Uri.encodeComponent(profileId)}';
  }

  static String configSectionLocation(String sectionId) {
    return '$config/${Uri.encodeComponent(sectionId)}';
  }

  static bool isSetupLocation(String location) {
    return location == setup || location.startsWith('$setup/');
  }

  static bool isChatThreadLocation(String location) {
    return location.startsWith('$chats/');
  }

  static bool isNavigationDestinationLocation({
    required String location,
    required String destinationPath,
  }) {
    return location == destinationPath ||
        location.startsWith('$destinationPath/');
  }
}
