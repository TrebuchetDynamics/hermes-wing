import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

final _source = StateProvider<HermesChannel>((_) => throw UnimplementedError());
Finder _queueKey(String suffix) =>
    find.byKey(ValueKey('hermes-queued-follow-up-$suffix'));
final _composerKey = find.byKey(const ValueKey('hermes-composer-field'));

Future<void> _frames(WidgetTester tester) async {
  // Streaming is intentionally indefinite; pumpAndSettle would never finish.
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
    for (final transition in [
      'profile',
      'profile-roundtrip',
      'origin',
      'origin-roundtrip',
      'session',
      'session-roundtrip',
      'contact',
      'contact-roundtrip',
      'channel',
      'channel-roundtrip',
      'disconnect',
      'disconnect-roundtrip',
      'replacement-queue',
      'dispose',
    ]) {
      testWidgets('queued Open rejects stale $transition failure at $width', (
        tester,
      ) async {
        final h = await _pump(tester, width);
        await h.parkQueue(tester);
        await _open(tester, width);
        expect(h.channel.selectSessionCalls, ['sess_1']);
        final original = h.channel.state;
        _QueueChannel? replacement;
        switch (transition) {
          case 'profile':
          case 'profile-roundtrip':
            // Session IDs deliberately remain identical in the other profile.
            h.channel.change(original.copyWith(selectedProfileId: 'b'));
            if (transition.endsWith('roundtrip')) h.channel.change(original);
          case 'origin':
          case 'origin-roundtrip':
            h.channel.change(
              original.copyWith(connectedBaseUrl: 'https://other.invalid'),
            );
            if (transition.endsWith('roundtrip')) h.channel.change(original);
          case 'session':
          case 'session-roundtrip':
            h.channel.change(original.copyWith(activeSessionId: 'sess_1'));
            if (transition.endsWith('roundtrip')) h.channel.change(original);
          case 'contact':
          case 'contact-roundtrip':
            h.directory.change(
              const GatewayContactId(gatewayId: 'other', profileId: 'a'),
            );
            if (transition.endsWith('roundtrip')) h.directory.change(null);
          case 'channel':
          case 'channel-roundtrip':
            replacement = _QueueChannel();
            addTearDown(replacement.dispose);
            replacement.change(original);
            h.container.read(_source.notifier).state = replacement;
            // Force provider notification before returning: no frame between A-B-A.
            h.container.read(hermesChannelProvider);
            if (transition.endsWith('roundtrip')) {
              h.container.read(_source.notifier).state = h.channel;
              h.container.read(hermesChannelProvider);
            }
          case 'disconnect':
          case 'disconnect-roundtrip':
          case 'replacement-queue':
            h.channel.change(
              original.copyWith(status: HermesConnectionStatus.disconnected),
            );
            if (transition != 'disconnect') {
              h.channel.change(
                transition == 'replacement-queue'
                    ? original.copyWith(selectedProfileId: 'b')
                    : original,
              );
              // Admit new work through the real composer after lifecycle reset.
              await h.enqueue(tester, 'Replacement');
              await tester.enterText(_composerKey, 'Replacement draft');
            }
          case 'dispose':
            h.page.value = const SizedBox();
        }
        await _frames(tester);
        final queueBefore = _queueSummary(tester);
        final draftBefore = _draft(tester);
        h.channel.reject();
        await _frames(tester);
        expect(tester.takeException(), isNull);
        expect(
          _queueKey('error'),
          findsNothing,
          reason:
              'An obsolete selection must not add replacement-owner feedback',
        );
        expect(_queueSummary(tester), queueBefore);
        expect(_draft(tester), draftBefore);
        expect(h.channel.selectSessionCalls, ['sess_1']);
        expect(h.channel.sent, isEmpty);
        expect(replacement?.selectSessionCalls ?? [], isEmpty);
        expect(replacement?.sent ?? [], isEmpty);
        if (_queueKey('manage').evaluate().isNotEmpty) {
          await tester.tap(_queueKey('manage'));
          await _frames(tester);
          expect(
            find.text(
              transition == 'replacement-queue' ||
                      transition == 'disconnect-roundtrip'
                  ? 'Replacement'
                  : 'Queued original',
            ),
            findsOneWidget,
          );
          expect(_queueKey('remove-1'), findsNothing);
          await tester.tap(find.text('Close'));
          await _frames(tester);
        }
      });
    }
    testWidgets('same-owner queued Open failure stays actionable at $width', (
      tester,
    ) async {
      final h = await _pump(tester, width);
      await h.parkQueue(tester);
      final queueBefore = _queueSummary(tester);
      final draftBefore = _draft(tester);
      await _open(tester, width);
      h.channel.reject();
      await _frames(tester);
      expect(tester.takeException(), isNull);
      expect(_queueKey('error'), findsOneWidget);
      final error = tester
          .widget<Semantics>(_queueKey('error'))
          .properties
          .label!;
      expect(error, contains('Could not open queued follow-up session:'));
      expect(error, contains('Selection unavailable'));
      expect(error, contains('[redacted]'));
      expect(error, isNot(contains('secret-example')));
      expect(_queueSummary(tester), queueBefore);
      expect(_draft(tester), draftBefore);
      expect(h.channel.sent, isEmpty);
      expect(h.channel.selectSessionCalls, ['sess_1']);
      h.channel.selection = Completer<void>();
      await _open(tester, width);
      expect(h.channel.selectSessionCalls, ['sess_1', 'sess_1']);
      h.channel.reject();
      await _frames(tester);
      expect(_queueKey('error'), findsOneWidget);
      expect(h.channel.sent, isEmpty);
    });
  }
}

String? _draft(WidgetTester tester) => _composerKey.evaluate().isEmpty
    ? null
    : tester.widget<TextField>(_composerKey).controller!.text;

List<String?> _queueSummary(WidgetTester tester) => find
    .descendant(
      of: find.byKey(const ValueKey('hermes-queued-follow-up')),
      matching: find.byType(Text),
    )
    .evaluate()
    .map((element) => (element.widget as Text).data)
    .toList();

Future<void> _open(WidgetTester tester, double width) async {
  if (width < 600) {
    await tester.tap(_queueKey('more-actions'));
    await _frames(tester);
    await tester.tap(find.text('Open session'));
  } else {
    await tester.tap(_queueKey('open-session'));
  }
  await _frames(tester);
}

class _QueueChannel extends FakeHermesChannel {
  _QueueChannel()
    : super(
        selectedProfileId: 'a',
        connectedBaseUrl: 'https://example.invalid',
        sessions: const [
          HermesSession(id: 'sess_1', source: 'fake'),
          HermesSession(id: 'sess_2', source: 'fake'),
        ],
      ) {
    beginStreamingTurn('Running');
    // Keep both sessions busy so owner changes cannot drain the queue.
    final initial = super.state;
    _replacement = initial.copyWith(
      messages: {...initial.messages, 'sess_2': initial.messages['sess_1']!},
    );
  }
  HermesChannelState? _replacement;
  Completer<void> selection = Completer<void>();
  final sent = <String>[];
  @override
  HermesChannelState get state => _replacement ?? super.state;
  void change(HermesChannelState value) {
    _replacement = value;
    notifyListeners();
  }

  @override
  Future<void> selectSession(String sessionId, {bool Function()? canAccept}) {
    selectSessionCalls.add(sessionId);
    return selection.future;
  }

  void reject() => selection.completeError(
    StateError('Selection unavailable secret-example'),
  );

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
  @override
  GatewayContactId? get activeContactId => _contact;
  void change(GatewayContactId? contact) {
    _contact = contact;
    notifyListeners();
  }
}

class _Harness {
  _Harness(this.channel, this.container, this.page, this.directory);
  final _QueueChannel channel;
  final ProviderContainer container;
  final ValueNotifier<Widget> page;
  final _QueueDirectory directory;

  Future<void> enqueue(WidgetTester tester, String text) async {
    await tester.enterText(_composerKey, text);
    await _frames(tester);
    await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
    await _frames(tester);
  }

  Future<void> parkQueue(WidgetTester tester) async {
    await enqueue(tester, 'Queued original');
    channel.change(channel.state.copyWith(activeSessionId: 'sess_2'));
    await _frames(tester);
    await tester.enterText(_composerKey, 'Parked session draft');
    await _frames(tester);
    expect(_queueKey('error'), findsNothing);
    expect(_queueKey('manage'), findsOneWidget);
    expect(channel.sent, isEmpty);
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
  return _Harness(channel, container, page, directory);
}
