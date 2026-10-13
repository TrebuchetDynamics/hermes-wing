import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/core/wing_link/wing_link_client.dart';

import 'support/linux_test_isolation.dart';

// Retained service safety coverage, not an Agent feature or supported setup path.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> manifest(String variable) {
    final path = Platform.environment[variable];
    if (path == null) throw StateError('A private live manifest is required.');
    final value = jsonDecode(File(path).readAsStringSync());
    return (value is List ? value.first : value) as Map<String, dynamic>;
  }

  testWidgets(
    'retained directory service grant, file exclusion and revocation',
    (tester) async {
      final issued = manifest('WING_LIVE_LINK_MANIFEST');
      final binary = Platform.environment['WING_LIVE_LINK_BINARY']!;
      final root = requireLinuxLiveDirectoryRoot(
        Platform.environment['WING_LIVE_DIRECTORY_ROOT']!,
        requireLinuxTestRoot('wing-linux-coverage.'),
      );
      final client = WingLinkClient(
        origin: Uri.parse(issued['wing_link_origin'] as String),
        token: issued['wing_link_token'] as String,
      );
      final grant = await Process.run(binary, ['directories', 'grant', root]);
      expect(grant.exitCode, 0);
      final id = (grant.stdout as String).trim().split('\t').first;
      var revoked = false;
      addTearDown(() async {
        if (!revoked) await Process.run(binary, ['directories', 'revoke', id]);
      });
      final roots = await client.listDirectoryRoots();
      final granted = roots.singleWhere((row) => row.name == 'grant-root');
      expect(roots.length, lessThanOrEqualTo(32));
      final page = await client.listChildDirectories(
        handle: granted.handle,
        limit: 1,
      );
      expect(page.directories, hasLength(1));
      final child = page.directories.single;
      expect(child.name, 'child-folder');
      expect(page.nextOffset, isNull);
      expect(
        page.directories.map((row) => row.name),
        isNot(contains('private-file.txt')),
      );
      final revoke = await Process.run(binary, ['directories', 'revoke', id]);
      expect(revoke.exitCode, 0);
      revoked = true;
      for (final handle in [granted.handle, child.handle]) {
        await expectLater(
          client.listChildDirectories(handle: handle),
          throwsA(
            isA<WingLinkHttpException>().having(
              (error) => error.statusCode,
              'status',
              410,
            ),
          ),
        );
      }
      expect(
        (await client.listDirectoryRoots()).any(
          (row) => row.handle == granted.handle,
        ),
        isFalse,
      );
    },
  );
}
