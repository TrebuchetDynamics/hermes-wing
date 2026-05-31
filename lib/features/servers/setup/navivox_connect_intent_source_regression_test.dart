import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../models/connection_import.dart';
import 'navivox_connect_intent_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel(
    'com.trebuchetdynamics.navivox/connect_intents',
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test(
    'initialImport replays payload consumed by availability probe',
    () async {
      var calls = 0;
      final payload = {
        'payload': 'https://gateway.example/connect?token=nvbx_token',
        'source': 'shared_text',
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
            expect(call.method, 'initialConnectIntent');
            calls += 1;
            return calls == 1 ? payload : null;
          });

      final observer = NavivoxConnectIntentObserver();
      final source = NavivoxConnectIntentSource(
        methodChannel: methodChannel,
        observer: observer,
      );

      expect(await source.isAvailable(), isTrue);

      final result = await source.initialImport();

      expect(calls, 1);
      expect(result, isNotNull);
      expect(result!.baseUrl, 'https://gateway.example');
      expect(result.token, 'nvbx_token');
      expect(result.source, PairingHandoffSource.sharedText);
      expect(identical(observer.lastImport, result), isTrue);
    },
  );

  test(
    'repeated availability checks do not drop cached initial payload',
    () async {
      var calls = 0;
      final payload = {
        'payload': 'https://gateway.example/connect?token=nvbx_token',
        'source': 'direct_app_open',
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
            expect(call.method, 'initialConnectIntent');
            calls += 1;
            return calls == 1 ? payload : null;
          });

      final source = NavivoxConnectIntentSource(methodChannel: methodChannel);

      expect(await source.isAvailable(), isTrue);
      expect(await source.isAvailable(), isTrue);

      final result = await source.initialImport();

      expect(calls, 2);
      expect(result, isNotNull);
      expect(result!.baseUrl, 'https://gateway.example');
      expect(result.token, 'nvbx_token');
      expect(result.source, PairingHandoffSource.directAppOpen);
    },
  );
}
