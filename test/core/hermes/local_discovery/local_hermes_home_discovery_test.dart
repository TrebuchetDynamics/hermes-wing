import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_platform_io.dart';

void main() {
  late Directory workspace;
  setUp(() async {
    workspace = await Directory(
      Platform.environment['TMPDIR']!,
    ).createTemp('wing-local-discovery-');
  });
  tearDown(() async => workspace.delete(recursive: true));

  test('default discovery inspects only injected user home/.hermes', () async {
    final home = await Directory('${workspace.path}/.hermes').create();
    final discovery = LocalHermesHomeDiscovery(
      platform: IoLocalHermesHomePlatform(userHome: workspace.path),
    );
    final result = await discovery.inspectDefault();
    expect(result.status, LocalHermesHomeStatus.supported);
    expect(result.canonicalPath, await home.resolveSymbolicLinks());
  });
  test(
    'unsupported platforms never access home or directory metadata',
    () async {
      final discovery = LocalHermesHomeDiscovery(
        platform: _UnsupportedPlatform(),
      );
      expect(
        (await discovery.inspectDefault()).status,
        LocalHermesHomeStatus.unsupported,
      );
      expect(
        (await discovery.inspectSelected('/selected')).status,
        LocalHermesHomeStatus.unsupported,
      );
    },
  );

  test(
    'invalid or missing home never falls back to current directory',
    () async {
      final platform = _RecordingPlatform();
      final discovery = LocalHermesHomeDiscovery(platform: platform);
      expect(
        (await discovery.inspectDefault()).status,
        LocalHermesHomeStatus.unreadable,
      );
      for (final path in [
        '',
        'relative',
        '~/hermes',
        '/bad\u0000path',
        '/line\npath',
        '/${'a' * 4096}',
      ]) {
        expect(
          (await discovery.inspectSelected(path)).status,
          LocalHermesHomeStatus.unreadable,
        );
      }
      expect(platform.inspected, isEmpty);
    },
  );

  test('unexpected platform failures are sanitized', () async {
    final discovery = LocalHermesHomeDiscovery(platform: _FailingPlatform());
    final result = await discovery.inspectSelected('/selected');
    expect(result.status, LocalHermesHomeStatus.unreadable);
    expect(result.canonicalPath, isNull);
  });

  test('empty injected home is not the filesystem root', () async {
    final platform = _RecordingPlatform(userHome: '');
    final result = await LocalHermesHomeDiscovery(
      platform: platform,
    ).inspectDefault();
    expect(result.status, LocalHermesHomeStatus.unreadable);
    expect(platform.inspected, isEmpty);
  });

  test('Android IO backend refuses metadata inspection', () async {
    final result = await IOOverrides.runZoned(
      () => _AndroidPlatform().inspectDirectory('/selected'),
      createDirectory: (_) =>
          throw StateError('must not inspect Android files'),
    );
    expect(result.status, LocalHermesHomeStatus.unsupported);
    expect(result.canonicalPath, isNull);
  });

  test(
    'selected folder uses current canonical directory on each call',
    () async {
      final first = await Directory('${workspace.path}/first').create();
      final second = await Directory('${workspace.path}/second').create();
      final link = await Link('${workspace.path}/selected').create(first.path);
      final discovery = LocalHermesHomeDiscovery(
        platform: IoLocalHermesHomePlatform(userHome: workspace.path),
      );
      expect(
        (await discovery.inspectSelected(link.path)).canonicalPath,
        await first.resolveSymbolicLinks(),
      );
      await link.update(second.path);
      expect(
        (await discovery.inspectSelected(link.path)).canonicalPath,
        await second.resolveSymbolicLinks(),
      );
      await second.delete();
      final gone = await discovery.inspectSelected(link.path);
      expect(gone.status, LocalHermesHomeStatus.absent);
      expect(gone.canonicalPath, isNull);
      expect(
        (await discovery.inspectSelected(first.path)).canonicalPath,
        await first.resolveSymbolicLinks(),
      );
    },
  );

  test(
    'stat failure after canonicalization is not a false-positive directory',
    () async {
      final discovery = LocalHermesHomeDiscovery(
        platform: IoLocalHermesHomePlatform(userHome: workspace.path),
      );
      final result = await IOOverrides.runZoned(
        () => discovery.inspectSelected('${workspace.path}/selected'),
        createDirectory: (_) =>
            _DisappearedDirectory('${workspace.path}/missing'),
      );
      expect(result.status, LocalHermesHomeStatus.unreadable);
      expect(result.canonicalPath, isNull);
    },
  );

  test('missing default is absent, not a usable Hermes home', () async {
    final discovery = LocalHermesHomeDiscovery(
      platform: IoLocalHermesHomePlatform(userHome: workspace.path),
    );
    final result = await discovery.inspectDefault();
    expect(result.status, LocalHermesHomeStatus.absent);
    expect(result.canonicalPath, isNull);
  });

  test('a regular file is not a Hermes home directory', () async {
    final file = await File('${workspace.path}/.hermes').create();
    final discovery = LocalHermesHomeDiscovery(
      platform: IoLocalHermesHomePlatform(userHome: workspace.path),
    );
    final result = await discovery.inspectSelected(file.path);
    expect(result.status, LocalHermesHomeStatus.notDirectory);
    expect(result.canonicalPath, isNull);
  });

  test('permission denied is unreadable without leaking raw errors', () async {
    final discovery = LocalHermesHomeDiscovery(
      platform: IoLocalHermesHomePlatform(userHome: workspace.path),
    );
    final result = await IOOverrides.runZoned(
      () => discovery.inspectSelected('${workspace.path}/denied'),
      createDirectory: (_) => _DeniedDirectory(),
    );
    expect(result.status, LocalHermesHomeStatus.unreadable);
    expect(result.canonicalPath, isNull);
    expect(result.toString(), isNot(contains('private error')));
  });
}

class _UnsupportedPlatform implements LocalHermesHomePlatform {
  @override
  bool get isSupported => false;
  @override
  String? get userHome => throw StateError('must not access home');
  @override
  Future<LocalHermesHomeInspection> inspectDirectory(String path) =>
      throw StateError('must not inspect');
}

class _RecordingPlatform implements LocalHermesHomePlatform {
  _RecordingPlatform({this.userHome});
  final inspected = <String>[];
  @override
  bool get isSupported => true;
  @override
  final String? userHome;
  @override
  Future<LocalHermesHomeInspection> inspectDirectory(String path) async {
    inspected.add(path);
    return LocalHermesHomeInspection.directory(path);
  }
}

class _FailingPlatform extends _RecordingPlatform {
  @override
  Future<LocalHermesHomeInspection> inspectDirectory(String path) async =>
      throw StateError('private error');
}

class _AndroidPlatform extends IoLocalHermesHomePlatform {
  _AndroidPlatform() : super(userHome: '/unused');
  @override
  bool get isSupported => false;
}

class _DisappearedDirectory implements Directory {
  _DisappearedDirectory(this.missingPath);
  final String missingPath;
  @override
  Future<String> resolveSymbolicLinks() async => '/redacted';
  @override
  Future<FileStat> stat() => FileStat.stat(missingPath);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DeniedDirectory implements Directory {
  @override
  Future<String> resolveSymbolicLinks() async =>
      throw const FileSystemException(
        'private error',
        '/redacted',
        OSError('denied', 13),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
