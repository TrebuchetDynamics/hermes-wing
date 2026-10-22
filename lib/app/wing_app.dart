import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/enrollment/providers/hermes_enrollment_provider.dart';
import '../features/enrollment/services/hermes_connect_intent_source.dart';
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
  StreamSubscription<bool>? _connectIntentSubscription;

  @override
  void initState() {
    super.initState();
    final source = ref.read(hermesConnectIntentSourceProvider);
    _connectIntentSubscription = source.inputEvents().listen(
      (_) => unawaited(_consumeInput(source, incoming: true)),
      onError: (_) => _openEnrollment(incoming: true),
    );
    unawaited(_consumeInput(source));
  }

  Future<void> _consumeInput(
    HermesConnectIntentSource source, {
    bool incoming = false,
  }) async {
    try {
      final present = await source.consumeInitialInput();
      if (present || incoming) _openEnrollment(incoming: incoming);
    } catch (_) {
      _openEnrollment(incoming: incoming);
    }
  }

  void _openEnrollment({bool incoming = false}) {
    if (mounted) {
      final router = ref.read(routerProvider);
      const route = '${AppRoutes.enroll}?step=pair';
      if (!incoming) {
        router.go(route);
      } else if (router.state.uri.path != AppRoutes.enroll) {
        unawaited(router.push<void>(route));
      } else {
        router.replace<void>(route);
      }
    }
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
