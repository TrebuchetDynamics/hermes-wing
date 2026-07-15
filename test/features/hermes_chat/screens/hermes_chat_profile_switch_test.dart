import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/hermes/channel/hermes_channel.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:navivox/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

const _profiles = [
  HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
  HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
];

Future<void> _pumpChat(WidgetTester tester, FakeHermesChannel channel) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(
          FakeHermesEndpointStore(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HermesChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('chat header seeds the default agent and switches client-side', (
    tester,
  ) async {
    final channel = FakeHermesChannel(profiles: _profiles);
    addTearDown(channel.dispose);

    await _pumpChat(tester, channel);

    // Nothing was explicitly selected, so the header seeds the default agent.
    expect(find.widgetWithText(TextButton, 'Hermes One'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-profile-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coding Agent'));
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['coder']);
  });

  testWidgets('switching agents clears stale pending approvals', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      profiles: _profiles,
      selectedProfileId: 'default',
    );
    addTearDown(channel.dispose);

    await _pumpChat(tester, channel);

    channel.emitApprovalRequest(
      const HermesApprovalRequest(
        id: 'approval-1',
        toolCallId: 'tool-1',
        prompt: 'Run a command?',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hermes-approval-deny')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-profile-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coding Agent'));
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['coder']);
    // The prior profile's pending approval is cleared on switch.
    expect(find.byKey(const ValueKey('hermes-approval-deny')), findsNothing);
  });
}
