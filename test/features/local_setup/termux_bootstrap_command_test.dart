import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/local_setup/models/termux_bootstrap_command.dart';

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

void main() {
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
    expect(command, contains('--max-filesize 1048576'));
  });

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
