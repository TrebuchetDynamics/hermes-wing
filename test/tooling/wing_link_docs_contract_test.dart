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
    final readme = File('README.md').readAsStringSync();
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
    expect(adr, contains('private-LAN/Tailscale interface'));
    expect(adr, contains('every non-loopback listener uses TLS 1.3'));
    expect(context, contains('remote management API'));
    expect(threatModel, contains('opaque handles'));
    expect(roadmap, contains('Profiles, directories, and Projects'));
    expect(profileGuide, contains('Current profile path'));
    expect(profileGuide, contains('Repository and subfolder assignment'));
    expect(wingLinkGuide, contains('folder picker'));
    expect(
      wingLinkGuide,
      contains('does not enumerate file names or metadata'),
    );
    expect(wingLinkGuide, contains('Every non-loopback listener uses TLS 1.3'));
    expect(wingLinkGuide, contains('not a chat proxy'));
    expect(wingLinkGuide, isNot(contains('arbitrary remote shell')));
    expect(compatibility, isNot(contains('/api/model/set')));
    expect(roadmap, contains('mutation hidden until an exact route'));
    expect(
      roadmap,
      contains('File listing, preview, reading, or editing through Wing Link'),
    );
    expect(readme, contains('general provider operations are planned.'));
    expect(
      readme,
      contains('existing-profile credential edits remain blocked'),
    );
    expect(
      readme,
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
