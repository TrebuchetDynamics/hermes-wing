import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/enrollment/screens/hermes_enrollment_screen.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_add_screen.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/features/hermes_chat/widgets/localized_managed_ssh_connection_form.dart';
import 'package:wing/theme/wing_theme.dart';

import '../support/fake_hermes_channel.dart';
import '../widgets/managed_ssh_generated_key_ui_test.dart' as generated;
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_ssh_quick_connect_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

Finder control(String name) => find.byKey(ValueKey(name));

Future<void> capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (Platform.environment['WING_CAPTURE_COMPACT_CONNECTIONS'] != '1') return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('.task-evidence/compact-connections')
      ..createSync(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<GlobalKey> mount(
    WidgetTester tester,
    Widget screen, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);
    if (Platform.environment['WING_CAPTURE_COMPACT_CONNECTIONS'] == '1') {
      await tester.runAsync(() async {
        final sdk = Platform.environment['FLUTTER_ROOT']!;
        for (final family in ['sans-serif', 'Roboto']) {
          await (FontLoader(family)..addFont(
                File(
                  '$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
                ).readAsBytes().then(ByteData.sublistView),
              ))
              .load();
        }
        await (FontLoader('MaterialIcons')..addFont(
              File(
                '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
              ).readAsBytes().then(ByteData.sublistView),
            ))
            .load();
      });
    }
    final channel = FakeHermesChannel.disconnected();
    final store = FakeHermesEndpointStore();
    final directory = HermesGatewayDirectory(
      store: store,
      cache: FakeGatewayContactCache(),
      loader: FakeGatewaySummaryLoader({}),
      activeChannel: channel,
    );
    addTearDown(channel.dispose);
    final boundary = GlobalKey();
    final capturing =
        Platform.environment['WING_CAPTURE_COMPACT_CONNECTIONS'] == '1';
    // Widget-test component defaults use Ahem; resolve the native font for captures.
    final captureTheme = wingDarkTheme.copyWith(
      chipTheme: wingDarkTheme.chipTheme.copyWith(
        labelStyle: wingDarkTheme.chipTheme.labelStyle?.copyWith(
          fontFamily: 'sans-serif',
        ),
      ),
      listTileTheme: wingDarkTheme.listTileTheme.copyWith(
        titleTextStyle: wingDarkTheme.listTileTheme.titleTextStyle?.copyWith(
          fontFamily: 'sans-serif',
        ),
        subtitleTextStyle: wingDarkTheme.listTileTheme.subtitleTextStyle
            ?.copyWith(fontFamily: 'sans-serif'),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sshQuickConnectStoreProvider.overrideWithValue(
            FakeSshQuickConnectStore(),
          ),
          hermesChannelProvider.overrideWith((_) => channel),
          hermesEndpointStoreProvider.overrideWithValue(store),
          hermesGatewayDirectoryProvider.overrideWith((_) => directory),
          hermesVoiceCaptureServiceProvider.overrideWithValue(null),
          hermesTextToSpeechServiceProvider.overrideWithValue(null),
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: capturing ? captureTheme : wingDarkTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (Platform.environment['WING_CAPTURE_COMPACT_CONNECTIONS'] == '1') {
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/branding/hermes-emblem.png'),
          tester.element(find.byType(MaterialApp)),
        ),
      );
      await tester.pumpAndSettle();
    }
    return boundary;
  }

  testWidgets(
    'Android welcome has one primary SSH action before secondary setup',
    (tester) async {
      final boundary = await mount(tester, const HermesEnrollmentScreen());
      expect(control('hermes-welcome-ssh'), findsOneWidget);
      expect(tester.widget(control('hermes-welcome-ssh')), isA<FilledButton>());
      expect(
        tester.widget(control('hermes-welcome-remote')),
        isA<OutlinedButton>(),
      );
      final phone = control('hermes-enrollment-local-setup');
      expect(tester.widget(phone), isA<OutlinedButton>());
      expect(
        find.ancestor(of: phone, matching: find.byType(Card)),
        findsNothing,
      );
      expect(
        tester.getSize(phone).width,
        tester.getSize(control('hermes-welcome-remote')).width,
      );
      expect(tester.getSize(phone).height, greaterThanOrEqualTo(48));
      expect(find.text('HERMES WING'), findsNothing);
      expect(find.textContaining('self-improving AI assistant'), findsNothing);
      expect(
        tester.getTopLeft(control('hermes-welcome-ssh')).dy,
        lessThan(tester.getTopLeft(control('hermes-welcome-remote')).dy),
      );
      await capture(tester, boundary, 'welcome-390');
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final width in [320.0, 1280.0]) {
    testWidgets(
      'Termux welcome button wraps at 200% text on $width',
      (tester) async {
        final boundary = await mount(
          tester,
          const HermesEnrollmentScreen(),
          width: width,
          scale: 2,
        );
        final phone = control('hermes-enrollment-local-setup');
        await tester.ensureVisible(phone);
        await tester.pumpAndSettle();
        expect(tester.widget(phone), isA<OutlinedButton>());
        expect(tester.getSize(phone).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSize(phone).width,
          tester.getSize(control('hermes-welcome-remote')).width,
        );
        expect(tester.getBottomRight(phone).dx, lessThanOrEqualTo(width - 24));
        await capture(tester, boundary, 'welcome-termux-$width-2x');
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'SSH entry keeps a single heading and clears navigation/keyboard at $scale text',
      (tester) async {
        final boundary = await mount(
          tester,
          const HermesAddScreen(mode: HermesConnectionMode.ssh),
          scale: scale,
        );
        expect(find.text('Add Hermes'), findsOneWidget);
        final viewport = find
            .ancestor(
              of: control('hermes-primary-connection-modes'),
              matching: find.byType(SingleChildScrollView),
            )
            .first;
        expect(tester.getBottomRight(viewport).dy, lessThanOrEqualTo(820));
        for (final mode in ['ssh', 'remote', 'local']) {
          expect(
            tester
                .widget<ChoiceChip>(control('hermes-connection-mode-$mode'))
                .showCheckmark,
            isFalse,
          );
        }
        if (scale == 1) {
          final hostGroup = find
              .ancestor(
                of: control('managed-ssh-host'),
                matching: find.byType(Padding),
              )
              .first;
          final portGroup = find
              .ancestor(
                of: control('managed-ssh-ssh-port'),
                matching: find.byType(Padding),
              )
              .first;
          expect(
            tester.getTopLeft(hostGroup).dy,
            tester.getTopLeft(portGroup).dy,
          );
          await capture(tester, boundary, 'ssh-390');
        }
        final cancel = find.widgetWithText(TextButton, 'Cancel');
        await tester.ensureVisible(cancel);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(cancel).dy, lessThanOrEqualTo(820));
        tester.view.padding = const FakeViewPadding(top: 24);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final token = control('managed-ssh-agent-token');
        await tester.ensureVisible(token);
        await tester.tap(token);
        await tester.pumpAndSettle();
        await tester.ensureVisible(cancel);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(cancel).dy, lessThanOrEqualTo(544));
        if (scale == 1) await capture(tester, boundary, 'ssh-keyboard-390');
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  testWidgets(
    'selected SSH key stays compact with explicit public details',
    (tester) async {
      final store = generated.FakeGeneratedStore()
        ..retained = generated.fixture();
      final boundary = await mount(
        tester,
        Scaffold(
          appBar: AppBar(title: const Text('Add Hermes')),
          body: SafeArea(
            top: false,
            child: LocalizedManagedSshConnectionForm(
              generatedKeyStore: store,
              onSubmit: (_) async {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await generated.tapControl(tester, 'auth-private-key');
      await generated.tapControl(tester, 'use-generated-key');
      expect(control('managed-ssh-generated-public-key'), findsNothing);
      expect(control('managed-ssh-copy-public-key'), findsOneWidget);
      await capture(tester, boundary, 'ssh-key-390');
      await generated.tapControl(tester, 'key-details');
      expect(find.text(store.retained!.publicKey), findsOneWidget);
      expect(find.text(store.retained!.fingerprint), findsOneWidget);
      expect(find.textContaining('PRIVATE KEY'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Termux starts concise but retains install warnings before documentation',
    (tester) async {
      final boundary = await mount(
        tester,
        const HermesAddScreen(mode: HermesConnectionMode.local),
      );
      expect(find.text('Add Hermes'), findsOneWidget);
      expect(control('platform-local-existing-agent'), findsOneWidget);
      expect(control('platform-local-package-warning'), findsNothing);
      expect(control('platform-local-agent-docs'), findsNothing);
      await capture(tester, boundary, 'termux-390');
      await tester.tap(control('platform-local-setup-details'));
      await tester.pumpAndSettle();
      expect(control('platform-local-package-warning'), findsOneWidget);
      expect(control('platform-local-agent-docs'), findsOneWidget);
      expect(
        tester.getTopLeft(control('platform-local-package-warning')).dy,
        lessThan(tester.getTopLeft(control('platform-local-agent-docs')).dy),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
