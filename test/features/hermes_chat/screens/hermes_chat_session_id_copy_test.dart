import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

final targetId = '  opaque-会話-${List.filled(150, 'x').join()}  ';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  for (final width in [390.0, 1280.0]) {
    testWidgets('exact ID action exists separately at $width', (tester) async {
      await pumpChat(tester, width);
      await openMenu(tester);
      expect(find.text('Copy session ID'), findsOneWidget);
      expect(find.text('Copy details'), findsOneWidget);
    });
    for (final outcome in [
      'success',
      'failure',
      'disposed',
      'profile',
      'origin',
      'row',
      'roundtrip',
      'disposed failure',
      'profile failure',
      'origin failure',
      'row failure',
    ]) {
      testWidgets('ID clipboard $outcome at $width', (tester) async {
        final channel = await pumpChat(tester, width);
        final initial = channel.state;
        final semantics = tester.ensureSemantics();

        final gate = Completer<void>();
        final writes = clipboard(tester, gate);
        await openMenu(tester);
        await tester.tap(find.text('Copy session ID'));
        await tester.pumpAndSettle();
        expect(writes, [targetId]);
        expect(find.text('Copied session ID.'), findsNothing);
        expect(
          find.text('Could not copy session ID. Try again.'),
          findsNothing,
        );
        expect(identical(channel.state, initial), isTrue);
        expect(channel.selectSessionCalls, isEmpty);
        expect(channel.createSessionCalls, isEmpty);
        expect(channel.sentImageDataUrls, isEmpty);
        if (outcome.startsWith('disposed')) {
          await tester.pumpWidget(const SizedBox.shrink());
        } else if (!['success', 'failure'].contains(outcome)) {
          invalidate(channel, outcome.split(' ').first);
          await tester.pumpAndSettle();
        }
        if (outcome.endsWith('failure')) {
          gate.completeError(
            PlatformException(
              code: 'rejected',
              message: 'private-diagnostic-marker',
            ),
          );
        } else {
          gate.complete();
        }
        await tester.pumpAndSettle();
        expect(writes, [targetId]);
        expect(
          find.text('Copied session ID.'),
          outcome == 'success' ? findsOneWidget : findsNothing,
        );
        final failure = find.text('Could not copy session ID. Try again.');
        expect(failure, outcome == 'failure' ? findsOneWidget : findsNothing);
        expect(find.textContaining('private-diagnostic-marker'), findsNothing);
        expect(tester.takeException(), isNull);
        if (outcome == 'failure') {
          expect(
            tester.getSemantics(failure).flagsCollection.isLiveRegion,
            isTrue,
          );

          await openMenu(tester);
          await tester.tap(find.text('Copy session ID'));
          await tester.pumpAndSettle();
          expect(writes, [targetId, targetId]);
          expect(find.text('Copied session ID.'), findsOneWidget);
          expect(identical(channel.state, initial), isTrue);
        }
        semantics.dispose();
      });
    }
    for (final transition in ['profile', 'origin', 'row', 'roundtrip']) {
      testWidgets('unactivated stale menu $transition at $width', (
        tester,
      ) async {
        final channel = await pumpChat(tester, width);
        final writes = clipboard(tester, Completer<void>()..complete());
        await openMenu(tester);
        invalidate(channel, transition);
        // Submit before rebuilding: invalidation must be synchronous.
        await tester.tap(find.text('Copy session ID'));
        await tester.pumpAndSettle();
        expect(writes, isEmpty);
        expect(find.text('Copied session ID.'), findsNothing);
        expect(channel.selectSessionCalls, isEmpty);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('disposed row rejects open menu at $width', (tester) async {
      final channel = await pumpChat(tester, width);
      final writes = clipboard(tester, Completer<void>()..complete());
      await openMenu(tester);
      invalidate(channel, 'row');
      await tester.pump();
      expect(
        find.byKey(ValueKey('hermes-session-row-$targetId')),
        findsNothing,
      );
      expect(find.text('Copy session ID'), findsOneWidget);
      await tester.tap(find.text('Copy session ID'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(tester.takeException(), isNull);
    });
    testWidgets('overlap and removed row roundtrip at $width', (tester) async {
      final channel = await pumpChat(tester, width);
      final original = channel.state;
      final gate = Completer<void>();
      final writes = clipboard(tester, gate);
      await openMenu(tester);
      await tester.tap(find.text('Copy session ID'));
      await tester.pumpAndSettle();
      await openMenu(tester);
      await tester.tap(find.text('Copy session ID'));
      await tester.pumpAndSettle();
      expect(writes, [targetId]);
      invalidate(channel, 'row');
      channel.change(original);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Copied session ID.'), findsNothing);
      expect(writes, [targetId]);
    });
    testWidgets('keyboard ID copy and Escape at $width', (tester) async {
      final channel = await pumpChat(tester, width, keyboard: true);
      final initial = channel.state;
      final writes = clipboard(tester, Completer<void>()..complete());
      final key = ValueKey('hermes-session-menu-$targetId');
      await tabTo(tester, key);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Copy session ID'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Copy session ID'), findsNothing);
      expect(writes, isEmpty);
      await tabTo(tester, key);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      for (var i = 0; i < 8 && !focusedText('Copy session ID'); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      expect(focusedText('Copy session ID'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(writes, [targetId]);
      expect(identical(channel.state, initial), isTrue);
      expect(channel.selectSessionCalls, isEmpty);
    });
  }
}

Future<OwnerChannel> pumpChat(
  WidgetTester tester,
  double width, {
  bool keyboard = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = OwnerChannel(
    sessions: [
      const HermesSession(id: 'active', source: 'api_server', title: 'Active'),
      HermesSession(
        id: targetId,
        source: 'api_server',
        title: 'Target',
        preview: 'Excluded synthetic transcript',
      ),
    ],
    activeSessionId: 'active',
  );
  addTearDown(channel.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hermesChannelProvider.overrideWithValue(channel)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (width < 600) {
    if (keyboard) {
      await tabTo(tester, const ValueKey('hermes-more-actions-button'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      for (var i = 0; i < 8 && !focusedText('Sessions'); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      expect(focusedText('Sessions'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    } else {
      await tester.tap(
        find.byKey(const ValueKey('hermes-more-actions-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sessions'));
    }
    await tester.pumpAndSettle();
  }
  return channel;
}

Future<void> openMenu(WidgetTester tester) async {
  final menu = find.byKey(ValueKey('hermes-session-menu-$targetId'));
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await tester.pumpAndSettle();
}

List<String> clipboard(WidgetTester tester, Completer<void> gate) {
  final writes = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.getData') {
        fail('Clipboard reads are forbidden');
      }
      if (call.method == 'Clipboard.setData') {
        writes.add((call.arguments as Map)['text'] as String);
        if (writes.length == 1) await gate.future;
      }
      return null;
    },
  );
  addTearDown(() {
    if (!gate.isCompleted) gate.complete();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
  return writes;
}

void invalidate(OwnerChannel channel, String transition) {
  final original = channel.state;
  channel.change(switch (transition) {
    'origin' => original.copyWith(
      connectedBaseUrl: 'https://replacement.invalid',
    ),
    'row' => original.copyWith(
      sessions: original.sessions.where((row) => row.id != targetId).toList(),
    ),
    _ => original.copyWith(selectedProfileId: 'replacement'),
  });
  if (transition == 'roundtrip') channel.change(original);
}

class OwnerChannel extends FakeHermesChannel {
  OwnerChannel({super.sessions, super.activeSessionId});
  HermesChannelState? replacement;
  @override
  HermesChannelState get state => replacement ?? super.state;
  void change(HermesChannelState next) {
    replacement = next;
    notifyListeners();
  }
}

bool focusedKey(Key key) {
  var found = false;
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((element) {
    if (element.widget.key == key) found = true;
    return !found;
  });
  return found;
}

bool focusedText(String text) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context is! Element) return false;
  if (FocusManager.instance.primaryFocus is FocusScopeNode) return false;
  var found = false;
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Text && widget.data == text) found = true;
    element.visitChildren(visit);
  }

  visit(context);
  return found;
}

Future<void> tabTo(WidgetTester tester, Key key) async {
  for (var i = 0; i < 80 && !focusedKey(key); i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(focusedKey(key), isTrue, reason: 'Tab must reach selected row menu');
}
