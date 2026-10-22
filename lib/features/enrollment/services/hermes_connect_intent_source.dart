import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Content-free notifications for retired Android connection inputs.
///
/// Native ingress discards URI/shared-text contents before notifying Flutter.
/// Consumers can only open direct Agent reconnection guidance, never inspect or
/// exchange a handoff. Unsupported platforms and channel failures report no input.
abstract interface class HermesConnectIntentSource {
  /// Returns and clears the pending notification so a later enrollment visit
  /// cannot replay it.
  Future<bool> consumeInitialInput();

  /// Notifications delivered to an already-running activity. Only `true` is
  /// emitted; contents of external inputs never cross this interface.
  Stream<bool> inputEvents();
}

/// Uses the native rejection-notification channels registered in MainActivity.
class MethodChannelHermesConnectIntentSource
    implements HermesConnectIntentSource {
  MethodChannelHermesConnectIntentSource({
    MethodChannel methodChannel = _defaultMethodChannel,
    EventChannel eventChannel = _defaultEventChannel,
  }) : this._(methodChannel, eventChannel);

  MethodChannelHermesConnectIntentSource._(
    this._methodChannel,
    this._eventChannel,
  );

  static const _defaultMethodChannel = MethodChannel(
    'com.trebuchetdynamics.hermes.wing/connect_intents',
  );
  static const _defaultEventChannel = EventChannel(
    'com.trebuchetdynamics.hermes.wing/connect_intents/events',
  );

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  // Reuse the native stream: another EventChannel stream replaces its handler.
  late final Stream<bool> _inputEvents = _createInputEvents();

  bool get _supportsNativeChannel =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> consumeInitialInput() async {
    if (!_supportsNativeChannel) return false;
    try {
      return await _methodChannel.invokeMethod<bool>(
            'consumeInitialConnectIntent',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> inputEvents() => _inputEvents;

  Stream<bool> _createInputEvents() {
    if (!_supportsNativeChannel) return const Stream<bool>.empty();
    return _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is bool && event)
        .cast<bool>()
        .handleError((Object _) {});
  }
}
