import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import '../../../../support/test_navivox_channel.dart';
import '../../shared/widgets/inline_span_test_helpers.dart';
import '../../shared/widgets/chat_screen_test_fixtures.dart';
import '../../shared/profiles/profile_scope_test_helpers.dart';
import 'shared/profile_contact_screen_test_fixtures.dart';

const _chatProfileSearchFieldKey = 'chat-profile-search-field';
const _chatAllServersFilterKey = 'chat-all-servers-filter';
const _chatActiveProfileKey = 'chat-active-profile';
const _chatContextActionKey = 'chat-context-action';

String _chatServerFilterKey(String serverId) => 'chat-server-filter-$serverId';

void main() {
  testWidgets('renders profiles as a flat multi-server contact list', (
    tester,
  ) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    expect(find.text('Navivox'), findsOneWidget);
    expect(
      find.byKey(const ValueKey(_chatProfileSearchFieldKey)),
      findsOneWidget,
    );
    expect(find.text('Mineru Builder'), findsOneWidget);
    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(
      find.byKey(ValueKey(chatProfileContactKey(chatMineruProfileScope))),
      findsOneWidget,
    );
    expect(
      find.text('Ready to work on mineru · online · 2 roots'),
      findsOneWidget,
    );
    expect(
      find.text('Waiting for token · auth required · 1 root'),
      findsOneWidget,
    );
    expect(
      find.text('Gateway unavailable · offline · 0 roots'),
      findsOneWidget,
    );
    expect(find.text('2 roots'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(ValueKey(chatProfileContactKey(chatMineruProfileScope))),
        matching: find.byType(Chip),
      ),
      findsNothing,
    );
    expect(find.text('auth'), findsNothing);
    expect(
      find.byKey(ValueKey(chatProfileAttentionKey(chatSupportProfileScope))),
      findsOneWidget,
    );
    expect(find.text('1'), findsNothing);
    expect(find.text('May 16'), findsWidgets);
    expect(find.text('May 15'), findsOneWidget);
    expect(find.byTooltip('Add profile'), findsOneWidget);
  });

  testWidgets('selected contact is highlighted like the active Telegram chat', (
    tester,
  ) async {
    final channel = profileContactListChannel(
      selectedKey: chatProfileScopeKey(chatMineruProfileScope),
    );

    await pumpProfileContactList(tester, channel: channel);

    final selectedTile = tester.widget<ListTile>(
      find.byKey(ValueKey(chatProfileContactKey(chatMineruProfileScope))),
    );
    final otherTile = tester.widget<ListTile>(
      find.byKey(ValueKey(chatProfileContactKey(chatSupportProfileScope))),
    );

    expect(selectedTile.selected, isTrue);
    expect(otherTile.selected, isFalse);
  });

  testWidgets('contacts move voice and attention state out of the avatar', (
    tester,
  ) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    expect(
      find.byKey(ValueKey(chatProfilePresenceKey(chatMineruProfileScope))),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey(chatProfileVoiceReadyKey(chatMineruProfileScope))),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey(chatProfileVoiceKey(chatMineruProfileScope))),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(chatProfilePresenceKey(chatSupportProfileScope))),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey(chatProfileVoiceReadyKey(chatSupportProfileScope))),
      findsNothing,
    );
  });

  testWidgets('server filter chips narrow contacts by gateway', (tester) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    expect(
      find.byKey(const ValueKey(_chatAllServersFilterKey)),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(_chatServerFilterKey(chatMineruServerId))),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(_chatServerFilterKey(chatSupportServerId))),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(ValueKey(_chatServerFilterKey(chatSupportServerId))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
    expect(find.text('Personal'), findsNothing);
    expect(find.text('1 profile'), findsOneWidget);
  });

  testWidgets('profile list overflow menu plugs top-level routes', (
    tester,
  ) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    await tester.tap(find.byTooltip('Open profile list menu'));
    await tester.pumpAndSettle();

    expect(find.text('Manage gateways'), findsOneWidget);
    expect(find.text('Manage profiles'), findsOneWidget);
    expect(find.text('Memory'), findsWidgets);
    expect(find.text('Config'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.text('Manage gateways'));
    await tester.pumpAndSettle();

    expect(find.text('Gateways'), findsOneWidget);
  });

  testWidgets('add profile menu rows are plugged into actions', (tester) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    await tester.tap(find.byTooltip('Add profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New profile'));
    await tester.pumpAndSettle();

    expect(find.text('Create from seed'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-seed-input')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add server'));
    await tester.pumpAndSettle();

    expect(find.text('Gateways'), findsOneWidget);
  });

  testWidgets('search highlights matching contact title text like Telegram', (
    tester,
  ) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    await tester.enterText(
      find.byKey(const ValueKey(_chatProfileSearchFieldKey)),
      'mineru',
    );
    await tester.pumpAndSettle();

    final highlighted = tester.widget<Text>(
      find.descendant(
        of: find.byKey(
          ValueKey(chatProfileContactTitleKey(chatMineruProfileScope)),
        ),
        matching: find.byType(Text),
      ),
    );
    final span = highlighted.textSpan! as TextSpan;

    expect(span.toPlainText(), 'Mineru Builder');
    expect(
      spanForInlineText(span, 'Mineru')?.style?.fontWeight,
      FontWeight.w700,
    );
    expect(spanForInlineText(span, 'Mineru')?.style?.color, isNotNull);
  });

  testWidgets('search filters profile contacts like Telegram chat search', (
    tester,
  ) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    expect(
      find.byKey(const ValueKey(_chatProfileSearchFieldKey)),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey(_chatProfileSearchFieldKey)),
      'support',
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
    expect(find.text('Personal'), findsNothing);
  });

  testWidgets('search matches profile health and capability diagnostics', (
    tester,
  ) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    await tester.enterText(
      find.byKey(const ValueKey(_chatProfileSearchFieldKey)),
      'auth required',
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
    expect(find.text('Personal'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey(_chatProfileSearchFieldKey)),
      'mic unavailable',
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
  });

  testWidgets('search shows a no results state', (tester) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    await tester.enterText(
      find.byKey(const ValueKey(_chatProfileSearchFieldKey)),
      'missing',
    );
    await tester.pumpAndSettle();

    expect(find.text('No chats found'), findsOneWidget);
    expect(find.text('Mineru Builder'), findsNothing);
  });

  testWidgets('streaming profile contact shows Telegram-like typing state', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(chatProfileListServers, activeServerId: 'local')
      ..seedProfileContacts([
        NavivoxProfileContact(
          serverId: chatProfileListContacts.first.serverId,
          profileId: chatProfileListContacts.first.profileId,
          displayName: chatProfileListContacts.first.displayName,
          serverLabel: chatProfileListContacts.first.serverLabel,
          health: chatProfileListContacts.first.health,
          latestPreview: chatProfileListContacts.first.latestPreview,
          latestAt: chatProfileListContacts.first.latestAt,
          workspaceRootCount: chatProfileListContacts.first.workspaceRootCount,
          micAvailable: chatProfileListContacts.first.micAvailable,
          activeTurnState: 'streaming',
        ),
        ...chatProfileListContacts.skip(1),
      ]);

    await pumpProfileContactList(tester, channel: channel);

    expect(find.text('typing… · online · 2 roots'), findsOneWidget);
    expect(
      find.byKey(ValueKey(chatProfileActiveTurnKey(chatMineruProfileScope))),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(chatProfileTypingDotKey(chatMineruProfileScope, 0))),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(chatProfileTypingDotKey(chatMineruProfileScope, 1))),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(chatProfileTypingDotKey(chatMineruProfileScope, 2))),
      findsOneWidget,
    );
  });

  testWidgets('selecting a profile opens scoped chat and sends in that scope', (
    tester,
  ) async {
    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    await tester.tap(
      find.byKey(ValueKey(chatProfileContactKey(chatSupportProfileScope))),
    );
    await tester.pumpAndSettle();

    expectSelectedProfileContactScope(channel, chatProfileListContacts[1]);
    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.byKey(const ValueKey(_chatActiveProfileKey)), findsNothing);
    expect(find.byKey(const ValueKey(_chatContextActionKey)), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'triage latest ticket',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(channel.sentTexts, ['triage latest ticket']);
    expectLastSentTextToChatProfileScope(
      channel,
      text: 'triage latest ticket',
      scope: chatSupportProfileScope,
    );
  });

  testWidgets('selecting a profile encodes chat route path segments', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'office team', name: 'Office Team', status: 'online'),
      ], activeServerId: 'office team')
      ..seedProfileContacts([
        NavivoxProfileContact(
          serverId: 'office team',
          profileId: 'support/desk',
          displayName: 'Support Escalation',
          serverLabel: 'office team',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Watching escalations',
          latestAt: DateTime(2026, 5, 16, 10, 12),
          workspaceRootCount: 1,
          micAvailable: true,
        ),
      ]);

    await pumpProfileContactList(tester, channel: channel);

    await tester.tap(
      find.byKey(
        ValueKey(
          chatProfileContactKey((
            serverId: 'office team',
            profileId: 'support/desk',
          )),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Route not found'), findsNothing);
    expectSelectedProfileScope(
      channel,
      serverId: 'office team',
      profileId: 'support/desk',
    );
    expect(find.text('Support Escalation'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Message Gormes'),
      'triage escalation',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expectLastSentTextCall(
      channel,
      text: 'triage escalation',
      serverId: 'office team',
      profileId: 'support/desk',
    );
  });

  testWidgets('chat back button returns to profile contacts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    await tester.tap(
      find.byKey(ValueKey(chatProfileContactKey(chatSupportProfileScope))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Navivox'), findsOneWidget);
    expect(
      find.byKey(ValueKey(chatProfileContactKey(chatMineruProfileScope))),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey(chatProfileContactKey(chatSupportProfileScope))),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('long pressing a profile opens diagnostics and scoped actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    await tester.longPress(
      find.byKey(ValueKey(chatProfileContactKey(chatMineruProfileScope))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile details'), findsOneWidget);
    expect(find.text('Mineru Builder\nmineru'), findsOneWidget);
    expect(find.text('Profile diagnostics'), findsOneWidget);
    expect(find.text('Health: online'), findsOneWidget);
    expect(find.text('Workspace: 2 roots'), findsOneWidget);
    expect(find.text('Voice: mic available'), findsOneWidget);
    expect(find.text('Latest: Ready to work on mineru'), findsOneWidget);
    expect(find.text('Identity / system prompt'), findsOneWidget);
    expect(find.text('Profile path: mineru'), findsOneWidget);
    expect(find.text('Connected channels'), findsOneWidget);
    expect(find.text('Local/web chat: enabled'), findsOneWidget);
    expect(find.text('Memory settings'), findsOneWidget);
    expect(find.text('Goncho status: available'), findsOneWidget);
    expect(find.text('Skills list'), findsOneWidget);
    expect(find.text('Skills: not reported by API'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Config/environment summary'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Config/environment summary'), findsOneWidget);
    expect(find.text('Config: profile scoped'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Logs/status'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Logs/status'), findsOneWidget);
    expect(find.text('Status: online'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open chat'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Open chat'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open memory'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Open memory'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);

    await tester.tap(find.text('Open memory'));
    await tester.pumpAndSettle();

    expectSelectedProfileContactScope(channel, chatProfileListContacts[0]);
    expect(find.text('Memory'), findsWidgets);
    expect(find.text('Profile: Mineru Builder'), findsOneWidget);
  });

  testWidgets('profile edit action opens profile-scoped config', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final channel = profileContactListChannel();

    await pumpProfileContactList(tester, channel: channel);

    await tester.longPress(
      find.byKey(ValueKey(chatProfileContactKey(chatSupportProfileScope))),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Edit profile'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    expectSelectedProfileContactScope(channel, chatProfileListContacts[1]);
    expect(find.text('Config'), findsWidgets);
    expect(find.text('Profile: Support Triage'), findsOneWidget);
  });

  testWidgets('deep-linked chat route selects the profile scope', (
    tester,
  ) async {
    final channel = profileContactListChannel();

    await pumpChatProfileScopeScreen(
      tester,
      channel: channel,
      scope: chatSupportProfileScope,
    );
    await tester.pumpAndSettle();

    expectSelectedProfileContactScope(channel, chatProfileListContacts[1]);
    expect(find.text('Support Triage'), findsOneWidget);
    expect(find.byKey(const ValueKey(_chatActiveProfileKey)), findsNothing);
    expect(find.byKey(const ValueKey(_chatContextActionKey)), findsOneWidget);

    await openChatInfoSheet(tester);

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Support Triage'), findsWidgets);
    expect(find.text(chatSupportServerId), findsOneWidget);
  });
}
