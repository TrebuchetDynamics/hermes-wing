import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/models/hermes_capabilities.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/providers/hermes_directory_lifetime.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';
import '../../features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../../features/hermes_chat/support/fake_hermes_gateway_directory.dart';

const sessions = [
  HermesSession(
    id: 'synthetic-active',
    source: 'test',
    title: 'Synthetic active',
  ),
  HermesSession(
    id: 'synthetic-other',
    source: 'test',
    title: 'Synthetic other',
  ),
];
final other = find.byKey(const ValueKey('shell-open-session-synthetic-other'));
final active = find.byKey(
  const ValueKey('shell-open-session-synthetic-active'),
);
final create = find.byKey(const ValueKey('shell-new-session'));

class DelayedChannel extends FakeHermesChannel {
  DelayedChannel()
    : super(sessions: sessions, activeSessionId: 'synthetic-active');
  HermesChannelState? replacement;
  Completer<void>? gate;
  @override
  HermesChannelState get state => replacement ?? super.state;
  void change(HermesChannelState value) {
    replacement = value;
    notifyListeners();
  }

  @override
  Future<void> selectSession(String id, {bool Function()? canAccept}) async {
    if (!(canAccept?.call() ?? true)) return;
    selectSessionCalls.add(id);
    await gate?.future;
    if (canAccept?.call() ?? true) change(state.copyWith(activeSessionId: id));
  }

  @override
  Future<void> createSession({
    String? title,
    bool Function()? canAccept,
  }) async {
    if (!(canAccept?.call() ?? true)) return;
    createSessionCalls.add(title);
    await gate?.future;
    if (canAccept?.call() ?? true) {
      change(
        state.copyWith(
          sessions: [
            ...state.sessions,
            const HermesSession(id: 'synthetic-new', source: 'test'),
          ],
          activeSessionId: 'synthetic-new',
        ),
      );
    }
  }
}

class ContactDirectory extends HermesGatewayDirectory {
  ContactDirectory(HermesChannel channel)
    : super(
        store: FakeHermesEndpointStore(),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
  GatewayContactId? contact;
  bool activating = false;
  String? restoring;
  @override
  GatewayContactId? get activeContactId => contact;
  @override
  bool get isActivating => activating;
  @override
  String? get restoringSessionId => restoring;
  void changed() => notifyListeners();
}

class Harness {
  Harness(this.channel) {
    directory = ContactDirectory(channel);
    lifetime.attach(directory);
    container = ProviderContainer(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesDirectoryLifetimeProvider.overrideWithValue(lifetime),
        // Passive shell must never read this override.
        hermesGatewayDirectoryProvider.overrideWith((_) {
          constructions++;
          return directory;
        }),
      ],
    );
    router = GoRouter(
      initialLocation: '/tools',
      routes: [
        ShellRoute(
          builder: (_, state, child) =>
              AppShell(location: state.uri.path, child: child),
          routes: [
            for (final path in ['/hermes', '/tools', '/settings'])
              GoRoute(
                path: path,
                builder: (_, _) => Scaffold(
                  body: Column(
                    children: [
                      Text('Page $path'),
                      const TextField(key: ValueKey('route-draft')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  final DelayedChannel channel;
  final lifetime = HermesDirectoryLifetime();
  late final ContactDirectory directory;
  late final ProviderContainer container;
  late final GoRouter router;
  int constructions = 0;
  Widget app({double scale = 1}) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (_, child) => MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
    ),
  );
  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    double height = 1100,
  }) async {
    tester.view.physicalSize = Size(1280, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() {
      container.dispose();
      directory.dispose();
      lifetime.dispose();
      channel.dispose();
      router.dispose();
    });
    await tester.pumpWidget(app(scale: scale));
    await tester.pumpAndSettle();
  }

  String get path => router.routeInformationProvider.value.uri.path;
  void noIncidentalWork() {
    expect(constructions, 0);
    expect(channel.connectCalls, isEmpty);
    expect(channel.selectProfileCalls, isEmpty);
    expect(channel.loadMoreSessionsCalls, 0);
    expect(channel.loadEarlierMessagesCalls, 0);
    expect(channel.state.activeMessages, isEmpty);
    expect(channel.assignModelCalls, isEmpty);
    expect(channel.lockSessionModelCalls, isEmpty);
    expect(channel.respondToApprovalCalls, isEmpty);
    expect(channel.loadModelsCalls, 0);
  }
}

void main() {
  testWidgets(
    'production shell opens exact nonactive and active loaded rows once',
    (tester) async {
      final h = Harness(DelayedChannel());
      await h.pump(tester);
      h.noIncidentalWork();
      expect(h.path, '/tools');
      await tester.ensureVisible(other);
      await tester.tap(other);
      await tester.pumpAndSettle();
      expect(h.channel.selectSessionCalls, ['synthetic-other']);
      expect(h.channel.state.activeSessionId, 'synthetic-other');
      expect(h.path, '/hermes');
      h.router.go('/tools');
      await tester.pumpAndSettle();
      await tester.tap(other);
      await tester.pumpAndSettle();
      expect(h.channel.selectSessionCalls, [
        'synthetic-other',
        'synthetic-other',
      ]);
      h.noIncidentalWork();
    },
  );

  for (final newSession in [false, true]) {
    testWidgets(
      'late rejection after owner loss is silent for ${newSession ? 'create' : 'open'}',
      (tester) async {
        final h = Harness(DelayedChannel()..gate = Completer<void>());
        await h.pump(tester);
        await tester.ensureVisible(newSession ? create : other);
        await tester.tap(newSession ? create : other);
        await tester.pump();
        final before = h.channel.state;
        h.channel.change(
          before.copyWith(selectedProfileId: 'synthetic-replaced'),
        );
        h.channel.change(before);
        h.channel.gate!.completeError(StateError('synthetic rejection'));
        await tester.pumpAndSettle();
        expect(
          find.text('Could not open the session. Try again in Chat.'),
          findsNothing,
        );
        expect(h.path, '/tools');
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'acknowledgement and pending single-flight ${newSession ? 'create' : 'open'}',
      (tester) async {
        final h = Harness(DelayedChannel()..gate = Completer<void>());
        await h.pump(tester);
        final button = newSession ? create : other;
        await tester.ensureVisible(button);
        final callback = tester.widget<TextButton>(button).onPressed!;
        callback();
        callback();
        await tester.pump();
        expect(h.path, '/tools');
        expect(tester.widget<TextButton>(button).onPressed, isNull);
        expect(find.text('Opening session…'), findsOneWidget);
        h.channel.gate!.complete();
        await tester.pumpAndSettle();
        expect(h.path, '/hermes');
        expect(
          newSession
              ? h.channel.createSessionCalls.length
              : h.channel.selectSessionCalls.length,
          1,
        );
        expect(
          h.channel.state.activeSessionId,
          newSession ? 'synthetic-new' : 'synthetic-other',
        );
        h.noIncidentalWork();
      },
    );

    for (final invalidation in [
      'profile',
      'endpoint',
      'disconnect',
      'selecting',
      'uncertain',
      'contact',
      'directory',
      'removed',
      'route',
      'collapse',
      'dispose',
      'channel',
      'lifetime',
    ]) {
      testWidgets(
        'late ${newSession ? 'create' : 'open'} rejected after $invalidation including change-back',
        (tester) async {
          final h = Harness(DelayedChannel()..gate = Completer<void>());
          await h.pump(tester);
          final before = h.channel.state;
          await tester.ensureVisible(newSession ? create : other);
          await tester.tap(newSession ? create : other);
          await tester.pump();
          switch (invalidation) {
            case 'profile':
              h.channel.change(
                before.copyWith(selectedProfileId: 'synthetic-replacement'),
              );
              h.channel.change(before);
            case 'endpoint':
              h.channel.change(
                before.copyWith(connectedBaseUrl: 'http://127.0.0.1:8649'),
              );
              h.channel.change(before);
            case 'disconnect':
              h.channel.change(
                before.copyWith(status: HermesConnectionStatus.disconnected),
              );
              h.channel.change(before);
            case 'selecting':
              h.channel.change(before.copyWith(isSelectingProfile: true));
              h.channel.change(before);
            case 'uncertain':
              h.channel.change(before.copyWith(hasUnreconciledRun: true));
              h.channel.change(before);
            case 'contact':
              h.directory.contact = const GatewayContactId(
                gatewayId: 'synthetic',
                profileId: 'synthetic',
              );
              h.directory.changed();
              h.directory.contact = null;
              h.directory.changed();
            case 'directory':
              h.lifetime.detach(h.directory);
              h.lifetime.attach(h.directory);
            case 'removed':
              h.channel.change(before.copyWith(sessions: [sessions.first]));
              h.channel.change(before);
            case 'route':
              h.router.go('/settings');
              await tester.pumpAndSettle();
            case 'collapse':
              await tester.tap(
                find.byKey(const ValueKey('desktop-sidebar-toggle')),
              );
              await tester.pumpAndSettle();
            case 'dispose':
              await tester.pumpWidget(const SizedBox());
            case 'channel':
              final replacement = DelayedChannel();
              addTearDown(replacement.dispose);
              h.container.updateOverrides([
                hermesChannelProvider.overrideWithValue(replacement),
                hermesDirectoryLifetimeProvider.overrideWithValue(h.lifetime),
                hermesGatewayDirectoryProvider.overrideWith((_) => h.directory),
              ]);
              await h.container.pump();
              await tester.pump();
            case 'lifetime':
              final replacement = HermesDirectoryLifetime()
                ..attach(h.directory);
              addTearDown(replacement.dispose);
              h.container.updateOverrides([
                hermesChannelProvider.overrideWithValue(h.channel),
                hermesDirectoryLifetimeProvider.overrideWithValue(replacement),
                hermesGatewayDirectoryProvider.overrideWith((_) => h.directory),
              ]);
              await h.container.pump();
              await tester.pump();
          }
          h.channel.gate!.complete();
          await tester.pumpAndSettle();
          expect(h.channel.state.activeSessionId, 'synthetic-active');
          expect(h.path, invalidation == 'route' ? '/settings' : '/tools');
          h.noIncidentalWork();
        },
      );
    }

    testWidgets(
      'rejected ${newSession ? 'create' : 'open'} remains on feature with explicit error and retry',
      (tester) async {
        final h = Harness(DelayedChannel()..gate = Completer<void>());
        await h.pump(tester);
        await tester.ensureVisible(newSession ? create : other);
        await tester.tap(newSession ? create : other);
        await tester.pump();
        h.channel.gate!.completeError(StateError('synthetic failure'));
        await tester.pumpAndSettle();
        expect(h.path, '/tools');
        expect(
          find.text('Could not open the session. Try again in Chat.'),
          findsOneWidget,
        );
        h.channel.gate = null;
        await tester.ensureVisible(newSession ? create : other);
        await tester.tap(newSession ? create : other);
        await tester.pumpAndSettle();
        expect(h.path, '/hermes');
      },
    );
  }

  testWidgets('rendered callback cannot revive after same-frame row removal', (
    tester,
  ) async {
    final h = Harness(DelayedChannel());
    await h.pump(tester);
    final callback = tester.widget<TextButton>(other).onPressed!;
    final before = h.channel.state;
    h.channel.change(before.copyWith(sessions: [sessions.first]));
    h.channel.change(before);
    callback();
    await tester.pumpAndSettle();
    expect(h.channel.selectSessionCalls, isEmpty);
    expect(h.path, '/tools');
  });

  for (final denial in ['method', 'scope', 'schema', 'context']) {
    testWidgets('session history $denial loss invalidates rendered actions', (
      tester,
    ) async {
      final h = Harness(DelayedChannel());
      await h.pump(tester);
      final callback = tester.widget<TextButton>(other).onPressed!;
      final before = h.channel.state;
      final denied = HermesCapabilityDocument.fromJson({
        'schema_version': denial == 'schema' ? 99 : 1,
        'endpoints': {
          'session_messages': {
            'method': denial == 'method' ? 'POST' : 'GET',
            'path': '/api/sessions/{session_id}/messages',
            'required_scopes': denial == 'scope' ? ['sessions:read'] : [],
            'profile_scoped': denial == 'context',
          },
        },
      });
      h.channel.change(before.copyWith(capabilities: denied));
      expect(h.channel.state.canReadSessionHistory, isFalse);
      h.channel.change(before);
      callback();
      await tester.pumpAndSettle();
      expect(h.channel.selectSessionCalls, isEmpty);
      h.noIncidentalWork();
    });
  }

  for (final unsettled in [
    'disconnect',
    'selecting',
    'restoring',
    'activating',
    'uncertain',
  ]) {
    testWidgets('disabled while $unsettled without reads', (tester) async {
      final h = Harness(DelayedChannel());
      await h.pump(tester);
      switch (unsettled) {
        case 'disconnect':
          h.channel.change(
            h.channel.state.copyWith(
              status: HermesConnectionStatus.disconnected,
            ),
          );
        case 'selecting':
          h.channel.change(h.channel.state.copyWith(isSelectingProfile: true));
        case 'uncertain':
          h.channel.change(h.channel.state.copyWith(hasUnreconciledRun: true));
        case 'restoring':
          h.directory.restoring = 'synthetic-other';
          h.directory.changed();
        case 'activating':
          h.directory.activating = true;
          h.directory.changed();
      }
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(create).onPressed, isNull);
      expect(other, findsNothing);
      h.noIncidentalWork();
    });
  }

  testWidgets(
    'named selected semantics, keyboard, collapse and compact resize',
    (tester) async {
      final h = Harness(DelayedChannel());
      await h.pump(tester, height: 600, scale: 2);
      final semantics = tester.ensureSemantics();
      await tester.ensureVisible(active);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(active),
        matchesSemantics(
          label: 'Open Synthetic active',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('route-draft')),
        'synthetic local draft',
      );
      bool focused(Finder target) =>
          tester
              .getSemantics(target)
              .getSemanticsData()
              .flagsCollection
              .isFocused
              .toBoolOrNull() ==
          true;
      Future<void> reach(Finder target, {bool backwards = false}) async {
        for (var i = 0; i < 30 && !focused(target); i++) {
          if (backwards) {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          if (backwards) {
            await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          }
          await tester.pumpAndSettle();
        }
        expect(focused(target), isTrue);
      }

      await reach(other);
      await reach(active, backwards: true);
      await reach(other);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(h.path, '/hermes');
      expect(h.channel.selectSessionCalls, ['synthetic-other']);
      h.router.go('/tools');
      await tester.pumpAndSettle();
      await reach(create, backwards: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(h.channel.createSessionCalls.length, 1);
      // Collapse removes session controls, not merely their pixels.
      await tester.tap(find.byKey(const ValueKey('desktop-sidebar-toggle')));
      await tester.pumpAndSettle();
      expect(other, findsNothing);
      expect(create, findsNothing);
      await tester.tap(find.byKey(const ValueKey('desktop-sidebar-toggle')));
      await tester.pumpAndSettle();
      expect(other, findsOneWidget);
      tester.view.physicalSize = const Size(390, 900);
      await tester.pumpAndSettle();
      expect(create, findsNothing);
      expect(
        find.byKey(const ValueKey('mobile-shell-navigation-bar')),
        findsOneWidget,
      );
      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpAndSettle();
      expect(other, findsOneWidget);
      expect(tester.takeException(), isNull);
      h.noIncidentalWork();
      semantics.dispose();
    },
  );
}
