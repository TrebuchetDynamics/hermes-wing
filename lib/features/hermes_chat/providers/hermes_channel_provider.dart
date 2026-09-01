import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hermes/channel/hermes_api_channel.dart';
import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../core/hermes/setup/secure_hermes_detached_run_store.dart';
import '../../../core/hermes/setup/secure_hermes_endpoint_store.dart';
import '../gateways/gateway_contact_cache.dart';
import '../gateways/hermes_gateway_directory.dart';

/// Persists the Hermes endpoint (base URL + API key); see
/// docs/adr/security-and-privacy.md.
final hermesEndpointStoreProvider = Provider<HermesEndpointStore>(
  (ref) => SecureHermesEndpointStore(),
);

/// Native Hermes channel; see
/// docs/adr/client.md.
final hermesChannelProvider = Provider<HermesChannel>((ref) {
  final channel = HermesApiChannel(
    detachedRunStore: SecureHermesDetachedRunStore(),
  );
  ref.onDispose(channel.dispose);
  return channel;
});

/// Reactive projection of the immutable state owned by [hermesChannelProvider].
final hermesChannelStateProvider = Provider<HermesChannelState>((ref) {
  final channel = ref.watch(hermesChannelProvider);
  void onChanged() => ref.invalidateSelf();
  channel.addListener(onChanged);
  ref.onDispose(() => channel.removeListener(onChanged));
  return channel.state;
});

final hermesGatewaySummaryLoaderProvider = Provider<GatewaySummaryLoader>(
  (ref) => const HermesApiGatewaySummaryLoader(),
);

final gatewayContactCacheProvider = Provider<GatewayContactCache>(
  (ref) => GatewayContactCache(),
);

final hermesGatewayDirectoryProvider =
    ChangeNotifierProvider<HermesGatewayDirectory>((ref) {
      final directory = HermesGatewayDirectory(
        store: ref.watch(hermesEndpointStoreProvider),
        cache: ref.watch(gatewayContactCacheProvider),
        loader: ref.watch(hermesGatewaySummaryLoaderProvider),
        activeChannel: ref.watch(hermesChannelProvider),
      );
      unawaited(directory.start());
      return directory;
    });
