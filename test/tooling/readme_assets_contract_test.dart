import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('README assets are reproducible and show healthy current states', () {
    final generator = File('scripts/generate_readme_assets.mjs');
    final e2eEntryPoint = File('lib/main_e2e.dart');
    final hero = File('assets/readme/hero.svg').readAsStringSync();
    final runtime = File('assets/readme/runtime-flow.svg').readAsStringSync();
    final runtimeMobile = File(
      'assets/readme/runtime-flow-mobile.svg',
    ).readAsStringSync();
    final fixture = File('serve_web.mjs').readAsStringSync();
    final readme = File('README.md').readAsStringSync();
    final landing = File('site/index.html').readAsStringSync();

    expect(generator.existsSync(), isTrue);
    expect(fixture, contains('/e2e/hermes/presentation'));
    expect(fixture, contains('Gateway readiness'));

    expect(hero, contains('RUN COMPLETE'));
    expect(hero, isNot(contains('APPROVAL REQUIRED')));
    expect(hero, isNot(contains('DENY / STOP')));

    for (final diagram in [runtime, runtimeMobile]) {
      expect(diagram, contains('HTTPS'));
      expect(diagram, contains('SSE'));
      expect(diagram, contains('Wing Link'));
      expect(diagram.toLowerCase(), contains('fail closed'));
    }

    final generatorSource = generator.existsSync()
        ? generator.readAsStringSync()
        : '';
    final e2eSource = e2eEntryPoint.existsSync()
        ? e2eEntryPoint.readAsStringSync()
        : '';
    expect(generatorSource, contains('showcase.png'));
    expect(generatorSource, contains('showcase-mobile.png'));
    expect(generatorSource, contains('reducedMotion: "reduce"'));
    expect(generatorSource, contains('animations: "disabled"'));
    expect(generatorSource, contains('name: "Review"'));
    expect(generatorSource, contains('Review Hermes approval'));
    expect(generatorSource, contains('name: "Approve once"'));
    expect(generatorSource, contains('MOBILE · APPROVAL'));
    expect(generatorSource, contains('"_no_installed_skill_match_"'));
    expect(
      generatorSource,
      contains('Refusing to capture presentation containing'),
    );

    final desktopPointerMove = generatorSource.indexOf(
      'desktop.page.mouse.move(0, 0)',
    );
    final desktopSettlingDelay = generatorSource.indexOf(
      'desktop.page.waitForTimeout(600)',
    );
    expect(desktopPointerMove, isNonNegative);
    expect(desktopSettlingDelay, isNonNegative);
    expect(
      desktopPointerMove,
      lessThan(desktopSettlingDelay),
      reason:
          'Move the pointer off transient controls before the settling delay.',
    );
    expect(readme, contains('Try the web alpha'));
    expect(readme, contains('showcase-mobile.png'));
    expect(readme, contains('Profile, provider, and model setup belongs to'));
    expect(generatorSource, contains('approveOnce.scrollIntoViewIfNeeded()'));
    expect(readme, contains('Go 1.26 or newer'));
    expect(readme, contains('~/.local/bin/wing-link setup'));
    expect(readme, contains('Deprecated Wing Link profile/provider adapters'));
    expect(readme, isNot(contains('--provider')));
    expect(readme, isNot(contains('--profile')));
    expect(readme, isNot(contains('--model')));
    expect(landing, contains('runtime-flow-mobile.svg'));

    for (final document in [readme, landing]) {
      expect(document, isNot(contains('physical Android device receipt')));
      expect(document, isNot(contains('physical-device QA receipt')));
    }
    expect(landing, contains('low-risk approval request'));
    expect(generatorSource, isNot(contains('erasePendingRunSpinner')));
    expect(generatorSource, contains('wingE2EReduceMotion'));
    expect(e2eSource, contains("@JS('wingE2EReduceMotion')"));
    expect(e2eSource, contains('disableAnimations: disabled'));
  });
}
