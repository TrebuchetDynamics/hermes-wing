// Android-engine regressions with deterministic services and framework input.
// This is not OS IME, TalkBack, live Agent or physical-audio qualification.
import 'dart:io';
import 'dart:ui' show GestureSettings;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/features/hermes_chat/screens/hermes_chat_mobile_usability_test.dart'
    as mobile;
import '../test/features/hermes_chat/screens/hermes_chat_composer_accessibility_test.dart'
    as accessibility;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid ||
      !const bool.fromEnvironment('WING_ANDROID_CHAT_USABILITY_QA')) {
    throw StateError(
      'Use an isolated Android QA target and explicit test define',
    );
  }
  binding.shouldPropagateDevicePointerEvents = true;
  setUp(() {
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final view = binding.platformDispatcher.implicitView!;
    view.physicalSize = const Size(800, 600);
    view.devicePixelRatio = 1;
    view.padding = FakeViewPadding.zero;
    view.viewPadding = FakeViewPadding.zero;
    view.viewInsets = FakeViewPadding.zero;
    view.systemGestureInsets = FakeViewPadding.zero;
    view.gestureSettings = const GestureSettings();
  });
  group('compact composer', mobile.main);
  group('accessible controls', accessibility.main);
}
