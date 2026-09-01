class TermuxBootstrapCommand {
  TermuxBootstrapCommand._({
    required this.tag,
    required this.installerCommit,
    required this.installerSha256,
    required this.assetSha256,
    required this.assetSize,
  });

  factory TermuxBootstrapCommand.fromJson(Map<String, Object?> json) {
    const expectedKeys = {
      'available',
      'tag',
      'installer_commit',
      'installer_sha256',
      'asset_sha256',
      'asset_size',
    };
    if (json.keys.toSet().difference(expectedKeys).isNotEmpty ||
        expectedKeys.difference(json.keys.toSet()).isNotEmpty ||
        json['available'] != true) {
      throw const FormatException('Termux bootstrap metadata is unavailable');
    }

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
        !RegExp(r'^[0-9a-f]{40}$').hasMatch(installerCommit) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(installerSha256) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(assetSha256) ||
        assetSize < 1 ||
        assetSize > 50 * 1024 * 1024) {
      throw const FormatException('Invalid Termux bootstrap metadata');
    }

    return TermuxBootstrapCommand._(
      tag: tag,
      installerCommit: installerCommit,
      installerSha256: installerSha256,
      assetSha256: assetSha256,
      assetSize: assetSize,
    );
  }

  final String tag;
  final String installerCommit;
  final String installerSha256;
  final String assetSha256;
  final int assetSize;

  String get command =>
      'pkg install -y curl coreutils && i="\$(mktemp)" && '
      'curl --proto \'=https\' --tlsv1.2 --fail --location '
      '--connect-timeout 15 --max-time 300 --max-filesize $assetSize '
      '--output "\$i" '
      '"https://raw.githubusercontent.com/TrebuchetDynamics/hermes-wing/'
      '$installerCommit/install-wing-link.sh" && '
      'printf \'%s  %s\\n\' \'$installerSha256\' "\$i" | sha256sum -c - && '
      '"\$PREFIX/bin/bash" "\$i" --tag \'$tag\' '
      '--sha256 \'$assetSha256\' --size \'$assetSize\' --setup';
}
