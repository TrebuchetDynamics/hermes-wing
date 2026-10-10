import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_discovery.dart';
import 'package:wing/core/hermes/local_discovery/local_hermes_home_platform_unsupported.dart';

void main() {
  test(
    'browser fallback is explicitly unsupported with no host path',
    () async {
      final platform = createLocalHermesHomePlatform();
      expect(platform.isSupported, isFalse);
      expect(platform.userHome, isNull);
      final discovery = LocalHermesHomeDiscovery(platform: platform);
      if (kIsWeb) {
        // Exercise the conditional production factory, not just the stub.
        final browserDefault = await LocalHermesHomeDiscovery()
            .inspectDefault();
        expect(browserDefault.status, LocalHermesHomeStatus.unsupported);
        expect(browserDefault.canonicalPath, isNull);
      }
      for (final result in [
        await discovery.inspectDefault(),
        await discovery.inspectSelected('/selected'),
        await platform.inspectDirectory('/selected'),
      ]) {
        expect(result.status, LocalHermesHomeStatus.unsupported);
        expect(result.canonicalPath, isNull);
      }
    },
  );
}
