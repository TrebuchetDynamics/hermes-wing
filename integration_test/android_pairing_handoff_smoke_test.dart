import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/servers/setup/navivox_connect_intent_source.dart';
import 'package:navivox/features/servers/setup/navivox_connect_intent_source_provider.dart';
import 'package:navivox/features/servers/setup/setup_qr_import_presentation.dart';
import 'package:navivox/router/app_router.dart';
import 'package:navivox/testing/connect_and_talk_channel.dart';

const _sentinelToken = 'ci-secret-token-do-not-render';
const _directPayload =
    'navivox://connect?base_url=http%3A%2F%2F127.0.0.1%3A8765&token=$_sentinelToken';
const _sharedPayload =
    'navivox://connect?base_url=http%3A%2F%2F127.0.0.1%3A8766&token=$_sentinelToken';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android direct app-open handoff reaches setup without leaking token',
    (tester) async {
      final observer = NavivoxConnectIntentObserver();
      final channel = ConnectAndTalkChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(
        _SmokeApp(
          channel: channel,
          source: _ScriptedConnectIntentSource(
            observer: observer,
            initial: _directPayload,
            source: PairingHandoffSource.directAppOpen,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(observer.lastImport?.source, PairingHandoffSource.directAppOpen);
      expect(observer.lastImport?.token, _sentinelToken);
      expect(find.textContaining(_sentinelToken), findsNothing);
    },
  );

  testWidgets(
    'Android shared text handoff reaches setup without leaking token',
    (tester) async {
      final observer = NavivoxConnectIntentObserver();
      final channel = ConnectAndTalkChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(
        _SmokeApp(
          channel: channel,
          source: _ScriptedConnectIntentSource(
            observer: observer,
            initial: _sharedPayload,
            source: PairingHandoffSource.sharedText,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(observer.lastImport?.source, PairingHandoffSource.sharedText);
      expect(observer.lastImport?.token, _sentinelToken);
      expect(find.textContaining(_sentinelToken), findsNothing);
    },
  );
}

class _SmokeApp extends StatelessWidget {
  const _SmokeApp({required this.channel, required this.source});

  final ConnectAndTalkChannel channel;
  final NavivoxConnectIntentSource source;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        navivoxChannelProvider.overrideWithValue(channel),
        navivoxConnectIntentSourceProvider.overrideWithValue(source),
      ],
      child: const _MaterialApp(),
    );
  }
}

class _MaterialApp extends ConsumerWidget {
  const _MaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}

class _ScriptedConnectIntentSource extends NavivoxConnectIntentSource {
  _ScriptedConnectIntentSource({
    required this.observer,
    required this.initial,
    required this.source,
  });

  final NavivoxConnectIntentObserver observer;
  final String initial;
  final PairingHandoffSource source;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<SetupQrImageImport?> initialImport() async {
    final parsed = parseNavivoxQrPayload(initial)?.withSource(source);
    if (parsed != null) observer.record(parsed);
    return parsed;
  }

  @override
  Stream<SetupQrImageImport> get imports => const Stream.empty();
}
