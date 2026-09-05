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
    expect(
      gettingStarted,
      contains('general provider operations are planned.'),
    );
    expect(
      gettingStarted,
      contains('existing-profile credential edits remain blocked'),
    );
    expect(
      gettingStarted,
      contains(
        'hermes config set --force platforms.api_server.extra.host '
        '<trusted-vpn-ip>',
      ),
    );
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
    expect(termuxRunbook, contains('127.0.0.1:8654'));
    expect(termuxRunbook, contains('pair again'));
    expect(termuxRunbook, contains('Tier 2'));
    expect(termuxRunbook, isNot(contains('RUN_COMMAND')));
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
