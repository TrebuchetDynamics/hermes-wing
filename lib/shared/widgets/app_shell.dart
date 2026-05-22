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
      _Destination(AppRoutes.memory, Icons.psychology_alt_outlined, 'Memory'),
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
          showNavigationMenu: !isChatThread,
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
    required this.showNavigationMenu,
    required this.onSelected,
  });

  final Widget child;
  final List<_Destination> destinations;
  final int selectedIndex;
  final bool showNavigationMenu;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: showNavigationMenu
          ? _AppNavigationDrawer(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            )
          : null,
      floatingActionButton: showNavigationMenu
          ? Builder(
              builder: (context) => FloatingActionButton.small(
                heroTag: 'navivox-navigation-menu',
                tooltip: 'Open navigation menu',
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.primary,
                elevation: 0,
                highlightElevation: 0,
                shape: const CircleBorder(),
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Icon(Icons.menu),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      body: child,
    );
  }
}

class _AppNavigationDrawer extends StatelessWidget {
  const _AppNavigationDrawer({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(color: colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.onPrimary.withAlpha(32),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Navivox',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Gormes operator console',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (var index = 0; index < destinations.length; index++)
              ListTile(
                leading: Icon(destinations[index].icon),
                title: Text(destinations[index].label),
                selected: index == selectedIndex,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelected(index);
                },
              ),
          ],
        ),
      ),
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
