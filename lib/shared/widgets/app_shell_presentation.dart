import 'package:flutter/material.dart';

import '../../router/app_routes.dart';

class AppShellPresentation {
  const AppShellPresentation();

  List<AppShellDestination> get destinations => _destinations;

  List<AppShellDestination> get mobileNavigationDestinations => _destinations;

  List<AppShellDestination> get mobileOverflowDestinations => const [];

  String get navigationMenuTooltip => 'Open navigation menu';

  String get mobileOverflowLabel => 'More';

  String get mobileOverflowTooltip => 'Open more destinations';

  String get drawerHeaderTitle => 'Navivox';

  String get drawerHeaderSubtitle => 'Hermes Agent mobile console';

  AppShellNavigationState stateForLocation(String location) {
    final selectedIndex = destinations.indexWhere(
      (destination) => AppRoutes.isNavigationDestinationLocation(
        location: location,
        destinationPath: destination.path,
      ),
    );
    final selected = selectedIndex < 0 ? 0 : selectedIndex;
    return AppShellNavigationState(
      destinations: destinations,
      mobileNavigationDestinations: mobileNavigationDestinations,
      mobileOverflowDestinations: mobileOverflowDestinations,
      selectedIndex: selected,
      showNavigationMenu: true,
    );
  }
}

class AppShellNavigationState {
  const AppShellNavigationState({
    required this.destinations,
    required this.mobileNavigationDestinations,
    required this.mobileOverflowDestinations,
    required this.selectedIndex,
    required this.showNavigationMenu,
  });

  final List<AppShellDestination> destinations;
  final List<AppShellDestination> mobileNavigationDestinations;
  final List<AppShellDestination> mobileOverflowDestinations;
  final int selectedIndex;
  final bool showNavigationMenu;

  AppShellDestination get selectedDestination => destinations[selectedIndex];

  int get selectedMobileIndex {
    final selectedPath = selectedDestination.path;
    final primaryIndex = mobileNavigationDestinations.indexWhere(
      (destination) => AppRoutes.isNavigationDestinationLocation(
        location: selectedPath,
        destinationPath: destination.path,
      ),
    );
    if (primaryIndex >= 0) return primaryIndex;
    return mobileNavigationDestinations.length;
  }
}

class AppShellDestination {
  const AppShellDestination({
    required this.path,
    required this.icon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final String label;
}

const _hermesDestination = AppShellDestination(
  path: AppRoutes.hermes,
  icon: Icons.auto_awesome_outlined,
  label: 'Hermes',
);
const _settingsDestination = AppShellDestination(
  path: AppRoutes.settings,
  icon: Icons.keyboard_voice_outlined,
  label: 'Settings',
);

const _destinations = [_hermesDestination, _settingsDestination];
