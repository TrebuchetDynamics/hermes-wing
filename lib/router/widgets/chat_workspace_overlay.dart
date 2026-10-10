import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app_routes.dart';

/// Navigator owns the retained workspace and its complete return location.
/// Deep links have no retained workspace and return through normal chat entry.
class ChatWorkspaceOverlay extends StatelessWidget {
  const ChatWorkspaceOverlay({required this.child, super.key});

  final Widget child;

  static void open(BuildContext context, String location) {
    final path = Uri.parse(location).path;
    final isOverlay =
        path == AppRoutes.profiles ||
        path == AppRoutes.settings ||
        path == AppRoutes.settingsVoice ||
        path == AppRoutes.settingsDiagnostics;
    if (isOverlay && GoRouterState.of(context).uri.path == AppRoutes.hermes) {
      context.push(location);
    } else {
      context.go(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    void dismiss() {
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(AppRoutes.hermes);
      }
    }

    return PopScope(
      canPop: router.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) dismiss();
      },
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): dismiss},
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 8 : 24,
            ),
            child: Material(
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      key: const ValueKey('chat-workspace-overlay-close'),
                      autofocus: true,
                      tooltip: AppLocalizations.of(context).closeAction,
                      onPressed: dismiss,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  Expanded(child: SelectionArea(child: child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
