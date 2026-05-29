import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/features/servers/setup/navivox_connect_intent_source.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';
import 'package:navivox/router/app_router.dart';
import 'package:navivox/testing/connect_and_talk_channel.dart';

void main() {
  testWidgets('connect-info lands on chat and sends a text turn', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connect to Gormes'), findsOneWidget);
    expect(find.text('Connect and talk'), findsOneWidget);
    expect(find.textContaining('gormes navivox connect-info'), findsWidgets);
    expect(find.textContaining('Android emulator'), findsOneWidget);
    expect(find.textContaining('10.0.2.2'), findsOneWidget);
    expect(find.textContaining('physical Android device'), findsOneWidget);
    expect(_caseInsensitiveText('telephony'), findsNothing);
    expect(_caseInsensitiveText('fake'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Gateway address'),
      'http://127.0.0.1:8765',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Pairing token'),
      'nvbx_test_token',
    );
    await tester.ensureVisible(find.text('Connect and talk'));
    await tester.tap(find.text('Connect and talk'));
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
    expect(find.text('Gormes Gateway'), findsNothing);
    expect(find.textContaining('Gateway online'), findsOneWidget);
    expect(find.text('Default profile'), findsOneWidget);

    await tester.tap(find.text('Default profile'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'hello gateway',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(channel.sentTexts, ['hello gateway']);
    expect(find.text('hello gateway'), findsOneWidget);
    expect(find.text('hello from gateway'), findsOneWidget);
    expect(_caseInsensitiveText('telephony'), findsNothing);
  });

  testWidgets(
    'setup exposes web accessibility labels for connection controls',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final channel = ConnectAndTalkChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const _RouterTestApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Gateway address field'), findsOneWidget);
      expect(find.bySemanticsLabel('Gateway port field'), findsOneWidget);
      expect(find.bySemanticsLabel('Pairing token field'), findsOneWidget);
      expect(find.bySemanticsLabel('Import QR image'), findsOneWidget);
      expect(find.bySemanticsLabel('Copy fix instructions'), findsOneWidget);
      expect(find.bySemanticsLabel('Show pairing token'), findsOneWidget);
      expect(find.bySemanticsLabel('Connect and talk'), findsOneWidget);
    },
  );

  testWidgets('pressing done in the token field connects to Gormes', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Gateway address'),
      'http://127.0.0.1:8765',
    );
    final tokenField = find.widgetWithText(TextField, 'Pairing token');
    await tester.enterText(tokenField, 'nvbx_test_token');
    await tester.showKeyboard(tokenField);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
  });

  testWidgets('setup uses separate address and port fields', (tester) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Gateway address'),
      '127.0.0.1',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Port'), '8765');
    await tester.ensureVisible(find.text('Connect and talk'));
    await tester.tap(find.text('Connect and talk'));
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
  });

  testWidgets('setup detects a port pasted into the address field', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Gateway address'),
      'http://127.0.0.1:7319',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Port'), '8765');
    await tester.ensureVisible(find.text('Connect and talk'));
    await tester.tap(find.text('Connect and talk'));
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:7319');
  });

  testWidgets('setup trims connection details and omits blank token', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Gateway address'),
      '  http://127.0.0.1:8765  ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Pairing token'),
      '   ',
    );
    await tester.ensureVisible(find.text('Connect and talk'));
    await tester.tap(find.text('Connect and talk'));
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
    expect(channel.connectedToken, isNull);
  });

  testWidgets('setup preserves imported connect-info websocket URL', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          home: SetupScreen(
            qrImageImporter: () async => const SetupQrImageImport(
              baseUrl: 'https://gateway.example:8765',
              token: 'nvbx_imported_token',
              webSocketUrl: 'wss://stream.example:9443/custom/stream',
            ),
          ),
        ),
      ),
    );

    final importButton = find.byKey(const ValueKey('setup-import-qr-button'));
    await tester.ensureVisible(importButton);
    await tester.tap(importButton);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Connect and talk'));
    await tester.tap(find.text('Connect and talk'));
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'https://gateway.example:8765');
    expect(channel.connectedToken, 'nvbx_imported_token');
    expect(
      channel.connectedWebSocketUrl,
      'wss://stream.example:9443/custom/stream',
    );
  });

  testWidgets('setup imports initial Android Navivox connection link', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          home: SetupScreen(
            connectIntentSource: _FakeConnectIntentSource(
              initial: const SetupQrImageImport(
                baseUrl: 'http://127.0.0.1:8765',
                token: 'nvbx_deeplink_token',
                webSocketUrl: 'ws://127.0.0.1:8765/v1/navivox/stream',
                source: PairingHandoffSource.sharedText,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Imported Navivox connection link.'), findsOneWidget);
    await tester.ensureVisible(find.text('Connect and talk'));
    await tester.tap(find.text('Connect and talk'));
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
    expect(channel.connectedToken, 'nvbx_deeplink_token');
    expect(
      channel.connectedWebSocketUrl,
      'ws://127.0.0.1:8765/v1/navivox/stream',
    );
  });

  testWidgets(
    'setup auto-connects initial direct app-open link without active gateway',
    (tester) async {
      final channel = ConnectAndTalkChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: MaterialApp(
            home: SetupScreen(
              connectIntentSource: _FakeConnectIntentSource(
                initial: const SetupQrImageImport(
                  baseUrl: 'http://127.0.0.1:8765',
                  token: 'nvbx_direct_token',
                  webSocketUrl: 'ws://127.0.0.1:8765/v1/navivox/stream',
                  source: PairingHandoffSource.directAppOpen,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
      expect(channel.connectedToken, 'nvbx_direct_token');
    },
  );

  testWidgets('setup imports foreground Android Navivox connection link', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);
    final intentStream = StreamController<SetupQrImageImport>();
    addTearDown(intentStream.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: MaterialApp(
          home: SetupScreen(
            connectIntentSource: _FakeConnectIntentSource(
              imports: intentStream.stream,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    intentStream.add(
      const SetupQrImageImport(
        baseUrl: 'https://gateway.example:8765',
        token: 'nvbx_foreground_token',
        webSocketUrl: 'wss://gateway.example:8765/v1/navivox/stream',
        source: PairingHandoffSource.sharedText,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Imported Navivox connection link.'), findsOneWidget);
    await tester.ensureVisible(find.text('Connect and talk'));
    await tester.tap(find.text('Connect and talk'));
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'https://gateway.example:8765');
    expect(channel.connectedToken, 'nvbx_foreground_token');
    expect(
      channel.connectedWebSocketUrl,
      'wss://gateway.example:8765/v1/navivox/stream',
    );
  });

  testWidgets('setup validates the gateway URL before connecting', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Gateway address'),
      'ftp://example.com',
    );
    await tester.ensureVisible(find.text('Connect and talk'));
    await tester.tap(find.text('Connect and talk'));
    await tester.pumpAndSettle();

    expect(find.text('Use http, https, ws, or wss.'), findsOneWidget);
    expect(channel.connectedBaseUrl, isNull);
    expect(find.text('Connect to Gormes'), findsOneWidget);
  });

  testWidgets('setup screen shows Termux same-device bootstrap guidance', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Same-device setup'), findsOneWidget);
    expect(find.textContaining('Termux'), findsWidgets);
    expect(find.textContaining('paste the bootstrap command'), findsOneWidget);
    expect(
      find.textContaining('Navivox should open from the pairing link'),
      findsOneWidget,
    );
    expect(find.textContaining('gateway status'), findsOneWidget);
    expect(find.textContaining('gormes navivox pair'), findsWidgets);
    expect(find.text('Copy one-paste bootstrap'), findsOneWidget);
    expect(find.text('Copy fix instructions'), findsWidgets);
    expect(find.text('Advanced Termux commands'), findsNothing);
    expect(find.text('Copy Termux download links'), findsNothing);
    expect(_caseInsensitiveText('curl | sh'), findsNothing);
  });

  testWidgets('copy one-paste bootstrap stays safe and inspect-first', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add(
            (call.arguments as Map<Object?, Object?>)['text']! as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const _RouterTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Copy one-paste bootstrap'));
    await tester.tap(find.text('Copy one-paste bootstrap'));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect(copied.single, contains('one pasted Termux command'));
    expect(copied.single, contains('pkg upgrade -y'));
    expect(copied.single, contains('pkg install -y git curl'));
    expect(
      copied.single,
      contains(
        'curl -fsSLO https://github.com/TrebuchetDynamics/gormes-agent/releases/latest/download/install.sh',
      ),
    );
    expect(
      copied.single,
      contains('Press q to continue install, or Ctrl-C to abort'),
    );
    expect(copied.single, contains('less install.sh'));
    expect(copied.single, contains('GORMES_SKIP_SETUP=1 bash install.sh'));
    expect(
      copied.single,
      contains('(gormes navivox pair || gormes navivox connect-info)'),
    );
    expect(copied.single.toLowerCase(), isNot(contains('curl | sh')));
    expect(copied.single.toLowerCase(), isNot(contains('nvbx_')));
    expect(find.text('Copied one-paste Termux bootstrap.'), findsOneWidget);
  });

  testWidgets(
    'copy Navivox fix instructions gives actionable status recovery',
    (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<Object?, Object?>)['text']! as String,
            );
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final channel = ConnectAndTalkChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const _RouterTestApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Copy fix instructions').last);
      await tester.tap(find.text('Copy fix instructions').last);
      await tester.pumpAndSettle();

      expect(copied, hasLength(1));
      expect(copied.single, contains('Navivox operator fix instructions'));
      expect(copied.single, contains('gormes navivox status'));
      expect(copied.single, contains('gormes navivox pair'));
      expect(copied.single, contains('Keep that command open'));
      expect(copied.single, contains('pairing link'));
      expect(copied.single, contains('gormes navivox connect-info'));
      expect(copied.single, contains('10.0.2.2'));
      expect(copied.single.toLowerCase(), isNot(contains('nvbx_')));
      expect(copied.single.toLowerCase(), isNot(contains('silent install')));
      expect(find.text('Copied Navivox fix instructions.'), findsOneWidget);
    },
  );

  testWidgets(
    'connect failure gives connect-info guidance without token leak',
    (tester) async {
      final channel = FailingConnectChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const _RouterTestApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Gateway address'),
        'http://127.0.0.1:8765',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Pairing token'),
        'nvbx_secret_should_not_render',
      );
      await tester.ensureVisible(find.text('Connect and talk'));
      await tester.tap(find.text('Connect and talk'));
      await tester.pumpAndSettle();

      expect(find.text('Could not connect to Gormes gateway.'), findsOneWidget);
      expect(find.textContaining('gormes navivox status'), findsWidgets);
      expect(find.textContaining('gormes navivox pair'), findsWidgets);
      expect(find.textContaining('connect-info'), findsWidgets);
      expect(
        _caseInsensitiveText('nvbx_secret_should_not_render'),
        findsNothing,
      );
      expect(_caseInsensitiveText('telephony'), findsNothing);
    },
  );
}

Finder _caseInsensitiveText(String needle) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final data = widget.data;
    if (data == null) return false;
    return data.toLowerCase().contains(needle.toLowerCase());
  });
}

class _FakeConnectIntentSource extends NavivoxConnectIntentSource {
  _FakeConnectIntentSource({this.initial, Stream<SetupQrImageImport>? imports})
    : _imports = imports ?? const Stream<SetupQrImageImport>.empty();

  final SetupQrImageImport? initial;
  final Stream<SetupQrImageImport> _imports;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<SetupQrImageImport?> initialImport() async => initial;

  @override
  Stream<SetupQrImageImport> get imports => _imports;
}

class _RouterTestApp extends ConsumerWidget {
  const _RouterTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}
