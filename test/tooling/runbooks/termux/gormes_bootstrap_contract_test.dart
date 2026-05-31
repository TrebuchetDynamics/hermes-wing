import 'package:flutter_test/flutter_test.dart';

import '../../shared/file_contract_helpers.dart';
import '../shared/runbook_contract_helpers.dart';

void main() {
  test('Termux Gormes bootstrap guide documents safe Android phases', () {
    final text = readRunbookContractWithSharedPolicy(
      'docs/runbooks/termux/gormes-bootstrap.md',
    );
    final readme = readRequiredFile('README.md');

    expectRunbookContainsAll(text, [
      '# Termux Gormes Bootstrap',
      'Phase 1',
      'Phase 2',
      'Android >= 7',
      'F-Droid',
      'GitHub Releases',
      'Google Play',
      'do not mix Termux APK sources',
      'pkg upgrade',
      'pkg install git curl',
      'termux-setup-storage',
      'install.sh',
      'bash install.sh',
      'GORMES_SKIP_SETUP=1 bash install.sh',
    ]);
    expect(
      text,
      contains('(gormes navivox pair || gormes navivox connect-info)'),
    );
    expectRunbookContainsAll(text, [
      'Navivox cannot silently install Gormes',
      'gormes navivox connect-info',
      'Do not paste tokens',
      'one terminal interaction maximum',
    ]);
    expect(
      text,
      contains('Install Termux, paste one command, continue in Navivox'),
    );
    expectRunbookContainsAll(text, [
      'Gormes installed successfully',
      'Navivox (recommended)',
      'CLI setup',
      'gormes navivox pair',
      'start local bridge',
      'generate a pairing token',
      'show a QR',
      'print localhost URL',
      'wait for Navivox connection',
      'Termux:Boot',
      'same APK source',
      'gormes gateway boot-install',
      'gormes gateway boot-uninstall',
      '.termux/boot/gormes-gateway.sh',
    ]);
    expectRunbookOmitsAll(text, ['curl | sh', 'pm install']);
    expectRunbookHasNoSecretPlaceholders(text);
    expect(readme, contains('docs/runbooks/termux/gormes-bootstrap.md'));
  });
}
