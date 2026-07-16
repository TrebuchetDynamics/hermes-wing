import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/agents/screens/agents_screen.dart';
import '../../features/enrollment/screens/hermes_enrollment_screen.dart';
import '../../features/hermes_chat/screens/hermes_chat_screen.dart';
import '../../features/needle_spike/needle_spike_flag.dart';
import '../../features/needle_spike/screens/needle_spike_screen.dart';
import '../../features/providers/screens/providers_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
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
            path: AppRoutes.agents,
            builder: (context, state) => const AgentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.providers,
            builder: (context, state) => const ProvidersScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
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
      // needleSpikeEnabled is a compile-time const, so in default builds
      // this route and all transitively imported spike Dart code are
      // tree-shaken from the AOT snapshot. NOTE: the native
      // libcactus_engine.so under android/app/src/main/jniLibs/ is packaged
      // by Gradle regardless of this flag once built (~4 MB compressed); it
      // is gitignored and only present on machines that ran
      // scripts/spike/build_cactus_engine.sh.
      if (needleSpikeEnabled)
        GoRoute(
          path: AppRoutes.needleSpike,
          builder: (context, state) => const NeedleSpikeScreen(),
        ),
    ],
    errorBuilder: (context, state) => _SelectableRoute(
      child: Scaffold(
        appBar: AppBar(title: const Text('Hermes Wing')),
        body: Center(child: Text('Route not found: ${state.uri.path}')),
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
