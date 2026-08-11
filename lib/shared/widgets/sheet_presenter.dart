import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Content models
// ---------------------------------------------------------------------------

/// Content for a modal bottom sheet presented by [showSheet].
sealed class SheetContent {
  const SheetContent._();

  String get title;
}

/// A sheet with a title and a list of tappable action rows.
class ActionSheet extends SheetContent {
  @override
  final String title;
  final List<SheetActionRow> rows;

  const ActionSheet(this.title, {required this.rows}) : super._();
}

/// A sheet with a title, read-only info rows, and tappable action rows below
/// a divider.
class InfoActionSheet extends SheetContent {
  @override
  final String title;
  final List<SheetInfoRow> infoRows;
  final List<SheetActionRow> actions;

  const InfoActionSheet(
    this.title, {
    required this.infoRows,
    required this.actions,
  }) : super._();
}

/// A single tappable row in an [ActionSheet] or [InfoActionSheet].
class SheetActionRow {
  final IconData icon;
  final String label;
  final String? subtitle;
  final void Function(BuildContext sheetContext) onTap;

  const SheetActionRow(
    this.icon,
    this.label, {
    this.subtitle,
    required this.onTap,
  });
}

/// A read-only info row in an [InfoActionSheet].
class SheetInfoRow {
  final IconData icon;
  final String label;
  final String value;

  const SheetInfoRow(this.icon, this.label, this.value);
}

// ---------------------------------------------------------------------------
// Presenter
// ---------------------------------------------------------------------------

/// Shows a modal bottom sheet for the given [content].
///
/// The presenter owns `showDragHandle: true`, `SafeArea`, scroll behavior, and
/// padding. Callers provide structured content via [SheetContent] variants.
void showSheet(BuildContext context, SheetContent content) {
  switch (content) {
    case ActionSheet(:final title, :final rows):
      _showActionSheet(context, title, rows);
    case InfoActionSheet(:final title, :final infoRows, :final actions):
      _showInfoActionSheet(context, title, infoRows, actions);
  }
}

void _showActionSheet(
  BuildContext context,
  String title,
  List<SheetActionRow> rows,
) {
  final useScroll = rows.length > 6;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: useScroll,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: useScroll
          ? DraggableScrollableSheet(
              expand: false,
              initialChildSize: _initialSheetSize(rows.length),
              minChildSize: 0.24,
              maxChildSize: 0.90,
              builder: (context, scrollController) => ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  for (final row in rows) _buildActionRow(context, row),
                ],
              ),
            )
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final row in rows) _buildActionRow(context, row),
              ],
            ),
    ),
  );
}

void _showInfoActionSheet(
  BuildContext context,
  String title,
  List<SheetInfoRow> infoRows,
  List<SheetActionRow> actions,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.64,
        minChildSize: 0.24,
        maxChildSize: 0.90,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildInfoGrid(context, infoRows),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (final action in actions) _buildActionRow(context, action),
          ],
        ),
      ),
    ),
  );
}

Widget _buildInfoGrid(BuildContext context, List<SheetInfoRow> rows) {
  const spacing = 12.0;
  return LayoutBuilder(
    builder: (context, constraints) {
      final columnWidth = (constraints.maxWidth - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: 4,
        children: [
          for (final row in rows)
            SizedBox(
              width: columnWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(row.icon, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            row.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

Widget _buildActionRow(BuildContext context, SheetActionRow row) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(row.icon),
    title: Text(row.label),
    subtitle: row.subtitle == null ? null : Text(row.subtitle!),
    onTap: () => row.onTap(context),
  );
}

double _initialSheetSize(int rowCount) {
  if (rowCount <= 3) return 0.32;
  if (rowCount <= 5) return 0.46;
  return 0.64;
}
