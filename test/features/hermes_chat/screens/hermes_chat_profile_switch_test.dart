import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';
import '../support/fake_hermes_endpoint_store.dart';

const _profiles = [
  HermesProfile(id: 'default', displayName: 'Hermes One', revision: 'd'),
  HermesProfile(id: 'coder', displayName: 'Coding Agent', revision: 'c'),
];

void _stageImageAttachment(WidgetTester tester) {
  final composer = tester.widget<TextField>(
    find.byKey(const ValueKey('hermes-composer-field')),
  );
  composer.contentInsertionConfiguration!.onContentInserted(
    KeyboardInsertedContent(
      mimeType: 'image/png',
      uri: 'content://keyboard/profile-owned-image',
      data: Uint8List.fromList([
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        0x00,
      ]),
    ),
  );
}

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
  testWidgets('agent switch clears a staged attachment', (tester) async {
    final channel = FakeHermesChannel(profiles: _profiles);
    addTearDown(channel.dispose);

    await _pumpChat(tester, channel);

    // Nothing was explicitly selected, so the header seeds the default agent.
    expect(find.widgetWithText(TextButton, 'Hermes One'), findsOneWidget);
    _stageImageAttachment(tester);
    await tester.pump();
    expect(find.text('pasted-image.png'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-profile-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coding Agent'));
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['coder']);
    expect(find.text('pasted-image.png'), findsNothing);
    expect(find.text('Ready to send'), findsNothing);
  });

  testWidgets('failed agent switch preserves the staged attachment', (
    tester,
  ) async {
    final channel = FakeHermesChannel(
      profiles: _profiles,
      selectedProfileId: 'default',
      selectProfileFails: true,
    );
    addTearDown(channel.dispose);
    await _pumpChat(tester, channel);

    _stageImageAttachment(tester);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('hermes-profile-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coding Agent'));
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['coder']);
    expect(find.text('pasted-image.png'), findsOneWidget);
    expect(find.text('Ready to send'), findsOneWidget);
  });

  testWidgets('agent switcher scrolls a long profile inventory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final profiles = [
      for (var index = 0; index < 20; index++)
        HermesProfile(
          id: 'agent-$index',
          displayName: 'Agent $index',
          revision: 'r$index',
        ),
    ];
    final channel = FakeHermesChannel(profiles: profiles);
    addTearDown(channel.dispose);

    await _pumpChat(tester, channel);
    await tester.tap(find.byKey(const ValueKey('hermes-profile-switcher')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Agent 19'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Agent 19'));
    await tester.pumpAndSettle();

    expect(channel.selectProfileCalls, ['agent-19']);
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
