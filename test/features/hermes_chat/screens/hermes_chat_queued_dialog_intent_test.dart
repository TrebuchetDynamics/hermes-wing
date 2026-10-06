import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

final _source = StateProvider<HermesChannel>((_) => throw UnimplementedError());
Finder _key(String name) =>
    find.byKey(ValueKey('hermes-queued-follow-up-$name'));
Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  for (final width in [390.0, 1280.0]) {
    for (final operation in ['manage', 'clear']) {
      testWidgets('$operation rejects replacement queue at $width', (
        tester,
      ) async {
        final h = await _pump(tester, width);
        await h.enqueue(tester, 'Original');
        await _open(tester, width, operation);
        final stale = _action(tester, operation);
        // A connection loss clears the real screen queue. The root dialog survives.
        final owner = h.channel.state;
        h.channel.change(
          owner.copyWith(status: HermesConnectionStatus.disconnected),
        );
        h.channel.change(owner.copyWith(selectedProfileId: 'b'));
        // Exercise the retained production composer callback, as an in-flight action,
        // without bypassing queue admission or accessing private screen state.
        h.enqueueRetained('Replacement');
        stale();
        await _frames(tester);
        expect(tester.takeException(), isNull);
        await _close(tester);
        expect(
          _key('manage'),
          findsOneWidget,
          reason: 'Stale owner A action must not delete owner B work',
        );
        expect(h.channel.sent, isEmpty);
        expect(h.channel.listeners.length, h.baseline);
      });
      for (final transition in [
        'roundtrip',
        'origin',
        'session',
        'selecting',
        'replacement',
        'replacement-roundtrip',
        'contact',
        'contact-roundtrip',
        'disconnect',
        'unmount',
      ]) {
        testWidgets('$operation invalidates $transition at $width', (
          tester,
        ) async {
          final h = await _pump(tester, width);
          await h.enqueue(tester, 'Original');
          final beforeDialog = h.channel.listeners.toSet();
          await _open(tester, width, operation);
          final dialogObservers = h.channel.listeners.difference(beforeDialog);
          expect(dialogObservers, hasLength(1));
          final stale = _action(tester, operation);
          final original = h.channel.state;
          switch (transition) {
            case 'roundtrip':
              h.channel.change(original.copyWith(selectedProfileId: 'b'));
              h.channel.change(original);
            case 'origin':
              h.channel.change(
                original.copyWith(
                  connectedBaseUrl: 'https://replacement.invalid',
                ),
              );
            case 'session':
              h.channel.change(original.copyWith(activeSessionId: 'other'));
            case 'selecting':
              h.channel.change(original.copyWith(isSelectingProfile: true));
              h.channel.change(original);
            case 'replacement':
            case 'replacement-roundtrip':
              final replacement = _QueueChannel();
              addTearDown(replacement.dispose);
              h.container.read(_source.notifier).state = replacement;
              h.container.read(hermesChannelProvider);
              if (transition == 'replacement-roundtrip') {
                h.container.read(_source.notifier).state = h.channel;
                h.container.read(hermesChannelProvider);
              }
            case 'contact':
            case 'contact-roundtrip':
              h.directory.change(
                const GatewayContactId(gatewayId: 'other', profileId: 'a'),
              );
              if (transition == 'contact-roundtrip') h.directory.change(null);
            case 'disconnect':
              h.channel.change(
                original.copyWith(status: HermesConnectionStatus.disconnected),
              );
              h.channel.change(original);
              h.enqueueRetained('Replacement');
            case 'unmount':
              h.page.value = const SizedBox();
              await tester.pump();
              expect(h.channel.listeners.length, 1);
              expect(h.directory.listeners.length, h.directoryBaseline - 1);
          }
          stale();
          await _frames(tester);
          expect(tester.takeException(), isNull);
          if (operation == 'manage') await _close(tester);
          expect(h.channel.sent, isEmpty);
          if (transition == 'unmount') {
            expect(h.channel.listeners.length, 1);
          } else {
            // Return only after the stale callback; fresh intent must see retained work.
            h.container.read(_source.notifier).state = h.channel;
            h.container.read(hermesChannelProvider);
            h.directory.change(null);
            h.channel.change(original);
            await _frames(tester);
            expect(_key('manage'), findsOneWidget);
            expect(h.channel.listeners.intersection(dialogObservers), isEmpty);
            expect(h.directory.listeners.length, h.directoryBaseline);
          }
        });
      }
      for (final cancel in [false, true]) {
        testWidgets('$operation same-owner cancel=$cancel at $width', (
          tester,
        ) async {
          final h = await _pump(tester, width);
          await h.enqueue(tester, 'First');
          await h.enqueue(tester, 'Second');
          await _open(tester, width, operation);
          if (cancel) {
            if (operation == 'clear') {
              await tester.tap(_key('clear-keep'));
              await _frames(tester);
            } else {
              await _close(tester);
            }
          } else if (operation == 'clear') {
            await tester.tap(_key('clear-confirm'));
            await _frames(tester);
          } else {
            await tester.tap(_key('remove-0'));
            await _frames(tester);
            expect(find.text('Second'), findsOneWidget);
            expect(find.text('First'), findsNothing);
            await tester.tap(_key('remove-0'));
            await _frames(tester);
          }
          expect(find.byType(AlertDialog), findsNothing);
          expect(_key('manage'), cancel ? findsOneWidget : findsNothing);
          expect(h.channel.sent, isEmpty);
          expect(h.channel.listeners.length, h.baseline);
          expect(h.directory.listeners.length, h.directoryBaseline);
          expect(tester.takeException(), isNull);
        });
      }
    }
    for (final selected in [0, 1]) {
      testWidgets(
        'Manage addresses displayed row $selected after automatic send at $width',
        (tester) async {
          final h = await _pump(tester, width);
          for (final text in ['First', 'Second', 'Third']) {
            await h.enqueue(tester, text);
          }
          await _open(tester, width, 'manage');
          final stale = tester
              .widget<IconButton>(
                find.descendant(
                  of: _key('remove-$selected'),
                  matching: find.byType(IconButton),
                ),
              )
              .onPressed!;
          // Normal channel completion removes First via the unchanged automatic-send path.
          h.channel.change(h.channel.state.copyWith(messages: const {}));
          expect(h.channel.sent, ['First']);
          stale();
          await _frames(tester);
          expect(tester.takeException(), isNull);
          expect(find.text('Third'), findsOneWidget);
          expect(
            find.text('Second'),
            selected == 0 ? findsOneWidget : findsNothing,
          );
          await _close(tester);
          expect(h.channel.listeners.length, h.baseline);
        },
      );
    }
    testWidgets(
      'Manage closes safely when the displayed queue disappears at $width',
      (tester) async {
        final h = await _pump(tester, width);
        await h.enqueue(tester, 'First');
        final beforeDialog = h.channel.listeners.toSet();
        await _open(tester, width, 'manage');
        final dialogObservers = h.channel.listeners.difference(beforeDialog);
        expect(dialogObservers, hasLength(1));
        final stale = _action(tester, 'manage');
        h.channel.change(h.channel.state.copyWith(sessions: const []));
        stale();
        await _frames(tester);
        expect(find.byType(AlertDialog), findsNothing);
        expect(_key('manage'), findsNothing);
        expect(h.channel.sent, isEmpty);
        expect(h.channel.listeners.intersection(dialogObservers), isEmpty);
        expect(h.directory.listeners.length, h.directoryBaseline);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('completed Manage callbacks cannot act again at $width', (
      tester,
    ) async {
      final h = await _pump(tester, width);
      await h.enqueue(tester, 'First');
      await _open(tester, width, 'manage');
      final stale = _action(tester, 'manage');
      await _close(tester);
      stale();
      await _frames(tester);
      expect(_key('manage'), findsOneWidget);
      expect(h.channel.sent, isEmpty);
      expect(h.channel.listeners.length, h.baseline);
      expect(h.directory.listeners.length, h.directoryBaseline);
      expect(tester.takeException(), isNull);
    });
    testWidgets('same-owner additions retain Cancel All semantics at $width', (
      tester,
    ) async {
      final h = await _pump(tester, width);
      await h.enqueue(tester, 'First');
      await _open(tester, width, 'clear');
      h.enqueueRetained('Added');
      await tester.tap(_key('clear-confirm'));
      await _frames(tester);
      expect(_key('manage'), findsNothing);
      expect(h.channel.sent, isEmpty);
      expect(h.channel.listeners.length, h.baseline);
      expect(tester.takeException(), isNull);
    });
  }
}

VoidCallback _action(WidgetTester tester, String operation) =>
    operation == 'clear'
    ? tester.widget<FilledButton>(_key('clear-confirm')).onPressed!
    : tester
          .widget<IconButton>(
            find.descendant(
              of: _key('remove-0'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed!;

Future<void> _open(WidgetTester tester, double width, String operation) async {
  if (operation == 'manage') {
    await tester.tap(_key('manage'));
  } else if (width < 600) {
    await tester.tap(_key('more-actions'));
    await _frames(tester);
    await tester.tap(find.text('Cancel all'));
  } else {
    await tester.tap(_key('cancel'));
  }
  await _frames(tester);
  expect(find.byType(AlertDialog), findsOneWidget);
}

Future<void> _close(WidgetTester tester) async {
  if (_key('manage-dialog').evaluate().isNotEmpty) {
    await tester.tap(
      find.descendant(of: _key('manage-dialog'), matching: find.text('Close')),
    );
    await _frames(tester);
  }
}

class _QueueChannel extends FakeHermesChannel {
  _QueueChannel()
    : super(
        selectedProfileId: 'a',
        connectedBaseUrl: 'https://example.invalid',
      ) {
    beginStreamingTurn('Running');
  }
  HermesChannelState? _replacement;
  final listeners = <VoidCallback>{};
  final sent = <String>[];
  @override
  HermesChannelState get state => _replacement ?? super.state;
  void change(HermesChannelState value) {
    _replacement = value;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
    super.removeListener(listener);
  }

  @override
  Future<void> sendText(
    String text, {
    String? imageDataUrl,
    String? textAttachment,
    String? attachmentName,
  }) async {
    sent.add(text);
  }
}

class _QueueDirectory extends HermesGatewayDirectory {
  _QueueDirectory(FakeHermesEndpointStore store, _QueueChannel channel)
    : super(
        store: store,
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
  GatewayContactId? _contact;
  final listeners = <VoidCallback>{};
  @override
  GatewayContactId? get activeContactId => _contact;
  void change(GatewayContactId? contact) {
    _contact = contact;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
    super.removeListener(listener);
  }
}

class _Harness {
  _Harness(
    this.channel,
    this.container,
    this.page,
    this.composer,
    this.send,
    this.baseline,
    this.directory,
    this.directoryBaseline,
  );
  final _QueueChannel channel;
  final ProviderContainer container;
  final ValueNotifier<Widget> page;
  final TextEditingController composer;
  final VoidCallback send;
  final int baseline;
  final _QueueDirectory directory;
  final int directoryBaseline;
  void enqueueRetained(String text) {
    composer.text = text;
    send();
  }

  Future<void> enqueue(WidgetTester tester, String text) async {
    await tester.enterText(
      find.byKey(const ValueKey('hermes-composer-field')),
      text,
    );
    await _frames(tester);
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await _frames(tester);
  }
}

Future<_Harness> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = _QueueChannel();
  addTearDown(channel.dispose);
  final store = FakeHermesEndpointStore();
  final directory = _QueueDirectory(store, channel);
  final container = ProviderContainer(
    overrides: [
      _source.overrideWith((_) => channel),
      hermesChannelProvider.overrideWith((ref) => ref.watch(_source)),
      hermesEndpointStoreProvider.overrideWithValue(store),
      hermesGatewayDirectoryProvider.overrideWith((_) => directory),
      hermesVoiceCaptureServiceProvider.overrideWithValue(null),
      hermesTextToSpeechServiceProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  final page = ValueNotifier<Widget>(const HermesChatScreen());
  addTearDown(page.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ValueListenableBuilder<Widget>(
          valueListenable: page,
          builder: (_, child, _) => child,
        ),
      ),
    ),
  );
  await _frames(tester);
  expect(tester.takeException(), isNull);
  final composer = tester
      .widget<TextField>(find.byKey(const ValueKey('hermes-composer-field')))
      .controller!;
  // The button is enabled after text entry; retain that production callback.
  composer.text = 'Seed';
  await _frames(tester);
  final send = tester
      .widget<IconButton>(find.byKey(const ValueKey('hermes-send-button')))
      .onPressed!;
  composer.clear();
  await _frames(tester);
  return _Harness(
    channel,
    container,
    page,
    composer,
    send,
    channel.listeners.length,
    directory,
    directory.listeners.length,
  );
}
