import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contacts_view.dart';

void main() {
  testWidgets('renders contacts ordered across gateways and opens one', (
    tester,
  ) async {
    final contacts = sortGatewayContacts([
      _contact('a', 'a1', 'Agent A1', 'Alpha', '2026-07-16T05:00:00Z'),
      _contact('a', 'a2', 'Agent A2', 'Alpha', '2026-07-16T04:00:00Z'),
      _contact('a', 'a3', 'Agent A3', 'Alpha', '2026-07-16T03:00:00Z'),
      _contact('b', 'b1', 'Agent B1', 'Beta', '2026-07-16T02:00:00Z'),
      _contact('b', 'b2', 'Agent B2', 'Beta', '2026-07-16T01:00:00Z'),
    ]);
    GatewayContactId? opened;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GatewayContactsView(
            contacts: contacts,
            refreshing: false,
            onRefresh: () async {},
            onOpen: (id) => opened = id,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('gateway-contact-row')), findsNWidgets(5));
    expect(find.text('Alpha · online'), findsNWidgets(3));
    expect(find.text('Beta · online'), findsNWidgets(2));
    await tester.tap(find.text('Agent B2'));
    expect(opened, const GatewayContactId(gatewayId: 'b', profileId: 'b2'));
  });

  testWidgets('pull to refresh invokes the refresh callback', (tester) async {
    var refreshCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GatewayContactsView(
            contacts: [
              _contact('a', 'a1', 'Agent A1', 'Alpha', '2026-07-16T05:00:00Z'),
            ],
            refreshing: false,
            onRefresh: () async => refreshCalls++,
            onOpen: (_) {},
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(refreshCalls, 1);
  });

  testWidgets('empty state only offers the configured connect action', (
    tester,
  ) async {
    var connectCalls = 0;
    Widget view([VoidCallback? onConnect]) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GatewayContactsView(
          contacts: const [],
          refreshing: false,
          onRefresh: () async {},
          onOpen: (_) {},
          onConnect: onConnect,
        ),
      ),
    );

    await tester.pumpWidget(view());
    expect(find.text('Add your first Hermes agent'), findsOneWidget);
    expect(
      find.text(
        'Connect a gateway to see its agent profiles and start a conversation.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add gateway or agent'), findsNothing);

    await tester.pumpWidget(view(() => connectCalls++));
    await tester.tap(find.byKey(const ValueKey('gateway-contacts-add')));
    expect(connectCalls, 1);
  });

  testWidgets('empty onboarding remains usable at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GatewayContactsView(
            contacts: const [],
            refreshing: false,
            onRefresh: () async {},
            onOpen: (_) {},
            onConnect: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('gateway-contacts-add')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refreshing shows list and contact progress affordances', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GatewayContactsView(
            contacts: [
              _contact(
                'a',
                'a1',
                'Agent A1',
                'Alpha',
                '2026-07-16T05:00:00Z',
                availability: GatewayAvailability.refreshing,
              ),
            ],
            refreshing: true,
            onRefresh: () async {},
            onOpen: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Alpha · refreshing'), findsOneWidget);
  });

  testWidgets('avatar uses the first trimmed grapheme or question fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GatewayContactsView(
            contacts: [
              _contact(
                'a',
                'emoji',
                '  👩🏽‍💻 Agent',
                'Alpha',
                '2026-07-16T05:00:00Z',
              ),
              _contact('b', 'blank', '   ', 'Beta', '2026-07-16T04:00:00Z'),
            ],
            refreshing: false,
            onRefresh: () async {},
            onOpen: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('👩🏽‍💻'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('long session preview is limited to one ellipsized line', (
    tester,
  ) async {
    const preview =
        'This deliberately long session preview must stay on one line in the contact list.';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GatewayContactsView(
            contacts: [
              _contact(
                'a',
                'a1',
                'Agent A1',
                'Alpha',
                '2026-07-16T05:00:00Z',
                preview: preview,
              ),
            ],
            refreshing: false,
            onRefresh: () async {},
            onOpen: (_) {},
          ),
        ),
      ),
    );

    final previewText = tester.widget<Text>(find.text(preview));
    expect(previewText.maxLines, 1);
    expect(previewText.overflow, TextOverflow.ellipsis);
  });

  testWidgets('timestamp renders normalized UTC hour and minute', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GatewayContactsView(
            contacts: [
              _contact(
                'a',
                'a1',
                'Agent A1',
                'Alpha',
                '2026-07-16T07:09:00+02:00',
              ),
            ],
            refreshing: false,
            onRefresh: () async {},
            onOpen: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('05:09'), findsOneWidget);
  });

  testWidgets('offline contact stays visible and announces its status', (
    tester,
  ) async {
    final contact = _contact(
      'a',
      'a1',
      'Agent A1',
      'Alpha',
      '2026-07-16T05:00:00Z',
      availability: GatewayAvailability.offline,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GatewayContactsView(
            contacts: [contact],
            refreshing: false,
            onRefresh: () async {},
            onOpen: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Agent A1'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('gateway-contact-a-a1')))
          .label,
      contains('offline'),
    );
  });
}

GatewayContact _contact(
  String gatewayId,
  String profileId,
  String profileName,
  String gatewayLabel,
  String lastActive, {
  GatewayAvailability availability = GatewayAvailability.online,
  String preview = 'Latest message',
}) => GatewayContact(
  id: GatewayContactId(gatewayId: gatewayId, profileId: profileId),
  gatewayLabel: gatewayLabel,
  profileName: profileName,
  latestSession: HermesSession(
    id: '$gatewayId-$profileId-session',
    source: 'test',
    preview: preview,
    lastActive: lastActive,
  ),
  sessionCount: 1,
  availability: availability,
);
