import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/wing_theme.dart';
import 'app_shell_presentation.dart';
import 'sheet_presenter.dart';

// ponytail: one app shell; route state can replace this if nested shells arrive.
final appShellNavigationVisible = ValueNotifier(true);

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final presentation = AppShellPresentation(
      AppLocalizations.of(context),
    ).stateForLocation(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return child;
        return _DesktopShell(
          destinations: presentation.destinations,
          selectedIndex: presentation.selectedIndex,
          onSelected: (index) =>
              context.go(presentation.destinations[index].path),
          child: child,
        );
      },
    );
  }
}

class AppShellMenuButton extends StatelessWidget {
  const AppShellMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appShellNavigationVisible,
      builder: (context, visible, _) {
        if (!visible || MediaQuery.sizeOf(context).width >= 600) {
          return const SizedBox.shrink();
        }
        final presentation = AppShellPresentation(AppLocalizations.of(context));
        return IconButton(
          key: const ValueKey('app-shell-menu-button'),
          tooltip: presentation.mobileOverflowTooltip,
          icon: const Icon(Icons.apps_outlined),
          onPressed: () => showSheet(
            context,
            ActionSheet(
              presentation.mobileOverflowLabel,
              rows: [
                for (final destination in presentation.destinations)
                  SheetActionRow(
                    destination.icon,
                    destination.label,
                    onTap: (sheetContext) {
                      Navigator.of(sheetContext).pop();
                      context.go(destination.path);
                    },
                  ),
              ],
            ),
          ),
        );
      },
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
  final List<AppShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: wingHermesDarkTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            body: Row(
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
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
                    'HERMES ONE',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hermes Wing',
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
