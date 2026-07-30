import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'wing_tips.dart';

/// A compact, dismissible first-run tip. Renders nothing until the persisted
/// dismissals load, and never again once [tip] was dismissed, so callers can
/// place it unconditionally on the surface where the tip matters.
class WingTipCard extends ConsumerWidget {
  const WingTipCard({required this.tip, required this.text, super.key});

  final WingTip tip;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(wingTipsProvider).shouldShow(tip)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      key: ValueKey('wing-tip-${tip.name}'),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      color: colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
            IconButton(
              key: ValueKey('wing-tip-${tip.name}-dismiss'),
              tooltip: AppLocalizations.of(context).tipDismissTooltip,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => ref.read(wingTipsProvider.notifier).dismiss(tip),
            ),
          ],
        ),
      ),
    );
  }
}
