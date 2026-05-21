import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';

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
      title: 'Navivox',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff256d85)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
