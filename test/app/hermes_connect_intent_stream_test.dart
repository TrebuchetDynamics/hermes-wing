import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/enrollment/services/hermes_connect_intent_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'content-free native input events survive enrollment cancellation',
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
        if (call.method == 'consumeInitialConnectIntent') return true;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(control, null));
      final source = MethodChannelHermesConnectIntentSource(
        methodChannel: control,
        eventChannel: const EventChannel(name),
      );
      expect(await source.consumeInitialInput(), isTrue);
      final shellEvents = <Object?>[];
      final screenEvents = <Object?>[];
      final shell = source.inputEvents().listen(shellEvents.add);
      final screen = source.inputEvents().listen(screenEvents.add);
      addTearDown(shell.cancel);
      addTearDown(screen.cancel);
      await Future<void>.delayed(Duration.zero);
      expect(listens, 1);
      await messenger.handlePlatformMessage(
        name,
        const StandardMethodCodec().encodeSuccessEnvelope(true),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(shellEvents, [true]);
      expect(screenEvents, [true]);
      await screen.cancel();
      expect(cancels, 0);
      for (final invalid in [
        false,
        null,
        {'payload': 'fixture-retired-input'},
      ]) {
        await messenger.handlePlatformMessage(
          name,
          const StandardMethodCodec().encodeSuccessEnvelope(invalid),
          (_) {},
        );
      }
      await messenger.handlePlatformMessage(
        name,
        const StandardMethodCodec().encodeSuccessEnvelope(true),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(shellEvents, [true, true]);
      expect(screenEvents, [true]);
      await shell.cancel();
      expect(cancels, 1);
    },
  );
}
