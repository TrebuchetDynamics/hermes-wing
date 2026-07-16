import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../router/app_router.dart';
import '../theme/wing_theme.dart';

class WingApp extends StatelessWidget {
  const WingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _WingMaterialApp());
  }
}

class _WingMaterialApp extends ConsumerWidget {
  const _WingMaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: wingLightTheme,
      darkTheme: wingDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
