import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/navivox_channel.dart';
import '../gateway/gateway_navivox_channel.dart';

final navivoxChannelProvider = Provider<NavivoxChannel>((ref) {
  final channel = GatewayNavivoxChannel();
  ref.onDispose(channel.dispose);
  return channel;
});

final gatewayNavivoxChannelProvider = Provider<GatewayNavivoxChannel>((ref) {
  return ref.watch(navivoxChannelProvider) as GatewayNavivoxChannel;
});
