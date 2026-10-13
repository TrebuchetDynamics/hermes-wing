import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Wing Link is a bounded remote management plane', () {
    final adr = File('docs/adr/runtime-and-delivery.md').readAsStringSync();
    final context = File('CONTEXT.md').readAsStringSync();
    final threatModel = File(
      'docs/security/threat-model.md',
    ).readAsStringSync();
    final roadmap = File('ROADMAP.md').readAsStringSync();
    final routes = File('docs/product/routes.md').readAsStringSync();
    final gettingStarted = File('docs/getting-started.md').readAsStringSync();
    final compatibility = File(
      'docs/product/hermes-compatibility.md',
    ).readAsStringSync();
    final profileGuide = File(
      'docs/product/gateway-profile-management.md',
    ).readAsStringSync();
    final wingLinkGuide = File('docs/product/wing-link.md').readAsStringSync();
    final supersededBridgeDesign = File(
      'docs/superpowers/specs/2026-08-06-wing-link-multi-agent-management-design.md',
    ).readAsStringSync();

    expect(adr, contains('external authoritative runtime'));
    expect(adr, contains('authenticated remote management plane'));
    expect(adr, contains('arbitrary commands,'));
    expect(adr, contains('config keys, and paths'));
    expect(adr, contains('private-LAN, NetBird, or Tailscale interface'));
    expect(adr, contains('every non-loopback listener uses TLS 1.3'));
    expect(wingLinkGuide, contains('Default-range NetBird/Tailscale'));
    expect(wingLinkGuide, contains('custom-range IPv4 and IPv6'));
    expect(wingLinkGuide, contains('Network location never substitutes'));
    expect(context, contains('remote management API'));
    expect(threatModel, contains('opaque handles'));
    expect(roadmap, contains('Profiles, directories, and Projects'));
    expect(routes, contains('opaque handles'));
    expect(routes, contains('Project creation remains unavailable'));
    expect(routes, isNot(contains('remote file browser')));
    expect(roadmap, contains('child folders only'));
    expect(roadmap, contains('Project-aware Chat remains gated'));
    expect(profileGuide, contains('Current profile path'));
    expect(profileGuide, contains('Repository and subfolder assignment'));
    expect(wingLinkGuide, contains('folder browser'));
    expect(wingLinkGuide, contains('does not enumerate'));
    expect(wingLinkGuide, contains('file names or metadata'));
    expect(wingLinkGuide, contains('Every non-loopback listener uses TLS 1.3'));
    expect(wingLinkGuide, contains('not a chat proxy'));
    expect(wingLinkGuide, isNot(contains('arbitrary remote shell')));
    expect(compatibility, isNot(contains('/api/model/set')));
    expect(roadmap, contains('mutation hidden until an exact route'));
    expect(
      roadmap,
      contains('File listing, preview, reading, or editing through Wing Link'),
    );
    expect(gettingStarted, contains('Wing connects directly to Hermes Agent.'));
    expect(gettingStarted, contains('Wing Link is deprecated.'));
    expect(gettingStarted, isNot(contains('./install-wing-link.sh')));
    expect(
      wingLinkGuide,
      contains('Wing Link exposure and Hermes Agent exposure are separate'),
    );
    expect(wingLinkGuide, contains('configures the Agent API on `127.0.0.1`'));
    expect(
      supersededBridgeDesign,
      contains('Status: superseded; do not implement'),
    );
  });

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
    expect(runtimeDecision, contains('explicit user-run bootstrap'));
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
