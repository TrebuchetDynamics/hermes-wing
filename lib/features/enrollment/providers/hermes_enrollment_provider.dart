import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hermes_connect_intent_source.dart';

/// Supplies legacy intent ingress for discard and direct reconnection guidance.
final hermesConnectIntentSourceProvider = Provider<HermesConnectIntentSource>(
  (ref) => MethodChannelHermesConnectIntentSource(),
);
