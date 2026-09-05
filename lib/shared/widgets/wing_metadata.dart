import 'package:flutter/material.dart';

/// Non-interactive metadata has no chip padding or reserved touch target.
class WingMetadata extends StatelessWidget {
  const WingMetadata({super.key, this.avatar, required this.label});

  final Widget? avatar;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null) ...[
            IconTheme(
              data: IconThemeData(
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              child: avatar!,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: DefaultTextStyle(
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              child: label,
            ),
          ),
        ],
      ),
    );
  }
}
