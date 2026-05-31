import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/chat/commands/local_command_intent.dart';

import '../shared/profile_contact_chat_test_fixtures.dart';

void main() {
  const contacts = [chatMineruBuilderContact, chatSupportTriageContact];

  const resolver = LocalCommandResolver();

  test('ignores ordinary chat text without consuming it', () {
    final intent = resolver.resolve(
      raw: 'hello mineru',
      commandWord: 'navi',
      commandMode: false,
      fromVoice: false,
      profileSwitchingEnabled: true,
      contacts: contacts,
    );

    expect(intent.action, LocalCommandAction.none);
    expect(intent.consumesInput, isFalse);
  });

  test('enters command mode when only the command word is spoken', () {
    final intent = resolver.resolve(
      raw: 'navi',
      commandWord: 'navi',
      commandMode: false,
      fromVoice: true,
      profileSwitchingEnabled: true,
      contacts: contacts,
    );

    expect(intent.action, LocalCommandAction.enterCommandMode);
    expect(intent.consumesInput, isTrue);
  });

  test('uses command mode to resolve a bare voice profile command', () {
    final intent = resolver.resolve(
      raw: 'support',
      commandWord: 'navi',
      commandMode: true,
      fromVoice: true,
      profileSwitchingEnabled: true,
      contacts: contacts,
    );

    expect(intent.action, LocalCommandAction.switchProfile);
    expect(intent.target, contacts[1]);
    expect(intent.message, 'Switched to Support Triage.');
  });

  test('classifies built-in commands and custom command-word help copy', () {
    final cancel = resolver.resolve(
      raw: 'hey cancel',
      commandWord: 'hey',
      commandMode: false,
      fromVoice: false,
      profileSwitchingEnabled: true,
      contacts: contacts,
    );
    final stop = resolver.resolve(
      raw: 'hey stop',
      commandWord: 'hey',
      commandMode: false,
      fromVoice: false,
      profileSwitchingEnabled: true,
      contacts: contacts,
    );
    final settings = resolver.resolve(
      raw: 'hey settings',
      commandWord: 'hey',
      commandMode: false,
      fromVoice: false,
      profileSwitchingEnabled: true,
      contacts: contacts,
    );
    final help = resolver.resolve(
      raw: 'hey help',
      commandWord: 'hey',
      commandMode: false,
      fromVoice: false,
      profileSwitchingEnabled: true,
      contacts: contacts,
    );

    expect(cancel.action, LocalCommandAction.cancel);
    expect(
      cancel.message,
      'Cancel requested. Started side effects may still exist.',
    );
    expect(stop.action, LocalCommandAction.stop);
    expect(
      stop.message,
      'Stop requested. Started side effects may still exist.',
    );
    expect(settings.action, LocalCommandAction.openSettings);
    expect(help.action, LocalCommandAction.showMessage);
    expect(
      help.message,
      'Voice commands: hey <profile>, cancel, stop, settings, help.',
    );
  });

  test(
    'returns disabled, disambiguation, and unknown profile-command intents',
    () {
      final disabled = resolver.resolve(
        raw: 'navi support',
        commandWord: 'navi',
        commandMode: false,
        fromVoice: false,
        profileSwitchingEnabled: false,
        contacts: contacts,
      );
      final duplicate = resolver.resolve(
        raw: 'navi mineru',
        commandWord: 'navi',
        commandMode: false,
        fromVoice: false,
        profileSwitchingEnabled: true,
        contacts: [
          contacts[0],
          const NavivoxProfileContact(
            serverId: 'office',
            profileId: 'mineru',
            displayName: 'Mineru',
            serverLabel: 'office',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Ready',
          ),
        ],
      );
      final unknown = resolver.resolve(
        raw: 'navi unknown profile',
        commandWord: 'navi',
        commandMode: false,
        fromVoice: false,
        profileSwitchingEnabled: true,
        contacts: contacts,
      );

      expect(disabled.action, LocalCommandAction.profileSwitchingDisabled);
      expect(disabled.message, 'Voice profile switching is disabled.');
      expect(duplicate.action, LocalCommandAction.disambiguateProfile);
      expect(duplicate.message, 'Choose one profile named mineru.');
      expect(unknown.action, LocalCommandAction.unknown);
      expect(unknown.message, 'Voice command not recognized: unknown profile.');
    },
  );
}
