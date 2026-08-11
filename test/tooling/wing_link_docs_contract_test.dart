import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Wing Link is a local host supervisor only', () {
    final adr = File(
      'docs/adr/0044-wing-link-local-runtime-supervisor.md',
    ).readAsStringSync();
    expect(adr, contains('127.0.0.1:8654'));
    expect(adr, contains('Hermes Agent remains authoritative'));
    expect(adr, contains('Termux RUN_COMMAND'));
    expect(adr, contains('OmniRoute is optional'));
    expect(adr, contains('Recommended Donna starter profile'));
    expect(adr, contains('lacks the `distribution.yaml`'));
    expect(adr, isNot(contains('Wing Link proxies Hermes chat')));
    final context = File('CONTEXT.md').readAsStringSync();
    final threatModel = File(
      'docs/security/threat-model.md',
    ).readAsStringSync();
    final roadmap = File('ROADMAP.md').readAsStringSync();
    final profileGuide = File(
      'docs/product/gateway-profile-management.md',
    ).readAsStringSync();
    final supersededBridgeDesign = File(
      'docs/superpowers/specs/2026-08-06-wing-link-multi-agent-management-design.md',
    ).readAsStringSync();

    expect(context, contains('host supervisor'));
    expect(context, isNot(contains('bridge API-first local profile topology')));
    expect(threatModel, contains('Wing Link control token'));
    expect(threatModel, isNot(contains('profile topology bridge')));
    expect(roadmap, contains('no Hermes domain bridge'));
    expect(profileGuide, contains('only approved profile and provider path'));
    expect(profileGuide, contains('Prototype migration note'));
    expect(adr, contains('does not manage Hermes domain state'));
    expect(adr, isNot(contains('initial CLI adapters cover profile topology')));
    expect(supersededBridgeDesign, contains('Status: superseded'));
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
