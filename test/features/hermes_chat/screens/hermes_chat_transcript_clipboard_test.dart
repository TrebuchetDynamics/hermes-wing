import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

final _source = StateProvider<HermesChannel>((_) => throw UnimplementedError());
const _failure = 'Could not copy transcript. Try again.';

class _Channel extends FakeHermesChannel {
  _Channel() : super(selectedProfileId: 'a') {
    beginStreamingTurn('Synthetic question 日本語 😀');
    completeStreamingTurn(text: 'Synthetic **answer**.');
  }
  HermesChannelState? _replacement;
  @override
  HermesChannelState get state => _replacement ?? super.state;
  void change(HermesChannelState state) {
    _replacement = state;
    notifyListeners();
  }
}

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _options(WidgetTester tester, double width) async {
  if (width < 480) {
    await tester.tap(find.byKey(const ValueKey('hermes-more-actions-button')));
    await _frames(tester);
    await tester.tap(find.text('Copy transcript'));
  } else {
    await tester.tap(
      find.byKey(const ValueKey('hermes-copy-transcript-button')),
    );
  }
  await _frames(tester);
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    }),
  );
  for (final width in [390.0, 1280.0]) {
    for (final format in ['text', 'markdown']) {
      for (final rejected in [true, false]) {
        for (final transition in [
          'none',
          'ui',
          'route',
          'profile',
          'session',
          'origin',
          'replacement',
          'roundtrip',
        ]) {
          testWidgets(
            '$format ${rejected ? 'reject' : 'success'} $transition $width',
            (tester) async {
              tester.view.physicalSize = Size(width, 1000);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final semantics = tester.ensureSemantics();
              final previousPrint = debugPrint;
              try {
                final channel = _Channel();
                addTearDown(channel.dispose);
                final store = FakeHermesEndpointStore();
                final directory = HermesGatewayDirectory(
                  store: store,
                  cache: FakeGatewayContactCache(),
                  loader: FakeGatewaySummaryLoader({}),
                  activeChannel: channel,
                );
                final container = ProviderContainer(
                  overrides: [
                    _source.overrideWith((_) => channel),
                    hermesChannelProvider.overrideWith(
                      (ref) => ref.watch(_source),
                    ),
                    hermesEndpointStoreProvider.overrideWithValue(store),
                    hermesGatewayDirectoryProvider.overrideWith(
                      (_) => directory,
                    ),
                    hermesVoiceCaptureServiceProvider.overrideWithValue(null),
                    hermesTextToSpeechServiceProvider.overrideWithValue(null),
                  ],
                );
                addTearDown(container.dispose);
                final page = ValueNotifier<Widget>(const HermesChatScreen());
                addTearDown(page.dispose);
                final navigator = GlobalKey<NavigatorState>();
                final writes = <String>[];
                final gate = Completer<void>();
                final messenger = tester.binding.defaultBinaryMessenger;
                messenger.setMockMethodCallHandler(SystemChannels.platform, (
                  call,
                ) async {
                  if (call.method == 'Clipboard.setData') {
                    writes.add((call.arguments as Map)['text'] as String);
                    if (writes.length == 1) await gate.future;
                  }
                  return null;
                });
                addTearDown(
                  () => messenger.setMockMethodCallHandler(
                    SystemChannels.platform,
                    null,
                  ),
                );
                final logs = <String>[];
                debugPrint = (message, {wrapWidth}) {
                  if (message != null) logs.add(message);
                };

                await tester.pumpWidget(
                  UncontrolledProviderScope(
                    container: container,
                    child: MaterialApp(
                      navigatorKey: navigator,
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      home: ValueListenableBuilder<Widget>(
                        valueListenable: page,
                        builder: (_, child, _) => child,
                      ),
                    ),
                  ),
                );
                await _frames(tester);
                if (transition == 'route') {
                  unawaited(
                    navigator.currentState!.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HermesChatScreen(),
                      ),
                    ),
                  );
                  await _frames(tester);
                }
                expect(tester.takeException(), isNull);
                final original = channel.state;
                final strings = AppLocalizations.of(
                  tester.element(find.byType(HermesChatScreen).last),
                );
                expect(strings.transcriptCopyFailedMessage, _failure);
                final success = strings.transcriptCopiedMessage(
                  format == 'markdown'
                      ? strings.transcriptFormatMarkdown
                      : strings.transcriptFormatText,
                );
                final expected = format == 'markdown'
                    ? '## You\n\nSynthetic question 日本語 😀\n\n## Hermes\n\nSynthetic **answer**.'
                    : 'You:\nSynthetic question 日本語 😀\n\nHermes:\nSynthetic **answer**.';
                await _options(tester, width);
                await tester.tap(
                  find.byKey(ValueKey('hermes-copy-transcript-$format')),
                );
                await _frames(tester);
                expect(writes, [expected]);
                expect(find.byType(BottomSheet), findsNothing);
                expect(find.text(success), findsNothing);
                expect(find.text(_failure), findsNothing);
                if (transition == 'ui') {
                  page.value = const SizedBox();
                } else if (transition == 'route') {
                  navigator.currentState!.pop();
                } else if (transition == 'replacement') {
                  final replacement = _Channel();
                  addTearDown(replacement.dispose);
                  container.read(_source.notifier).state = replacement;
                } else if (transition == 'profile' ||
                    transition == 'roundtrip') {
                  channel.change(original.copyWith(selectedProfileId: 'b'));
                  if (transition == 'roundtrip') channel.change(original);
                } else if (transition == 'session') {
                  channel.change(original.copyWith(activeSessionId: 'other'));
                } else if (transition == 'origin') {
                  channel.change(
                    original.copyWith(
                      connectedBaseUrl: 'https://replacement.invalid',
                    ),
                  );
                }
                await _frames(tester);
                if (rejected) {
                  gate.completeError(
                    PlatformException(
                      code: 'clipboard-rejected-marker',
                      message: 'private-diagnostic-marker',
                      details: 'private-details-marker',
                    ),
                  );
                } else {
                  gate.complete();
                }
                await _frames(tester);
                expect(tester.takeException(), isNull);
                expect(writes, [expected]);
                expect(find.textContaining('private-'), findsNothing);
                expect(logs.join(), isNot(contains('private-')));
                expect(
                  logs.join(),
                  isNot(contains('clipboard-rejected-marker')),
                );
                expect(
                  find.text(success),
                  transition == 'none' && !rejected
                      ? findsOneWidget
                      : findsNothing,
                );
                expect(
                  find.text(_failure),
                  transition == 'none' && rejected
                      ? findsOneWidget
                      : findsNothing,
                );
                if (transition == 'none' && rejected) {
                  expect(
                    tester
                        .getSemantics(find.text(_failure))
                        .flagsCollection
                        .isLiveRegion,
                    isTrue,
                  );
                  await tester.pump(const Duration(seconds: 5));
                  await _frames(tester);
                  expect(writes, [expected], reason: 'No automatic retry');
                  await _options(tester, width);
                  await tester.tap(
                    find.byKey(ValueKey('hermes-copy-transcript-$format')),
                  );
                  await _frames(tester);
                  expect(writes, [expected, expected]);
                  expect(find.text(success), findsOneWidget);
                  expect(find.text(_failure), findsNothing);
                  expect(tester.takeException(), isNull);
                }
                expect(channel.sentVoiceTranscripts, isEmpty);
                expect(channel.sentImageDataUrls, isEmpty);
                expect(channel.loadEarlierMessagesCalls, 0);
                expect(channel.createSessionCalls, isEmpty);
                expect(channel.selectProfileCalls, isEmpty);
                expect(channel.selectSessionCalls, isEmpty);
              } finally {
                debugPrint = previousPrint;
                semantics.dispose();
              }
            },
          );
        }
      }
      testWidgets('$format dismissed sheet $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final channel = _Channel();
        addTearDown(channel.dispose);
        var writes = 0;
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'Clipboard.setData') writes++;
          return null;
        });
        addTearDown(
          () =>
              messenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              hermesChannelProvider.overrideWithValue(channel),
              hermesVoiceCaptureServiceProvider.overrideWithValue(null),
              hermesTextToSpeechServiceProvider.overrideWithValue(null),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HermesChatScreen(),
            ),
          ),
        );
        await _frames(tester);
        await _options(tester, width);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await _frames(tester);
        expect(find.byType(BottomSheet), findsNothing);
        expect(writes, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
