import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
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
      find.widgetWithText(TextField, 'Gateway base URL'),
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
    expect(find.text('Gormes Gateway'), findsOneWidget);
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

    expect(
      find.textContaining('Run Gormes on this Android device'),
      findsOneWidget,
    );
    expect(find.textContaining('Termux'), findsWidgets);
    expect(find.textContaining('updates packages'), findsOneWidget);
    expect(find.textContaining('installs git/curl'), findsOneWidget);
    expect(
      find.textContaining('downloads and pauses for `install.sh` review'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Navivox cannot silently install Gormes'),
      findsOneWidget,
    );
    expect(find.textContaining('Navivox (recommended)'), findsOneWidget);
    expect(find.textContaining('paste one command'), findsOneWidget);
    expect(
      find.textContaining('Scan/import the QR from `gormes navivox pair`'),
      findsOneWidget,
    );
    expect(find.textContaining('gormes navivox pair'), findsWidgets);
    expect(find.textContaining('connect-info fallback'), findsOneWidget);
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

  testWidgets('copy Termux download links stores official sources only', (
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

    await tester.ensureVisible(find.text('Copy Termux download links'));
    await tester.tap(find.text('Copy Termux download links'));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect(copied.single, contains('https://termux.dev/en/'));
    expect(copied.single, contains('https://f-droid.org/packages/com.termux/'));
    expect(
      copied.single,
      contains('https://github.com/termux/termux-app/releases'),
    );
    expect(copied.single, contains('Use one signing source'));
    expect(copied.single.toLowerCase(), isNot(contains('play.google')));
    expect(find.text('Copied Termux download links.'), findsOneWidget);
  });

  testWidgets('copy same-device Termux connection hint keeps tokens out', (
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

    await tester.ensureVisible(find.text('Copy same-device connection hint'));
    await tester.tap(find.text('Copy same-device connection hint'));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Same Android device'));
    expect(copied.single, contains('Gormes in Termux'));
    expect(copied.single, contains('http://127.0.0.1:<port>'));
    expect(copied.single, contains('http://10.0.2.2:<port>'));
    expect(copied.single, contains('LAN, VPN, or Tailscale'));
    expect(copied.single, contains('gormes navivox connect-info'));
    expect(copied.single.toLowerCase(), isNot(contains('nvbx_')));
    expect(find.text('Copied same-device connection hint.'), findsOneWidget);
  });

  testWidgets('copy Navivox pair handoff describes app-first setup', (
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

    await tester.ensureVisible(find.text('Copy Navivox pair handoff'));
    await tester.tap(find.text('Copy Navivox pair handoff'));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect(copied.single, contains('one terminal interaction maximum'));
    expect(copied.single, contains('Navivox (recommended)'));
    expect(copied.single, contains('gormes navivox pair'));
    expect(copied.single, contains('start local bridge'));
    expect(copied.single, contains('generate a pairing token'));
    expect(copied.single, contains('show a QR'));
    expect(copied.single, contains('print localhost URL'));
    expect(copied.single, contains('wait for Navivox connection'));
    expect(copied.single, contains('gormes navivox connect-info'));
    expect(copied.single.toLowerCase(), isNot(contains('nvbx_')));
    expect(copied.single.toLowerCase(), isNot(contains('silent install')));
    expect(find.text('Copied Navivox pair handoff.'), findsOneWidget);
  });

  testWidgets('copy post-install Termux checks keeps tokens out', (
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

    await tester.ensureVisible(find.text('Copy post-install checks'));
    await tester.tap(find.text('Copy post-install checks'));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect(copied.single, contains('After bash install.sh'));
    expect(copied.single, contains('gormes version'));
    expect(copied.single, contains('gormes doctor --offline'));
    expect(copied.single, contains('gormes navivox connect-info'));
    expect(copied.single, contains('paste it only into Navivox'));
    expect(copied.single.toLowerCase(), isNot(contains('nvbx_')));
    expect(copied.single.toLowerCase(), isNot(contains('curl -fsslo')));
    expect(find.text('Copied post-install Termux checks.'), findsOneWidget);
  });

  testWidgets(
    'copy Termux gateway lifecycle avoids desktop service assumptions',
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

      await tester.ensureVisible(find.text('Copy Termux gateway lifecycle'));
      await tester.tap(find.text('Copy Termux gateway lifecycle'));
      await tester.pumpAndSettle();

      expect(copied, hasLength(1));
      expect(copied.single, contains('foreground/tmux lifecycle'));
      expect(copied.single, contains('tmux new-session'));
      expect(copied.single, contains('gormes gateway'));
      expect(copied.single, contains('gormes gateway status'));
      expect(copied.single, contains('gormes gateway stop'));
      expect(copied.single, contains('gormes navivox connect-info'));
      expect(copied.single, contains('termux-wake-lock'));
      expect(copied.single, contains('Android battery'));
      expect(copied.single.toLowerCase(), isNot(contains('nvbx_')));
      expect(copied.single, isNot(contains('systemd')));
      expect(copied.single, isNot(contains('Scheduled Task')));
      expect(find.text('Copied Termux gateway lifecycle.'), findsOneWidget);
    },
  );

  testWidgets('copy Termux boot helper stays explicit and reversible', (
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

    await tester.ensureVisible(find.text('Copy Termux:Boot helper'));
    await tester.tap(find.text('Copy Termux:Boot helper'));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect(copied.single, contains('Termux:Boot'));
    expect(copied.single, contains('same APK source'));
    expect(copied.single, contains('gormes gateway boot-install'));
    expect(copied.single, contains('gormes gateway boot-uninstall'));
    expect(copied.single, contains('.termux/boot/gormes-gateway.sh'));
    expect(copied.single.toLowerCase(), contains('reboot'));
    expect(copied.single, contains('does not install APKs'));
    expect(copied.single.toLowerCase(), isNot(contains('nvbx_')));
    expect(copied.single.toLowerCase(), isNot(contains('pm install')));
    expect(find.text('Copied Termux:Boot helper.'), findsOneWidget);
  });

  testWidgets('copy optional Termux storage command stays permission-scoped', (
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

    await tester.ensureVisible(find.text('Copy optional storage command'));
    await tester.tap(find.text('Copy optional storage command'));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect(copied.single, contains('termux-setup-storage'));
    expect(copied.single, contains('Only run this if'));
    expect(copied.single, contains('Android storage permission'));
    expect(copied.single, contains('logs, screenshots, or exported files'));
    expect(copied.single.toLowerCase(), isNot(contains('nvbx_')));
    expect(copied.single.toLowerCase(), isNot(contains('bash install.sh')));
    expect(
      find.text('Copied optional Termux storage command.'),
      findsOneWidget,
    );
  });

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
        find.widgetWithText(TextField, 'Gateway base URL'),
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
      expect(find.textContaining('gormes navivox connect-info'), findsWidgets);
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

class _RouterTestApp extends ConsumerWidget {
  const _RouterTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(routerConfig: ref.watch(routerProvider));
  }
}
