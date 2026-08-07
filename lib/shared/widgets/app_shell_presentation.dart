import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../router/app_routes.dart';

class AppShellPresentation {
  const AppShellPresentation(this.localizations);

  final AppLocalizations localizations;

  List<AppShellDestination> get destinations => [
    _hermesDestination,
    _officeDestination,
    _agentsDestination,
    _providersDestination,
    _toolsDestination,
    _schedulesDestination,
    _gatewayDestination,
    _settingsDestination,
  ];

  String get mobileOverflowLabel => localizations.moreDestinations;

  String get mobileOverflowTooltip => localizations.openMoreDestinations;

  AppShellDestination get _hermesDestination => AppShellDestination(
    path: AppRoutes.hermes,
    icon: Icons.auto_awesome_outlined,
    label: localizations.hermesDestination,
  );

  AppShellDestination get _officeDestination => AppShellDestination(
    path: AppRoutes.office,
    icon: Icons.apartment_outlined,
    label: localizations.officeDestination,
  );

  AppShellDestination get _agentsDestination => AppShellDestination(
    path: AppRoutes.profiles,
    icon: Icons.support_agent_outlined,
    label: localizations.agentsDestination,
  );

  AppShellDestination get _providersDestination => AppShellDestination(
    path: AppRoutes.providers,
    icon: Icons.vpn_key_outlined,
    label: localizations.providersDestination,
  );

  AppShellDestination get _toolsDestination => AppShellDestination(
    path: AppRoutes.tools,
    icon: Icons.build_outlined,
    label: localizations.toolsDestination,
  );

  AppShellDestination get _schedulesDestination => AppShellDestination(
    path: AppRoutes.schedules,
    icon: Icons.schedule_outlined,
    label: localizations.schedulesDestination,
  );

  AppShellDestination get _gatewayDestination => AppShellDestination(
    path: AppRoutes.gateway,
    icon: Icons.dns_outlined,
    label: localizations.gatewayDestination,
  );

  AppShellDestination get _settingsDestination => AppShellDestination(
    path: AppRoutes.settings,
    icon: Icons.settings_outlined,
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
      selectedIndex: selected,
    );
  }
}

class AppShellNavigationState {
  const AppShellNavigationState({
    required this.destinations,
    required this.selectedIndex,
  });

  final List<AppShellDestination> destinations;
  final int selectedIndex;
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
