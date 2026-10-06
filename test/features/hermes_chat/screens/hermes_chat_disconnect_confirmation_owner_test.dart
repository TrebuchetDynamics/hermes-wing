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

final _channelSource = StateProvider<HermesChannel>(
  (_) => throw UnimplementedError(),
);
final _directorySource = StateProvider<HermesGatewayDirectory>(
  (_) => throw UnimplementedError(),
);

class _Channel extends FakeHermesChannel {
  _Channel() : super(connectedBaseUrl: 'https://example.invalid');
  HermesChannelState? replacement;
  @override
  HermesChannelState get state => replacement ?? super.state;
  void change(HermesChannelState next) {
    replacement = next;
    notifyListeners();
  }

  @override
  Future<void> disconnect() {
    replacement = null;
    return super.disconnect();
  }
}

class _Cache extends FakeGatewayContactCache {
  int clears = 0;
  @override
  Future<void> clearSelection() {
    clears++;
    return super.clearSelection();
  }
}

class _Directory extends HermesGatewayDirectory {
  _Directory(_Channel channel, FakeHermesEndpointStore store, _Cache cache)
    : super(
        store: store,
        cache: cache,
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
  GatewayContactId? contact;
  GatewayContact? displayedContact;
  @override
  GatewayContact? get activeContact => displayedContact;
  int shows = 0;
  bool disposed = false;
  @override
  void dispose() {
    if (disposed) return;
    disposed = true;
    super.dispose();
  }

  @override
  GatewayContactId? get activeContactId => contact;
  void changeContact(GatewayContactId? next) {
    contact = next;
    notifyListeners();
  }

  @override
  Future<void> showDirectory() {
    shows++;
    contact = null;
    return super.showDirectory();
  }
}

Future<
  ({
    _Channel channel,
    _Directory directory,
    _Cache cache,
    FakeHermesEndpointStore store,
    ProviderContainer container,
    ValueNotifier<Widget> page,
  })
>
_mount(WidgetTester tester, double width) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final channel = _Channel();
  final store = FakeHermesEndpointStore();
  final cache = _Cache();
  final directory = _Directory(channel, store, cache);
  addTearDown(channel.dispose);
  addTearDown(directory.dispose);
  final container = ProviderContainer(
    overrides: [
      _channelSource.overrideWith((_) => channel),
      _directorySource.overrideWith((_) => directory),
      hermesChannelProvider.overrideWith((ref) => ref.watch(_channelSource)),
      hermesGatewayDirectoryProvider.overrideWith(
        (ref) => ref.watch(_directorySource),
      ),
      hermesEndpointStoreProvider.overrideWithValue(store),
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
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('hermes-composer-field')),
    'Retained draft',
  );
  return (
    channel: channel,
    directory: directory,
    cache: cache,
    store: store,
    container: container,
    page: page,
  );
}

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _open(WidgetTester tester, double width) async {
  if (width < 480) {
    await tester.tap(
      find.byKey(const ValueKey('hermes-more-actions-button')).hitTestable(),
    );
    await _frames(tester);
    await tester.tap(find.text('Disconnect').hitTestable());
  } else {
    await tester.tap(
      find.byKey(const ValueKey('hermes-disconnect-button')).hitTestable(),
    );
  }
  await _frames(tester);
  expect(
    find.byKey(const ValueKey('hermes-disconnect-confirm-dialog')),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull);
}

void _noOtherMutations(_Channel channel, FakeHermesEndpointStore store) {
  expect(channel.connectCalls, isEmpty);
  expect(channel.sentTextAttachments, isEmpty);
  expect(channel.sentVoiceTranscripts, isEmpty);
  expect(channel.createSessionCalls, isEmpty);
  expect(channel.selectSessionCalls, isEmpty);
  expect(channel.respondToApprovalCalls, isEmpty);
  expect(channel.renameSessionCalls, isEmpty);
  expect(channel.deleteSessionCalls, isEmpty);
  expect(channel.forkSessionCalls, isEmpty);
  expect(channel.selectProfileCalls, isEmpty);
  expect(store.saveCalls, isEmpty);
  expect(store.saveAllCalls, isEmpty);
  expect(store.deleteProfileCalls, isEmpty);
  expect(store.clearCalls, 0);
}

void main() {
  for (final width in [1280.0, 390.0]) {
    testWidgets(
      'Stale Disconnect retains queued work and approvals at $width',
      (tester) async {
        final h = await _mount(tester, width);
        h.channel.beginStreamingTurn('Synthetic active work');
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('hermes-composer-field')),
          'Queued work',
        );
        await _frames(tester);
        await tester.tap(
          find.byKey(const ValueKey('hermes-send-button')).hitTestable(),
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('hermes-composer-field')),
          'Retained draft',
        );
        h.channel.emitApprovalRequest(
          const HermesApprovalRequest(
            id: 'pending',
            toolCallId: 'tool',
            prompt: 'Synthetic approval',
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('hermes-approval-banner')),
          findsOneWidget,
        );
        expect(find.textContaining('Queued work'), findsOneWidget);
        await _open(tester, width);
        h.directory.changeContact(
          const GatewayContactId(gatewayId: 'other', profileId: 'other'),
        );
        h.directory.changeContact(null);
        await tester.tap(
          find.byKey(const ValueKey('hermes-disconnect-confirm')).hitTestable(),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(h.directory.shows, 0);
        expect(h.channel.disconnectCalls, 0);
        expect(h.cache.clears, 0);
        expect(
          find.byKey(const ValueKey('hermes-approval-banner')),
          findsOneWidget,
        );
        expect(find.textContaining('Queued work'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('hermes-composer-field')),
              )
              .controller!
              .text,
          'Retained draft',
        );
        _noOtherMutations(h.channel, h.store);
        h.page.value = const SizedBox.shrink();
        await tester.pump();
      },
    );
    for (final transition in [
      'unchanged',
      'cancel',
      'channel',
      'channel return',
      'contact',
      'contact return',
      'origin',
      'origin return',
      'connection return',
      'profile return',
      'session return',
      'directory',
      'unmount',
      'metadata',
      'label',
    ]) {
      testWidgets('Disconnect confirmation $transition at $width', (
        tester,
      ) async {
        final h = await _mount(tester, width);
        if (transition == 'label') {
          h.directory.displayedContact = const GatewayContact(
            id: GatewayContactId(gatewayId: 'original', profileId: 'default'),
            gatewayLabel: 'Original label',
            profileName: 'Default',
            sessionCount: 1,
            availability: GatewayAvailability.online,
          );
          h.directory.changeContact(h.directory.displayedContact!.id);
          await tester.pumpAndSettle();
        }
        await _open(tester, width);
        final original = h.channel.state;
        final other = _Channel();
        final otherCache = _Cache();
        final otherDirectory = _Directory(other, h.store, otherCache);
        addTearDown(other.dispose);
        addTearDown(otherDirectory.dispose);
        switch (transition) {
          case 'channel':
          case 'channel return':
            h.container.read(_channelSource.notifier).state = other;
            h.container.read(hermesChannelProvider);
            if (transition == 'channel return') {
              h.container.read(_channelSource.notifier).state = h.channel;
              h.container.read(hermesChannelProvider);
            }
          case 'directory':
            h.container.read(_directorySource.notifier).state = otherDirectory;
            h.container.read(hermesGatewayDirectoryProvider);
          case 'contact':
          case 'contact return':
            h.directory.changeContact(
              const GatewayContactId(gatewayId: 'other', profileId: 'other'),
            );
            if (transition == 'contact return') h.directory.changeContact(null);
          case 'origin':
          case 'origin return':
            h.channel.change(
              original.copyWith(
                connectedBaseUrl: 'https://replacement.invalid',
              ),
            );
            if (transition == 'origin return') h.channel.change(original);
          case 'connection return':
            h.channel.change(
              original.copyWith(status: HermesConnectionStatus.disconnected),
            );
            h.channel.change(original);
          case 'profile return':
            h.channel.change(original.copyWith(selectedProfileId: 'other'));
            h.channel.change(original);
          case 'session return':
            h.channel.change(original.copyWith(activeSessionId: 'other'));
            h.channel.change(original);
          case 'unmount':
            h.page.value = const SizedBox.shrink();
          case 'metadata':
            h.channel.change(
              original.copyWith(errorMessage: 'Synthetic informational change'),
            );
          case 'label':
            h.directory.displayedContact = h.directory.displayedContact!
                .copyWith(gatewayLabel: 'New label');
            h.directory.notifyListeners();
        }
        await tester.pumpAndSettle();
        final composer = find.byKey(const ValueKey('hermes-composer-field'));
        final draft = composer.evaluate().isEmpty
            ? null
            : tester.widget<TextField>(composer).controller!.text;
        await tester.tap(
          find
              .byKey(
                ValueKey(
                  transition == 'cancel'
                      ? 'hermes-disconnect-cancel'
                      : 'hermes-disconnect-confirm',
                ),
              )
              .hitTestable(),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final admitted =
            transition == 'unchanged' ||
            transition == 'metadata' ||
            transition == 'label';
        expect(h.directory.shows, admitted ? 1 : 0);
        expect(h.channel.disconnectCalls, admitted ? 1 : 0);
        expect(h.cache.clears, admitted ? 1 : 0);
        expect(otherDirectory.shows, 0);
        expect(other.disconnectCalls, 0);
        expect(otherCache.clears, 0);
        _noOtherMutations(h.channel, h.store);
        _noOtherMutations(other, h.store);
        if (!admitted && draft != null) {
          expect(tester.widget<TextField>(composer).controller!.text, draft);
        }
        h.page.value = const SizedBox.shrink();
        await tester.pumpAndSettle();
      });
    }
  }
}
