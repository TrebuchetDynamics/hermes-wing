import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

const pinnedKey = ValueKey('hermes-session-disclosure-pinned');
const chatsKey = ValueKey('hermes-session-disclosure-chats');
Finder row(String id) => find.byKey(ValueKey('hermes-session-row-$id'));

void main() {
  testWidgets('compact date subgroups remain reachable in a short window', (
    tester,
  ) async {
    final channel = await pumpChat(tester, 390, height: 600);
    final current = DateTime.now();
    final now = DateTime(current.year, current.month, current.day, 12);
    channel.change(
      channel.state.copyWith(
        sessions: [
          for (final (id, days) in [
            ('today', 0),
            ('yesterday', 1),
            ('week', 3),
            ('earlier', 10),
          ])
            HermesSession(
              id: id,
              source: 'test',
              title: id,
              lastActive: now.subtract(Duration(days: days)).toIso8601String(),
            ),
        ],
        activeSessionId: 'today',
      ),
    );
    await tester.pumpAndSettle();
    final list = find.byKey(const ValueKey('hermes-sessions-list'));
    expect(
      find.byKey(const ValueKey('hermes-session-group-today')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hermes-session-group-yesterday')),
      findsOneWidget,
    );
    // Later date groups are lazily built below the short viewport.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('hermes-session-group-this-week')),
      100,
      scrollable: find.descendant(
        of: list,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('hermes-session-group-this-week')),
      findsOneWidget,
    );
    await tester.drag(list, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tabTo(tester, chatsKey, backwards: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('hermes-session-group-this-week')),
      findsNothing,
    );
  });
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  for (final width in [390.0, 1280.0]) {
    additionalCases(width);
    testWidgets('semantic independent disclosure at $width', (tester) async {
      final channel = await pumpChat(tester, width);
      final semantics = tester.ensureSemantics();
      final original = channel.state;
      expect(
        tester.getSemantics(find.byKey(pinnedKey)),
        matchesSemantics(
          label: 'Pinned',
          isButton: true,
          hasExpandedState: true,
          isExpanded: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      await tester.tap(find.byKey(pinnedKey));
      await tester.pumpAndSettle();
      expect(row('pin'), findsNothing);
      expect(
        find.byKey(const ValueKey('hermes-session-menu-pin')),
        findsNothing,
      );
      expect(find.bySemanticsLabel(RegExp('Pinned example')), findsNothing);
      expect(row('active'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(pinnedKey)).flagsCollection.isExpanded,
        Tristate.isFalse,
      );
      await tester.tap(find.byKey(chatsKey));
      await tester.pumpAndSettle();
      expect(row('active'), findsNothing);
      expect(find.text('Earlier'), findsNothing);
      expect(find.textContaining('No sessions'), findsNothing);
      await tester.tap(find.byKey(pinnedKey));
      await tester.pumpAndSettle();
      expect(row('pin'), findsOneWidget);
      expect(row('active'), findsNothing);
      expect(identical(channel.state, original), isTrue);
      expect(channel.selectSessionCalls, isEmpty);
      expect(channel.createSessionCalls, isEmpty);
      expect(channel.loadMoreSessionsCalls, 0);
      semantics.dispose();
    });

    testWidgets('keyboard traversal and focus recovery at $width', (
      tester,
    ) async {
      final channel = await pumpChat(tester, width);
      await tabTo(tester, pinnedKey);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(focusedKey(pinnedKey), isTrue);
      expect(row('pin'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedKey(chatsKey), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(focusedKey(chatsKey), isTrue);
      expect(row('active'), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(focusedKey(pinnedKey), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tabTo(tester, const ValueKey('hermes-session-menu-pin'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Unpin'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(channel.selectSessionCalls, isEmpty);
      await tabTo(tester, chatsKey);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(row('active'));
      await tester.pumpAndSettle();
      expect(channel.selectSessionCalls, ['active']);
    });

    testWidgets('filtered pins and search preserve collapsed state at $width', (
      tester,
    ) async {
      final channel = await pumpChat(tester, width);
      final original = channel.state;
      final prefs = await SharedPreferences.getInstance();
      final pins = prefs.getStringList('wing.hermes.pinned_sessions.v1');
      await tester.tap(find.byKey(pinnedKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(chatsKey));
      await tester.pumpAndSettle();
      final search = find.byKey(
        ValueKey(
          width < 600
              ? 'hermes-session-search-field'
              : 'hermes-session-rail-search-field',
        ),
      );
      await tester.enterText(search, 'Active');
      await tester.pumpAndSettle();
      expect(find.byKey(pinnedKey), findsNothing);
      expect(row('active'), findsNothing);
      await tester.enterText(search, 'absent');
      await tester.pumpAndSettle();
      expect(find.byKey(chatsKey), findsNothing);
      expect(find.textContaining('absent'), findsWidgets);
      await tester.tap(
        find.byKey(
          ValueKey(
            width < 600
                ? 'hermes-session-search-clear'
                : 'hermes-session-rail-search-clear',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(pinnedKey), findsOneWidget);
      expect(row('pin'), findsNothing);
      expect(row('active'), findsNothing);
      expect(identical(channel.state, original), isTrue);
      expect(prefs.getStringList('wing.hermes.pinned_sessions.v1'), pins);
      expect(channel.selectSessionCalls, isEmpty);
      expect(channel.loadMoreSessionsCalls, 0);
    });

    for (final transition in ['profile', 'host', 'roundtrip']) {
      testWidgets(
        'owner $transition invalidates cached disclosures at $width',
        (tester) async {
          final channel = await pumpChat(tester, width);
          await tester.tap(find.byKey(chatsKey));
          await tester.pumpAndSettle();
          final stale = tester
              .widget<TextButton>(
                find.descendant(
                  of: find.byKey(chatsKey),
                  matching: find.byType(TextButton),
                ),
              )
              .onPressed!;
          final original = channel.state;
          channel.change(
            transition == 'host'
                ? original.copyWith(
                    connectedBaseUrl: 'https://replacement.invalid',
                  )
                : original.copyWith(selectedProfileId: 'replacement'),
          );
          if (transition == 'roundtrip') channel.change(original);
          stale();
          await tester.pumpAndSettle();
          expect(row('active'), findsOneWidget);
          expect(channel.selectSessionCalls, isEmpty);
          expect(channel.selectProfileCalls, isEmpty);
          await tester.pumpWidget(const SizedBox.shrink());
          stale();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('same-owner inventory and stream retain state at $width', (
      tester,
    ) async {
      final channel = await pumpChat(tester, width);
      await tester.tap(find.byKey(chatsKey));
      await tester.pumpAndSettle();
      final next = channel.state.copyWith(
        sessions: [
          ...channel.state.sessions,
          const HermesSession(id: 'fresh', source: 'manual', title: 'Fresh'),
        ],
        messages: {
          'active': [
            HermesChatTurn(
              id: 'stream',
              sessionId: 'active',
              author: HermesTurnAuthor.assistant,
              createdAt: DateTime.utc(2020),
              text: 'Synthetic output',
              status: HermesTurnStatus.streaming,
            ),
          ],
        },
      );
      channel.change(next);
      // Streaming animations do not settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(row('active'), findsNothing);
      expect(row('fresh'), findsNothing);
      expect(row('pin'), findsOneWidget);
      await tester.tap(find.byKey(chatsKey));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('hermes-session-streaming-active')),
        findsOneWidget,
      );
      expect(identical(channel.state, next), isTrue);
      expect(channel.stopActiveTurnCalls, 0);
      expect(channel.selectSessionCalls, isEmpty);
    });

    testWidgets('last pin disappears and all-pinned inventory at $width', (
      tester,
    ) async {
      final channel = await pumpChat(tester, width);
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-menu-active')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin'));
      await tester.pumpAndSettle();
      expect(find.byKey(chatsKey), findsOneWidget);
      expect(find.text('Earlier'), findsNothing);
      await tester.tap(find.byKey(chatsKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('hermes-session-menu-active')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unpin'));
      await tester.pumpAndSettle();
      expect(row('active'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('hermes-session-menu-pin')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unpin'));
      await tester.pumpAndSettle();
      expect(find.byKey(pinnedKey), findsNothing);
      expect(row('pin'), findsNothing);
      await tester.tap(find.byKey(chatsKey));
      await tester.pumpAndSettle();
      expect(row('pin'), findsOneWidget);
      expect(row('active'), findsOneWidget);
      expect(channel.selectSessionCalls, isEmpty);
    });
  }
}

void additionalCases(double width) {
  testWidgets('draft and volatile recreation at $width', (tester) async {
    final channel = await pumpChat(tester, width);
    if (width < 600) {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }
    final composer = find.byKey(const ValueKey('hermes-composer-field'));
    await tester.enterText(composer, 'Synthetic unsent draft');
    await tester.pumpAndSettle();
    if (width < 600) {
      await tester.tap(
        find.byKey(const ValueKey('hermes-more-actions-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sessions'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(pinnedKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(chatsKey));
    await tester.pumpAndSettle();
    expect(channel.state.activeSessionId, 'active');
    expect(channel.selectSessionCalls, isEmpty);
    expect(channel.sentImageDataUrls, isEmpty);
    if (width < 600) {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(composer).controller!.text,
        'Synthetic unsent draft',
      );
      await tester.tap(
        find.byKey(const ValueKey('hermes-more-actions-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sessions'));
      await tester.pumpAndSettle();
    } else {
      expect(
        tester.widget<TextField>(composer).controller!.text,
        'Synthetic unsent draft',
      );
      tester.view.physicalSize = const Size(390, 1000);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1280, 1000);
      await tester.pumpAndSettle();
    }
    expect(row('pin'), findsOneWidget);
    expect(row('active'), findsOneWidget);
  });

  testWidgets('hidden rows keep bulk selection and delete targets at $width', (
    tester,
  ) async {
    final channel = await pumpChat(tester, width);
    final prefix = width < 600 ? 'hermes-sessions' : 'hermes-session-rail';
    await tester.tap(find.byKey(ValueKey('$prefix-select')));
    await tester.pumpAndSettle();
    await tester.tap(row('pin'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byKey(pinnedKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(chatsKey));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('$prefix-select-all')));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('$prefix-delete-selected')));
    await tester.pumpAndSettle();
    expect(channel.deleteSessionCalls, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey('hermes-sessions-delete-confirm')),
    );
    await tester.pumpAndSettle();
    expect(channel.deleteSessionCalls, ['active', 'pin']);
  });

  testWidgets('source filter applies to hidden bulk targets at $width', (
    tester,
  ) async {
    final channel = await pumpChat(tester, width);
    channel.change(
      channel.state.copyWith(
        sessions: [
          ...channel.state.sessions,
          const HermesSession(id: 'other', source: 'other', title: 'Other'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(chatsKey));
    await tester.pumpAndSettle();
    final filterPrefix = width < 600 ? 'hermes-session' : 'hermes-session-rail';
    await tester.tap(find.byKey(ValueKey('$filterPrefix-source-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('other').last);
    await tester.pumpAndSettle();
    expect(find.byKey(pinnedKey), findsNothing);
    expect(row('other'), findsNothing);
    final prefix = width < 600 ? 'hermes-sessions' : 'hermes-session-rail';
    await tester.tap(find.byKey(ValueKey('$prefix-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('$prefix-select-all')));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byKey(chatsKey));
    await tester.pumpAndSettle();
    expect(row('other'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(channel.selectSessionCalls, isEmpty);
  });

  testWidgets('empty inventory is not collapsed inventory at $width', (
    tester,
  ) async {
    final channel = await pumpChat(tester, width);
    channel.change(channel.state.copyWith(sessions: const []));
    await tester.pumpAndSettle();
    expect(find.byKey(pinnedKey), findsNothing);
    expect(find.byKey(chatsKey), findsNothing);
    expect(find.textContaining('No'), findsWidgets);
    expect(channel.createSessionCalls, isEmpty);
  });

  for (final pending in [false, true]) {
    testWidgets(
      'disclosure preserves ${pending ? 'pending' : 'failed'} selection at $width',
      (tester) async {
        final channel = await pumpChat(tester, width);
        if (pending) channel.selectionGate = Completer<void>();
        channel.selectSessionFails = !pending;
        final selection = channel.selectSession('pin');
        if (!pending) await expectLater(selection, throwsStateError);
        await tester.tap(find.byKey(chatsKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(chatsKey));
        await tester.pumpAndSettle();
        expect(channel.state.activeSessionId, 'active');
        expect(channel.selectSessionCalls, ['pin']);
        if (pending) {
          channel.selectionGate!.complete();
          await selection;
          await tester.pumpAndSettle();
          expect(channel.state.activeSessionId, 'pin');
        }
      },
    );
  }

  testWidgets('200 percent text reduced motion short window at $width', (
    tester,
  ) async {
    await pumpChat(tester, width, scale: 2, height: 700);
    await tester.scrollUntilVisible(
      find.byKey(pinnedKey),
      -100,
      scrollable: find.descendant(
        of: find.byKey(
          ValueKey(
            width < 600 ? 'hermes-sessions-list' : 'hermes-session-rail-list',
          ),
        ),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tabTo(tester, pinnedKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(focusedKey(pinnedKey), isTrue);
    await tabTo(tester, chatsKey);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(row('pin'), findsNothing);
    expect(row('active'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('channel replacement resets with reused session IDs at $width', (
    tester,
  ) async {
    final channel = await pumpChat(tester, width);
    await tester.tap(find.byKey(chatsKey));
    await tester.pumpAndSettle();
    final stale = tester
        .widget<TextButton>(
          find.descendant(
            of: find.byKey(chatsKey),
            matching: find.byType(TextButton),
          ),
        )
        .onPressed!;
    final replacement = DisclosureChannel();
    addTearDown(replacement.dispose);
    await tester.pumpWidget(chatApp(replacement));
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(row('active'), findsOneWidget);
    expect(replacement.selectSessionCalls, isEmpty);
    expect(channel.selectSessionCalls, isEmpty);
  });
}

class DisclosureChannel extends FakeHermesChannel {
  DisclosureChannel()
    : super(
        sessions: const [
          HermesSession(id: 'active', source: 'manual', title: 'Active'),
          HermesSession(id: 'pin', source: 'manual', title: 'Pinned example'),
        ],
        activeSessionId: 'active',
      );
  HermesChannelState? replacement;
  Completer<void>? selectionGate;
  @override
  Future<void> selectSession(String id, {bool Function()? canAccept}) async {
    if (selectionGate == null) {
      return super.selectSession(id, canAccept: canAccept);
    }
    selectSessionCalls.add(id);
    await selectionGate!.future;
    if (canAccept?.call() ?? true) change(state.copyWith(activeSessionId: id));
  }

  @override
  HermesChannelState get state => replacement ?? super.state;
  void change(HermesChannelState value) {
    replacement = value;
    notifyListeners();
  }
}

Future<DisclosureChannel> pumpChat(
  WidgetTester tester,
  double width, {
  double scale = 1,
  double height = 1000,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = DisclosureChannel();
  addTearDown(channel.dispose);
  await tester.pumpWidget(chatApp(channel, scale: scale));
  await tester.pumpAndSettle();
  if (width < 600) {
    await tester.tap(find.byKey(const ValueKey('hermes-more-actions-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sessions'));
    await tester.pumpAndSettle();
  }
  final menu = find.byKey(const ValueKey('hermes-session-menu-pin'));
  if (menu.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      menu,
      100,
      scrollable: find.descendant(
        of: find.byKey(
          ValueKey(
            width < 600 ? 'hermes-sessions-list' : 'hermes-session-rail-list',
          ),
        ),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      ),
    );
  } else {
    await tester.ensureVisible(menu);
  }
  await tester.pumpAndSettle();
  await tester.ensureVisible(menu);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('hermes-session-menu-pin')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pin'));
  await tester.pumpAndSettle();
  return channel;
}

Widget chatApp(DisclosureChannel channel, {double scale = 1}) => ProviderScope(
  overrides: [hermesChannelProvider.overrideWithValue(channel)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: const HermesChatScreen(),
  ),
);

bool focusedKey(Key key) {
  var found = false;
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((element) {
    if (element.widget.key == key) found = true;
    return !found;
  });
  return found;
}

Future<void> tabTo(
  WidgetTester tester,
  Key key, {
  bool backwards = false,
}) async {
  for (var i = 0; i < 100 && !focusedKey(key); i++) {
    if (backwards) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (backwards) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
  }
  expect(focusedKey(key), isTrue, reason: 'Keyboard must reach $key');
}
