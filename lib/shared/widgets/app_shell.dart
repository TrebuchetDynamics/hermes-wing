import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/hermes/channel/hermes_channel_state.dart';
import '../../features/profiles/providers/profile_selection_provider.dart';
import '../../features/settings/providers/shell_preferences_provider.dart';
import '../../features/hermes_chat/providers/hermes_channel_provider.dart';
import '../../features/hermes_chat/widgets/shell_session_access.dart';
import '../../features/hermes_chat/widgets/global_session_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_routes.dart';
import '../../router/widgets/chat_workspace_overlay.dart';
import '../security/wing_redaction.dart';
import 'app_shell_desktop_style.dart';
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
    final sidebarExpanded = ref.watch(wingSidebarExpandedProvider);

    return GlobalSessionScope(
      child: AnimatedBuilder(
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
            final desktopPresentation = AppShellPresentation(
              l10n,
            ).stateForLocation(location, desktop: true);
            return _DesktopShell(
              expanded: sidebarExpanded,
              onToggle: () => ref
                  .read(wingSidebarExpandedProvider.notifier)
                  .setSidebarExpanded(!ref.read(wingSidebarExpandedProvider)),
              destinations: desktopPresentation.destinations,
              selectedIndex: desktopPresentation.selectedIndex,
              onSelected: (index) => ChatWorkspaceOverlay.open(
                context,
                desktopPresentation.destinations[index].path,
              ),
              status: status,
              child: child,
            );
          },
        ),
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
                  if (index == 3) {
                    _showMoreDestinations(
                      context,
                      title: AppLocalizations.of(context).moreDestinations,
                      destinations: presentation.destinations
                          .where(
                            (destination) =>
                                destination.path != AppRoutes.hermes &&
                                destination.path != AppRoutes.profiles &&
                                destination.path != AppRoutes.gateway,
                          )
                          .toList(),
                      status: status,
                      currentPath: location,
                    );
                    return;
                  }
                  ChatWorkspaceOverlay.open(
                    context,
                    [
                      AppRoutes.hermes,
                      AppRoutes.profiles,
                      AppRoutes.gateway,
                    ][index],
                  );
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.chat_bubble_outline),
                    selectedIcon: const Icon(Icons.chat_bubble),
                    label: AppLocalizations.of(context).hermesDestination,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.people_outline),
                    selectedIcon: const Icon(Icons.people),
                    label: AppLocalizations.of(context).agentsDestination,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.dns_outlined),
                    label: AppLocalizations.of(context).gatewayDestination,
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
    if (AppRoutes.isNavigationDestinationLocation(
      location: location,
      destinationPath: AppRoutes.profiles,
    )) {
      return 1;
    }
    if (location == AppRoutes.gateway) return 2;
    return 3;
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
      infoBuilder: (sheetContext) {
        final channel = ProviderScope.containerOf(
          context,
        ).read(hermesChannelProvider);
        return AnimatedBuilder(
          animation: channel,
          builder: (context, _) => _DesktopStatusBar(
            initiallyExpanded: true,
            status: _AppShellStatus.fromState(
              channel.state,
              AppLocalizations.of(context),
            ),
          ),
        );
      },
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
    required this.expanded,
    required this.onToggle,
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
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = AppShellDesktopStyle.forBrightness(theme.brightness);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            // Scrolling destinations must not reorder the shell/route boundary.
            child: FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              child: Row(
                children: [
                  FocusTraversalGroup(
                    policy: WidgetOrderTraversalPolicy(),
                    child: SizedBox(
                      key: const ValueKey('desktop-sidebar'),
                      width: expanded ? 250 : 64,
                      child: Theme(
                        data: style.sidebarTheme(theme),
                        child: Builder(
                          builder: (context) => ColoredBox(
                            color: style.rail,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 64,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Align(
                                      alignment: expanded
                                          ? Alignment.centerRight
                                          : Alignment.center,
                                      child: MergeSemantics(
                                        key: const ValueKey(
                                          'desktop-sidebar-toggle',
                                        ),
                                        child: Semantics(
                                          expanded: expanded,
                                          child: IconButton(
                                            style: style.toggleStyle(),
                                            constraints:
                                                const BoxConstraints.tightFor(
                                                  width: 48,
                                                  height: 48,
                                                ),
                                            tooltip: expanded
                                                ? MaterialLocalizations.of(
                                                    context,
                                                  ).expandedIconTapHint
                                                : MaterialLocalizations.of(
                                                    context,
                                                  ).collapsedIconTapHint,
                                            icon: Icon(
                                              expanded
                                                  ? Icons.chevron_left
                                                  : Icons.chevron_right,
                                              size: 16,
                                            ),
                                            onPressed: onToggle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  // Keep layout-built destinations ordered before
                                  // the fixed footer regardless of attach timing.
                                  child: FocusTraversalGroup(
                                    policy: WidgetOrderTraversalPolicy(),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) => SingleChildScrollView(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: constraints.maxHeight,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                children: [
                                                  _navigationGroup(
                                                    context,
                                                    key: const ValueKey(
                                                      'desktop-workflow-navigation',
                                                    ),
                                                    label: AppLocalizations.of(
                                                      context,
                                                    ).shellWorkflowNavigation,
                                                    start: 0,
                                                    end: 3,
                                                  ),
                                                  if (expanded)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 8,
                                                      ),
                                                      child:
                                                          ShellSessionAccess(),
                                                    ),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  const Divider(
                                                    indent: 12,
                                                    endIndent: 12,
                                                  ),
                                                  _navigationGroup(
                                                    context,
                                                    key: const ValueKey(
                                                      'desktop-utility-navigation',
                                                    ),
                                                    label: AppLocalizations.of(
                                                      context,
                                                    ).shellUtilityNavigation,
                                                    start: 3,
                                                    end: destinations.length,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _DesktopProfileFooter(
                                  expanded: expanded,
                                  status: status,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FocusTraversalGroup(
                      policy: ReadingOrderTraversalPolicy(),
                      child: Container(
                        color: style.workArea,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            return Align(
                              alignment: Alignment.topCenter,
                              // A nested route's BlockSemantics must not hide the
                              // rail painted before it from keyboard/semantic focus.
                              child: Semantics(
                                container: true,
                                explicitChildNodes: true,
                                child: SizedBox(
                                  width: width,
                                  child: Theme(
                                    data: theme.copyWith(
                                      scaffoldBackgroundColor: style.workArea,
                                    ),
                                    child: child,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _DesktopStatusBar(status: status),
        ],
      ),
    );
  }

  Widget _navigationGroup(
    BuildContext context, {
    required Key key,
    required String label,
    required int start,
    required int end,
  }) {
    final theme = Theme.of(context);
    return Semantics(
      key: key,
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = start; index < end; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Builder(
                  builder: (destinationContext) => Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onFocusChange: (focused) {
                      if (focused) {
                        Scrollable.ensureVisible(
                          destinationContext,
                          alignment: 0.5,
                        );
                      }
                    },
                    child: MergeSemantics(
                      child: Semantics(
                        selected: selectedIndex == index,
                        child: Tooltip(
                          message: destinations[index].label,
                          excludeFromSemantics: true,
                          child: TextButton(
                            style: AppShellDesktopStyle.forBrightness(
                              theme.brightness,
                            ).navigationStyle(selected: selectedIndex == index),
                            onPressed: () => onSelected(index),
                            child: expanded
                                ? Row(
                                    children: [
                                      Icon(destinations[index].icon, size: 16),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(destinations[index].label),
                                      ),
                                    ],
                                  )
                                : Semantics(
                                    label: destinations[index].label,
                                    child: ExcludeSemantics(
                                      child: Icon(
                                        destinations[index].icon,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Display only: no inventory read, selection or deferred domain intent.
class _DesktopProfileFooter extends StatelessWidget {
  const _DesktopProfileFooter({required this.expanded, required this.status});

  final bool expanded;
  final _AppShellStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = AppShellDesktopStyle.forBrightness(
      Theme.of(context).brightness,
    );
    // Bound after redaction; use the same safe context in every new surface.
    final profile = wingRedactedPreview(status.profile, maxLength: 80);
    final label =
        '${l10n.chatProfileManage} — ${status.profileLabel}: $profile';
    return Container(
      key: const ValueKey('desktop-profile-footer'),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: style.border)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.profileLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: style.secondary, fontSize: 11),
                  ),
                  Text(
                    key: const ValueKey('desktop-profile-value'),
                    profile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: style.secondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          Tooltip(
            message: label,
            excludeFromSemantics: true,
            child: TextButton(
              key: const ValueKey('desktop-manage-profiles'),
              style: style.toggleStyle().copyWith(
                visualDensity: VisualDensity.standard,
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                ),
              ),
              onPressed: () =>
                  ChatWorkspaceOverlay.open(context, AppRoutes.profiles),
              child: Semantics(
                label: label,
                child: ExcludeSemantics(
                  child: expanded
                      ? Row(
                          children: [
                            const Icon(Icons.people_outline, size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Text(l10n.chatProfileManage)),
                          ],
                        )
                      : const Icon(Icons.people_outline, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopStatusBar extends StatefulWidget {
  const _DesktopStatusBar({
    required this.status,
    this.initiallyExpanded = false,
  });

  final _AppShellStatus status;
  final bool initiallyExpanded;

  @override
  State<_DesktopStatusBar> createState() => _DesktopStatusBarState();
}

class _DesktopStatusBarState extends State<_DesktopStatusBar> {
  bool _inspect = false;

  @override
  void initState() {
    super.initState();
    _inspect = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = AppShellDesktopStyle.forBrightness(theme.brightness);
    final rows = widget.status.infoRows;
    return Container(
      key: const ValueKey('app-shell-status-bar'),
      constraints: const BoxConstraints(minHeight: 26),
      decoration: BoxDecoration(
        color: style.rail,
        border: Border(top: BorderSide(color: style.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Inspection stays inline and is rebuilt from the current owner;
          // no modal captures obsolete connection/profile/model context.
          final columns = _inspect
              ? (constraints.maxWidth /
                        (260 * MediaQuery.textScalerOf(context).scale(1)))
                    .floor()
                    .clamp(1, rows.length)
              : rows.length;
          final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final row in rows)
                SizedBox(
                  width: width,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: style.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => setState(() => _inspect = !_inspect),
                    child: Semantics(
                      label:
                          '${row.label}: ${wingRedactSensitiveText(row.value)}',
                      expanded: _inspect,
                      child: ExcludeSemantics(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(row.icon, size: 12, color: style.secondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: DefaultTextStyle(
                                style: theme.textTheme.labelMedium!.copyWith(
                                  color: style.secondary,
                                  fontSize: 11,
                                  height: 1,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_inspect) Text(row.label),
                                    Text(
                                      wingRedactSensitiveText(row.value),
                                      maxLines: _inspect ? null : 1,
                                      overflow: _inspect
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
