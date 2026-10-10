import 'package:wing/core/hermes/ssh/ssh_connection_request.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dartssh2/dartssh2.dart';
import 'package:pinenacl/ed25519.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/features/hermes_chat/ssh_keys/managed_ssh_generated_key.dart';
import 'package:wing/features/hermes_chat/ssh_keys/managed_ssh_generated_key_store.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';
import 'package:wing/features/hermes_chat/widgets/managed_ssh_connection_panel.dart';
import 'package:wing/features/hermes_chat/widgets/managed_ssh_connection_form.dart';
import 'managed_ssh_connection_panel_test.dart' as support;

// Public deterministic seed, never a personal or randomly generated runtime key.
ManagedSshGeneratedKey fixture() {
  final signing = SigningKey.fromSeed(
    Uint8List.fromList(List<int>.filled(32, 7)),
  );
  return ManagedSshGeneratedKey.fromPrivatePem(
    OpenSSHEd25519KeyPair(
      signing.verifyKey.asTypedList,
      signing.asTypedList,
      'hermes-wing',
    ).toPem(),
  );
}

class FakeGeneratedStore extends ManagedSshGeneratedKeyStore {
  int generates = 0, loads = 0;
  ManagedSshGeneratedKey? retained;
  Completer<ManagedSshGeneratedKey>? pending;
  bool fail = false;
  @override
  Future<ManagedSshGeneratedKey> generate() async {
    generates++;
    if (fail) throw StateError('synthetic secret exception');
    return retained = pending == null
        ? retained ?? fixture()
        : await pending!.future;
  }

  @override
  Future<ManagedSshGeneratedKey?> load() async {
    loads++;
    if (fail) throw StateError('synthetic secret exception');
    return retained;
  }
}

Finder control(String id) => find.byKey(ValueKey('managed-ssh-$id'));
Future<void> tapControl(WidgetTester tester, String id) async {
  await tester.ensureVisible(control(id));
  await tester.pumpAndSettle();
  await tester.tap(control(id));
  await tester.pumpAndSettle();
}

Future<
  ({
    support.FakeForward forward,
    support.FakeChannel channel,
    ManagedSshConnectionController controller,
  })
>
mount(
  WidgetTester tester,
  FakeGeneratedStore store, {
  VoidCallback? cancel,
  GlobalKey? captureKey,
}) async {
  final forward = support.FakeForward();
  final channel = support.FakeChannel();
  final controller = ManagedSshConnectionController(forward, channel);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        managedSshConnectionControllerProvider.overrideWithValue(controller),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RepaintBoundary(
          key: captureKey,
          child: Scaffold(
            body: ManagedSshConnectionPanel(
              generatedKeyStore: store,
              onCancel: cancel ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() {
    controller.dispose();
    channel.dispose();
  });
  return (forward: forward, channel: channel, controller: controller);
}

Future<void> generate(WidgetTester tester) async {
  await tapControl(tester, 'auth-private-key');
  await tapControl(tester, 'generate-key');
  await tapControl(tester, 'generate-confirm');
}

Future<void> connect(WidgetTester tester) async {
  for (final entry in {
    'host': 'ssh.example.invalid',
    'username': 'tester',
    'agent-token': 'synthetic-agent-token',
  }.entries) {
    await tester.ensureVisible(control(entry.key));
    await tester.enterText(control(entry.key), entry.value);
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final button = find.widgetWithText(FilledButton, 'Connect via SSH');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'production panel exposes deliberate generation only in private-key mode',
    (tester) async {
      final store = FakeGeneratedStore();
      await mount(tester, store);
      expect(control('generate-key'), findsNothing);
      expect(store.generates, 0);
      expect(store.loads, 0);
      await tapControl(tester, 'auth-private-key');
      expect(control('generate-key'), findsOneWidget);
      expect(store.generates, 0);
      expect(store.loads, 0);
    },
  );

  for (final dismiss in ['cancel', 'keyboard', 'barrier']) {
    testWidgets(
      'consent $dismiss defaults to refusal with zero store effects',
      (tester) async {
        final store = FakeGeneratedStore();
        await mount(tester, store);
        await tapControl(tester, 'auth-private-key');
        await tapControl(tester, 'generate-key');
        final strings = AppLocalizations.of(
          tester.element(find.byType(ManagedSshConnectionForm)),
        );
        expect(
          find.text(strings.managedSshGenerateKeyConsentBody),
          findsOneWidget,
        );
        expect(
          tester.widget<TextButton>(control('generate-cancel')).autofocus,
          isTrue,
        );
        if (dismiss == 'cancel') {
          await tapControl(tester, 'generate-cancel');
        } else if (dismiss == 'keyboard') {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
        } else {
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
        }
        expect(find.byType(AlertDialog), findsNothing);
        expect(store.generates, 0);
        expect(store.loads, 0);
        expect(store.retained, isNull);
        expect(control('copy-public-key'), findsNothing);
      },
    );
  }

  testWidgets(
    'generated key is the actual managed-forward private callback, public clipboard only',
    (tester) async {
      final store = FakeGeneratedStore();
      final app = await mount(tester, store);
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
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
      await generate(tester);
      final key = store.retained!;
      expect(store.generates, 1);
      expect(find.text(key.fingerprint), findsOneWidget);
      expect(find.text(key.publicKey), findsOneWidget);
      expect(find.textContaining('PRIVATE KEY'), findsNothing);
      expect(control('passphrase'), findsNothing);
      final staleCopy = tester
          .widget<OutlinedButton>(control('copy-public-key'))
          .onPressed!;
      await tapControl(tester, 'copy-public-key');
      expect(clipboard, [key.publicKey]);
      await connect(tester);
      expect(app.forward.credentials, isNotNull);
      expect(await app.forward.credentials!.privateKey!(), key.privatePem);
      expect(app.forward.credentials!.password, isNull);
      expect(
        app.channel.token,
        isNull,
        reason: 'Agent token is not SSH authentication',
      );
      expect(
        control('copy-public-key'),
        findsNothing,
        reason: 'Attempt drops form private selection',
      );
      staleCopy();
      await tester.pumpAndSettle();
      expect(clipboard, [key.publicKey]);
      app.forward.ready();
      await tester.pumpAndSettle();
      expect(app.channel.token, 'synthetic-agent-token');
      expect(store.retained, same(key));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'form drops private selection at submission before callback completion',
    (tester) async {
      final store = FakeGeneratedStore()..retained = fixture();
      await mount(tester, store);
      final production = tester.widget<ManagedSshConnectionForm>(
        find.byType(ManagedSshConnectionForm),
      );
      final pending = Completer<void>();
      SshConnectionRequest? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManagedSshConnectionForm(
              labels: production.labels,
              generatedKeyLabels: production.generatedKeyLabels,
              generatedKeyStore: store,
              onSubmit: (input) {
                submitted = input;
                return pending.future;
              },
              onCancel: () {},
            ),
          ),
        ),
      );
      await tapControl(tester, 'auth-private-key');
      await tapControl(tester, 'use-generated-key');
      await connect(tester);
      expect(submitted?.privateKey == store.retained!.privatePem, isTrue);
      expect(control('generated-public-key'), findsNothing);
      expect(control('copy-public-key'), findsNothing);
      pending.complete();
      await tester.pumpAndSettle();
      expect(store.retained, isNotNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'canceling selected generated key discloses retention and revokes captured copy',
    (tester) async {
      final store = FakeGeneratedStore();
      await mount(tester, store);
      await generate(tester);
      final key = store.retained!;
      final copy = tester
          .widget<OutlinedButton>(control('copy-public-key'))
          .onPressed!;
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
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
      final cancel = find.widgetWithText(TextButton, 'Cancel');
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      final strings = AppLocalizations.of(
        tester.element(find.byType(ManagedSshConnectionForm)),
      );
      expect(
        find.text(strings.managedSshGenerateKeyConsentBody),
        findsOneWidget,
      );
      copy();
      await tester.pumpAndSettle();
      expect(copied, isEmpty);
      expect(control('copy-public-key'), findsNothing);
      expect(store.retained, same(key));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'reopened production panel deliberately reuses saved key without generation or overwrite',
    (tester) async {
      final store = FakeGeneratedStore()..retained = fixture();
      await mount(tester, store);
      expect(store.loads, 0);
      await tapControl(tester, 'auth-private-key');
      expect(control('copy-public-key'), findsNothing);
      await tapControl(tester, 'use-generated-key');
      expect(store.generates, 0);
      expect(store.loads, 1);
      final key = store.retained;
      await tester.pumpWidget(const SizedBox());
      final app = await mount(tester, store);
      await tapControl(tester, 'auth-private-key');
      expect(store.loads, 1);
      expect(control('generated-public-key'), findsNothing);
      await tapControl(tester, 'use-generated-key');
      await connect(tester);
      expect(await app.forward.credentials!.privateKey!(), key!.privatePem);
      expect(store.generates, 0);
      expect(store.loads, 2);
      expect(store.retained, same(key));
      app.forward.ready();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final action in ['generate-key', 'use-generated-key']) {
    testWidgets(
      '$action secure storage failure is sanitized and cannot submit',
      (tester) async {
        final store = FakeGeneratedStore()..fail = true;
        final app = await mount(tester, store);
        await tapControl(tester, 'auth-private-key');
        await tapControl(tester, action);
        if (action == 'generate-key') {
          await tapControl(tester, 'generate-confirm');
        }
        final strings = AppLocalizations.of(
          tester.element(find.byType(ManagedSshConnectionForm)),
        );
        expect(
          find.text(strings.managedSshGeneratedKeyStorageFailure),
          findsOneWidget,
        );
        expect(find.textContaining('synthetic secret'), findsNothing);
        expect(control('copy-public-key'), findsNothing);
        await connect(tester);
        expect(app.forward.credentials, isNull);
        expect(app.channel.token, isNull);
        expect(store.retained, isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final abandon in ['cancel', 'password', 'dispose']) {
    testWidgets(
      'late generated result after $abandon remains retained but never selects or connects',
      (tester) async {
        final store = FakeGeneratedStore()
          ..pending = Completer<ManagedSshGeneratedKey>();
        final app = await mount(tester, store);
        await generate(tester);
        expect(store.generates, 1);
        expect(
          tester.widget<OutlinedButton>(control('generate-key')).onPressed,
          isNull,
        );
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        if (abandon == 'password') {
          await tapControl(tester, 'auth-password');
        } else if (abandon == 'cancel') {
          final cancel = find.widgetWithText(TextButton, 'Cancel');
          await tester.ensureVisible(cancel);
          await tester.tap(cancel);
          await tester.pumpAndSettle();
        } else {
          await tester.pumpWidget(const SizedBox());
        }
        store.pending!.complete(fixture());
        await tester.pumpAndSettle();
        expect(store.retained, isNotNull);
        expect(control('copy-public-key'), findsNothing);
        expect(control('generated-public-key'), findsNothing);
        expect(app.forward.credentials, isNull);
        expect(app.channel.token, isNull);
        if (abandon != 'dispose') {
          final strings = AppLocalizations.of(
            tester.element(find.byType(ManagedSshConnectionForm)),
          );
          expect(
            find.text(strings.managedSshGenerateKeyConsentBody),
            findsOneWidget,
            reason: 'Persistence is disclosed, not falsely rolled back',
          );
          await tapControl(tester, 'auth-private-key');
          await connect(tester);
          expect(app.forward.credentials, isNull);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'compact and wide production generated public view renders without private input',
    (tester) async {
      if (Platform.environment['WING_CAPTURE_GENERATED_KEY_UI'] != '1') return;
      final sdk = Platform.environment['FLUTTER_ROOT'];
      expect(sdk, isNotNull, reason: 'Capture requires resolved SDK fonts');
      await tester.runAsync(() async {
        final loader = FontLoader('Roboto')
          ..addFont(
            File(
              '$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
            ).readAsBytes().then(ByteData.sublistView),
          );
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            File(
              '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytes().then(ByteData.sublistView),
          );
        await loader.load();
        await icons.load();
      });
      for (final size in [const Size(390, 844), const Size(960, 900)]) {
        await tester.binding.setSurfaceSize(size);
        final boundary = GlobalKey();
        final store = FakeGeneratedStore();
        await mount(tester, store, captureKey: boundary);
        await generate(tester);
        await tester.ensureVisible(control('generated-public-key'));
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(find.text(store.retained!.publicKey), findsOneWidget);
        expect(find.textContaining('PRIVATE KEY'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('.task-evidence/generated-ssh-key-ui')
            ..createSync(recursive: true);
          await File(
            '${dir.path}/generated-${size.width.toInt()}.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox());
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}
