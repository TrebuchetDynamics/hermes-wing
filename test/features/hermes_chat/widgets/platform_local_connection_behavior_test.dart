import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'platform_local_connection_panel_test.dart'
    show pumpEntry, key, SyntheticHome;

void main() {
  testWidgets(
    'initial This phone connection cannot send token to hydrated saved remote',
    (tester) async {
      final channel = RejectedLocalChannel(
        HermesConnectionFailureKind.authentication,
      );
      final store = FakeHermesEndpointStore(
        initial: const HermesEndpointConfig(
          id: 'synthetic-remote',
          baseUrl: 'https://saved.example.invalid',
          apiKey: 'synthetic-test-only',
        ),
      );
      await pumpEntry(
        tester,
        TargetPlatform.android,
        channelOverride: channel,
        storeOverride: store,
        initialMode: HermesConnectionMode.local,
      );
      await activate(tester, 'platform-local-skip-guide');
      await tester.enterText(
        key('hermes-api-key-field'),
        'synthetic-local-test',
      );
      await activate(tester, 'hermes-connect-button');
      expect(channel.connectCalls.single.baseUrl, 'http://127.0.0.1:8642');
      expect(store.saveCalls, isEmpty);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('phone guide is manual and docs open only deliberately', (
    tester,
  ) async {
    final opened = <Uri>[];
    final (channel, store, home) = await pumpEntry(
      tester,
      TargetPlatform.android,
      launcher: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    expect(opened, isEmpty);
    expect(home.calls, isEmpty);
    await activate(tester, 'platform-local-termux-docs');
    expect(
      opened.single.toString(),
      'https://github.com/termux/termux-app#installation',
    );
    await activate(tester, 'platform-local-agent-docs');
    expect(
      opened.last.toString(),
      'https://hermes-agent.nousresearch.com/docs/getting-started/termux',
    );
    await activate(tester, 'platform-local-existing-agent');
    expect(find.text('2. Configure and start Agent'), findsOneWidget);
    expect(key('hermes-api-key-field'), findsNothing);
    await activate(tester, 'platform-local-api-docs');
    expect(
      opened.last.toString(),
      'https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server',
    );
    await activate(tester, 'platform-local-started-agent');
    expect(find.text('http://127.0.0.1:8642'), findsOneWidget);
    expect(
      tester.widget<TextField>(key('hermes-api-key-field')).obscureText,
      isTrue,
    );
    expect(key('hermes-base-url-field'), findsNothing);
    expect(channel.state.isConnected, isFalse);
    expect((channel as FakeHermesChannel).connectCalls, isEmpty);
    expect(store.saveCalls, isEmpty);
    await activate(tester, 'platform-local-guide-back');
    expect(find.text('2. Configure and start Agent'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'chooser cancellation preserves discovery; selection inspects metadata only',
    (tester) async {
      var picks = 0;
      final (channel, store, home) = await pumpEntry(
        tester,
        TargetPlatform.linux,
        picker: () async => ++picks == 1 ? null : '/synthetic/alternate',
      );
      expect(home.calls, ['/synthetic/.hermes']);
      await activate(tester, 'platform-local-choose-home');
      expect(home.calls, ['/synthetic/.hermes']);
      expect(find.text('/synthetic/.hermes'), findsOneWidget);
      await activate(tester, 'platform-local-choose-home');
      expect(home.calls, ['/synthetic/.hermes', '/synthetic/alternate']);
      expect(find.text('/synthetic/alternate'), findsOneWidget);
      expect((channel as FakeHermesChannel).connectCalls, isEmpty);
      expect(store.saveCalls, isEmpty);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'selected metadata beats stale default; disposed picker is ignored',
    (tester) async {
      final initial = Completer<LocalHermesHomeInspection>();
      final picked = Completer<String?>();
      var picks = 0;
      final home = SyntheticHome(
        inspect: (path) => path.endsWith('.hermes')
            ? initial.future
            : Future.value(LocalHermesHomeInspection.directory(path)),
      );
      await pumpEntry(
        tester,
        TargetPlatform.linux,
        home: home,
        picker: () async => ++picks == 1 ? '/synthetic/new' : picked.future,
      );
      await activate(tester, 'platform-local-choose-home');
      initial.complete(
        const LocalHermesHomeInspection.directory('/synthetic/stale'),
      );
      await tester.pumpAndSettle();
      expect(find.text('/synthetic/new'), findsOneWidget);
      expect(find.text('/synthetic/stale'), findsNothing);
      await activate(tester, 'platform-local-choose-home');
      await activate(tester, 'hermes-connection-mode-remote');
      picked.complete('/synthetic/disposed');
      await tester.pumpAndSettle();
      expect(home.calls, ['/synthetic/.hermes', '/synthetic/new']);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  for (final status in [
    LocalHermesHomeStatus.absent,
    LocalHermesHomeStatus.notDirectory,
    LocalHermesHomeStatus.unreadable,
    LocalHermesHomeStatus.unsupported,
  ]) {
    testWidgets('Linux metadata $status does not imply readiness', (
      tester,
    ) async {
      final (channel, store, _) = await pumpEntry(
        tester,
        TargetPlatform.linux,
        home: SyntheticHome(
          inspect: (_) async => LocalHermesHomeInspection.unavailable(status),
        ),
      );
      expect(find.text('Directory found — discovery only'), findsNothing);
      expect(key('platform-local-home-path'), findsNothing);
      expect((channel as FakeHermesChannel).connectCalls, isEmpty);
      expect(store.saveCalls, isEmpty);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  for (final failure in [
    HermesConnectionFailureKind.authentication,
    HermesConnectionFailureKind.network,
  ]) {
    testWidgets('phone explicit $failure connection retains sanitized owner', (
      tester,
    ) async {
      final channel = RejectedLocalChannel(failure);
      final (_, store, _) = await pumpEntry(
        tester,
        TargetPlatform.android,
        channelOverride: channel,
      );
      await activate(tester, 'platform-local-skip-guide');
      await tester.enterText(
        key('hermes-api-key-field'),
        'synthetic-test-only',
      );
      expect(channel.connectCalls, isEmpty);
      await activate(tester, 'hermes-connect-button');
      expect(channel.connectCalls.single.baseUrl, 'http://127.0.0.1:8642');
      expect(find.textContaining('private response'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.contains('synthetic-test-only') ?? false),
        ),
        findsNothing,
      );
      expect(
        tester.widget<TextField>(key('hermes-api-key-field')).obscureText,
        isTrue,
      );
      expect(channel.state.isConnected, isFalse);
      expect(store.saveCalls, isEmpty);
      await tester.pump(const Duration(seconds: 2));
      expect(channel.connectCalls, hasLength(1));
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets(
    'phone explicit connect keeps established channel and secure-save semantics',
    (tester) async {
      final (channel, store, _) = await pumpEntry(
        tester,
        TargetPlatform.android,
      );
      await activate(tester, 'platform-local-skip-guide');
      await tester.enterText(
        key('hermes-api-key-field'),
        'synthetic-test-only',
      );
      await tester.enterText(
        key('hermes-profile-label-field'),
        'Synthetic local',
      );
      expect(store.saveCalls, isEmpty);
      await activate(tester, 'hermes-connect-button');
      expect((channel as FakeHermesChannel).connectCalls, hasLength(1));
      // Established Add Hermes semantics save the endpoint then disconnect the
      // attempt before the directory becomes the navigation owner.
      expect(channel.state.isConnected, isFalse);
      expect(channel.disconnectCalls, 1);
      expect(store.saveCalls, hasLength(1));
      expect(store.saveCalls.single.baseUrl, 'http://127.0.0.1:8642');
      expect(store.saveCalls.single.label, 'Synthetic local');
      expect(store.clearCalls, 0);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'docs launcher failure is sanitized and never advances the guide',
    (tester) async {
      await pumpEntry(
        tester,
        TargetPlatform.android,
        launcher: (_) async =>
            throw StateError('private docs response /private/home'),
      );
      await activate(tester, 'platform-local-agent-docs');
      expect(key('platform-local-docs-error'), findsOneWidget);
      expect(find.textContaining('private docs response'), findsNothing);
      expect(find.text('1. Termux and Agent'), findsOneWidget);
      expect(key('hermes-api-key-field'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'selected inspection after disposal cannot update new Local entry',
    (tester) async {
      final result = Completer<LocalHermesHomeInspection>();
      final home = SyntheticHome(
        inspect: (path) => path.endsWith('.hermes')
            ? Future.value(LocalHermesHomeInspection.directory(path))
            : result.future,
      );
      await pumpEntry(
        tester,
        TargetPlatform.linux,
        home: home,
        picker: () async => '/synthetic/pending',
      );
      await activate(tester, 'platform-local-choose-home');
      await activate(tester, 'hermes-connection-mode-remote');
      await activate(tester, 'hermes-connection-mode-local');
      result.complete(
        const LocalHermesHomeInspection.directory('/synthetic/pending'),
      );
      await tester.pumpAndSettle();
      expect(find.text('/synthetic/.hermes'), findsOneWidget);
      expect(find.text('/synthetic/pending'), findsNothing);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('compact 200 percent Local remains keyboard operable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpEntry(tester, TargetPlatform.android, textScale: 2);
    await keyboardActivate(tester, 'platform-local-skip-guide');
    await tester.ensureVisible(key('hermes-api-key-field'));
    await tester.tap(key('hermes-api-key-field'));
    await tester.enterText(key('hermes-api-key-field'), 'synthetic-test-only');
    expect(
      tester.widget<TextField>(key('hermes-api-key-field')).obscureText,
      isTrue,
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final size in [const Size(390, 844), const Size(1280, 1000)]) {
    testWidgets('deterministic production Local render at $size', (
      tester,
    ) async {
      await loadCaptureFonts(tester);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpEntry(
        tester,
        size.width < 500 ? TargetPlatform.android : TargetPlatform.linux,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'local-${size.width.toInt()}');
      debugDefaultTargetPlatformOverride = null;
    });
  }
}

Future<void> activate(WidgetTester tester, String value) async {
  await tester.ensureVisible(key(value));
  await tester.tap(key(value));
  await tester.pumpAndSettle();
}

Future<void> keyboardActivate(WidgetTester tester, String value) async {
  await tester.ensureVisible(key(value));
  for (var i = 0; i < 100; i++) {
    var found = false;
    FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
      element,
    ) {
      if (element.widget.key == ValueKey(value)) found = true;
      return !found;
    });
    if (found) {
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
  fail('Keyboard traversal did not reach $value');
}

class RejectedLocalChannel extends FakeHermesChannel {
  RejectedLocalChannel(this.failure)
    : super(status: HermesConnectionStatus.disconnected);
  final HermesConnectionFailureKind failure;
  HermesChannelState? rejected;
  @override
  HermesChannelState get state => rejected ?? super.state;
  @override
  Future<void> connect({
    required String baseUrl,
    String? apiKey,
    bool deferSessionSelection = false,
  }) async {
    connectCalls.add(FakeHermesConnectCall(baseUrl: baseUrl, apiKey: apiKey));
    rejected = HermesChannelState(
      status: HermesConnectionStatus.error,
      errorMessage: 'private response synthetic-test-only /private/home',
      connectionFailureKind: failure,
    );
    notifyListeners();
  }
}

Future<void> loadCaptureFonts(WidgetTester tester) async {
  final root = Platform.environment['LOCAL_CAPTURE_FONT_ROOT'];
  if (root == null) return;
  await tester.runAsync(() async {
    final text = FontLoader('Roboto');
    text.addFont(
      File('$root/Roboto-Regular.ttf').readAsBytes().then(ByteData.sublistView),
    );
    await text.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(
      File(
        Platform.environment['LOCAL_CAPTURE_ICON_FONT']!,
      ).readAsBytes().then(ByteData.sublistView),
    );
    await icons.load();
  });
}

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['LOCAL_CAPTURE_OUTPUT'];
  if (directory == null) return;
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    key('platform-local-render'),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '$directory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
