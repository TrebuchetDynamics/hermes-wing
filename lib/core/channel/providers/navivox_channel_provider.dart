import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/credentials/credential_store_provider.dart';
import '../contracts/navivox_channel.dart';
import '../gateway/gateway_navivox_channel.dart';

final navivoxChannelProvider = Provider<NavivoxChannel>((ref) {
  final credentialStore = ref.watch(durableCredentialStoreProvider);
  final channel = GatewayNavivoxChannel(credentialStore: credentialStore);
  ref.onDispose(channel.dispose);
  return channel;
});

final gatewayNavivoxChannelProvider = Provider<GatewayNavivoxChannel>((ref) {
  return ref.watch(navivoxChannelProvider) as GatewayNavivoxChannel;
});
