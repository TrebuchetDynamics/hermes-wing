import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_memory.dart';

void main() {
  group('memory overview database label', () {
    test('redacts unix absolute database paths to basename', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': '/var/lib/navivox/profiles/mineru/memory.db',
      });

      expect(overview.databaseLabel, 'redacted/memory.db');
      expect(overview.databaseLabel, isNot(contains('/var/lib/navivox')));
    });

    test('redacts windows absolute database paths to basename', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': r'C:\Users\xel\navivox\profiles\mineru\memory.db',
      });

      expect(overview.databaseLabel, 'redacted/memory.db');
      expect(overview.databaseLabel, isNot(contains(r'C:\Users\xel')));
    });

    test('keeps gormes-relative database labels recognizable', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': '/home/xel/.gormes/profiles/mineru/memory.db',
      });

      expect(overview.databaseLabel, '~/.gormes/profiles/mineru/memory.db');
      expect(overview.databaseLabel, isNot(contains('/home/xel')));
    });

    test('keeps windows gormes-relative database labels recognizable', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': r'C:\Users\xel\.gormes\profiles\mineru\memory.db',
      });

      expect(overview.databaseLabel, '~/.gormes/profiles/mineru/memory.db');
      expect(overview.databaseLabel, isNot(contains(r'C:\Users\xel')));
    });

    test('rejects gormes suffixes with traversal provenance', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': '/home/xel/.gormes/../secrets/memory.db',
      });

      expect(overview.databaseLabel, 'redacted/memory.db');
      expect(overview.databaseLabel, isNot(contains('..')));
      expect(overview.databaseLabel, isNot(contains('secrets')));
    });

    test('redacts relative database paths with directory provenance', () {
      final overview = NavivoxMemoryOverview.fromJson({
        'database_path': 'profiles/mineru/memory.db',
      });

      expect(overview.databaseLabel, 'redacted/memory.db');
      expect(overview.databaseLabel, isNot(contains('profiles/mineru')));
    });
  });

  test('overview counts clamp impossible negative gateway values', () {
    final overview = NavivoxMemoryOverview.fromJson({
      'counts': {
        'turns': '-2',
        'memory_items': -1,
        'observations': 3,
        'conclusions': null,
        'session_summaries': '-7',
        'entities': 0,
        'relationships': 1.9,
      },
    });

    expect(overview.totalTurns, 0);
    expect(overview.activeMemoryItems, 0);
    expect(overview.observations, 3);
    expect(overview.conclusions, 0);
    expect(overview.sessionSummaries, 0);
    expect(overview.entities, 0);
    expect(overview.relationships, 1);
    expect(navivoxMemoryCountFromJson('-4'), 0);
  });

  test('memory degradation aliases share non-empty reason semantics', () {
    final search = NavivoxMemorySearchResult.fromJson({
      'items': const [],
      'reason': ' degraded via alias ',
    });
    final detail = NavivoxMemoryDetail.fromJson({
      'id': 'memory-1',
      'type': 'memory_items',
      'content': 'memory',
      'degraded_reason': ' degraded via canonical field ',
    });
    final action = NavivoxMemoryActionResult.fromJson({
      'accepted': false,
      'action': 'archive',
      'message': 'not now',
      'degraded_reason': '   ',
    });

    expect(search.isDegraded, isTrue);
    expect(search.degradedReason, 'degraded via alias');
    expect(detail.isDegraded, isTrue);
    expect(detail.degradedReason, 'degraded via canonical field');
    expect(action.isDegraded, isFalse);
  });
}
