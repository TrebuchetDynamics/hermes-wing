import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_api_channel.dart';
import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../core/hermes/setup/secure_hermes_endpoint_store.dart';

/// Persists the Hermes endpoint (base URL + API key); see
/// docs/adr/0004-hermes-endpoint-and-secret-storage.md.
final hermesEndpointStoreProvider = Provider<HermesEndpointStore>(
  (ref) => SecureHermesEndpointStore(),
);

/// Connects [channel] to a previously saved Hermes endpoint, if any. A no-op
/// when nothing was saved yet, so first launch still lands on the connect
/// form in `HermesChatScreen`.
Future<void> hermesAutoConnect(
  HermesChannel channel,
  HermesEndpointStore store,
) async {
  final saved = await store.load();
  if (saved == null) return;
  await channel.connect(baseUrl: saved.baseUrl, apiKey: saved.apiKey);
}

/// Native Hermes channel; see
/// docs/adr/0007-native-hermes-channel-not-wing-channel-adapter.md.
final hermesChannelProvider = Provider<HermesChannel>((ref) {
  final store = ref.watch(hermesEndpointStoreProvider);
  final channel = HermesApiChannel();
  unawaited(hermesAutoConnect(channel, store));
  ref.onDispose(channel.dispose);
  return channel;
});
