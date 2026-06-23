import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/setup/navivox_connect_intent_source.dart';
import 'package:navivox/features/servers/screens/setup_screen.dart';
import 'package:navivox/testing/connect_and_talk_channel.dart';

import '../../../shared/app/test_material_app.dart';
import '../../../shared/app/test_router_app.dart';
import '../../../shared/finders/test_finders.dart';
import '../shared/setup_screen_test_contracts.dart';

void main() {
  testWidgets('connect-info lands on chat and sends a text turn', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
    await tester.pumpAndSettle();

    expect(find.text('Connect to Gormes'), findsOneWidget);
    expect(find.text('Pairing readiness'), findsNothing);
    expect(find.text('Ready for pairing details'), findsNothing);
    expect(find.text('Need setup help?'), findsOneWidget);
    expect(find.textContaining('Termux bootstrap'), findsOneWidget);
    expect(caseInsensitiveText('telephony'), findsNothing);
    expect(caseInsensitiveText('fake'), findsNothing);

    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), 'http://127.0.0.1:8765');
    await tester.enterText(setupTokenField(), 'nvbx_test_token');
    await tester.ensureVisible(setupConnectAction());
    await tester.tap(setupConnectAction());
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
    expect(caseInsensitiveText('telephony'), findsNothing);
  });

  testWidgets(
    'setup exposes web accessibility labels for connection controls',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final channel = ConnectAndTalkChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
      await tester.pumpAndSettle();

      // Primary control always visible.
      expect(find.bySemanticsLabel(setupImportQrLabel), findsOneWidget);

      // Expand manual entry to check its accessibility labels.
      await expandManualEntry(tester);

      expect(find.bySemanticsLabel('Gateway URL field'), findsOneWidget);
      expect(find.bySemanticsLabel('Pairing token field'), findsOneWidget);
      expect(find.bySemanticsLabel('Show pairing token'), findsOneWidget);
      expect(find.bySemanticsLabel('Connect and talk'), findsOneWidget);
    },
  );

  testWidgets('pressing done in the token field connects to Gormes', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
    await tester.pumpAndSettle();

    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), 'http://127.0.0.1:8765');
    final tokenField = setupTokenField();
    await tester.enterText(tokenField, 'nvbx_test_token');
    await tester.showKeyboard(tokenField);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
  });

  testWidgets('setup uses a single URL field for gateway address and port', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
    await tester.pumpAndSettle();

    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), 'http://127.0.0.1:8765');
    await tester.ensureVisible(setupConnectAction());
    await tester.tap(setupConnectAction());
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
  });

  testWidgets('setup detects a port pasted into the address field', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
    await tester.pumpAndSettle();

    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), 'http://127.0.0.1:7319');
    await tester.ensureVisible(setupConnectAction());
    await tester.tap(setupConnectAction());
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'http://127.0.0.1:7319');
  });

  testWidgets('setup trims connection details and omits blank token', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
    await tester.pumpAndSettle();

    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), '  http://127.0.0.1:8765  ');
    await tester.enterText(setupTokenField(), '   ');
    await tester.ensureVisible(setupConnectAction());
    await tester.tap(setupConnectAction());
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
      TestNavivoxMaterialApp(
        channel: channel,
        home: SetupScreen(
          qrImageImporter: () async => const SetupQrImageImport(
            baseUrl: 'https://gateway.example:8765',
            token: 'nvbx_imported_token',
            webSocketUrl: 'wss://stream.example:9443/custom/stream',
          ),
        ),
      ),
    );

    final importButton = setupImportQrAction();
    await tester.ensureVisible(importButton);
    await tester.tap(importButton);
    await tester.pumpAndSettle();
    expect(find.text('Review imported handoff'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('setup-pairing-readiness-card')),
        matching: find.textContaining('QR image'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(setupConnectAction());
    await tester.tap(setupConnectAction());
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'https://gateway.example:8765');
    expect(channel.connectedToken, 'nvbx_imported_token');
    expect(
      channel.connectedWebSocketUrl,
      'wss://stream.example:9443/custom/stream',
    );
  });

  testWidgets('setup ignores late initial Android link after dispose', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);
    final initialImport = Completer<SetupQrImageImport?>();

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: SetupScreen(
          connectIntentSource: _DelayedInitialConnectIntentSource(
            initial: initialImport.future,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const SizedBox.shrink()),
    );
    initialImport.complete(
      const SetupQrImageImport(
        baseUrl: 'http://127.0.0.1:8765',
        token: 'nvbx_late_token',
        source: PairingHandoffSource.sharedText,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(channel.connectedBaseUrl, isNull);
  });

  testWidgets('setup imports initial Android Navivox connection link', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
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
    );
    await tester.pumpAndSettle();

    expect(find.text('Imported Navivox connection link.'), findsOneWidget);
    await tester.ensureVisible(setupConnectAction());
    await tester.tap(setupConnectAction());
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
        TestNavivoxMaterialApp(
          channel: channel,
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
      );
      await tester.pumpAndSettle();

      expect(channel.connectedBaseUrl, 'http://127.0.0.1:8765');
      expect(channel.connectedToken, 'nvbx_direct_token');
    },
  );

  testWidgets('setup ignores foreground Android link after dispose', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);
    final intentStream = StreamController<SetupQrImageImport>();
    addTearDown(intentStream.close);

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: SetupScreen(
          connectIntentSource: _FakeConnectIntentSource(
            imports: intentStream.stream,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      TestNavivoxMaterialApp(channel: channel, home: const SizedBox.shrink()),
    );
    intentStream.add(
      const SetupQrImageImport(
        baseUrl: 'https://gateway.example:8765',
        token: 'nvbx_late_foreground_token',
        source: PairingHandoffSource.sharedText,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(channel.connectedBaseUrl, isNull);
  });

  testWidgets('setup imports foreground Android Navivox connection link', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);
    final intentStream = StreamController<SetupQrImageImport>();
    addTearDown(intentStream.close);

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: SetupScreen(
          connectIntentSource: _FakeConnectIntentSource(
            imports: intentStream.stream,
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
    await tester.ensureVisible(setupConnectAction());
    await tester.tap(setupConnectAction());
    await tester.pumpAndSettle();

    expect(channel.connectedBaseUrl, 'https://gateway.example:8765');
    expect(channel.connectedToken, 'nvbx_foreground_token');
    expect(
      channel.connectedWebSocketUrl,
      'wss://gateway.example:8765/v1/navivox/stream',
    );
  });

  testWidgets('direct app-open auto-connect failure does not leak token', (
    tester,
  ) async {
    final channel = FailingConnectChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      TestNavivoxMaterialApp(
        channel: channel,
        home: SetupScreen(
          connectIntentSource: _FakeConnectIntentSource(
            initial: const SetupQrImageImport(
              baseUrl: 'http://127.0.0.1:8765',
              token: 'nvbx_direct_secret_should_not_render',
              source: PairingHandoffSource.directAppOpen,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pairing needs attention'), findsOneWidget);
    expect(
      find.text('Could not connect from the pairing link.'),
      findsOneWidget,
    );
    expect(
      caseInsensitiveText('nvbx_direct_secret_should_not_render'),
      findsNothing,
    );
  });

  testWidgets('setup validates the gateway URL before connecting', (
    tester,
  ) async {
    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
    await tester.pumpAndSettle();

    await expandManualEntry(tester);
    await tester.enterText(setupUrlField(), 'ftp://example.com');
    await tester.ensureVisible(setupConnectAction());
    await tester.tap(setupConnectAction());
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

    await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Need setup help?'));
    await tester.tap(find.text('Need setup help?'));
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
    expect(find.text('Copy fix instructions'), findsOneWidget);
    expect(find.text('Advanced Termux commands'), findsNothing);
    expect(find.text('Copy Termux download links'), findsNothing);
    expect(caseInsensitiveText('curl | sh'), findsNothing);
  });

  testWidgets('copy one-paste bootstrap stays safe and inspect-first', (
    tester,
  ) async {
    final clipboard = ClipboardCapture()..install(tester);

    final channel = ConnectAndTalkChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Need setup help?'));
    await tester.tap(find.text('Need setup help?'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Copy one-paste bootstrap'));
    await tester.tap(find.text('Copy one-paste bootstrap'));
    await tester.pumpAndSettle();

    expect(clipboard.copiedTexts, hasLength(1));
    expect(clipboard.copiedTexts.single, contains('one pasted Termux command'));
    expect(clipboard.copiedTexts.single, contains('pkg upgrade -y'));
    expect(clipboard.copiedTexts.single, contains('pkg install -y git curl'));
    expect(
      clipboard.copiedTexts.single,
      contains(
        'curl -fsSLO https://github.com/TrebuchetDynamics/gormes-agent/releases/latest/download/install.sh',
      ),
    );
    expect(
      clipboard.copiedTexts.single,
      contains('Press q to continue install, or Ctrl-C to abort'),
    );
    expect(clipboard.copiedTexts.single, contains('less install.sh'));
    expect(
      clipboard.copiedTexts.single,
      contains('GORMES_SKIP_SETUP=1 bash install.sh'),
    );
    expect(
      clipboard.copiedTexts.single,
      contains('(gormes navivox pair || gormes navivox connect-info)'),
    );
    expect(
      clipboard.copiedTexts.single.toLowerCase(),
      isNot(contains('curl | sh')),
    );
    expect(
      clipboard.copiedTexts.single.toLowerCase(),
      isNot(contains('nvbx_')),
    );
    expect(find.text('Copied one-paste Termux bootstrap.'), findsOneWidget);
  });

  testWidgets(
    'copy Navivox fix instructions gives actionable status recovery',
    (tester) async {
      final clipboard = ClipboardCapture()..install(tester);

      final channel = ConnectAndTalkChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Need setup help?'));
      await tester.tap(find.text('Need setup help?'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Copy fix instructions'));
      await tester.tap(find.text('Copy fix instructions'));
      await tester.pumpAndSettle();

      expect(clipboard.copiedTexts, hasLength(1));
      expect(
        clipboard.copiedTexts.single,
        contains('Navivox operator fix instructions'),
      );
      expect(clipboard.copiedTexts.single, contains('gormes navivox status'));
      expect(clipboard.copiedTexts.single, contains('gormes navivox pair'));
      expect(clipboard.copiedTexts.single, contains('Keep that command open'));
      expect(clipboard.copiedTexts.single, contains('pairing link'));
      expect(
        clipboard.copiedTexts.single,
        contains('gormes navivox connect-info'),
      );
      expect(clipboard.copiedTexts.single, contains('10.0.2.2'));
      expect(
        clipboard.copiedTexts.single.toLowerCase(),
        isNot(contains('nvbx_')),
      );
      expect(
        clipboard.copiedTexts.single.toLowerCase(),
        isNot(contains('silent install')),
      );
      expect(find.text('Copied Navivox fix instructions.'), findsOneWidget);
    },
  );

  testWidgets(
    'connect failure gives connect-info guidance without token leak',
    (tester) async {
      final channel = FailingConnectChannel();
      addTearDown(channel.dispose);

      await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
      await tester.pumpAndSettle();

      await expandManualEntry(tester);
      await tester.enterText(setupUrlField(), 'http://127.0.0.1:8765');
      await tester.enterText(
        setupTokenField(),
        'nvbx_secret_should_not_render',
      );
      await tester.ensureVisible(setupConnectAction());
      await tester.tap(setupConnectAction());
      await tester.pumpAndSettle();

      expect(find.text('Pairing needs attention'), findsOneWidget);
      expect(find.text('Could not connect to Gormes gateway.'), findsOneWidget);
      expect(find.textContaining('gormes navivox status'), findsWidgets);
      expect(find.textContaining('gormes navivox pair'), findsWidgets);
      expect(find.textContaining('connect-info'), findsWidgets);
      expect(
        caseInsensitiveText('nvbx_secret_should_not_render'),
        findsNothing,
      );
      expect(caseInsensitiveText('telephony'), findsNothing);
    },
  );
}

class _DelayedInitialConnectIntentSource extends NavivoxConnectIntentSource {
  _DelayedInitialConnectIntentSource({required this.initial});

  final Future<SetupQrImageImport?> initial;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<SetupQrImageImport?> initialImport() => initial;

  @override
  Stream<SetupQrImageImport> get imports => const Stream.empty();
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
