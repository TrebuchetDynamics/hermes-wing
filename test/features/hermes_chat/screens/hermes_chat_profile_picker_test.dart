import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

const profiles = [
  HermesProfile(
    id: 'beta',
    displayName: 'Beta',
    model: 'Model-B',
    revision: '1',
  ),
  HermesProfile(
    id: 'active',
    displayName: 'Current',
    model: 'Model-A',
    revision: '1',
  ),
  HermesProfile(
    id: 'literal[1]',
    displayName: 'Builder',
    model: 'Model-C',
    revision: '1',
  ),
];
final source = StateProvider<HermesChannel>(
  (ref) => throw UnimplementedError(),
);
final search = find.byKey(const ValueKey('chat-profile-search'));
final clear = find.byKey(const ValueKey('chat-profile-clear'));
final manage = find.byKey(const ValueKey('chat-profile-manage'));
Finder row(String id) => find.byKey(ValueKey('chat-profile-row-$id'));

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  for (final width in [390.0, 1280.0]) {
    testWidgets('loaded picker searches at $width', (tester) async {
      final h = await pumpChat(tester, width);
      final original = h.channel.state;
      await openPicker(tester);
      expect(search, findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus,
        tester.widget<TextField>(search).focusNode,
      );
      expect(visibleIds(tester), ['active', 'beta', 'literal[1]']);
      for (final query in ['bEtA', 'LITERAL[1]', 'mOdEl-C', 'BUILDER']) {
        await tester.enterText(search, query);
        await tester.pump();
        expect(visibleIds(tester), [query == 'bEtA' ? 'beta' : 'literal[1]']);
        expect(row('active'), findsNothing);
        expect(identical(h.channel.state, original), isTrue);
        expectNoMutations(h.channel);
      }
      await tester.enterText(search, '.*');
      await tester.pump();
      expect(find.text('No matching profiles'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(search, findsOneWidget);
      expectNoMutations(h.channel);
      await tester.tap(clear);
      await tester.pump();
      expect(visibleIds(tester), ['active', 'beta', 'literal[1]']);
      await tester.enterText(search, 'beta');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(search, findsNothing);
      expectNoMutations(h.channel);
      await openPicker(tester);
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    });

    testWidgets('empty inventory is distinct at $width', (tester) async {
      final h = await pumpChat(tester, width);
      await openPicker(tester);
      h.channel.change(h.channel.state.copyWith(profiles: const []));
      await tester.pump();
      expect(find.text('No profiles available'), findsOneWidget);
      await tester.enterText(search, 'anything');
      await tester.pump();
      expect(find.text('No profiles available'), findsOneWidget);
      expect(find.text('No matching profiles'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expectNoMutations(h.channel);
    });

    testWidgets('text editing and Tab row activation at $width', (
      tester,
    ) async {
      final h = await pumpChat(tester, width);
      await openPicker(tester);
      await tester.enterText(search, 'beta');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(
        tester.widget<TextField>(search).controller!.selection.baseOffset,
        3,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(
        tester.widget<TextField>(search).controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 4),
      );
      expectNoMutations(h.channel);
      await tabTo(tester, const ValueKey('chat-profile-row-beta'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(h.channel.selectProfileCalls, ['beta']);
    });

    testWidgets('active selection and duplicate closure activation at $width', (
      tester,
    ) async {
      final h = await pumpChat(tester, width);
      await openPicker(tester);
      final choose = tester.widget<ListTile>(row('active')).onTap!;
      final manageAction = tester.widget<TextButton>(manage).onPressed!;
      choose();
      choose();
      manageAction();
      await tester.pumpAndSettle();
      expectNoMutations(h.channel);
      expect(h.router.routeInformationProvider.value.uri.path, '/hermes');
      expect(search, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('same-owner refresh retains query at $width', (tester) async {
      final h = await pumpChat(tester, width);
      await openPicker(tester);
      await tester.enterText(search, 'model-c');
      await tester.pump();
      h.channel.change(
        h.channel.state.copyWith(
          profiles: [
            ...profiles,
            const HermesProfile(
              id: 'new',
              displayName: 'New',
              model: 'MODEL-C',
              revision: '2',
            ),
          ],
        ),
      );
      await tester.pump();
      expect(tester.widget<TextField>(search).controller!.text, 'model-c');
      expect(visibleIds(tester), ['literal[1]', 'new']);
      h.channel.change(h.channel.state.copyWith(profiles: const []));
      await tester.pump();
      expect(find.text('No profiles available'), findsOneWidget);
      expect(tester.widget<TextField>(search).controller!.text, 'model-c');
      expectNoMutations(h.channel);
    });

    testWidgets('keyboard-only exact selection and native Tab at $width', (
      tester,
    ) async {
      final h = await pumpChat(tester, width);
      await tabTo(tester, const ValueKey('hermes-profile-switcher'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus,
        tester.widget<TextField>(search).focusNode,
      );
      await tester.enterText(search, 'model');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedKey(const ValueKey('chat-profile-clear')), isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus,
        tester.widget<TextField>(search).focusNode,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expectNoMutations(h.channel);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(h.channel.selectProfileCalls, ['beta']);
      expect(h.channel.state.selectedProfileId, 'beta');
    });

    testWidgets('keyboard manage dismisses without selection at $width', (
      tester,
    ) async {
      final h = await pumpChat(tester, width);
      final original = h.channel.state;
      await tabTo(tester, const ValueKey('hermes-profile-switcher'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.enterText(search, 'no matches');
      await tester.pump();
      await tabTo(tester, const ValueKey('chat-profile-manage'));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(focusedKey(const ValueKey('chat-profile-clear')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedKey(const ValueKey('chat-profile-manage')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(h.router.routeInformationProvider.value.uri.path, '/profiles');
      expect(search, findsNothing);
      expect(find.text('Profiles destination'), findsOneWidget);
      expect(identical(h.channel.state, original), isTrue);
      expectNoMutations(h.channel);
    });

    testWidgets(
      '200% reduced-motion semantics and highlighted scroll at $width',
      (tester) async {
        final h = await pumpChat(
          tester,
          width,
          scale: 2,
          inventory: [
            ...profiles,
            for (var i = 0; i < 24; i++)
              HermesProfile(
                id: 'p$i',
                displayName: 'Profile $i',
                model: 'Model $i',
                revision: '1',
              ),
          ],
        );
        final semantics = tester.ensureSemantics();
        await openPicker(tester);
        expect(
          tester.getSemantics(row('active')).flagsCollection.isSelected,
          Tristate.isTrue,
        );
        for (var i = 0; i < 26; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(row('p23').hitTestable(), findsOneWidget);
        final tile = tester.widget<ListTile>(row('p23'));
        expect(tile.trailing, isNotNull);
        expect(tester.takeException(), isNull);
        expectNoMutations(h.channel);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(search, findsNothing);
        semantics.dispose();
      },
    );

    for (final transition in [
      'profile',
      'endpoint',
      'disconnect',
      'pending',
      'profile roundtrip',
      'endpoint roundtrip',
      'channel',
      'channel roundtrip',
      'dispose',
    ]) {
      testWidgets('stale picker $transition at $width', (tester) async {
        final h = await pumpChat(tester, width);
        final replacement = OwnerChannel();
        addTearDown(replacement.dispose);
        await openPicker(tester);
        final staleChoose = tester.widget<ListTile>(row('beta')).onTap!;
        final staleManage = tester.widget<TextButton>(manage).onPressed!;
        final original = h.channel.state;
        if (transition == 'dispose') {
          await tester.pumpWidget(const SizedBox.shrink());
        } else if (transition.startsWith('channel')) {
          h.container.read(source.notifier).state = replacement;
          h.container.read(hermesChannelProvider);
          if (transition.endsWith('roundtrip')) {
            h.container.read(source.notifier).state = h.channel;
            h.container.read(hermesChannelProvider);
          }
        } else {
          final changed = switch (transition.split(' ').first) {
            'profile' => original.copyWith(selectedProfileId: 'elsewhere'),
            'endpoint' => original.copyWith(
              connectedBaseUrl: 'https://other.example.invalid',
            ),
            'pending' => original.copyWith(isSelectingProfile: true),
            _ => original.copyWith(status: HermesConnectionStatus.disconnected),
          };
          h.channel.change(changed);
          if (transition.endsWith('roundtrip')) h.channel.change(original);
        }
        // Invoke the cached controls before rebuilding, including loss/return.
        staleChoose();
        staleManage();
        await tester.pumpAndSettle();
        expectNoMutations(h.channel);
        expectNoMutations(replacement);
        expect(h.router.routeInformationProvider.value.uri.path, '/hermes');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('dismissed picker rejects cached controls at $width', (
      tester,
    ) async {
      final h = await pumpChat(tester, width);
      await openPicker(tester);
      final choose = tester.widget<ListTile>(row('beta')).onTap!;
      final manageAction = tester.widget<TextButton>(manage).onPressed!;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      choose();
      manageAction();
      await tester.pumpAndSettle();
      expectNoMutations(h.channel);
      expect(h.router.routeInformationProvider.value.uri.path, '/hermes');
      expect(tester.takeException(), isNull);
    });

    testWidgets('owner loss after dismissal rejects selection at $width', (
      tester,
    ) async {
      final h = await pumpChat(tester, width);
      await openPicker(tester);
      final original = h.channel.state;
      tester.widget<ListTile>(row('beta')).onTap!();
      h.channel.change(original.copyWith(selectedProfileId: 'elsewhere'));
      h.channel.change(original);
      await tester.pumpAndSettle();
      expectNoMutations(h.channel);
      expect(h.channel.state.selectedProfileId, 'active');
      expect(tester.takeException(), isNull);
    });

    testWidgets('stale header rejects admission at $width', (tester) async {
      final h = await pumpChat(tester, width);
      final switcher = tester.widget(
        find.byKey(const ValueKey('hermes-profile-switcher')),
      );
      final open = switcher is IconButton
          ? switcher.onPressed!
          : (switcher as TextButton).onPressed!;
      h.channel.change(h.channel.state.copyWith(isSelectingProfile: true));
      open();
      await tester.pumpAndSettle();
      expect(search, findsNothing);
      expectNoMutations(h.channel);
    });

    testWidgets('removed target rejects cached row at $width', (tester) async {
      final h = await pumpChat(tester, width);
      await openPicker(tester);
      final staleChoose = tester.widget<ListTile>(row('beta')).onTap!;
      h.channel.change(
        h.channel.state.copyWith(profiles: profiles.skip(1).toList()),
      );
      staleChoose();
      await tester.pumpAndSettle();
      expect(row('beta'), findsNothing);
      expect(search, findsOneWidget);
      expectNoMutations(h.channel);
    });

    for (final rejected in [false, true]) {
      testWidgets('delayed selection rejected=$rejected at $width', (
        tester,
      ) async {
        final gate = Completer<void>();
        final channel = OwnerChannel(
          gate: (_) => gate.future,
          rejected: rejected,
        );
        final h = await pumpChat(tester, width, channel: channel);
        await openPicker(tester);
        await tester.tap(row('beta'));
        await tester.pump();
        expect(channel.selectProfileCalls, ['beta']);
        expect(channel.state.selectedProfileId, 'active');
        final switcher = tester.widget(
          find.byKey(const ValueKey('hermes-profile-switcher')),
        );
        expect(
          switcher is IconButton
              ? switcher.onPressed
              : (switcher as TextButton).onPressed,
          isNull,
        );
        gate.complete();
        await tester.pumpAndSettle();
        expect(channel.selectProfileCalls, ['beta']);
        expect(channel.state.selectedProfileId, rejected ? 'active' : 'beta');
        if (rejected) {
          expect(
            find.textContaining('Could not switch profile:'),
            findsOneWidget,
          );
        }
        expect(h.channel.createSessionCalls, isEmpty);
      });
    }
  }
}

class OwnerChannel extends FakeHermesChannel {
  OwnerChannel({
    List<HermesProfile> inventory = profiles,
    Future<void> Function(String)? gate,
    bool rejected = false,
  }) : super(
         profiles: inventory,
         selectedProfileId: 'active',
         connectedBaseUrl: 'https://example.invalid',
         connectedWithApiKey: false,
         selectProfileGate: gate,
         selectProfileFails: rejected,
       );
  HermesChannelState? changed;
  @override
  HermesChannelState get state => changed ?? super.state;
  void change(HermesChannelState value) {
    changed = value;
    notifyListeners();
  }
}

class Harness {
  Harness(this.channel, this.container, this.router);
  final OwnerChannel channel;
  final ProviderContainer container;
  final GoRouter router;
}

Future<Harness> pumpChat(
  WidgetTester tester,
  double width, {
  List<HermesProfile> inventory = profiles,
  OwnerChannel? channel,
  double scale = 1,
  bool disableAnimations = true,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  channel ??= OwnerChannel(inventory: inventory);
  addTearDown(channel.dispose);
  final container = ProviderContainer(
    overrides: [
      source.overrideWith((ref) => channel!),
      hermesChannelProvider.overrideWith((ref) => ref.watch(source)),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/hermes',
    routes: [
      GoRoute(path: '/hermes', builder: (_, _) => const HermesChatScreen()),
      GoRoute(
        path: '/profiles',
        builder: (_, _) => const Scaffold(body: Text('Profiles destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return Harness(channel, container, router);
}

Future<void> openPicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('hermes-profile-switcher')));
  await tester.pumpAndSettle();
}

List<String> visibleIds(WidgetTester tester) => tester
    .widgetList<ListTile>(find.byType(ListTile))
    .where(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('chat-profile-row-'),
    )
    .map(
      (w) => (w.key! as ValueKey<String>).value.substring(
        'chat-profile-row-'.length,
      ),
    )
    .toList();

void expectNoMutations(FakeHermesChannel c) {
  expect(c.selectProfileCalls, isEmpty);
  expect(c.selectSessionCalls, isEmpty);
  expect(c.createSessionCalls, isEmpty);
  expect(c.sentImageDataUrls, isEmpty);
  expect(c.sentVoiceTranscripts, isEmpty);
  expect(c.lockSessionModelCalls, isEmpty);
  expect(c.assignModelCalls, isEmpty);
  expect(c.respondToApprovalCalls, isEmpty);
  expect(c.loadModelsCalls, 0);
  expect(c.loadProvidersCalls, 0);
  expect(c.stopActiveTurnCalls, 0);
}

bool focusedKey(Key key) {
  var found = false;
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((element) {
    if (element.widget.key == key) found = true;
    return true;
  });
  return found;
}

Future<void> tabTo(WidgetTester tester, Key key) async {
  for (var i = 0; i < 40 && !focusedKey(key); i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(focusedKey(key), isTrue, reason: 'Keyboard focus must reach $key');
}
