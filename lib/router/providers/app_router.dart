import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/profiles/screens/profiles_screen.dart';
import '../../features/enrollment/screens/hermes_enrollment_screen.dart';
import '../../features/gateway/screens/gateway_screen.dart';
import '../../features/hermes_chat/screens/hermes_add_screen.dart';
import '../../features/hermes_chat/screens/hermes_chat_screen.dart';
import '../../features/local_setup/screens/local_hermes_setup_screen.dart';
import '../../features/local_setup/providers/local_hermes_setup_provider.dart';
import '../../features/local_setup/screens/termux_hermes_setup_screen.dart';
import '../../features/office/screens/office_screen.dart';
import '../../features/providers/screens/providers_screen.dart';
import '../../features/schedules/screens/schedules_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/soul/screens/soul_screen.dart';
import '../../features/tools/screens/tools_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/wing_empty_state.dart';
import '../app_routes.dart';
import '../widgets/connection_entry_gate.dart';
import '../widgets/chat_workspace_overlay.dart';

/// The shared shell-route page: a motion-free 200ms fade-through, so route
/// changes read as one surface and stay comfortable under reduced motion.
Page<void> wingFadeThroughPage({
  required LocalKey key,
  required Widget child,
}) => CustomTransitionPage<void>(
  key: key,
  transitionDuration: const Duration(milliseconds: 200),
  reverseTransitionDuration: const Duration(milliseconds: 200),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      ),
  child: child,
);

Page<void> _chatOverlayPage(
  BuildContext context, {
  required LocalKey key,
  required Widget child,
}) => CustomTransitionPage<void>(
  key: key,
  opaque: false,
  barrierColor: Colors.black54,
  barrierDismissible: false,
  transitionDuration: const Duration(milliseconds: 200),
  reverseTransitionDuration: const Duration(milliseconds: 200),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(opacity: animation, child: child),
  child: ChatWorkspaceOverlay(child: child),
);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.hermes,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == '/' || path.isEmpty) return AppRoutes.hermes;
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final shell = _SelectableRoute(
            child: AppShell(location: state.matchedLocation, child: child),
          );
          // Explicit auxiliary routes remain usable without an Agent connection.
          if (state.uri.path != AppRoutes.hermes ||
              state.uri.queryParameters['connect'] == '1') {
            return shell;
          }
          return ConnectionEntryGate(child: shell);
        },
        routes: [
          GoRoute(
            path: AppRoutes.hermes,
            pageBuilder: (context, state) => wingFadeThroughPage(
              key: state.pageKey,
              child: HermesChatScreen(
                initiallyEditingConnection:
                    state.uri.queryParameters['connect'] == '1',
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.office,
            pageBuilder: (context, state) => wingFadeThroughPage(
              key: state.pageKey,
              child: const OfficeScreen(),
            ),
          ),

          GoRoute(
            path: AppRoutes.soul,
            pageBuilder: (context, state) => wingFadeThroughPage(
              key: state.pageKey,
              child: const SoulScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.providers,
            pageBuilder: (context, state) => wingFadeThroughPage(
              key: state.pageKey,
              child: const ProvidersScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.tools,
            pageBuilder: (context, state) => wingFadeThroughPage(
              key: state.pageKey,
              child: const ToolsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.schedules,
            pageBuilder: (context, state) => wingFadeThroughPage(
              key: state.pageKey,
              child: const SchedulesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.gateway,
            pageBuilder: (context, state) => wingFadeThroughPage(
              key: state.pageKey,
              child: const GatewayScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profiles,
        pageBuilder: (context, state) => _chatOverlayPage(
          context,
          key: state.pageKey,
          child: ProfilesScreen(
            startSetup: state.uri.queryParameters['setup'] == 'new',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _chatOverlayPage(
          context,
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsVoice,
        pageBuilder: (context, state) => _chatOverlayPage(
          context,
          key: state.pageKey,
          child: const VoiceSettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsDiagnostics,
        pageBuilder: (context, state) => _chatOverlayPage(
          context,
          key: state.pageKey,
          child: const DiagnosticsSettingsScreen(),
        ),
      ),
      // Enrollment is above the shell. Manual setup needs its own root page
      // so pushing it preserves Back without pushing a second shell instance.
      GoRoute(
        path: AppRoutes.addHermes,
        pageBuilder: (context, state) => wingFadeThroughPage(
          key: state.pageKey,
          child: state.uri.queryParameters['welcome'] == '1'
              ? HermesAddScreen(mode: _entryMode(state), fromWelcome: true)
              : _SelectableRoute(
                  child: AppShell(
                    location: state.matchedLocation,
                    child: HermesAddScreen(mode: _entryMode(state)),
                  ),
                ),
        ),
      ),
      GoRoute(
        path: AppRoutes.legacyAgents,
        redirect: (_, _) => AppRoutes.profiles,
      ),
      // Platform-specific local setup; deliberately outside the ShellRoute
      // because no Hermes endpoint is configured yet.
      GoRoute(
        path: AppRoutes.localSetup,
        redirect: (_, _) =>
            ref.read(localLinuxSetupAvailableProvider) ||
                (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            ? null
            : AppRoutes.enroll,
        builder: (context, state) => _SelectableRoute(
          child: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? const TermuxHermesSetupScreen()
              : const LocalHermesSetupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.enroll,
        builder: (context, state) => _SelectableRoute(
          child: HermesEnrollmentScreen(
            startPairing: state.uri.queryParameters['step'] == 'pair',
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) {
      final strings = AppLocalizations.of(context);
      return _SelectableRoute(
        child: Scaffold(
          appBar: AppBar(title: Text(strings.appTitle)),
          body: SafeArea(
            child: WingEmptyState(
              icon: Icons.explore_off_outlined,
              title: strings.routeNotFoundTitle,
              body: strings.routeNotFound(state.uri.path),
              actionLabel: strings.routeNotFoundAction,
              onAction: () => context.go(AppRoutes.hermes),
            ),
          ),
        ),
      );
    },
  );
});

HermesConnectionMode _entryMode(GoRouterState state) =>
    switch (state.uri.queryParameters['mode']) {
      'local' => HermesConnectionMode.local,
      'ssh' => HermesConnectionMode.ssh,
      _ => HermesConnectionMode.remote,
    };

class _SelectableRoute extends StatelessWidget {
  const _SelectableRoute({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SelectionArea(child: child);
}
