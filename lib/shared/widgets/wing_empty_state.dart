import 'package:flutter/material.dart';

/// Shared empty/info/error state used by the gateway-scoped screens
/// (Agents, Providers, Tools, Schedules, Gateway) so unselected, unsupported,
/// and failed states read as one consistent pattern.
class WingEmptyState extends StatelessWidget {
  const WingEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.liveRegion = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Semantics(
          container: true,
          liveRegion: liveRegion,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      icon,
                      size: 24,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (actionLabel != null) ...[
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: onAction,
                            child: Text(actionLabel!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
