import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/app.dart';
import 'package:wing/app/desktop_host_command_listener.dart';
import 'package:wing/router/app_router.dart';
import 'package:wing/router/app_routes.dart';

void main() {
  testWidgets('WingApp installs the native listener and opens Settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WingApp());
    await tester.pump();

    expect(find.byType(DesktopHostCommandListener), findsOneWidget);
    await _sendNativeMethodCall(WingDesktopHostCommands.openSettings);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('native settings command selects the existing Settings route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.hermes,
      routes: [
        GoRoute(
          path: AppRoutes.hermes,
          builder: (context, state) => const Scaffold(body: Text('Hermes')),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: DesktopHostCommandListener(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hermes'), findsOneWidget);

    await _sendNativeMethodCall(WingDesktopHostCommands.openSettings);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.settings);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('unknown native commands fail closed without changing routes', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.hermes,
      routes: [
        GoRoute(
          path: AppRoutes.hermes,
          builder: (context, state) => const Scaffold(body: Text('Hermes')),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: DesktopHostCommandListener(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _sendNativeMethodCall('unadvertisedCommand');
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.hermes);
    expect(find.text('Hermes'), findsOneWidget);
  });

  testWidgets('Control/Command comma select Settings without server work', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.hermes,
      routes: [
        GoRoute(
          path: AppRoutes.hermes,
          builder: (context, state) =>
              const Scaffold(body: TextField(autofocus: true)),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: DesktopHostCommandListener(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.settings);

    router.go(AppRoutes.hermes);
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.settings);
  });

  test(
    'desktop hosts retain canonical Hermes Wing identity and menu wiring',
    () {
      final appDelegate = File(
        'macos/Runner/AppDelegate.swift',
      ).readAsStringSync();
      final mainMenu = File(
        'macos/Runner/Base.lproj/MainMenu.xib',
      ).readAsStringSync();
      final macConfig = File(
        'macos/Runner/Configs/AppInfo.xcconfig',
      ).readAsStringSync();
      final macInfo = File('macos/Runner/Info.plist').readAsStringSync();
      final linuxConfig = File('linux/CMakeLists.txt').readAsStringSync();
      final linuxWindow = File(
        'linux/runner/my_application.cc',
      ).readAsStringSync();
      final windowsMain = File('windows/runner/main.cpp').readAsStringSync();
      final windowsWindow = File(
        'windows/runner/flutter_window.cpp',
      ).readAsStringSync();
      final windowsCommands = File(
        'windows/runner/desktop_host_commands.h',
      ).readAsStringSync();
      final windowsResources = File(
        'windows/runner/Runner.rc',
      ).readAsStringSync();
      final workflow = File(
        '.github/workflows/hermes-platform-smoke.yml',
      ).readAsStringSync();

      expect(appDelegate, contains(WingDesktopHostCommands.channelName));
      expect(
        appDelegate,
        contains('invokeMethod("${WingDesktopHostCommands.openSettings}"'),
      );
      expect(mainMenu, contains('title="Settings…" keyEquivalent=","'));
      expect(mainMenu, contains('selector="openSettings:"'));
      expect(mainMenu, contains('selector="orderFrontStandardAboutPanel:"'));
      expect(mainMenu, contains('selector="performMiniaturize:"'));
      expect(mainMenu, contains('selector="performZoom:"'));
      expect(mainMenu, contains('selector="toggleFullScreen:"'));
      expect(mainMenu, contains('target="Voe-Tx-rLC"'));
      expect(macConfig, contains('PRODUCT_NAME = wing'));
      expect(
        macConfig,
        contains(
          'PRODUCT_BUNDLE_IDENTIFIER = com.trebuchetdynamics.hermes.wing',
        ),
      );
      expect(
        macInfo,
        contains(
          '<key>CFBundleDisplayName</key>\n\t<string>Hermes Wing</string>',
        ),
      );
      expect(
        macInfo,
        contains('<key>CFBundleName</key>\n\t<string>Hermes Wing</string>'),
      );
      expect(
        linuxConfig,
        contains('set(APPLICATION_ID "com.trebuchetdynamics.hermes.wing")'),
      );
      expect(linuxWindow, contains('"Hermes Wing"'));
      expect(linuxWindow, contains(WingDesktopHostCommands.channelName));
      expect(linuxWindow, contains('fl_method_channel_invoke_method'));
      expect(
        linuxWindow,
        contains('"${WingDesktopHostCommands.openSettings}"'),
      );
      expect(
        linuxWindow,
        contains('gtk_menu_item_new_with_label("Settings…")'),
      );
      expect(linuxWindow, contains('GDK_KEY_comma'));
      expect(linuxWindow, contains('GDK_CONTROL_MASK'));
      expect(linuxWindow, contains('gtk_show_about_dialog'));
      expect(linuxWindow, contains('"About Hermes Wing"'));
      expect(linuxWindow, contains('gtk_window_iconify'));
      expect(linuxWindow, contains('gtk_window_is_maximized'));
      expect(linuxWindow, contains('"Maximize / Restore"'));
      expect(linuxWindow, contains('GDK_WINDOW_STATE_FULLSCREEN'));
      expect(linuxWindow, contains('GDK_KEY_F11'));
      expect(
        linuxWindow,
        contains('gtk_widget_set_size_request(GTK_WIDGET(window), 360, 480)'),
      );
      expect(windowsMain, contains('window.Create(L"Hermes Wing"'));
      expect(windowsMain, contains('VK_F11'));
      expect(windowsMain, contains('VK_OEM_COMMA'));
      expect(windowsMain, contains('TranslateAccelerator'));
      expect(windowsCommands, contains(WingDesktopHostCommands.channelName));
      expect(
        windowsCommands,
        contains('"${WingDesktopHostCommands.openSettings}"'),
      );
      expect(windowsWindow, contains('CreateApplicationMenu'));
      expect(windowsWindow, contains('L"Settings\\u2026\\tCtrl+,"'));
      expect(windowsWindow, contains('InvokeMethod'));
      expect(
        windowsWindow,
        contains('desktop_host_commands::kOpenSettingsMethod'),
      );
      expect(windowsWindow, contains('nullptr'));
      expect(windowsCommands, contains('kShowAboutCommand'));
      expect(windowsCommands, contains('kMinimizeWindowCommand'));
      expect(windowsCommands, contains('kToggleMaximizeWindowCommand'));
      expect(windowsCommands, contains('kToggleFullScreenCommand'));
      expect(windowsWindow, contains('L"About Hermes Wing"'));
      expect(windowsWindow, contains('MessageBoxW'));
      expect(windowsWindow, contains('ShowWindow(hwnd, SW_MINIMIZE)'));
      expect(
        windowsWindow,
        contains('IsZoomed(hwnd) ? SW_RESTORE : SW_MAXIMIZE'),
      );
      expect(windowsWindow, contains('ToggleFullScreen'));
      expect(windowsWindow, contains('WS_OVERLAPPEDWINDOW'));
      expect(windowsWindow, contains('MonitorFromWindow'));
      expect(windowsResources, contains('VALUE "ProductName", "Hermes Wing"'));
      expect(
        workflow,
        contains('build/macos/Build/Products/Debug/wing.app/**'),
      );
    },
  );
}

Future<void> _sendNativeMethodCall(String method) async {
  final completer = Completer<ByteData?>();
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        WingDesktopHostCommands.channelName,
        const StandardMethodCodec().encodeMethodCall(MethodCall(method)),
        completer.complete,
      );
  await completer.future;
}
