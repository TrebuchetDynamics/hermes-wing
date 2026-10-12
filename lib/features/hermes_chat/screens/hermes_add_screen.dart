import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../router/app_routes.dart';

import 'hermes_chat_screen.dart';

/// The connection setup surface. Chat owns the connection controller so adding
/// a Hermes endpoint cannot drift from reconnect and secure persistence rules.
class HermesAddScreen extends StatelessWidget {
  const HermesAddScreen({
    super.key,
    this.mode = HermesConnectionMode.remote,
    this.fromWelcome = false,
  });

  final HermesConnectionMode mode;
  final bool fromWelcome;

  @override
  Widget build(BuildContext context) {
    void cancel() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.enroll);
      }
    }

    final screen = HermesChatScreen(
      initiallyEditingConnection: true,
      initialConnectionMode: mode,
      onConnectionSaved: fromWelcome
          ? () => context.go(AppRoutes.hermes)
          : null,
      onConnectionCancelled: fromWelcome ? cancel : null,
    );
    // Scrolling enlarged form fields changes their screen-space reading order.
    // Keep traversal stable so cycling the form can still reach AppBar Back.
    return fromWelcome
        ? PopScope<void>(
            canPop: Navigator.of(context).canPop(),
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) cancel();
            },
            child: FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              child: screen,
            ),
          )
        : screen;
  }
}
