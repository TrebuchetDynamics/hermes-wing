import 'dart:async';

import 'package:flutter/services.dart';

import '../../models/connection_import.dart';
import 'navivox_connect_intent_channels.dart';
import 'navivox_connect_intent_initial_payload.dart';
import 'navivox_connect_intent_payload.dart';

class NavivoxConnectIntentSource {
  NavivoxConnectIntentSource({
    MethodChannel methodChannel = const MethodChannel(
      navivoxConnectIntentMethodChannelName,
    ),
    EventChannel eventChannel = const EventChannel(
      navivoxConnectIntentEventChannelName,
    ),
    NavivoxConnectIntentObserver? observer,
    NavivoxInitialConnectIntentPayloadCache? initialPayloadCache,
  }) : _methodChannel = methodChannel,
       _eventChannel = eventChannel,
       _observer = observer,
       _initialPayloadCache =
           initialPayloadCache ?? NavivoxInitialConnectIntentPayloadCache();

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  final NavivoxConnectIntentObserver? _observer;
  final NavivoxInitialConnectIntentPayloadCache _initialPayloadCache;

  Future<bool> isAvailable() async {
    try {
      final payload = await _methodChannel.invokeMethod<Object?>(
        initialNavivoxConnectIntentMethod,
      );
      _initialPayloadCache.remember(payload);
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
    final result = parseNavivoxConnectIntentPayload(payload);
    if (result != null) _observer?.record(result);
    return result;
  }

  Stream<SetupQrImageImport> get imports {
    return _eventChannel
        .receiveBroadcastStream()
        .handleError((_) {})
        .map(parseNavivoxConnectIntentPayload)
        .where((result) => result != null && result.hasValues)
        .cast<SetupQrImageImport>()
        .map((result) {
          _observer?.record(result);
          return result;
        });
  }

  Future<Object?> _initialPayload() async {
    if (_initialPayloadCache.hasPayload) {
      return _initialPayloadCache.take();
    }
    try {
      return await _methodChannel.invokeMethod<Object?>(
        initialNavivoxConnectIntentMethod,
      );
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
