import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/auth/native_gateway_auth.dart';
import 'package:wing/core/hermes/auth/secure_gateway_token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('cancelled write rolls back and cross-instance forget wins', () async {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final values = <String, String>{};
    final entered = Completer<void>();
    final release = Completer<void>();
    var held = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = call.arguments as Map;
          final key = args['key'] as String;
          switch (call.method) {
            case 'read':
              return values[key];
            case 'write':
              if (held) {
                held = false;
                entered.complete();
                await release.future;
              }
              values[key] = args['value'] as String;
            case 'delete':
              values.remove(key);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final origin = Uri.parse('https://example.invalid');
    final token = GatewayTokenSet.fromJson(origin, {
      'access_token': 'synthetic-token',
      'refresh_token': 'synthetic-refresh',
      'token_type': 'Bearer',
      'expires_at': 0,
      'provider': 'fixture',
      'user_id': 'fixture-user',
    });
    var current = true;
    final saving = SecureGatewayTokenStore().save(
      token,
      isCurrent: () => current,
    );
    await entered.future;
    current = false;
    final forgetting = SecureGatewayTokenStore().delete(origin);
    release.complete();
    await saving;
    await forgetting;
    expect(values, isEmpty);
    expect(await SecureGatewayTokenStore().load(origin), isNull);
  });
  test(
    'secure storage is exact-origin scoped and verifies stored origin',
    () async {
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final values = <String, String>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final args = call.arguments as Map;
            final key = args['key'] as String;
            switch (call.method) {
              case 'write':
                values[key] = args['value'] as String;
              case 'read':
                return values[key];
              case 'delete':
                values.remove(key);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final origin = Uri.parse('https://gateway.example.invalid');
      final other = Uri.parse('https://gateway.example.invalid:444');
      final tokens = GatewayTokenSet.fromJson(origin, {
        'access_token': 'fixture-access',
        'refresh_token': 'fixture-refresh',
        'token_type': 'Bearer',
        'expires_at': 0,
        'provider': 'fixture',
        'user_id': 'fixture-user',
      });
      final store = SecureGatewayTokenStore();
      await store.save(tokens);
      expect((await store.load(origin))?.accessToken, tokens.accessToken);
      expect(await store.load(other), isNull);
      final entry = values.entries.single;
      expect(entry.key, isNot(contains('gateway.example.invalid')));
      values[entry.key] = entry.value.replaceAll(
        origin.toString(),
        other.toString(),
      );
      await expectLater(
        store.load(origin),
        throwsA(isA<GatewayAuthException>()),
      );
      await store.delete(origin);
      expect(values, isEmpty);
    },
  );
}
