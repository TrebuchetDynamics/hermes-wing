import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../router/app_routes.dart';

class AppShellPresentation {
  const AppShellPresentation(this.localizations);

  final AppLocalizations localizations;

  List<AppShellDestination> get destinations => [
    _hermesDestination,
    _agentsDestination,
    _providersDestination,
    _settingsDestination,
  ];

  List<AppShellDestination> get mobileNavigationDestinations => [
    _hermesDestination,
    _settingsDestination,
  ];

  List<AppShellDestination> get mobileOverflowDestinations => [
    _agentsDestination,
    _providersDestination,
  ];

  String get mobileOverflowLabel => localizations.moreDestinations;

  String get mobileOverflowTooltip => localizations.openMoreDestinations;

  AppShellDestination get _hermesDestination => AppShellDestination(
    path: AppRoutes.hermes,
    icon: Icons.auto_awesome_outlined,
    label: localizations.hermesDestination,
  );

  AppShellDestination get _agentsDestination => AppShellDestination(
    path: AppRoutes.agents,
    icon: Icons.support_agent_outlined,
    label: localizations.agentsDestination,
  );

  AppShellDestination get _providersDestination => AppShellDestination(
    path: AppRoutes.providers,
    icon: Icons.vpn_key_outlined,
    label: localizations.providersDestination,
  );

  AppShellDestination get _settingsDestination => AppShellDestination(
    path: AppRoutes.settings,
    icon: Icons.keyboard_voice_outlined,
    label: localizations.settingsDestination,
  );

  AppShellNavigationState stateForLocation(String location) {
    final allDestinations = destinations;
    final selectedIndex = allDestinations.indexWhere(
      (destination) => AppRoutes.isNavigationDestinationLocation(
        location: location,
        destinationPath: destination.path,
      ),
    );
    final selected = selectedIndex < 0 ? 0 : selectedIndex;
    return AppShellNavigationState(
      destinations: allDestinations,
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
