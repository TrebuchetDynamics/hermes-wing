import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _Destination(AppRoutes.chats, Icons.chat_bubble_outlined, 'Chats'),
      _Destination(AppRoutes.servers, Icons.dns_outlined, 'Servers'),
      _Destination(AppRoutes.agents, Icons.smart_toy_outlined, 'Agents'),
      _Destination(AppRoutes.config, Icons.settings_outlined, 'Config'),
      _Destination(
        AppRoutes.settings,
        Icons.keyboard_voice_outlined,
        'Settings',
      ),
    ];
    final selectedIndex = destinations.indexWhere(
      (destination) => location.startsWith(destination.path),
    );
    final selected = selectedIndex < 0 ? 0 : selectedIndex;
    final isChatThread = location.startsWith('${AppRoutes.chats}/');

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _DesktopShell(
            destinations: destinations,
            selectedIndex: selected,
            onSelected: (index) => context.go(destinations[index].path),
            child: child,
          );
        }
        return _MobileShell(
          destinations: destinations,
          selectedIndex: selected,
          showNavigationBar: !isChatThread,
          onSelected: (index) => context.go(destinations[index].path),
          child: child,
        );
      },
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.child,
    required this.destinations,
    required this.selectedIndex,
    required this.showNavigationBar,
    required this.onSelected,
  });

  final Widget child;
  final List<_Destination> destinations;
  final int selectedIndex;
  final bool showNavigationBar;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: showNavigationBar
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            )
          : null,
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.child,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final Widget child;
  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            extended: true,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceContainerLowest,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.path, this.icon, this.label);

  final String path;
  final IconData icon;
  final String label;
}
