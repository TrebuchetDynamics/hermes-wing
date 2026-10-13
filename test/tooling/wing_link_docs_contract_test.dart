import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'current guidance describes direct Agent use and unavailable management',
    () {
      final context = File('CONTEXT.md').readAsStringSync();
      final runtime = File(
        'docs/adr/runtime-and-delivery.md',
      ).readAsStringSync();
      final routes = File('docs/product/routes.md').readAsStringSync();
      expect(
        context,
        contains('missing Agent credential requires direct reauthentication'),
      );
      expect(runtime, contains('external authoritative runtime'));
      expect(runtime, contains('no host-management service'));
      expect(routes, contains('Project creation remains unavailable'));
      for (final path in [
        'CONTEXT.md',
        'CONTRIBUTING.md',
        'AGENTS.md',
        'docs/getting-started.md',
        'docs/product/routes.md',
        'docs/product/gateway-profile-management.md',
        'docs/runbooks/android-hermes-setup.md',
      ]) {
        final text = File(path).readAsStringSync();
        expect(text, isNot(contains('./install-wing-link.sh')), reason: path);
        expect(text, isNot(contains('wing-link pair')), reason: path);
        expect(text, isNot(contains('(cd wing_link && go test')), reason: path);
      }
    },
  );

  test('Android Termux local hosting remains bounded', () {
    final runtimeDecision = File(
      'docs/adr/runtime-and-delivery.md',
    ).readAsStringSync();
    final threatModel = File(
      'docs/security/threat-model.md',
    ).readAsStringSync();
    final termuxRunbook = File(
      'docs/runbooks/android-termux-local-agent.md',
    ).readAsStringSync();

    expect(runtimeDecision, contains('Android/Termux'));
    expect(runtimeDecision, contains('best-effort background'));
    expect(runtimeDecision, contains('explicit user-run'));
    expect(
      runtimeDecision,
      contains('does not request Termux external-command access'),
    );
    expect(
      threatModel,
      contains('Wing and Termux remain separate app sandboxes'),
    );
    expect(termuxRunbook, contains('127.0.0.1:8642'));
    expect(termuxRunbook, contains('loopback still requires'));
    expect(termuxRunbook, contains('Agent authentication'));
    expect(termuxRunbook, contains('separate app sandboxes'));
    expect(termuxRunbook, contains('masked Agent token field'));
    expect(termuxRunbook, contains('explicitly retry'));
    expect(termuxRunbook, contains('saves no credential'));
    expect(termuxRunbook, contains('background operation is not qualified'));
    expect(_currentTermuxSetup(termuxRunbook), isNot(_retiredSetup));
    expect(termuxRunbook, isNot(contains('RUN_COMMAND')));
  });

  test('current first-connection guide matches the Android welcome', () {
    expect(_directSteps(_gettingStarted()), _directGuide);
  });

  test('direct guide guard rejects pairing offers and wrong Android order', () {
    final steps = _directSteps(_gettingStarted());
    for (final offer in [
      '**I have a QR code or pairing link**',
      '**Connect one profile manually**',
      'Scan a QR code to pair again.',
      'Run ./install-wing-link.sh and connect to 127.0.0.1:8654.',
    ]) {
      expect('$steps\nChoose $offer', isNot(_directGuide), reason: offer);
    }
    expect(
      steps
          .replaceFirst('1. **Connect via SSH**', '2. **Connect via SSH**')
          .replaceFirst(
            '2. **Connect to Remote Hermes**',
            '1. **Connect to Remote Hermes**',
          ),
      isNot(_directGuide),
    );
    expect(
      steps.replaceFirst(
        '3. **Use this phone (Termux)**',
        '1. **Use this phone (Termux)**',
      ),
      isNot(_directGuide),
    );
  });

  test('guide guards allow history but reject retired Termux setup', () {
    final guide = _gettingStarted();
    final runbook = File(
      'docs/runbooks/android-termux-local-agent.md',
    ).readAsStringSync();
    const history =
        '\nHistorical receipt: Scan a QR code to pair again on 127.0.0.1:8654.\n';
    expect(_directSteps('$guide$history'), _directGuide);
    expect(_currentTermuxSetup('$runbook$history'), isNot(_retiredSetup));
    for (final offer in [
      'pair again',
      '127.0.0.1:8654',
      './install-wing-link.sh',
    ]) {
      expect('${_currentTermuxSetup(runbook)}\n$offer', _retiredSetup);
    }
  });

  test('Nostr research is archived outside the core control plane', () {
    final research = File(
      'docs/research/buzz-nostr-lessons.md',
    ).readAsStringSync();
    expect(research, contains('Status: archived research'));
    expect(research, contains('Hermes API over HTTPS'));
    expect(research, contains('not confidential from the relay operator'));
    expect(research, contains('custom Nostr Relay Link remains deferred'));
  });
}

String _gettingStarted() => File('docs/getting-started.md').readAsStringSync();

String _directSteps(String guide) => guide
    .split('## Direct Agent connection\n')[1]
    .split('## Repair a saved direct connection\n')[0];

String _currentTermuxSetup(String guide) =>
    guide.split('## Historical evidence\n')[0];

final _retiredSetup = matches(
  RegExp(
    r'I have a QR code or pairing link|Connect one profile manually|'
    r'Scan a QR code|pair again|127\.0\.0\.1:8654|install-wing-link\.sh',
    caseSensitive: false,
  ),
);

final _directGuide = allOf([
  matches(
    r'1\. \*\*Connect via SSH\*\*[\s\S]*'
    r'2\. \*\*Connect to Remote Hermes\*\*[\s\S]*'
    r'3\. \*\*Use this phone \(Termux\)\*\*',
  ),
  contains('Android has no **Get Started** welcome action.'),
  contains('not a Hermes Project or conversation working directory'),
  contains('separate masked Agent API token'),
  matches(r'host\s+fingerprint'),
  contains('Never copy credentials into URLs or the clipboard.'),
  contains('explicit retry or cancel'),
  isNot(_retiredSetup),
]);
