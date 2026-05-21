import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';
import 'package:navivox/features/memory/screens/memory_dashboard_screen.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  testWidgets(
    'memory dashboard shows profile-scoped Goncho counts with a safe database label',
    (tester) async {
      final channel = TestNavivoxChannel()
        ..seedServers(const [
          NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
        ], activeServerId: 'local')
        ..seedProfileContacts(const [
          NavivoxProfileContact(
            serverId: 'local',
            profileId: 'mineru',
            displayName: 'Mineru Builder',
            serverLabel: 'local',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Goncho memory active',
          ),
        ], selectedKey: 'local::mineru')
        ..seedMemoryOverview(
          NavivoxMemoryOverview(
            profileId: 'mineru',
            workspaceId: 'gormes',
            databaseLabel: '~/.gormes/profiles/mineru/memory.db',
            health: NavivoxMemoryHealth.active,
            totalTurns: 120,
            activeMemoryItems: 12,
            observations: 34,
            conclusions: 5,
            sessionSummaries: 7,
            entities: 18,
            relationships: 21,
            lastUpdatedAt: DateTime.utc(2026, 5, 21, 15, 28, 18),
          ),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(home: MemoryDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Memory'), findsWidgets);
      expect(find.text('Goncho active'), findsOneWidget);
      expect(find.text('Profile: Mineru Builder'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('Turns'), findsWidgets);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Active memory items'), findsOneWidget);
      expect(find.text('~/.gormes/profiles/mineru/memory.db'), findsOneWidget);
      expect(find.textContaining('/home/xel'), findsNothing);
    },
  );

  testWidgets('memory dashboard includes searchable browse cards', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Goncho memory active',
        ),
      ], selectedKey: 'local::mineru')
      ..seedMemoryOverview(
        const NavivoxMemoryOverview(
          profileId: 'mineru',
          workspaceId: 'gormes',
          databaseLabel: '~/.gormes/profiles/mineru/memory.db',
          health: NavivoxMemoryHealth.active,
          totalTurns: 2,
          activeMemoryItems: 1,
          observations: 0,
          conclusions: 1,
          sessionSummaries: 0,
          entities: 0,
          relationships: 0,
        ),
      )
      ..seedMemorySearch(
        const NavivoxMemorySearchResult(
          items: [
            NavivoxMemoryItem(
              id: 'mem-1',
              type: NavivoxMemoryType.memoryItems,
              snippet: 'Mineru uses Goncho memory for workspace recall.',
              timestamp: '2026-05-21T15:30:00Z',
              sessionId: 's-1',
              peerId: 'mineru',
              status: 'current',
              tags: ['workspace', 'recall'],
              score: 0.92,
            ),
            NavivoxMemoryItem(
              id: 'conclusion-1',
              type: NavivoxMemoryType.conclusions,
              snippet: 'Juan prefers exact evidence before claims.',
              timestamp: '2026-05-21T15:31:00Z',
              sessionId: 's-2',
              peerId: 'juan',
              status: 'processed',
            ),
          ],
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: MemoryDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search & Browse'), findsOneWidget);
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    expect(find.text('Memory items'), findsOneWidget);
    expect(find.text('Conclusions'), findsWidgets);
    expect(
      find.text('Mineru uses Goncho memory for workspace recall.'),
      findsOneWidget,
    );
    expect(find.text('memory_items · current · s-1 · mineru'), findsOneWidget);
    expect(find.text('workspace'), findsOneWidget);
    expect(find.text('recall'), findsOneWidget);

    await tester.enterText(searchField, 'Goncho');
    await tester.pumpAndSettle();

    expect(channel.memorySearchCalls.last.query, 'Goncho');
    expect(channel.memorySearchCalls.last.profileId, 'mineru');
  });

  testWidgets(
    'tapping a memory card opens safe detail with management actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final channel = TestNavivoxChannel()
        ..seedServers(const [
          NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
        ], activeServerId: 'local')
        ..seedProfileContacts(const [
          NavivoxProfileContact(
            serverId: 'local',
            profileId: 'mineru',
            displayName: 'Mineru Builder',
            serverLabel: 'local',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Goncho memory active',
          ),
        ], selectedKey: 'local::mineru')
        ..seedMemoryOverview(
          const NavivoxMemoryOverview(
            profileId: 'mineru',
            workspaceId: 'gormes',
            databaseLabel: '~/.gormes/profiles/mineru/memory.db',
            health: NavivoxMemoryHealth.active,
            totalTurns: 2,
            activeMemoryItems: 1,
            observations: 0,
            conclusions: 1,
            sessionSummaries: 0,
            entities: 0,
            relationships: 0,
          ),
        )
        ..seedMemorySearch(
          const NavivoxMemorySearchResult(
            items: [
              NavivoxMemoryItem(
                id: 'mem-1',
                type: NavivoxMemoryType.memoryItems,
                snippet: 'Mineru uses Goncho memory for workspace recall.',
                sessionId: 's-1',
                peerId: 'mineru',
                status: 'current',
              ),
            ],
          ),
        )
        ..seedMemoryDetail(
          const NavivoxMemoryDetail(
            id: 'mem-1',
            type: NavivoxMemoryType.memoryItems,
            content: 'Mineru uses Goncho memory for workspace recall.',
            source: 'goncho_memory_items',
            sessionId: 's-1',
            peerId: 'mineru',
            createdAt: '2026-05-21T15:30:00Z',
            status: 'current',
            tags: ['workspace'],
            provenance: 'derived from reviewed session s-1',
            linkedEntities: ['Mineru', 'Goncho'],
            linkedRelationships: ['Mineru RELATED_TO Goncho'],
          ),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(home: MemoryDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final memoryCard = find.byKey(
        const ValueKey('memory-item-memory_items-mem-1'),
      );
      await tester.tap(memoryCard);
      await tester.pumpAndSettle();

      expect(channel.memoryDetailCalls.last.id, 'mem-1');
      expect(channel.memoryDetailCalls.last.profileId, 'mineru');
      expect(find.text('Memory detail'), findsOneWidget);
      expect(find.text('derived from reviewed session s-1'), findsOneWidget);
      expect(find.text('Raw source preserved'), findsOneWidget);
      expect(find.text('Mineru'), findsOneWidget);
      expect(find.text('Goncho'), findsOneWidget);
      expect(find.text('Mineru RELATED_TO Goncho'), findsOneWidget);
      expect(find.text('Pin'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Mark stale'), findsOneWidget);
      expect(find.text('Add correction'), findsOneWidget);
    },
  );

  testWidgets('memory detail sends safe management actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Goncho memory active',
        ),
      ], selectedKey: 'local::mineru')
      ..seedMemoryOverview(
        const NavivoxMemoryOverview(
          profileId: 'mineru',
          workspaceId: 'gormes',
          databaseLabel: '~/.gormes/profiles/mineru/memory.db',
          health: NavivoxMemoryHealth.active,
          totalTurns: 2,
          activeMemoryItems: 1,
          observations: 0,
          conclusions: 1,
          sessionSummaries: 0,
          entities: 0,
          relationships: 0,
        ),
      )
      ..seedMemorySearch(
        const NavivoxMemorySearchResult(
          items: [
            NavivoxMemoryItem(
              id: 'mem-1',
              type: NavivoxMemoryType.memoryItems,
              snippet: 'Mineru uses Goncho memory for workspace recall.',
              sessionId: 's-1',
              peerId: 'mineru',
              status: 'current',
            ),
          ],
        ),
      )
      ..seedMemoryDetail(
        const NavivoxMemoryDetail(
          id: 'mem-1',
          type: NavivoxMemoryType.memoryItems,
          content: 'Mineru uses Goncho memory for workspace recall.',
          source: 'goncho_memory_items',
          sessionId: 's-1',
          peerId: 'mineru',
          status: 'current',
        ),
      )
      ..seedMemoryActionResult(
        const NavivoxMemoryActionResult(
          accepted: true,
          action: NavivoxMemoryActionType.archive,
          message: 'Archive requested.',
          rawSourcePreserved: true,
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: MemoryDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('memory-item-memory_items-mem-1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(channel.memoryActionCalls.last.id, 'mem-1');
    expect(channel.memoryActionCalls.last.profileId, 'mineru');
    expect(
      channel.memoryActionCalls.last.action,
      NavivoxMemoryActionType.archive,
    );
    expect(find.text('Archive requested.'), findsOneWidget);

    await tester.tap(find.text('Add correction'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Use Mineru profile memory only.',
    );
    await tester.tap(find.text('Save correction'));
    await tester.pumpAndSettle();

    expect(channel.memoryActionCalls.last.id, 'mem-1');
    expect(
      channel.memoryActionCalls.last.action,
      NavivoxMemoryActionType.addCorrection,
    );
    expect(
      channel.memoryActionCalls.last.correction,
      'Use Mineru profile memory only.',
    );
    expect(find.text('Raw source preserved'), findsOneWidget);
  });

  testWidgets('memory dashboard reports degraded API state safely', (
    tester,
  ) async {
    final channel = TestNavivoxChannel()
      ..seedServers(const [
        NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
      ], activeServerId: 'local')
      ..seedProfileContacts(const [
        NavivoxProfileContact(
          serverId: 'local',
          profileId: 'mineru',
          displayName: 'Mineru Builder',
          serverLabel: 'local',
          health: NavivoxProfileHealth.warning,
          latestPreview: 'Memory API unavailable',
        ),
      ], selectedKey: 'local::mineru')
      ..seedMemoryOverview(
        const NavivoxMemoryOverview.degraded(
          profileId: 'mineru',
          reason: 'Gormes memory API is unavailable.',
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [navivoxChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(home: MemoryDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Goncho degraded'), findsOneWidget);
    expect(find.text('Gormes memory API is unavailable.'), findsOneWidget);
    expect(find.text('Profile: Mineru Builder'), findsOneWidget);
  });
}
