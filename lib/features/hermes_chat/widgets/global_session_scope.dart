import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import 'shell_session_access.dart';

/// Presentation admission only. Inventory and actions remain channel-owned.
class GlobalSessionScope extends StatefulWidget {
  const GlobalSessionScope({required this.child, super.key});
  final Widget child;

  static void open(BuildContext context) =>
      context.findAncestorStateOfType<_GlobalSessionScopeState>()?._open();

  @override
  State<GlobalSessionScope> createState() => _GlobalSessionScopeState();
}

class _GlobalSessionScopeState extends State<GlobalSessionScope> {
  bool _openPending = false;

  Future<void> _open() async {
    if (_openPending) return;
    _openPending = true;
    final opener = FocusManager.instance.primaryFocus;
    try {
      await showDialog<void>(
        context: context,
        traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
        builder: (dialogContext) => Dialog(
          child: SizedBox(
            width: 720,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: const ValueKey('global-sessions-close'),
                    tooltip: MaterialLocalizations.of(
                      dialogContext,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Flexible(child: ShellSessionAccess(fullPanel: true)),
              ],
            ),
          ),
        ),
      );
    } finally {
      _openPending = false;
      if (mounted &&
          opener != null &&
          opener.context != null &&
          opener.canRequestFocus) {
        opener.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.keyK &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        _open();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: widget.child,
  );
}

class GlobalSessionsButton extends StatelessWidget {
  const GlobalSessionsButton({this.enabled = true, super.key});
  final bool enabled;
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) =>
        event is KeyRepeatEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)
        ? KeyEventResult.handled
        : KeyEventResult.ignored,
    child: TextButton.icon(
      key: const ValueKey('global-sessions-open'),
      onPressed: enabled ? () => GlobalSessionScope.open(context) : null,
      icon: const Icon(Icons.search),
      label: Text(AppLocalizations.of(context).chatLayoutSessionsLabel),
    ),
  );
}
