import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Wing Link is a local host supervisor only', () {
    final adr = File('docs/adr/runtime-and-delivery.md').readAsStringSync();
    expect(adr, contains('Hermes Agent remains an external runtime'));
    expect(adr, contains('authenticated host supervisor'));
    expect(adr, contains('must not expose arbitrary shell or CLI execution'));
    expect(adr, contains('explicitly selected trusted private/VPN interface'));
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
    expect(profileGuide, contains('only approved\nprovider path'));
    expect(profileGuide, contains('Compatibility migration note'));
    expect(profileGuide, contains('fixed Wing Link profile adapter'));
    expect(adr, contains('must not expose arbitrary shell or CLI execution'));
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
