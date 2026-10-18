import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/router/app_routes.dart';
import 'package:wing/shared/widgets/app_shell.dart';
import 'package:wing/theme/wing_theme.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [390.0, 768.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('real Chat shell at $width and ${scale}x text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final captureDir = Platform.environment['WING_SHELL_CAPTURE_DIR'];
        if (captureDir != null) {
          await tester.runAsync(() async {
            final sdk = Platform.environment['FLUTTER_ROOT']!;
            final bytes = await File(
              '$sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
            ).readAsBytes();
            for (final family in ['Segoe UI', 'Ahem', 'Roboto']) {
              final loader = FontLoader(family)
                ..addFont(Future.value(ByteData.sublistView(bytes)));
              await loader.load();
            }
            final icons = await File(
              '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytes();
            await (FontLoader(
              'MaterialIcons',
            )..addFont(Future.value(ByteData.sublistView(icons)))).load();
          });
        }
        final channel = FakeHermesChannel();
        addTearDown(channel.dispose);
        final router = GoRouter(
          initialLocation: AppRoutes.hermes,
          routes: [
            ShellRoute(
              builder: (_, state, child) =>
                  AppShell(location: state.uri.path, child: child),
              routes: [
                GoRoute(
                  path: AppRoutes.hermes,
                  builder: (_, _) => const HermesChatScreen(),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [hermesChannelProvider.overrideWithValue(channel)],
            child: MaterialApp.router(
              theme: wingLightTheme,
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
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
        if (captureDir != null) {
          await tester.runAsync(() async {
            final image =
                await (tester.binding.renderViews.first.debugLayer!
                        as OffsetLayer)
                    .toImage(Rect.fromLTWH(0, 0, width, 1000));
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            await Directory(captureDir).create(recursive: true);
            await File(
              '$captureDir/shell-${width.toInt()}-${scale.toInt()}x.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
        final composer = find.byKey(const ValueKey('hermes-composer-field'));
        expect(composer.hitTestable(), findsOneWidget);
        await tester.enterText(composer, 'Synthetic retained draft');
        if (width >= 600) {
          final sidebar = find.byKey(const ValueKey('desktop-sidebar'));
          final workflow = find.byKey(
            const ValueKey('desktop-workflow-navigation'),
          );
          final utilities = find.byKey(
            const ValueKey('desktop-utility-navigation'),
          );
          final sessions = find.byKey(const ValueKey('shell-session-access'));
          expect(
            tester.getBottomLeft(workflow).dy,
            lessThanOrEqualTo(tester.getTopLeft(utilities).dy),
          );
          expect(
            tester.getBottomLeft(utilities).dy,
            lessThanOrEqualTo(tester.getTopLeft(sessions).dy),
          );
          expect(tester.getSize(sidebar).width, 250);
          expect(
            find.byKey(const ValueKey('hermes-session-rail-search-field')),
            findsNothing,
          );
          final editor = tester.state(composer);
          await tester.tap(
            find.byKey(const ValueKey('desktop-sidebar-toggle')),
          );
          await tester.pumpAndSettle();
          expect(tester.getSize(sidebar).width, 64);
          expect(sessions, findsNothing);
          expect(tester.state(composer), same(editor));
          expect(
            tester.widget<TextField>(composer).controller!.text,
            'Synthetic retained draft',
          );
          await tester.tap(
            find.byKey(const ValueKey('desktop-sidebar-toggle')),
          );
          await tester.pumpAndSettle();
          expect(sessions, findsOneWidget);
          await tester.ensureVisible(
            find.byKey(const ValueKey('shell-new-session')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('shell-new-session')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('desktop-manage-profiles')).hitTestable(),
            findsOneWidget,
          );
        } else {
          expect(find.byKey(const ValueKey('desktop-sidebar')), findsNothing);
          expect(
            find.byKey(const ValueKey('app-shell-menu-button')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('mobile-shell-navigation-bar')),
            findsNothing,
          );
        }
        expect(channel.selectSessionCalls, isEmpty);
        expect(channel.createSessionCalls, isEmpty);
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.hermes,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
