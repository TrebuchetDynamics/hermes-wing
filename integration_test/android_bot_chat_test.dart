// Deterministic Bot Chat journeys on an Android engine, not live Agent/SSH proof.
import 'dart:io';

import 'package:integration_test/integration_test.dart';

import '../test/features/hermes_chat/bots/bot_chat_navigation_test.dart'
    as navigation;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid ||
      !const bool.fromEnvironment('WING_ANDROID_BOT_CHAT_QA')) {
    throw StateError(
      'Use an isolated Android QA target and explicit test define',
    );
  }
  navigation.main();
}
