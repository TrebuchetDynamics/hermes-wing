import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/app.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/router/app_router.dart';

import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';

// Destructive to the disposable manifest's management credential. Run only on
// an owned Xvfb display with a fresh isolated Agent and Wing Link, never personal
// state. Pairing codes stay in memory and the display's temporary clipboard.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  WidgetController.hitTestWarningShouldBeFatal = true;
  if (Platform.environment['WING_LIVE_REVOKE_AND_REPAIR'] != '1') {
    throw StateError(
      'Explicit isolated revocation/re-pair qualification required.',
    );
  }
  testWidgets(
    'live UI revoke fails closed then fresh pairing restores management',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final agent =
          (jsonDecode(
                        File(
                          Platform.environment['WING_LIVE_PROFILE_MANIFEST']!,
                        ).readAsStringSync(),
                      )
                      as List)
                  .first
              as Map;
      final issued =
          jsonDecode(
                File(
                  Platform.environment['WING_LIVE_LINK_MANIFEST']!,
                ).readAsStringSync(),
              )
              as Map;
      final channel = HermesApiChannel();
      final store = FakeHermesEndpointStore(
        profiles: [
          HermesEndpointConfig(
            id: 'live-recovery',
            label: 'Linux recovery',
            baseUrl: agent['origin'] as String,
            apiKey: agent['token'] as String,
            wingLinkOrigin: issued['wing_link_origin'] as String,
            wingLinkToken: issued['wing_link_token'] as String,
            wingLinkDeviceId: issued['wing_link_credential_id'] as String,
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesChannelProvider.overrideWithValue(channel),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(channel.dispose);
      addTearDown(() => Clipboard.setData(const ClipboardData(text: '')));
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const WingApp()),
      );
      final directory = container.read(hermesGatewayDirectoryProvider);
      await directory.start();
      await directory.refresh();
      await directory.activateGateway('live-recovery');
      final router = container.read(routerProvider);
      Future<void> waitFor(bool Function() ready) async {
        await tester.pump();
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!ready()) {
          if (DateTime.now().isAfter(deadline)) {
            throw TestFailure('Live security UI did not reach its checkpoint.');
          }
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump(const Duration(milliseconds: 350));
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 350));
      }

      router.go('/gateway');
      final revoke = find.byKey(const ValueKey('gateway-trust-revoke'));
      await waitFor(() => revoke.evaluate().isNotEmpty);
      await tap(revoke);
      await tap(find.text('Cancel').last);
      final oldClient = WingLinkClient(
        origin: Uri.parse(issued['wing_link_origin'] as String),
        token: issued['wing_link_token'] as String,
      );
      await oldClient.getCurrentDevice();
      await tap(revoke);
      await tap(find.byKey(const ValueKey('gateway-trust-revoke-confirm')));
      await waitFor(
        () => find
            .textContaining('This device was revoked.')
            .evaluate()
            .isNotEmpty,
      );
      await expectLater(
        oldClient.getCurrentDevice(),
        throwsA(
          isA<WingLinkHttpException>().having(
            (error) => error.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(channel.state.isConnected, isTrue);
      expect(
        (await store.loadProfiles()).every((row) => row.wingLinkToken == null),
        isTrue,
      );

      final pair = await Process.start(
        Platform.environment['WING_LIVE_LINK_BINARY']!,
        ['pair', '--local', '--same-device', '--label', 'Linux recovery test'],
      );
      final stderr = pair.stderr.drain<void>();
      addTearDown(() async {
        pair.kill();
        await pair.exitCode;
        await stderr;
      });
      final line = await pair.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 20));
      final handoff = Uri.parse(line);
      if (handoff.host != '127.0.0.1' ||
          handoff.scheme != 'http' ||
          handoff.path != '/open') {
        throw TestFailure('Unexpected local handoff location.');
      }
      final http = HttpClient()..findProxy = (_) => 'DIRECT';
      addTearDown(() => http.close(force: true));
      final request = await http.getUrl(handoff);
      request.followRedirects = false;
      final response = await request.close();
      expect(response.statusCode, 200);
      expect(response.headers.value('cache-control'), contains('no-store'));
      final html = await response.transform(utf8.decoder).fold<String>('', (
        body,
        chunk,
      ) {
        if (body.length + chunk.length > 65536) {
          throw TestFailure('Oversized handoff page.');
        }
        return body + chunk;
      });
      final link = RegExp(
        r'href="(wing://connect\?[^" ]+)"',
      ).firstMatch(html)?.group(1)?.replaceAll('&amp;', '&');
      if (link == null) throw TestFailure('Pairing handoff was not present.');
      router.go('/enroll');
      await waitFor(
        () =>
            find.text('I have a QR code or pairing link').evaluate().isNotEmpty,
      );
      await tap(find.text('I have a QR code or pairing link'));
      await Clipboard.setData(ClipboardData(text: link));
      await tap(find.text('Paste pairing link'));
      await waitFor(() => find.text('Connect 1 profile').evaluate().isNotEmpty);
      await Clipboard.setData(const ClipboardData(text: ''));
      await tap(find.text('Connect 1 profile'));
      await waitFor(() => find.text('1 profile paired').evaluate().isNotEmpty);
      final repaired = (await store.loadProfiles())
          .where((row) => row.wingLinkToken != null)
          .single;
      expect(repaired.wingLinkToken != issued['wing_link_token'], isTrue);
      final newClient = WingLinkClient(
        origin: Uri.parse(repaired.wingLinkOrigin!),
        token: repaired.wingLinkToken!,
      );
      addTearDown(newClient.revokeCurrentDevice);
      await newClient.getCurrentDevice();
      expect(channel.state.isConnected, isTrue);
      expect(await pair.exitCode.timeout(const Duration(seconds: 15)), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
