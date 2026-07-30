import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/agents/screens/agents_screen.dart';
import '../../features/enrollment/screens/hermes_enrollment_screen.dart';
import '../../features/gateway/screens/gateway_screen.dart';
import '../../features/hermes_chat/screens/hermes_chat_screen.dart';
import '../../features/office/screens/office_screen.dart';
import '../../features/providers/screens/providers_screen.dart';
import '../../features/schedules/screens/schedules_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/tools/screens/tools_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/app_shell.dart';
import '../app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.hermes,
    redirect: (context, state) {
      final location = state.uri.toString();
      if (location == '/' || location.isEmpty) return AppRoutes.hermes;
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => _SelectableRoute(
          child: AppShell(location: state.matchedLocation, child: child),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.hermes,
            builder: (context, state) => const HermesChatScreen(),
          ),
          GoRoute(
            path: AppRoutes.office,
            builder: (context, state) => const OfficeScreen(),
          ),
          GoRoute(
            path: AppRoutes.agents,
            builder: (context, state) => const AgentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.providers,
            builder: (context, state) => const ProvidersScreen(),
          ),
          GoRoute(
            path: AppRoutes.tools,
            builder: (context, state) => const ToolsScreen(),
          ),
          GoRoute(
            path: AppRoutes.schedules,
            builder: (context, state) => const SchedulesScreen(),
          ),
          GoRoute(
            path: AppRoutes.gateway,
            builder: (context, state) => const GatewayScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsVoice,
            builder: (context, state) => const VoiceSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsDiagnostics,
            builder: (context, state) => const DiagnosticsSettingsScreen(),
          ),
        ],
      ),
      // Reached only via an Android connect intent
      // (wing://connect?...); deliberately outside the ShellRoute since
      // no Hermes endpoint is configured yet at that point.
      GoRoute(
        path: AppRoutes.enroll,
        builder: (context, state) =>
            _SelectableRoute(child: const HermesEnrollmentScreen()),
      ),
    ],
    errorBuilder: (context, state) => _SelectableRoute(
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).appTitle)),
        body: Center(
          child: Text(
            AppLocalizations.of(context).routeNotFound(state.uri.path),
          ),
        ),
      ),
    ),
  );
});

class _SelectableRoute extends StatelessWidget {
  const _SelectableRoute({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SelectionArea(child: child);
}
