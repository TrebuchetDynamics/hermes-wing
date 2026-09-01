import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/hermes/channel/hermes_channel_state.dart';
import '../../features/profiles/providers/profile_selection_provider.dart';
import '../../features/hermes_chat/providers/hermes_channel_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_routes.dart';
import 'app_shell_presentation.dart';
import 'sheet_presenter.dart';

// ponytail: one app shell; route state can replace this if nested shells arrive.
final appShellNavigationVisible = ValueNotifier(true);

class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final presentation = AppShellPresentation(l10n).stateForLocation(location);
    final channel = ref.watch(hermesChannelProvider);

    return AnimatedBuilder(
      animation: channel,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final status = _AppShellStatus.fromState(channel.state, l10n);
          if (constraints.maxWidth < 600) {
            return _MobileShell(
              location: location,
              presentation: presentation,
              status: status,
              child: child,
            );
          }
          return _DesktopShell(
            destinations: presentation.destinations,
            selectedIndex: presentation.selectedIndex,
            onSelected: (index) =>
                context.go(presentation.destinations[index].path),
            status: status,
            child: child,
          );
        },
      ),
    );
  }
}

class _AppShellNavigationScope extends InheritedWidget {
  const _AppShellNavigationScope({
    required this.suppressPageMenu,
    required super.child,
  });

  final bool suppressPageMenu;

  static bool suppressMenuOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_AppShellNavigationScope>()
          ?.suppressPageMenu ??
      false;

  @override
  bool updateShouldNotify(_AppShellNavigationScope oldWidget) =>
      suppressPageMenu != oldWidget.suppressPageMenu;
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.location,
    required this.child,
    required this.presentation,
    required this.status,
  });

  final String location;
  final Widget child;
  final AppShellNavigationState presentation;
  final _AppShellStatus status;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: appShellNavigationVisible,
    builder: (context, visible, _) => _AppShellNavigationScope(
      suppressPageMenu: visible,
      child: Scaffold(
        body: child,
        bottomNavigationBar: visible
            ? NavigationBar(
                key: const ValueKey('mobile-shell-navigation-bar'),
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  if (index == 2) {
                    _showMoreDestinations(
                      context,
                      title: AppLocalizations.of(context).moreDestinations,
                      destinations: presentation.destinations,
                      status: status,
                      currentPath: location,
                    );
                    return;
                  }
                  context.go(
                    index == 0 ? AppRoutes.hermes : AppRoutes.settings,
                  );
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: AppLocalizations.of(context).hermesDestination,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.settings_outlined),
                    label: AppLocalizations.of(context).settingsDestination,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.more_horiz),
                    label: AppLocalizations.of(context).moreDestinations,
                  ),
                ],
              )
            : null,
      ),
    ),
  );

  int get _selectedIndex {
    if (AppRoutes.isNavigationDestinationLocation(
      location: location,
      destinationPath: AppRoutes.hermes,
    )) {
      return 0;
    }
    if (AppRoutes.isSettingsLocation(location)) return 1;
    return 2;
  }
}

class AppShellMenuButton extends ConsumerWidget {
  const AppShellMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(hermesChannelProvider);
    return AnimatedBuilder(
      animation: channel,
      builder: (context, _) => ValueListenableBuilder<bool>(
        valueListenable: appShellNavigationVisible,
        builder: (context, visible, _) {
          if (!visible ||
              MediaQuery.sizeOf(context).width >= 600 ||
              _AppShellNavigationScope.suppressMenuOf(context)) {
            return const SizedBox.shrink();
          }
          final l10n = AppLocalizations.of(context);
          final presentation = AppShellPresentation(l10n);
          final status = _AppShellStatus.fromState(channel.state, l10n);
          return IconButton(
            key: const ValueKey('app-shell-menu-button'),
            tooltip: presentation.mobileOverflowTooltip,
            icon: const Icon(Icons.apps_outlined),
            onPressed: () {
              final currentPath = _routerPathOrEmpty(context);
              _showMoreDestinations(
                context,
                title: presentation.mobileOverflowLabel,
                destinations: presentation.destinations,
                status: status,
                currentPath: currentPath,
              );
            },
          );
        },
      ),
    );
  }
}

String _routerPathOrEmpty(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } on GoError {
    // Standalone widget previews/tests can use the menu without a router.
    return '';
  }
}

void _showMoreDestinations(
  BuildContext context, {
  required String title,
  required List<AppShellDestination> destinations,
  required _AppShellStatus status,
  required String currentPath,
}) {
  showSheet(
    context,
    InfoActionSheet(
      title,
      infoRows: status.infoRows,
      actions: [
        for (final destination in destinations)
          if (!AppRoutes.isNavigationDestinationLocation(
            location: currentPath,
            destinationPath: destination.path,
          ))
            SheetActionRow(
              destination.icon,
              destination.label,
              onTap: (sheetContext) {
                Navigator.of(sheetContext).pop();
                context.push(destination.path);
              },
            ),
      ],
    ),
  );
}

class _AppShellStatus {
  const _AppShellStatus({
    required this.gatewayLabel,
    required this.profileLabel,
    required this.modelLabel,
    required this.inventoryLabel,
    required this.gateway,
    required this.profile,
    required this.model,
    required this.inventory,
  });

  factory _AppShellStatus.fromState(
    HermesChannelState state,
    AppLocalizations l10n,
  ) {
    if (!state.isConnected) {
      return _AppShellStatus(
        gatewayLabel: l10n.gatewayLabel,
        profileLabel: l10n.shellProfileLabel,
        modelLabel: l10n.shellModelLabel,
        inventoryLabel: l10n.shellInventoryLabel,
        gateway: l10n.shellDisconnected,
        profile: l10n.shellNotLoaded,
        model: l10n.shellNotLoaded,
        inventory: l10n.shellNotLoaded,
      );
    }
    final uri = Uri.tryParse(state.connectedBaseUrl ?? '');
    final host = uri == null || uri.host.isEmpty
        ? 'Hermes'
        : uri.hasPort
        ? '${uri.host}:${uri.port}'
        : uri.host;
    final profileId = effectiveSelectedProfileId(state);
    final profile = state.selectedProfile;
    final profileName = profile?.displayName.trim().isNotEmpty == true
        ? profile!.displayName.trim()
        : profileId ?? l10n.shellNotLoaded;
    final assignedModel = state.modelInventory?.assignment.activeModel.trim();
    final model = assignedModel?.isNotEmpty == true
        ? assignedModel!
        : profile?.model.trim().isNotEmpty == true
        ? profile!.model.trim()
        : state.activeSession?.model?.trim().isNotEmpty == true
        ? state.activeSession!.model!.trim()
        : state.capabilities?.model.trim().isNotEmpty == true
        ? state.capabilities!.model.trim()
        : l10n.shellNotLoaded;
    final inventoryFailed =
        state.optionalResourceErrors.containsKey(
          HermesOptionalResource.skills,
        ) ||
        state.optionalResourceErrors.containsKey(
          HermesOptionalResource.toolsets,
        );
    final tools = <String>{
      for (final toolset in state.toolsets) ...toolset.tools,
    };
    final skillCount = state.skillDetails.isNotEmpty
        ? state.skillDetails.length
        : state.skills.length;
    return _AppShellStatus(
      gatewayLabel: l10n.gatewayLabel,
      profileLabel: l10n.shellProfileLabel,
      modelLabel: l10n.shellModelLabel,
      inventoryLabel: l10n.shellInventoryLabel,
      gateway: l10n.shellConnectedHost(host),
      profile: profileName,
      model: model,
      inventory: inventoryFailed
          ? l10n.shellUnavailable
          : l10n.shellInventorySummary(tools.length, skillCount),
    );
  }

  final String gatewayLabel;
  final String profileLabel;
  final String modelLabel;
  final String inventoryLabel;
  final String gateway;
  final String profile;
  final String model;
  final String inventory;

  List<SheetInfoRow> get infoRows => [
    SheetInfoRow(Icons.cloud_outlined, gatewayLabel, gateway),
    SheetInfoRow(Icons.person_outline, profileLabel, profile),
    SheetInfoRow(Icons.memory_outlined, modelLabel, model),
    SheetInfoRow(Icons.build_outlined, inventoryLabel, inventory),
  ];
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.child,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.status,
  });

  final Widget child;
  final List<AppShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final _AppShellStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelected,
                  extended: true,
                  minExtendedWidth: 256,
                  leading: const _HermesDesktopBrand(),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth < 1180
                            ? constraints.maxWidth
                            : 1180.0;
                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(width: width, child: child),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          _DesktopStatusBar(status: status),
        ],
      ),
    );
  }
}

class _DesktopStatusBar extends StatelessWidget {
  const _DesktopStatusBar({required this.status});

  final _AppShellStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = status.infoRows;
    return Container(
      key: const ValueKey('app-shell-status-bar'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(
              child: Tooltip(
                message: '${rows[index].label}: ${rows[index].value}',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rows[index].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      rows[index].value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HermesDesktopBrand extends StatelessWidget {
  const _HermesDesktopBrand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: SizedBox(
        width: 224,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.36),
                ),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HERMES WING',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hermes Agent client',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
