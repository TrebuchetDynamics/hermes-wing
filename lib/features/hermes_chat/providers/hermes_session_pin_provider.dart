import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/hermes_session_pin_store.dart';

/// One local pin owner shared by Chat, the sidebar and the session picker.
final hermesSessionPinStoreProvider = Provider<HermesSessionPinStore>((ref) {
  final store = HermesSessionPinStore();
  ref.onDispose(store.dispose);
  unawaited(store.load());
  return store;
});
