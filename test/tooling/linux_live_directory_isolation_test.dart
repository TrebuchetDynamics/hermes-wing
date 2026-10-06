import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/linux_test_isolation.dart';

void main() {
  late Directory owned;
  setUp(() {
    owned = Directory.systemTemp.createTempSync('wing-linux-coverage.');
    Directory(
      '${owned.path}/grant-root/child-folder',
    ).createSync(recursive: true);
  });
  tearDown(() => owned.deleteSync(recursive: true));

  test('live directory root is the canonical grant child of owned state', () {
    expect(
      requireLinuxLiveDirectoryRoot('${owned.path}/grant-root', owned.path),
      '${owned.path}/grant-root',
    );
  });

  test('rejects foreign, traversal and symlink directory roots', () {
    final foreign = Directory.systemTemp.createTempSync('wing-linux-foreign.');
    addTearDown(() => foreign.deleteSync(recursive: true));
    Directory('${foreign.path}/grant-root').createSync();
    final link = Link('${owned.path}/escape')..createSync(foreign.path);
    for (final root in [
      '${foreign.path}/grant-root',
      '${owned.path}/grant-root/../grant-root',
      '${link.path}/grant-root',
      '${owned.path}/grant-root/child-folder',
    ]) {
      expect(
        () => requireLinuxLiveDirectoryRoot(root, owned.path),
        throwsStateError,
      );
    }
  });

  test('rejects an exact grant-root name that links outside owned state', () {
    final foreign = Directory.systemTemp.createTempSync('wing-linux-foreign.');
    addTearDown(() => foreign.deleteSync(recursive: true));
    Directory('${owned.path}/grant-root').deleteSync(recursive: true);
    Link('${owned.path}/grant-root').createSync(foreign.path);
    expect(
      () =>
          requireLinuxLiveDirectoryRoot('${owned.path}/grant-root', owned.path),
      throwsStateError,
    );
  });
}
