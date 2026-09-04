import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/models/wing_link_directory.dart';
import 'package:wing/features/profiles/widgets/profile_directory_browser_sheet.dart';
import 'package:wing/l10n/app_localizations.dart';

Widget directoryBrowserLauncher(
  Future<void> Function(BuildContext context) open,
) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: FilledButton(
        onPressed: () => open(context),
        child: const Text('Browse'),
      ),
    ),
  ),
);

Finder _liveRegion(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      widget.properties.liveRegion == true &&
      widget.properties.label == label,
);

Future<void> _expectTabTraversalReaches(
  WidgetTester tester,
  Finder target,
) async {
  for (var index = 0; index < 20; index++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (tester.getSemantics(target).flagsCollection.isFocused ==
        Tristate.isTrue) {
      return;
    }
  }
  fail(
    'Keyboard traversal did not reach ${target.describeMatch(Plurality.one)}',
  );
}

void main() {
  testWidgets('browses approved child folders by opaque handle', (
    tester,
  ) async {
    final childRequests = <(String, int)>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showProfileDirectoryBrowser(
                context,
                loadRoots: () async => const [
                  WingLinkDirectory(
                    handle: 'dirh_rootAAAAAAAAAAAAAAAAAA',
                    name: 'repos',
                  ),
                ],
                loadChildren: (handle, offset) async {
                  childRequests.add((handle, offset));
                  return const WingLinkDirectoryPage(
                    directories: [
                      WingLinkDirectory(
                        handle: 'dirh_childAAAAAAAAAAAAAAAAA',
                        name: 'wing',
                      ),
                    ],
                  );
                },
              ),
              child: const Text('Browse'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('repos'));
    await tester.pumpAndSettle();

    expect(childRequests, [('dirh_rootAAAAAAAAAAAAAAAAAA', 0)]);
    expect(find.text('wing'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('directory-browser-select')),
      findsNothing,
    );
  });

  testWidgets('ignores a second folder tap while loading the first', (
    tester,
  ) async {
    final release = Completer<void>();
    final requests = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showProfileDirectoryBrowser(
                context,
                loadRoots: () async => const [
                  WingLinkDirectory(
                    handle: 'dirh_oneAAAAAAAAAAAAAAAAAAA',
                    name: 'one',
                  ),
                  WingLinkDirectory(
                    handle: 'dirh_twoAAAAAAAAAAAAAAAAAAA',
                    name: 'two',
                  ),
                ],
                loadChildren: (handle, offset) async {
                  requests.add(handle);
                  await release.future;
                  return const WingLinkDirectoryPage();
                },
              ),
              child: const Text('Browse'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('one'));
    await tester.tap(find.text('two'));
    expect(requests, ['dirh_oneAAAAAAAAAAAAAAAAAAA']);

    release.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows loading and an empty host-local grant instruction', (
    tester,
  ) async {
    final roots = Completer<List<WingLinkDirectory>>();
    await tester.pumpWidget(
      directoryBrowserLauncher(
        (context) => showProfileDirectoryBrowser(
          context,
          loadRoots: () => roots.future,
          loadChildren: (_, _) async => const WingLinkDirectoryPage(),
        ),
      ),
    );

    await tester.tap(find.text('Browse'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('directory-browser-loading')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Loading approved folders'), findsOneWidget);

    roots.complete(const []);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('wing-link directories grant PATH'),
      findsOneWidget,
    );
    expect(find.text('Close'), findsWidgets);
  });

  testWidgets('back restores an opaque parent level and pagination appends', (
    tester,
  ) async {
    final requests = <(String, int)>[];
    await tester.pumpWidget(
      directoryBrowserLauncher(
        (context) => showProfileDirectoryBrowser(
          context,
          loadRoots: () async => const [
            WingLinkDirectory(
              handle: 'dirh_rootAAAAAAAAAAAAAAAAAA',
              name: 'repos',
            ),
          ],
          loadChildren: (handle, offset) async {
            requests.add((handle, offset));
            if (handle.startsWith('dirh_root')) {
              return WingLinkDirectoryPage(
                directories: [
                  if (offset == 0)
                    const WingLinkDirectory(
                      handle: 'dirh_wingAAAAAAAAAAAAAAAAAA',
                      name: 'wing',
                    )
                  else
                    const WingLinkDirectory(
                      handle: 'dirh_otherAAAAAAAAAAAAAAAAA',
                      name: 'other',
                    ),
                ],
                nextOffset: offset == 0 ? 50 : null,
              );
            }
            return const WingLinkDirectoryPage(
              directories: [
                WingLinkDirectory(
                  handle: 'dirh_libAAAAAAAAAAAAAAAAAAA',
                  name: 'lib',
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('repos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('directory-browser-load-more')));
    await tester.pumpAndSettle();
    expect(find.text('wing'), findsOneWidget);
    expect(find.text('other'), findsOneWidget);
    expect(requests, [
      ('dirh_rootAAAAAAAAAAAAAAAAAA', 0),
      ('dirh_rootAAAAAAAAAAAAAAAAAA', 50),
    ]);

    await tester.tap(find.text('wing'));
    await tester.pumpAndSettle();
    expect(find.text('lib'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('directory-browser-back')));
    await tester.pumpAndSettle();
    expect(find.text('wing'), findsOneWidget);
    expect(find.text('lib'), findsNothing);
  });

  testWidgets(
    'clears stale levels before one recovery and never exposes failure data',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var rootLoads = 0;
      final recoveryRoots = Completer<List<WingLinkDirectory>>();
      final childRequests = <(String, int)>[];
      Future<List<WingLinkDirectory>> loadRoots() {
        rootLoads++;
        if (rootLoads == 2) return recoveryRoots.future;
        return Future.value(const [
          WingLinkDirectory(
            handle: 'dirh_rootAAAAAAAAAAAAAAAAAA',
            name: 'repos',
          ),
        ]);
      }

      Future<WingLinkDirectoryPage> loadChildren(
        String handle,
        int offset,
      ) async {
        childRequests.add((handle, offset));
        if (handle.startsWith('dirh_root')) {
          return const WingLinkDirectoryPage(
            directories: [
              WingLinkDirectory(
                handle: 'dirh_wingAAAAAAAAAAAAAAAAAA',
                name: 'wing',
              ),
            ],
          );
        }
        throw Exception('/tmp/host-root/private.txt');
      }

      await tester.pumpWidget(
        directoryBrowserLauncher(
          (context) => showProfileDirectoryBrowser(
            context,
            loadRoots: loadRoots,
            loadChildren: loadChildren,
          ),
        ),
      );

      await tester.tap(find.text('Browse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('repos'));
      await tester.pumpAndSettle();
      expect(find.text('repos'), findsOneWidget);
      await tester.tap(find.text('wing'));
      await tester.pump();

      expect(rootLoads, 2);
      expect(
        find.byKey(const ValueKey('directory-browser-loading')),
        findsOneWidget,
      );
      expect(find.text('repos'), findsNothing);
      expect(find.text('wing'), findsNothing);

      recoveryRoots.complete(const [
        WingLinkDirectory(handle: 'dirh_rootAAAAAAAAAAAAAAAAAA', name: 'repos'),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('repos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('wing'));
      await tester.pumpAndSettle();

      final retry = find.byKey(const ValueKey('directory-browser-retry'));
      expect(retry, findsOneWidget);
      expect(
        _liveRegion(
          'Approved folders are unavailable. Refresh the host grants and try again.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('/tmp/host-root'), findsNothing);
      expect(find.textContaining('private.txt'), findsNothing);
      final semanticsTree = tester
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!
          .toStringDeep();
      expect(semanticsTree, isNot(contains('/tmp/host-root')));
      expect(semanticsTree, isNot(contains('private.txt')));
      expect(
        childRequests,
        everyElement(
          predicate<(String, int)>(
            (request) =>
                request.$1.startsWith('dirh_') &&
                !request.$1.contains('/tmp/host-root') &&
                !request.$1.contains('private.txt') &&
                request.$2 == 0,
          ),
        ),
      );

      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(rootLoads, 3);
      expect(find.text('repos'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('Back and Close remain keyboard reachable at 200 percent', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: directoryBrowserLauncher(
          (context) => showProfileDirectoryBrowser(
            context,
            loadRoots: () async => const [
              WingLinkDirectory(
                handle: 'dirh_rootAAAAAAAAAAAAAAAAAA',
                name: 'repos',
              ),
            ],
            loadChildren: (_, _) async => const WingLinkDirectoryPage(
              directories: [
                WingLinkDirectory(
                  handle: 'dirh_childAAAAAAAAAAAAAAAAA',
                  name: 'wing',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('repos'));
    await tester.pumpAndSettle();
    final back = find.byKey(const ValueKey('directory-browser-back'));
    expect(back, findsOneWidget);
    expect(tester.takeException(), isNull);
    await _expectTabTraversalReaches(tester, back);
    await _expectTabTraversalReaches(tester, find.text('Close').last);
    semantics.dispose();
  });

  testWidgets(
    'Retry and Close remain keyboard reachable with live loading and error semantics at 200 percent',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var loads = 0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: directoryBrowserLauncher(
            (context) => showProfileDirectoryBrowser(
              context,
              loadRoots: () async {
                loads++;
                if (loads == 1) {
                  return const [
                    WingLinkDirectory(
                      handle: 'dirh_rootAAAAAAAAAAAAAAAAAA',
                      name: 'repos',
                    ),
                  ];
                }
                throw Exception('redacted');
              },
              loadChildren: (_, _) async => throw Exception('redacted'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Browse'));
      await tester.pump();
      final loading = _liveRegion('Loading approved folders');
      expect(loading, findsOneWidget);
      expect(tester.getSemantics(loading).flagsCollection.isLiveRegion, isTrue);
      await tester.pumpAndSettle();
      await tester.tap(find.text('repos'));
      await tester.pumpAndSettle();

      final retry = find.byKey(const ValueKey('directory-browser-retry'));
      expect(retry, findsOneWidget);
      final error = _liveRegion(
        'Approved folders are unavailable. Refresh the host grants and try again.',
      );
      expect(error, findsOneWidget);
      expect(tester.getSemantics(error).flagsCollection.isLiveRegion, isTrue);
      expect(tester.takeException(), isNull);
      await _expectTabTraversalReaches(tester, retry);
      await _expectTabTraversalReaches(tester, find.text('Close').last);
      semantics.dispose();
    },
  );
}
