import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/channel/hermes_channel_state.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/core/hermes/models/hermes_profile.dart';

import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/security/wing_redaction.dart';
import 'package:wing/shared/widgets/app_shell.dart';
import 'package:wing/shared/widgets/app_shell_desktop_style.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';
import '../../features/hermes_chat/support/fake_hermes_gateway_directory.dart';
import 'app_shell_focus_traversal_test.dart' as focus;
import 'app_shell_navigation_groups_test.dart' as navigation;

final footer = find.byKey(const ValueKey('desktop-profile-footer'));
final manage = find.byKey(const ValueKey('desktop-manage-profiles'));
final profileValue = find.byKey(const ValueKey('desktop-profile-value'));

class DisplayChannel extends FakeHermesChannel {
  DisplayChannel(this.current) : super(sessions: const []);
  HermesChannelState current;
  @override
  HermesChannelState get state => current;
  void change(HermesChannelState value) {
    current = value;
    notifyListeners();
  }
}

HermesChannelState displayState({
  String? id = 'a',
  String name = 'Profile A',
  List<HermesProfile>? profiles,
}) => HermesChannelState(
  status: HermesConnectionStatus.connected,
  selectedProfileId: id,
  profiles:
      profiles ??
      [HermesProfile(id: id ?? 'a', displayName: name, revision: 'r1')],
  capabilities: HermesCapabilityDocument.fromJson({
    'schema_version': 1,
    'auth': {'required': true, 'granted_scopes': <String>[]},
    'endpoints': {
      'profiles': {
        'method': 'GET',
        'path': '/api/profiles',
        'required_scopes': ['profiles:read'],
      },
      'profile_create': {
        'method': 'POST',
        'path': '/api/profiles',
        'required_scopes': ['profiles:write'],
      },
    },
  }),
);

Future<GoRouter> pumpFooter(
  WidgetTester tester,
  DisplayChannel channel, {
  double scale = 1,
  bool realDestination = false,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(channel.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.tools,
    routes: [
      ShellRoute(
        builder: (_, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.tools,
            builder: (_, _) =>
                const Scaffold(body: TextField(key: ValueKey('draft'))),
          ),
          GoRoute(
            path: AppRoutes.profiles,
            builder: (_, _) => realDestination
                ? const ProfilesScreen()
                : const Scaffold(body: Text('Profiles destination')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesGatewayDirectoryProvider.overrideWith((_) {
          if (!realDestination) {
            throw StateError('Passive footer constructed a directory');
          }
          return directoryFor(
            configs: const [],
            loader: FakeGatewaySummaryLoader(const {}),
            activeChannel: channel,
          );
        }),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void expectDisplay(WidgetTester tester, String value) {
  expect(tester.widget<Text>(profileValue).data, value);
  expect(
    find.descendant(
      of: footer,
      matching: find.byTooltip('Manage profiles — Profile: $value'),
    ),
    findsOneWidget,
  );
  expect(
    tester.getSemantics(manage).label,
    'Manage profiles — Profile: $value',
  );
}

void main() {
  testWidgets(
    'footer follows only current projection through owners, fallback and replacement',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      final semantics = tester.ensureSemantics();
      final channel = DisplayChannel(displayState());
      await pumpFooter(tester, channel);
      expectDisplay(tester, 'Profile A');
      for (final entry in [
        (displayState(id: 'b', name: 'Profile B'), 'Profile B'),
        (displayState(), 'Profile A'),
        (
          displayState(
            name: 'Replacement host',
          ).copyWith(connectedBaseUrl: 'http://127.0.0.1:18643'),
          'Replacement host',
        ),
        (displayState(id: 'missing', profiles: const []), 'missing'),
        (displayState(name: '  '), 'a'),
        (
          displayState(
            id: null,
            profiles: const [
              HermesProfile(
                id: 'first',
                displayName: 'Not selected',
                revision: 'r',
              ),
              HermesProfile(
                id: 'default',
                displayName: 'Not selected either',
                revision: 'r',
              ),
            ],
          ),
          'default',
        ),
        (
          displayState(
            id: null,
            profiles: const [
              HermesProfile(
                id: 'first',
                displayName: 'Not selected',
                revision: 'r',
              ),
            ],
          ),
          'first',
        ),
        (displayState(id: null, profiles: const []), 'Not loaded'),
        (
          displayState().copyWith(status: HermesConnectionStatus.disconnected),
          'Not loaded',
        ),
        (displayState(id: 'b', name: 'Profile B'), 'Profile B'),
      ]) {
        channel.change(entry.$1);
        await tester.pumpAndSettle();
        expectDisplay(tester, entry.$2);
      }
      final replacement = DisplayChannel(displayState(name: 'Replacement A'));
      addTearDown(replacement.dispose);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );
      container.updateOverrides([
        hermesChannelProvider.overrideWithValue(replacement),
        hermesGatewayDirectoryProvider.overrideWith(
          (_) => throw StateError('Passive footer constructed a directory'),
        ),
      ]);
      await tester.pumpAndSettle();
      expectDisplay(tester, 'Replacement A');
      channel.change(displayState(name: 'Obsolete owner'));
      await tester.pumpAndSettle();
      expectDisplay(tester, 'Replacement A');
      container.updateOverrides([
        hermesChannelProvider.overrideWithValue(channel),
        hermesGatewayDirectoryProvider.overrideWith(
          (_) => throw StateError('Passive footer constructed a directory'),
        ),
      ]);
      channel.change(displayState());
      await tester.pumpAndSettle();
      expectDisplay(tester, 'Profile A');
      navigation.expectNoChannelCalls(channel);
      navigation.expectNoChannelCalls(replacement);
      semantics.dispose();
    },
  );

  testWidgets(
    'footer bounds redacted value tooltip and semantics in both modes',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      final semantics = tester.ensureSemantics();
      // Sensitive-looking values are generated dummy markers, never runtime data.
      const name = 'Profile /home/example/private token=dummy';
      final channel = DisplayChannel(displayState(name: name));
      await pumpFooter(tester, channel);
      final safe = wingRedactedPreview(name, maxLength: 80);
      expect(safe, 'Profile [redacted-path] token=[redacted]');
      expectDisplay(tester, safe);
      expect(tester.getSemantics(profileValue).label, safe);
      await tester.tap(find.byKey(const ValueKey('desktop-sidebar-toggle')));
      await tester.pumpAndSettle();
      expect(profileValue, findsNothing);
      expect(
        tester.getSemantics(manage).label,
        'Manage profiles — Profile: $safe',
      );
      expect(
        find.descendant(
          of: footer,
          matching: find.byTooltip('Manage profiles — Profile: $safe'),
        ),
        findsOneWidget,
      );
      channel.change(displayState(name: List.filled(120, 'a').join()));
      await tester.pumpAndSettle();
      final bounded =
          'Manage profiles — Profile: ${List.filled(80, 'a').join()}…';
      expect(tester.getSemantics(manage).label, bounded);
      await tester.tap(find.byKey(const ValueKey('desktop-sidebar-toggle')));
      await tester.pumpAndSettle();
      expectDisplay(
        tester,
        wingRedactedPreview(
          channel.state.selectedProfile!.displayName,
          maxLength: 80,
        ),
      );
      navigation.expectNoChannelCalls(channel);
      semantics.dispose();
    },
  );

  for (final compact in [false, true]) {
    for (final activation in ['pointer', 'enter', 'space']) {
      testWidgets(
        'navigation only once, $activation compact=$compact, denied grants remain denied',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 900);
          final semantics = tester.ensureSemantics();
          final channel = DisplayChannel(displayState());
          final original = channel.state;
          final router = await pumpFooter(
            tester,
            channel,
            realDestination: true,
          );
          await tester.enterText(
            find.byKey(const ValueKey('draft')),
            'volatile draft',
          );
          if (compact) {
            await tester.tap(
              find.byKey(const ValueKey('desktop-sidebar-toggle')),
            );
            await tester.pumpAndSettle();
          }
          var navigations = 0;
          router.routerDelegate.addListener(() {
            navigations++;
          });
          if (activation == 'pointer') {
            await tester.tap(manage);
          } else {
            await navigation.reach(tester, manage);
            await tester.sendKeyEvent(
              activation == 'enter'
                  ? LogicalKeyboardKey.enter
                  : LogicalKeyboardKey.space,
            );
          }
          await tester.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.path,
            AppRoutes.profiles,
          );
          expect(navigations, 1);
          expect(find.byType(ProfilesScreen), findsOneWidget);
          expect(find.text('New Profile'), findsNothing);
          expect(find.byKey(const ValueKey('profiles-search')), findsNothing);
          expect(find.byTooltip('Edit Profile A'), findsNothing);
          expect(find.byType(Dialog), findsNothing);
          expect(channel.state, same(original));
          navigation.expectNoChannelCalls(channel);
          expect(channel.readProfileSoulCalls, isEmpty);
          channel.change(
            original.copyWith(status: HermesConnectionStatus.disconnected),
          );
          await tester.pumpAndSettle();
          channel.change(original);
          await tester.pumpAndSettle();
          expect(navigations, 1, reason: 'Reconnect never replays navigation');
          router.go(AppRoutes.tools);
          await tester.pumpAndSettle();
          // Ordinary go routing recreates this route-local editor; footer adds no draft store.
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .text,
            isEmpty,
          );
          navigation.expectNoChannelCalls(channel);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }

  testWidgets(
    'footer paints focus and reverses route boundary after scrolling collapse resize at 2x/360',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 360);
      final semantics = tester.ensureSemantics();
      final channel = DisplayChannel(displayState());
      await pumpFooter(tester, channel, scale: 2);
      for (final compact in [false, true, false]) {
        if (compact ||
            tester
                    .getSize(find.byKey(const ValueKey('desktop-sidebar')))
                    .width ==
                64) {
          await tester.tap(
            find.byKey(const ValueKey('desktop-sidebar-toggle')),
          );
          await tester.pumpAndSettle();
        }
        final scrollable = find
            .descendant(
              of: find.byKey(const ValueKey('desktop-sidebar')),
              matching: find.byType(Scrollable),
            )
            .first;
        final position = tester.state<ScrollableState>(scrollable).position;
        expect(position.maxScrollExtent, greaterThan(0));
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
        await navigation.reach(tester, manage);
        await tester.pump(const Duration(milliseconds: 350));
        expect(manage.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(manage);
        expect(bounds.width, greaterThanOrEqualTo(48));
        expect(bounds.height, greaterThanOrEqualTo(48));
        final material = tester.widget<Material>(
          find.descendant(of: manage, matching: find.byType(Material)).first,
        );
        final materialSize = tester.getSize(
          find.descendant(of: manage, matching: find.byType(Material)).first,
        );
        expect(materialSize.width, greaterThanOrEqualTo(48));
        expect(materialSize.height, greaterThanOrEqualTo(48));
        final shape = material.shape! as RoundedRectangleBorder;
        final style = AppShellDesktopStyle.forBrightness(Brightness.light);
        expect(shape.side.color, style.secondary);
        final pixels = (await tester.runAsync(() async {
          final image =
              await (tester.binding.renderViews.first.debugLayer!
                      as OffsetLayer)
                  .toImage(const Rect.fromLTWH(0, 0, 1280, 360));
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return data;
        }))!;
        var outlinePixels = 0;
        for (var y = bounds.top.toInt(); y < bounds.top.toInt() + 3; y++) {
          for (
            var x = bounds.left.toInt() + 12;
            x < bounds.right.toInt() - 12;
            x++
          ) {
            final offset = (y * 1280 + x) * 4;
            if (pixels.getUint8(offset) == 0x55 &&
                pixels.getUint8(offset + 1) == 0x55 &&
                pixels.getUint8(offset + 2) == 0x55) {
              outlinePixels++;
            }
          }
        }
        expect(outlinePixels, greaterThanOrEqualTo(24));
        final focused = FocusManager.instance.primaryFocus;
        await focus.tab(tester);

        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
        await focus.tab(tester, backwards: true);
        expect(FocusManager.instance.primaryFocus, same(focused));
        await focus.tab(tester, backwards: true);
        expect(
          navigation.flag(
            tester,
            find.bySemanticsLabel('Settings'),
            focused: true,
          ),
          isTrue,
        );
        await focus.tab(tester);
        expect(FocusManager.instance.primaryFocus, same(focused));
        tester.view.physicalSize = const Size(900, 360);
        await tester.pumpAndSettle();
        await focus.tab(tester);
        await focus.tab(tester, backwards: true);
        expect(FocusManager.instance.primaryFocus, same(focused));
        tester.view.physicalSize = const Size(1280, 360);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      navigation.expectNoChannelCalls(channel);
      semantics.dispose();
    },
  );
}
