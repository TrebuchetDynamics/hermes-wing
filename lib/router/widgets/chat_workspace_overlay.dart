import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app_routes.dart';

/// Overlay composition ported from the official Hermes Desktop.
///
/// The Desktop overlay uses an equidistant inset driven by the OS titlebar
/// height, a blurred backdrop, and a floating close (X) at the top-right with
/// no redundant header row. This widget reproduces that structure on Flutter:
///  - backdrop: 22% black with a small blur so the chat behind stays readable;
///  - inset:    titlebar height (34) + a small cap (10 compact / 14 wide),
///              identical on all four sides;
///  - chrome:   only the titlebar-sized close button remains; focus and
///              accessibility are preserved (autofocused, tooltip, Escape, and
///              a retained [SelectionArea]).
class ChatWorkspaceOverlay extends StatelessWidget {
  const ChatWorkspaceOverlay({required this.child, super.key});

  final Widget child;

  // Official Desktop titlebar height (src/app/shell/titlebar.ts).
  static const double _titlebarHeight = 34.0;

  static Future<void> open(
    BuildContext context,
    String location, {
    FocusNode? returnFocus,
  }) async {
    final path = Uri.parse(location).path;
    final isOverlay =
        path == AppRoutes.profiles ||
        path == AppRoutes.settings ||
        path == AppRoutes.settingsVoice ||
        path == AppRoutes.settingsDiagnostics;
    if (isOverlay && GoRouterState.of(context).uri.path == AppRoutes.hermes) {
      // History restores Navigator focus without completing the original push.
      returnFocus?.requestFocus();
      await context.push<void>(location);
      if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        returnFocus?.requestFocus();
      }
    } else {
      context.go(location);
    }
  }

  static Future<void> _restoreNavigatorFocusAfterPop(
    ModalRoute<dynamic> route,
    NavigatorState navigator,
  ) async {
    await route.completed;
    final frame = WidgetsBinding.instance.endOfFrame;
    WidgetsBinding.instance.ensureVisualUpdate();
    await frame;
    if (!navigator.mounted) return;
    final scope = navigator.focusNode.enclosingScope;
    final focus = FocusManager.instance.primaryFocus;
    // Teardown can park focus on the root. Resume this Navigator's own history,
    // never a captured editor or a replacement control that has taken focus.
    if (scope != null &&
        GoRouter.maybeOf(navigator.context)?.state.uri.path ==
            AppRoutes.hermes &&
        (focus == null ||
            identical(focus, FocusManager.instance.rootScope) ||
            identical(focus, scope))) {
      scope.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    void dismiss() {
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(AppRoutes.hermes);
      }
    }

    final wide = MediaQuery.sizeOf(context).width >= 600;
    // Equidistant inset on all four sides, driven by the official Desktop
    // titlebar height plus a small cap (10 compact / 14 wide).
    final double pad = _titlebarHeight + (wide ? 14 : 10);

    return PopScope(
      canPop: router.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          dismiss();
        } else if (route != null) {
          unawaited(_restoreNavigatorFocusAfterPop(route, navigator));
        }
      },
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): dismiss},
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(color: Colors.black.withValues(alpha: 0.22)),
                ),
                SelectionArea(
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 4,
                    shadowColor: Colors.black54,
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        child,
                        PositionedDirectional(
                          top: 4,
                          end: 0,
                          child: IconButton(
                            key: const ValueKey('chat-workspace-overlay-close'),
                            autofocus: true,
                            tooltip: AppLocalizations.of(context).closeAction,
                            onPressed: dismiss,
                            icon: const Icon(Icons.close),
                          ),
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
    );
  }
}
