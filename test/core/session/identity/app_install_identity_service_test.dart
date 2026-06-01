import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/session/app_install_identity_service.dart';

import '../support/session_shared_preferences_test_support.dart';

void main() {
  setUp(() {
    resetSessionPreferences();
  });

  test('creates and reuses a non-secret app install identity', () async {
    final service = AppInstallIdentityService(random: Random(1));

    final first = await service.getOrCreate();
    final second = await service.getOrCreate();

    expect(first, second);
    expect(first, startsWith('navi-install-'));
    expect(first.length, 'navi-install-'.length + 32);
  });

  test('normalizes existing app install identity', () async {
    resetSessionPreferences({
      AppInstallIdentityService.identityKey: '  navi-install-existing  ',
    });
    final service = AppInstallIdentityService(random: Random(1));

    final identity = await service.getOrCreate();

    expect(identity, 'navi-install-existing');
  });
}
