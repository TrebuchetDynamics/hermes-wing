import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/features/enrollment/widgets/gateway_login_panel.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import '../../core/hermes/support/gateway_tls_fixture.dart';
import '../../../integration_test/support/local_serve_chat_fixture.dart';
import '../../../integration_test/support/local_serve_read_fixture.dart';

class RealNetwork extends HttpOverrides {}

class LoginChatFixture extends LocalServeChatFixture {
  int exchanges = 0;
  @override
  Future<bool> handleExtra(HttpRequest request) async {
    Object? result;
    switch (request.uri.path) {
      case '/api/status':
        result = {
          'auth_flows': ['native_pkce'],
        };
      case '/api/auth/providers':
        result = {
          'providers': [
            {
              'name': 'fixture',
              'display_name': 'Fixture',
              'supports_password': true,
            },
          ],
        };
      case '/auth/native/token':
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        expect(body['code'], 'fixture-code');
        expect(body['code_verifier'], matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
        exchanges++;
        result = {
          'access_token': LocalServeReadFixture.token,
          'refresh_token': 'synthetic-refresh',
          'token_type': 'Bearer',
          'expires_at': 2000000000,
          'provider': 'fixture',
          'user_id': 'fixture-user',
        };
    }
    if (result == null) return super.handleExtra(request);
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(result));
    await request.response.close();
    return true;
  }
}

void main() {
  testWidgets('phone UI authorizes via HTTPS PKCE and opens exact WSS chat', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterSecureStorage.setMockInitialValues({});
    final gateway = LoginChatFixture();
    final channel = HermesApiChannel();
    final tls = GatewayTlsFixture();
    await tester.runAsync(() async {
      await gateway.start();
      await HttpOverrides.runWithHttpOverrides(
        () => tls.start(Uri.parse(gateway.origin)),
        RealNetwork(),
      );
    });
    var launches = 0;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SingleChildScrollView(child: GatewayLoginPanel()),
          ),
        ),
        GoRoute(
          path: '/hermes',
          builder: (_, _) => const Scaffold(body: Text('Connected chat')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hermesChannelProvider.overrideWithValue(channel),
          gatewayBrowserLauncherProvider.overrideWithValue((uri) async {
            launches++;
            final callback = Uri.parse(uri.queryParameters['redirect_uri']!);
            final client = HttpClient();
            try {
              final request = await client.getUrl(
                callback.replace(
                  queryParameters: {
                    'code': 'fixture-code',
                    'state': uri.queryParameters['state']!,
                  },
                ),
              );
              await (await request.close()).drain<void>();
            } finally {
              client.close(force: true);
            }
            return true;
          }),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('gateway-address')),
      tls.origin.toString(),
    );
    await tester.enterText(
      find.byKey(const ValueKey('gateway-profile')),
      'demo',
    );
    await tester.runAsync(() async {
      HttpOverrides.runWithHttpOverrides(() {
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('gateway-sign-in')))
            .onPressed!();
      }, RealNetwork());
      for (var i = 0; i < 100 && gateway.minted == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      for (var i = 0; i < 100 && channel.state.serveChat == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    for (var i = 0; i < 100 && channel.state.serveChat == null; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pumpAndSettle();
    expect(launches, 1);
    expect(gateway.exchanges, 1);
    expect(
      channel.state.selectedProfileId,
      'demo',
      reason:
          '${channel.state.status} ${channel.state.errorMessage} ${gateway.requests}',
    );
    expect(channel.state.serveChat?.canSubmit, isTrue);
    expect(find.text('Connected chat'), findsOneWidget);
    expect(gateway.count('prompt.submit'), 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      channel.dispose();
      await tls.close();
      await gateway.close();
    });
    router.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}
