import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';

void main() {
  for (final platform in TargetPlatform.values) {
    test('local discovery availability on $platform', () {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(localLinuxSetupAvailableProvider),
        !kIsWeb && platform == TargetPlatform.linux,
      );
    });
  }
}
