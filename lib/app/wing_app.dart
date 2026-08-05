import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/enrollment/providers/hermes_enrollment_provider.dart';
import '../features/settings/providers/theme_settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../router/app_router.dart';
import '../router/app_routes.dart';
import '../theme/wing_theme.dart';
import 'desktop_host_command_listener.dart';

class WingApp extends StatelessWidget {
  const WingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: DesktopHostCommandListener(child: _WingMaterialApp()),
    );
  }
}

class _WingMaterialApp extends ConsumerStatefulWidget {
  const _WingMaterialApp();

  @override
  ConsumerState<_WingMaterialApp> createState() => _WingMaterialAppState();
}

class _WingMaterialAppState extends ConsumerState<_WingMaterialApp> {
  StreamSubscription<String>? _connectIntentSubscription;

  @override
  void initState() {
    super.initState();
    final source = ref.read(hermesConnectIntentSourceProvider);
    _connectIntentSubscription = source.payloadEvents().listen(_openEnrollment);
    unawaited(
      source.initialPayload().then((payload) {
        if (payload != null) _openEnrollment(payload);
      }),
    );
  }

  void _openEnrollment(String _) {
    if (mounted) ref.read(routerProvider).go(AppRoutes.enroll);
  }

  @override
  void dispose() {
    _connectIntentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeSettings = ref.watch(wingThemeSettingsProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: wingThemeFor(themeSettings.palette, Brightness.light),
      darkTheme: wingThemeFor(themeSettings.palette, Brightness.dark),
      themeMode: themeSettings.mode,
      routerConfig: router,
    );
  }
}
