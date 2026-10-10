import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../test/shared/widgets/app_shell_status_accessibility_test.dart'
    as reference;
import 'support/status_accessibility_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'GTK full current status through compact recovery and route return',
    (tester) async {
      final root = Platform.environment['WING_STATUS_ROOT'];
      if (root == null ||
          Platform.environment['HOME'] != '$root/home' ||
          Platform.environment['WING_LIVE_AUTH'] != null) {
        throw StateError('Use the owned status launcher');
      }
      SharedPreferences.setMockInitialValues({});
      final highlight = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = highlight);
      addTearDown(() => binding.setSurfaceSize(null));
      for (final width in [390.0, 1280.0]) {
        for (final scale in [1.0, 2.0]) {
          final fixture = StatusAccessibilityNativeFixture();
          final router = GoRouter(
            initialLocation: '/hermes',
            routes: [
              for (final path in ['/hermes', '/settings'])
                GoRoute(
                  path: path,
                  builder: (_, _) => AppShell(
                    location: path,
                    child: Scaffold(
                      body: Text('Synthetic status workspace $path'),
                    ),
                  ),
                ),
            ],
          );
          await binding.setSurfaceSize(Size(width, 1000));
          await tester.pumpWidget(
            ProviderScope(
              overrides: [hermesChannelProvider.overrideWithValue(fixture)],
              child: MaterialApp.router(
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
          final semantics = tester.ensureSemantics();
          await reference.inspectStatus(tester, width);
          final phases = <String>[];
          Future<void> capture(String phase) async {
            final bar = find.byKey(const ValueKey('app-shell-status-bar'));
            await tester.ensureVisible(bar);
            await tester.pumpAndSettle();
            final rect = tester.getRect(bar);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
            expect(rect.bottom, lessThanOrEqualTo(1000));
            expect(tester.takeException(), isNull);
            expect(fixture.mutationCounts.values, everyElement(0));
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 250));
              final result = await Process.run('/usr/bin/import', [
                '-window',
                'root',
                '$root/cache/status-$width-$scale-$phase.png',
              ]);
              expect(result.exitCode, 0);
            });
            phases.add(phase);
          }

          expect(
            find.bySemanticsLabel(
              'Model: ${StatusAccessibilityNativeFixture.model}',
            ),
            findsOneWidget,
          );
          await capture('connected');
          for (final phase in ['recovering', 'failed', 'replacement']) {
            fixture.phase(phase);
            await tester.pumpAndSettle();
            expect(
              find.text(StatusAccessibilityNativeFixture.model),
              findsNothing,
            );
            if (phase == 'replacement') {
              expect(
                find.text(StatusAccessibilityNativeFixture.replacementModel),
                findsOneWidget,
              );
              expect(
                find.bySemanticsLabel(
                  'Profile: ${StatusAccessibilityNativeFixture.replacementProfile}',
                ),
                findsOneWidget,
              );
            } else {
              expect(find.text('Disconnected'), findsOneWidget);
              expect(
                find.text(StatusAccessibilityNativeFixture.profile),
                findsNothing,
              );
            }
            await capture(phase);
          }
          if (width < 600) {
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
          }
          router.go('/settings');
          await tester.pumpAndSettle();
          router.go('/hermes');
          await tester.pumpAndSettle();
          // Resize away and return without creating a session or model intent.
          await binding.setSurfaceSize(Size(width == 390 ? 1280 : 390, 1000));
          await tester.pumpAndSettle();
          await binding.setSurfaceSize(Size(width, 1000));
          await tester.pumpAndSettle();
          if (width < 600) {
            // Open the same public More path with keyboard; current replacement
            // values differ from the initial helper's connected assertions.
            for (var i = 0; i < 60; i++) {
              final context = FocusManager.instance.primaryFocus?.context;
              if (context
                      ?.findAncestorWidgetOfExactType<NavigationDestination>()
                      ?.label ==
                  'More') {
                break;
              }
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pump();
            }
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
          } else {
            // Activate an actual status button to restore inline inspection.
            final bar = find.byKey(const ValueKey('app-shell-status-bar'));
            for (var i = 0; i < 80; i++) {
              var inBar = false;
              FocusManager.instance.primaryFocus?.context
                  ?.visitAncestorElements((e) {
                    if (e.widget.key ==
                        const ValueKey('app-shell-status-bar')) {
                      inBar = true;
                    }
                    return !inBar;
                  });
              if (inBar) break;
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pump();
            }
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(
              find.descendant(
                of: bar,
                matching: find.text(
                  StatusAccessibilityNativeFixture.replacementModel,
                ),
              ),
              findsOneWidget,
            );
          }
          expect(
            tester
                .widget<Text>(
                  find.text(StatusAccessibilityNativeFixture.replacementModel),
                )
                .maxLines,
            isNull,
          );
          await capture('returned');
          final receipt = File('$root/cache/status-$width-$scale.pending');
          receipt.writeAsStringSync(
            jsonEncode({
              'native_pid': pid,
              'width': width,
              'text_scale': scale,
              'phases': phases,
              'mutations': fixture.mutationCounts,
              'keyboard_inspection': true,
              'current_owner': 'synthetic-replacement',
              'reduced_motion': true,
              'route_return': true,
              'resize_return': true,
            }),
          );
          receipt.renameSync('$root/cache/status-$width-$scale.json');
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(seconds: 1)),
          );
          semantics.dispose();
          await tester.pumpWidget(const SizedBox.shrink());
          router.dispose();
          fixture.dispose();
        }
      }
    },
  );
}
