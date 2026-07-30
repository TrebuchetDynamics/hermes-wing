import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/providers/theme_settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../router/app_router.dart';
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

class _WingMaterialApp extends ConsumerWidget {
  const _WingMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
