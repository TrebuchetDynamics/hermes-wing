import 'dart:async';

import 'package:flutter/services.dart';

import 'setup_qr_import_presentation.dart';

class NavivoxConnectIntentSource {
  const NavivoxConnectIntentSource({
    MethodChannel methodChannel = const MethodChannel(_methodChannelName),
    EventChannel eventChannel = const EventChannel(_eventChannelName),
    NavivoxConnectIntentObserver? observer,
  }) : _methodChannel = methodChannel,
       _eventChannel = eventChannel,
       _observer = observer;

  static const _methodChannelName =
      'com.trebuchetdynamics.navivox/connect_intents';
  static const _eventChannelName =
      'com.trebuchetdynamics.navivox/connect_intents/events';

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  final NavivoxConnectIntentObserver? _observer;

  Future<bool> isAvailable() async {
    try {
      await _methodChannel.invokeMethod<Object?>('initialConnectIntent');
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<SetupQrImageImport?> initialImport() async {
    final payload = await _initialPayload();
    if (payload == null) return null;
    final result = _parseConnectIntentPayload(payload);
    if (result != null) _observer?.record(result);
    return result;
  }

  Stream<SetupQrImageImport> get imports {
    return _eventChannel
        .receiveBroadcastStream()
        .handleError((_) {})
        .map(_parseConnectIntentPayload)
        .where((result) => result != null && result.hasValues)
        .cast<SetupQrImageImport>()
        .map((result) {
          _observer?.record(result);
          return result;
        });
  }

  Future<Object?> _initialPayload() async {
    try {
      return await _methodChannel.invokeMethod<Object?>('initialConnectIntent');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

class NavivoxConnectIntentObserver {
  SetupQrImageImport? lastImport;

  void record(SetupQrImageImport import) {
    lastImport = import;
  }
}

SetupQrImageImport? _parseConnectIntentPayload(Object? payload) {
  if (payload is String) {
    final text = payload.trim();
    if (text.isEmpty) return null;
    return parseNavivoxQrPayload(text);
  }
  if (payload is! Map) return null;
  final text = payload['payload']?.toString().trim();
  if (text == null || text.isEmpty) return null;
  final parsed = parseNavivoxQrPayload(text);
  if (parsed == null) return null;
  return parsed.withSource(_sourceFromPayload(payload['source']));
}

PairingHandoffSource _sourceFromPayload(Object? value) {
  return switch (value?.toString()) {
    'direct_app_open' => PairingHandoffSource.directAppOpen,
    'shared_text' => PairingHandoffSource.sharedText,
    _ => PairingHandoffSource.manual,
  };
}
