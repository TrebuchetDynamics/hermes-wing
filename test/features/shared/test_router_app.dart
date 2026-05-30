import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navivox/router/app_router.dart';

/// A [ConsumerWidget] that mounts the app router for integration tests.
///
/// Intended for use inside a [ProviderScope] with any channel overrides:
/// ```dart
/// ProviderScope(
///   overrides: [navivoxChannelProvider.overrideWithValue(channel)],
///   child: const TestRouterApp(),
/// )
/// ```
class TestRouterApp extends ConsumerWidget {
  const TestRouterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}
