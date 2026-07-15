import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../router/app_router.dart';
import '../theme/navivox_theme.dart';

class NavivoxApp extends StatelessWidget {
  const NavivoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _NavivoxMaterialApp());
  }
}

class _NavivoxMaterialApp extends ConsumerWidget {
  const _NavivoxMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: navivoxLightTheme,
      darkTheme: navivoxDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
