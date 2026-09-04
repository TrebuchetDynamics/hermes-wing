enum _TermuxBootstrapMode { release, source }

class TermuxBootstrapCommand {
  TermuxBootstrapCommand._({
    required this._mode,
    required this._installerSha256,
    this._tag,
    this._installerCommit,
    this._assetSha256,
    this._assetSize,
    this._sourceCommit,
    this._archiveSha256,
    this._archiveSize,
    this._hermesCommit,
    this._hermesInstallerSha256,
    this._hermesInstallerSize,
  });

  factory TermuxBootstrapCommand.fromJson(Map<String, Object?> json) {
    if (json['available'] != true) {
      throw const FormatException('Termux bootstrap metadata is unavailable');
    }
    return json['mode'] == 'source'
        ? TermuxBootstrapCommand._fromSourceJson(json)
        : TermuxBootstrapCommand._fromReleaseJson(json);
  }

  factory TermuxBootstrapCommand._fromReleaseJson(Map<String, Object?> json) {
    const expectedKeys = {
      'available',
      'tag',
      'installer_commit',
      'installer_sha256',
      'asset_sha256',
      'asset_size',
    };
    _requireExactKeys(json, expectedKeys);

    final tag = json['tag'];
    final installerCommit = json['installer_commit'];
    final installerSha256 = json['installer_sha256'];
    final assetSha256 = json['asset_sha256'];
    final assetSize = json['asset_size'];
    if (tag is! String ||
        installerCommit is! String ||
        installerSha256 is! String ||
        assetSha256 is! String ||
        assetSize is! int ||
        !RegExp(r'^v\d+\.\d+\.\d+-alpha\.\d+$').hasMatch(tag) ||
        !_isCommit(installerCommit) ||
        !_isSha256(installerSha256) ||
        !_isSha256(assetSha256) ||
        !_isBoundedSize(assetSize)) {
      throw const FormatException('Invalid Termux bootstrap metadata');
    }

    return TermuxBootstrapCommand._(
      mode: _TermuxBootstrapMode.release,
      tag: tag,
      installerCommit: installerCommit,
      installerSha256: installerSha256,
      assetSha256: assetSha256,
      assetSize: assetSize,
    );
  }

  factory TermuxBootstrapCommand._fromSourceJson(Map<String, Object?> json) {
    const expectedKeys = {
      'available',
      'mode',
      'commit',
      'archive_sha256',
      'archive_size',
      'installer_sha256',
      'hermes_commit',
      'hermes_installer_sha256',
      'hermes_installer_size',
    };
    _requireExactKeys(json, expectedKeys);

    final commit = json['commit'];
    final archiveSha256 = json['archive_sha256'];
    final archiveSize = json['archive_size'];
    final installerSha256 = json['installer_sha256'];
    final hermesCommit = json['hermes_commit'];
    final hermesInstallerSha256 = json['hermes_installer_sha256'];
    final hermesInstallerSize = json['hermes_installer_size'];
    if (commit is! String ||
        archiveSha256 is! String ||
        archiveSize is! int ||
        installerSha256 is! String ||
        hermesCommit is! String ||
        hermesInstallerSha256 is! String ||
        hermesInstallerSize is! int ||
        !_isCommit(commit) ||
        !_isSha256(archiveSha256) ||
        !_isSha256(installerSha256) ||
        !_isCommit(hermesCommit) ||
        !_isSha256(hermesInstallerSha256) ||
        !_isBoundedSize(archiveSize) ||
        !_isBoundedInstallerSize(hermesInstallerSize)) {
      throw const FormatException('Invalid Termux bootstrap metadata');
    }

    return TermuxBootstrapCommand._(
      mode: _TermuxBootstrapMode.source,
      sourceCommit: commit,
      archiveSha256: archiveSha256,
      archiveSize: archiveSize,
      installerSha256: installerSha256,
      hermesCommit: hermesCommit,
      hermesInstallerSha256: hermesInstallerSha256,
      hermesInstallerSize: hermesInstallerSize,
    );
  }

  final _TermuxBootstrapMode _mode;
  final String _installerSha256;
  final String? _tag;
  final String? _installerCommit;
  final String? _assetSha256;
  final int? _assetSize;
  final String? _sourceCommit;
  final String? _archiveSha256;
  final int? _archiveSize;
  final String? _hermesCommit;
  final String? _hermesInstallerSha256;
  final int? _hermesInstallerSize;

  String get command => switch (_mode) {
    _TermuxBootstrapMode.release => _releaseCommand,
    _TermuxBootstrapMode.source => _sourceCommand,
  };

  String get _releaseCommand {
    final tag = _tag!;
    final installerCommit = _installerCommit!;
    final assetSha256 = _assetSha256!;
    final assetSize = _assetSize!;
    return 'pkg install -y curl coreutils && i="\$(mktemp)" && '
        'curl --proto \'=https\' --tlsv1.2 --fail --location '
        '--connect-timeout 15 --max-time 300 --max-filesize $assetSize '
        '--output "\$i" '
        '"https://raw.githubusercontent.com/TrebuchetDynamics/hermes-wing/'
        '$installerCommit/install-wing-link.sh" && '
        'printf \'%s  %s\\n\' \'$_installerSha256\' "\$i" | sha256sum -c - && '
        '"\$PREFIX/bin/bash" "\$i" --tag \'$tag\' '
        '--sha256 \'$assetSha256\' --size \'$assetSize\' --setup';
  }

  String get _sourceCommand {
    final commit = _sourceCommit!;
    final archiveSha256 = _archiveSha256!;
    final archiveSize = _archiveSize!;
    final hermesCommit = _hermesCommit!;
    final hermesInstallerSha256 = _hermesInstallerSha256!;
    final hermesInstallerSize = _hermesInstallerSize!;
    return 'pkg install -y curl coreutils tar golang && '
        '(d="\$(mktemp -d)" && trap \'rm -rf "\$d"\' EXIT && '
        'h="\$d/hermes-install.sh" && '
        'curl --proto \'=https\' --tlsv1.2 --fail --location '
        '--connect-timeout 15 --max-time 300 '
        '--max-filesize $hermesInstallerSize --output "\$h" '
        '"https://raw.githubusercontent.com/NousResearch/hermes-agent/'
        '$hermesCommit/scripts/install.sh" && '
        'test "\$(wc -c < "\$h" | tr -d \' \')" = '
        '\'$hermesInstallerSize\' && '
        'printf \'%s  %s\\n\' \'$hermesInstallerSha256\' "\$h" | '
        'sha256sum -c - && '
        'a="\$d/source.tar.gz" && '
        'curl --proto \'=https\' --tlsv1.2 --fail --location '
        '--connect-timeout 15 --max-time 300 --max-filesize $archiveSize '
        '--output "\$a" '
        '"https://codeload.github.com/TrebuchetDynamics/hermes-wing/tar.gz/'
        '$commit" && '
        'test "\$(wc -c < "\$a" | tr -d \' \')" = \'$archiveSize\' && '
        'printf \'%s  %s\\n\' \'$archiveSha256\' "\$a" | sha256sum -c - && '
        'tar --extract --gzip --file "\$a" --directory "\$d" && '
        's="\$d/hermes-wing-$commit" && '
        'printf \'%s  %s\\n\' \'$_installerSha256\' '
        '"\$s/install-wing-link.sh" | sha256sum -c - && '
        '"\$PREFIX/bin/bash" "\$h" --commit \'$hermesCommit\' '
        '--skip-setup --non-interactive --hermes-home "\$HOME/.hermes" && '
        '"\$PREFIX/bin/bash" "\$s/install-wing-link.sh" --build --setup)';
  }
}

const _maximumBootstrapBytes = 50 * 1024 * 1024;
const _maximumInstallerBytes = 1024 * 1024;

void _requireExactKeys(Map<String, Object?> json, Set<String> expected) {
  final keys = json.keys.toSet();
  if (keys.difference(expected).isNotEmpty ||
      expected.difference(keys).isNotEmpty) {
    throw const FormatException('Invalid Termux bootstrap metadata');
  }
}

bool _isCommit(String value) => RegExp(r'^[0-9a-f]{40}$').hasMatch(value);

bool _isSha256(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

bool _isBoundedSize(int value) => value >= 1 && value <= _maximumBootstrapBytes;

bool _isBoundedInstallerSize(int value) =>
    value >= 1 && value <= _maximumInstallerBytes;
