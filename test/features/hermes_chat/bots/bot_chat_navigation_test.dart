import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';

import '../../../../integration_test/support/bot_chat_fixture.dart';
import '../../../../integration_test/support/local_serve_read_fixture.dart';
import '../screens/hermes_chat_session_workspace_test.dart'
    show mount, composer;
import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';
import '../support/fake_hermes_gateway_directory.dart';

class PendingBotChannel extends FakeHermesChannel
    implements HermesBotChatChannel {
  final gate = Completer<void>();
  bool? accepted;
  @override
  Future<bool> openBotChat({
    bool background = false,
    bool Function()? canAccept,
  }) async {
    await gate.future;
    accepted = canAccept?.call();
    return false;
  }
}

Future<void> chooseBot(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('hermes-more-actions-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bot Chat'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'compact missing-operation gap preserves ordinary session and draft',
    (tester) async {
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await mount(tester, channel);
      final session = channel.state.activeSessionId;
      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        'Synthetic ordinary draft',
      );
      await chooseBot(tester);
      expect(
        find.textContaining('Canonical Bot Chat requires'),
        findsOneWidget,
      );
      expect(channel.state.activeSessionId, session);
      expect(composer(tester).text, 'Synthetic ordinary draft');
      expect(channel.createSessionCalls, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a newer draft invalidates an older Bot navigation request',
    (tester) async {
      final channel = PendingBotChannel();
      addTearDown(channel.dispose);
      await mount(tester, channel);
      await chooseBot(tester);
      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        'Synthetic newer draft',
      );
      channel.gate.complete();
      await tester.pumpAndSettle();
      expect(channel.accepted, false);
      expect(composer(tester).text, 'Synthetic newer draft');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'native Bot history opens without discarding the ordinary draft on return',
    (tester) async {
      final oldHttp = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = oldHttp);
      final fixture = BotChatFixture(portOffset: 70);
      late HermesApiChannel channel;
      addTearDown(fixture.close);
      addTearDown(() => channel.dispose());
      await tester.runAsync(() async {
        // Native futures/sockets must originate outside the widget fake clock.
        channel = HermesApiChannel();
        await fixture.start();
        await channel.connectForwardedServeReads(
          baseUrl: fixture.origin,
          credential: LocalServeReadFixture.token,
          canAccept: () => true,
          onAcquire: (_) {},
        );
        await channel.enableLocalServeChat();
      });
      fixture.canonical.add({
        'row_id': 1,
        'role': 'assistant',
        'text': 'Synthetic Bot history',
      });
      final directory = HermesGatewayDirectory(
        store: FakeHermesEndpointStore(),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );
      await mount(tester, channel, directory: directory);
      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        'Synthetic ordinary draft',
      );
      late Completer<void> opened;
      void observe() {
        if (channel.state.activeSessionId == 'bot-tip' && !opened.isCompleted) {
          opened.complete();
        }
      }

      final action = tester
          .widget<PopupMenuButton<String>>(
            find.byKey(const ValueKey('hermes-more-actions-button')),
          )
          .onSelected!;
      await tester.runAsync(() async {
        opened = Completer<void>();
        channel.addListener(observe);
        action('bot-chat');
        await opened.future.timeout(const Duration(seconds: 10));
      });
      channel.removeListener(observe);
      await tester.pumpAndSettle();
      expect(find.text('Synthetic Bot history'), findsOneWidget);
      expect(composer(tester).text, isEmpty);
      await tester.runAsync(() => channel.selectSession('default-session'));
      await tester.pumpAndSettle();
      expect(composer(tester).text, 'Synthetic ordinary draft');
      expect(fixture.count('prompt.submit'), 0);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
