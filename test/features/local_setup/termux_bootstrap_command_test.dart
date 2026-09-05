import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/local_setup/models/termux_bootstrap_command.dart';

Map<String, Object?> _sourceMetadata({
  Object? commit = '0123456789abcdef0123456789abcdef01234567',
  Object? archiveSha256 =
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
  Object? archiveSize = 4321000,
  Object? installerSha256 =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  Object? hermesCommit = '89abcdef0123456789abcdef0123456789abcdef',
  Object? hermesInstallerSha256 =
      'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
  Object? hermesInstallerSize = 170000,
}) => {
  'available': true,
  'mode': 'source',
  'commit': commit,
  'archive_sha256': archiveSha256,
  'archive_size': archiveSize,
  'installer_sha256': installerSha256,
  'hermes_commit': hermesCommit,
  'hermes_installer_sha256': hermesInstallerSha256,
  'hermes_installer_size': hermesInstallerSize,
};

Map<String, Object?> _metadata({
  Object? tag = 'v0.1.0-alpha.9',
  Object? installerCommit = '0123456789abcdef0123456789abcdef01234567',
  Object? installerSha256 =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  Object? assetSha256 =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  Object? assetSize = 1234567,
}) => {
  'available': true,
  'tag': tag,
  'installer_commit': installerCommit,
  'installer_sha256': installerSha256,
  'asset_sha256': assetSha256,
  'asset_size': assetSize,
};

void main({bool includeHostChecks = true}) {
  test('renders only the fixed verified command shape', () {
    final command = TermuxBootstrapCommand.fromJson(_metadata()).command;

    expect(command, contains('pkg install -y curl coreutils'));
    expect(
      command,
      contains('raw.githubusercontent.com/TrebuchetDynamics/hermes-wing/'),
    );
    expect(command, contains('--tag \'v0.1.0-alpha.9\''));
    final digest = List.filled(64, 'b').join();
    expect(command, contains('--sha256 \'$digest\''));
    expect(command, contains('--size \'1234567\''));
    expect(command, contains('--setup'));
    expect(command, isNot(allOf(contains('curl -fsSL'), contains('| bash'))));
    expect(command, isNot(contains('token')));
    expect(command, isNot(contains('code=')));
    expect(command, contains('--max-filesize 1234567'));
  });

  test('renders a verified source-build fallback for development builds', () {
    final command = TermuxBootstrapCommand.fromJson(_sourceMetadata()).command;

    expect(command, contains('pkg install -y curl coreutils tar golang'));
    expect(
      command,
      contains(
        'https://codeload.github.com/TrebuchetDynamics/hermes-wing/tar.gz/'
        '0123456789abcdef0123456789abcdef01234567',
      ),
    );
    expect(command, contains('--max-filesize 4321000'));
    expect(command, contains("'4321000'"));
    expect(command, contains(List.filled(64, 'c').join()));
    expect(command, contains(List.filled(64, 'a').join()));
    expect(
      command,
      contains(
        'raw.githubusercontent.com/NousResearch/hermes-agent/'
        '89abcdef0123456789abcdef0123456789abcdef/scripts/install.sh',
      ),
    );
    expect(command, contains('--max-filesize 170000'));
    expect(command, contains(List.filled(64, 'd').join()));
    expect(
      command,
      contains('--commit \'89abcdef0123456789abcdef0123456789abcdef\''),
    );
    expect(command, contains('--skip-setup --non-interactive'));
    expect(command, contains('--build --setup'));
    if (includeHostChecks) {
      expect(Process.runSync('bash', ['-n', '-c', command]).exitCode, 0);
    }
    expect(command, isNot(contains('code=')));
    expect(command, isNot(contains('token')));
  });

  if (includeHostChecks) {
    test('packaged metadata is unavailable or a valid release command', () {
      final source = File(
        'assets/config/termux_bootstrap.json',
      ).readAsStringSync();
      final metadata = jsonDecode(source) as Map<String, Object?>;
      if (metadata['available'] == false) {
        expect(metadata, {'available': false});
      } else {
        expect(TermuxBootstrapCommand.fromJson(metadata).command, isNotEmpty);
      }
    });
  }

  test('rejects unavailable, malformed, and unbounded metadata', () {
    final invalid = <Map<String, Object?>>[
      {'available': false},
      _metadata(tag: 'latest'),
      _metadata(tag: 'v0.1.0-alpha.9;echo bad'),
      _metadata(installerCommit: List.filled(39, 'a').join()),
      _metadata(installerCommit: List.filled(40, 'A').join()),
      _metadata(installerSha256: List.filled(63, 'a').join()),
      _metadata(assetSha256: List.filled(64, 'A').join()),
      _metadata(assetSize: 0),
      _metadata(assetSize: 50 * 1024 * 1024 + 1),
      {..._metadata(), 'origin': 'https://example.invalid'},
      _sourceMetadata(commit: List.filled(40, 'A').join()),
      _sourceMetadata(archiveSha256: List.filled(63, 'c').join()),
      _sourceMetadata(archiveSize: 0),
      _sourceMetadata(archiveSize: 50 * 1024 * 1024 + 1),
      _sourceMetadata(hermesCommit: List.filled(40, 'A').join()),
      _sourceMetadata(hermesInstallerSha256: List.filled(63, 'd').join()),
      _sourceMetadata(hermesInstallerSize: 0),
      _sourceMetadata(hermesInstallerSize: 1024 * 1024 + 1),
      {..._sourceMetadata(), 'origin': 'https://example.invalid'},
    ];

    for (final metadata in invalid) {
      expect(
        () => TermuxBootstrapCommand.fromJson(metadata),
        throwsFormatException,
        reason: '$metadata',
      );
    }
  });
}
