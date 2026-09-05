import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/enrollment/services/hermes_connect_intent_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'closing enrollment keeps the app shell subscribed to native handoffs',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const name = 'wing-test/connect-events';
      const control = MethodChannel(name);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var listens = 0;
      var cancels = 0;
      messenger.setMockMethodCallHandler(control, (call) async {
        if (call.method == 'listen') listens++;
        if (call.method == 'cancel') cancels++;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(control, null));
      final source = MethodChannelHermesConnectIntentSource(
        eventChannel: const EventChannel(name),
      );
      final shellEvents = <String>[];
      final screenEvents = <String>[];
      final shell = source.payloadEvents().listen(shellEvents.add);
      final screen = source.payloadEvents().listen(screenEvents.add);
      addTearDown(shell.cancel);
      addTearDown(screen.cancel);
      await Future<void>.delayed(Duration.zero);
      expect(listens, 1);
      await messenger.handlePlatformMessage(
        name,
        const StandardMethodCodec().encodeSuccessEnvelope({
          'payload': 'first handoff',
        }),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(shellEvents, ['first handoff']);
      expect(screenEvents, ['first handoff']);
      await screen.cancel();
      expect(cancels, 0);
      await messenger.handlePlatformMessage(
        name,
        const StandardMethodCodec().encodeSuccessEnvelope({
          'payload': 'second handoff',
        }),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(shellEvents, ['first handoff', 'second handoff']);
      expect(screenEvents, ['first handoff']);
      await shell.cancel();
      expect(cancels, 1);
    },
  );
}
