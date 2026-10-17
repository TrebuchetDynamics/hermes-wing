import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public onboarding links resolve to maintained files and anchors', () {
    final linkPattern = RegExp(r'\]\(([^)]+)\)|href="([^"]+)"');
    for (final path in [
      'README.md',
      'docs/README.md',
      'docs/getting-started.md',
      'site/index.html',
    ]) {
      final source = File(path).readAsStringSync();
      for (final match in linkPattern.allMatches(source)) {
        var target = match.group(1) ?? match.group(2)!;
        const repository =
            'https://github.com/TrebuchetDynamics/hermes-wing/blob/main/';
        final fromRepository = target.startsWith(repository);
        if (fromRepository) target = target.substring(repository.length);
        // The docs index explicitly labels these Git-ignored historical receipts
        // as optional; user setup links must still resolve in a fresh checkout.
        if ((path == 'docs/README.md' &&
                target.startsWith('../.task-evidence/')) ||
            target.startsWith('http') ||
            (path.startsWith('site/') && !fromRepository)) {
          continue;
        }
        final parts = target.split('#');
        final file = parts.first.isEmpty
            ? File(path)
            : File(
                fromRepository
                    ? parts.first
                    : '${File(path).parent.path}/${parts.first}',
              );
        expect(
          file.existsSync() || Directory(file.path).existsSync(),
          isTrue,
          reason: '$path → $target',
        );
        if (parts.length == 1) continue;
        final text = file.readAsStringSync();
        final anchors = {
          ...RegExp(
            r'id="([^"]+)"',
          ).allMatches(text).map((match) => match.group(1)!),
          ...RegExp(r'^#{1,6} (.+)$', multiLine: true)
              .allMatches(text)
              .map(
                (match) => match
                    .group(1)!
                    .toLowerCase()
                    .replaceAll(RegExp(r'[^a-z0-9 _-]'), '')
                    .replaceAll(' ', '-'),
              ),
        };
        expect(anchors, contains(parts[1]), reason: '$path → $target');
      }
    }
  });

  test(
    'onboarding acquires the client before connection and preserves anchors',
    () {
      final readme = File('README.md').readAsStringSync();
      final guide = File('docs/getting-started.md').readAsStringSync();
      for (final source in [readme, guide]) {
        expect(
          source.contains('Build a native client') ||
              source.contains('Native Android or Linux'),
          isTrue,
        );
        expect(source.toLowerCase(), contains('streaming'));
        expect(source, contains('Do not use any tools.'));
        final optionalTask = RegExp(
          r'### Optional repository summary|optional \[repository summary\]',
        ).firstMatch(source);
        expect(optionalTask, isNotNull);
        expect(
          source.indexOf('Do not use any tools.'),
          lessThan(optionalTask!.start),
        );
        for (final anchor in [
          'get-the-client',
          'getting-started',
          'connect-your-agent',
          'pair-a-phone-or-another-computer',
          'your-first-conversation',
          'build-the-alpha-from-source',
          'when-a-connection-needs-attention',
        ]) {
          expect(source, contains('id="$anchor"'), reason: anchor);
        }
      }
      final index = File('docs/README.md').readAsStringSync();
      for (final source in [readme, guide, index]) {
        expect(source, contains('Your agent. Within reach.'));
      }
      expect(index.indexOf('## Start here'), isNonNegative);
      expect(index.indexOf('## Build and contribute'), isNonNegative);
      for (final reference in [
        '## Product reference',
        '## Document ownership',
        '## Evidence availability',
      ]) {
        expect(
          index.indexOf('## Start here'),
          lessThan(index.indexOf(reference)),
        );
        expect(
          index.indexOf('## Build and contribute'),
          lessThan(index.indexOf(reference)),
        );
      }
      final headings = [
        '## What you need',
        '## Build and open the client',
        '## Prepare your Agent',
        '## Direct Agent connection',
        '## Start the conversation',
        '## Need help?',
        '## Your data and permissions',
        '## Platform evidence and limits',
      ];
      for (var i = 1; i < headings.length; i++) {
        expect(guide.indexOf(headings[i - 1]), isNonNegative);
        expect(
          guide.indexOf(headings[i - 1]),
          lessThan(guide.indexOf(headings[i])),
        );
      }
      expect(guide, isNot(contains('worktree')));
      expect(guide, isNot(contains('fake endpoint storage')));
      expect(guide, contains('Browser SSH and OAuth sign-in are unsupported'));
      expect(guide, contains('not silently resend prompts'));
      expect(guide, contains('Linux GTK simulated'));
      expect(
        guide,
        contains(
          '| Outcome | User-facing UI | Simulated / native checks | Authenticated live evidence |',
        ),
      );
      expect(
        guide,
        contains(
          '| SSH | Android/Linux native interface; browser unsupported |',
        ),
      );
      expect(readme, contains('session chat and streaming'));
    },
  );

  test(
    'README assets use a synthetic repository story, not e2e status proof',
    () {
      final readme = File('README.md').readAsStringSync();
      final fixture = File('serve_web.mjs').readAsStringSync();
      final generator = File(
        'scripts/generate_readme_assets.mjs',
      ).readAsStringSync();
      expect(readme.split('\n').length - 1, inInclusiveRange(160, 180));
      expect(
        readme.indexOf('[Set up your first chat]'),
        lessThan(readme.indexOf('## Choose a path')),
      );
      final paths = [
        '### Preview the connection screen',
        '### Connect an existing Hermes Agent',
        '### Build a native client',
      ];
      for (var i = 1; i < paths.length; i++) {
        expect(
          readme.indexOf(paths[i - 1]),
          lessThan(readme.indexOf(paths[i])),
        );
      }
      expect(fixture, contains('Sample repository summary'));
      expect(fixture, contains('read_file README.md'));
      expect(fixture, contains('README summary: src/ contains the app'));
      expect(generator, contains('Sample repository summary'));
      expect(generator, contains('read_file · Sample repository summarized'));
      expect(generator, contains('"Gateway readiness"'));
      expect(generator, contains('Synthetic sample workflow'));
      expect(
        generator,
        contains('clip: { x: 530, y: 280, width: 750, height: 310 }'),
      );
      expect(generator, contains('"Office"'));
      expect(generator, contains('"echo e2e"'));
    },
  );

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
    final gettingStarted = File('docs/getting-started.md').readAsStringSync();
    final landing = File('site/index.html').readAsStringSync();

    expect(generator.existsSync(), isTrue);
    expect(fixture, contains('/e2e/hermes/presentation'));
    expect(fixture, contains('Sample repository summary'));

    expect(hero, contains('RUN COMPLETE'));
    expect(hero, isNot(contains('APPROVAL REQUIRED')));
    expect(hero, isNot(contains('DENY / STOP')));

    for (final diagram in [runtime, runtimeMobile]) {
      expect(diagram, contains('HTTPS'));
      expect(diagram, contains('SSE'));
      expect(diagram, contains('authoritative context'));
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
    expect(generatorSource, contains('MOBILE · FILE READ REVIEW'));
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
    expect(readme, contains('[Preview the connection screen]'));
    expect(readme, contains('This is an interface, not a working assistant;'));
    expect(readme, contains('authenticated Agent and configured provider.'));
    expect(readme, contains('docs/getting-started.md'));
    expect(readme, contains('showcase-mobile.png'));
    expect(readme, contains('runs the assistant,'));
    expect(readme, contains('conversations, tools, and configuration;'));
    expect(gettingStarted, contains('Agent remains the source of truth'));
    expect(readme, isNot(contains('Wing Link')));
    expect(generatorSource, contains('approveOnce.scrollIntoViewIfNeeded()'));
    expect(gettingStarted, contains('Wing connects directly to Hermes Agent.'));
    expect(gettingStarted, contains('Wing Link is not required.'));
    expect(gettingStarted, isNot(contains('./install-wing-link.sh')));
    expect(readme, isNot(contains('--provider')));
    expect(gettingStarted, isNot(contains('--provider')));
    expect(readme, isNot(contains('--profile')));
    expect(gettingStarted, isNot(contains('--profile')));
    expect(readme, isNot(contains('--model')));
    expect(gettingStarted, isNot(contains('--model')));
    expect(landing, contains('runtime-flow-mobile.svg'));

    for (final document in [readme, landing]) {
      expect(document, isNot(contains('physical Android device receipt')));
      expect(document, isNot(contains('physical-device QA receipt')));
    }
    expect(landing, contains('repository summary and phone approval request'));
    expect(generatorSource, isNot(contains('LIVE RUN')));
    expect(generatorSource, isNot(contains('Wing Link')));
    expect(generatorSource, contains('DEMO DATA · SIMULATED SESSION'));
    expect(hero, contains('DEMO DATA · SIMULATED SESSION'));
    expect(landing, isNot(contains('live session trace')));
    expect(generatorSource, isNot(contains('erasePendingRunSpinner')));
    expect(generatorSource, contains('wingE2EReduceMotion'));
    expect(e2eSource, contains("@JS('wingE2EReduceMotion')"));
    expect(
      e2eSource,
      matches(
        RegExp(
          r'disableAnimations:\s*disabled\s*\|\|\s*'
          r'MediaQuery\.disableAnimationsOf\(context\)',
        ),
      ),
      reason:
          'The fixture must preserve platform reduced motion as well as the '
          'explicit test setting, independent of Dart formatting.',
    );
  });
}
