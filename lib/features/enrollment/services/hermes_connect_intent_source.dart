import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Surfaces the raw Hermes Wing connect pairing payload string carried by the
/// Android activity's intent (an `ACTION_VIEW` deep link or `ACTION_SEND`
/// shared text), so it can be handed to `HermesEnrollmentPayload.parse()`.
/// Implementations must never throw: an inbound intent is untrusted input,
/// and platforms without a native implementation simply have nothing to
/// report.
abstract interface class HermesConnectIntentSource {
  /// The payload the app was launched or resumed with, if any. Returns
  /// `null` on unsupported platforms or when no pairing intent is pending.
  Future<String?> initialPayload();

  /// Payloads delivered to an already-running activity (`onNewIntent`).
  /// Empty on unsupported platforms; never throws or emits an error.
  Stream<String> payloadEvents();
}

/// [HermesConnectIntentSource] backed by the existing Android method/event
/// channels registered in `MainActivity.kt`. Other platforms have no native
/// counterpart, so both members return empty results rather than throwing.
class MethodChannelHermesConnectIntentSource
    implements HermesConnectIntentSource {
  const MethodChannelHermesConnectIntentSource({
    MethodChannel methodChannel = _defaultMethodChannel,
    EventChannel eventChannel = _defaultEventChannel,
  }) : this._(methodChannel, eventChannel);

  const MethodChannelHermesConnectIntentSource._(
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

  bool get _supportsNativeChannel =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<String?> initialPayload() async {
    if (!_supportsNativeChannel) return null;
    try {
      final result = await _methodChannel.invokeMethod<Object?>(
        'initialConnectIntent',
      );
      return _payloadFrom(result);
    } catch (_) {
      // An inbound intent is untrusted input surfaced across a platform
      // channel; a missing plugin, malformed payload, or transport error
      // must never crash enrollment. Treat every failure as "no payload".
      return null;
    }
  }

  @override
  Stream<String> payloadEvents() {
    if (!_supportsNativeChannel) return const Stream<String>.empty();
    return _eventChannel
        .receiveBroadcastStream()
        .map(_payloadFrom)
        .where((payload) => payload != null)
        .cast<String>()
        .handleError((Object _) {});
  }

  String? _payloadFrom(Object? raw) {
    if (raw is! Map) return null;
    final payload = raw['payload'];
    if (payload is! String) return null;
    final trimmed = payload.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
