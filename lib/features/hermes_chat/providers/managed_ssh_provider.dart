import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/ssh/managed_ssh.dart';

/// App-scoped transport, deliberately independent of connection-screen lifetime.
/// No endpoint URI, authentication or host trust is persisted by this provider.
final managedSshForwardProvider = Provider<ManagedSshForward>((ref) {
  final forward = ref.watch(managedSshForwardFactoryProvider)();
  ref.onDispose(() => unawaited(forward.dispose()));
  return forward;
});

/// A bounded test seam; production always uses the native Dart SSH transport.
final managedSshForwardFactoryProvider = Provider<ManagedSshForward Function()>(
  (ref) => ManagedSshForward.new,
);
