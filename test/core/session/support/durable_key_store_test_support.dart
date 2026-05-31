import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const durableKeysTestChannel = MethodChannel(
  'com.trebuchetdynamics.navivox/durable_keys',
);
const durableTestAlias = 'navivox_durable_test';

void clearDurableKeysMockHandler() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(durableKeysTestChannel, null);
}

void setDurableKeysMockHandler(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(durableKeysTestChannel, handler);
}
