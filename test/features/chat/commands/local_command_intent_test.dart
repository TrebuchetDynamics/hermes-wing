import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/chat/commands/local_command_body_parser.dart';
import 'package:navivox/features/chat/commands/local_command_builtins.dart';
import 'package:navivox/features/chat/commands/local_command_intent.dart';
import 'package:navivox/features/chat/commands/local_command_profile_matcher.dart';

import '../shared/profiles/profile_contact_chat_test_fixtures.dart';

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

  test(
    'accepts punctuation after the command word from speech transcripts',
    () {
      final intent = resolver.resolve(
        raw: 'navi, cancel',
        commandWord: 'navi',
        commandMode: false,
        fromVoice: true,
        profileSwitchingEnabled: true,
        contacts: contacts,
      );

      expect(intent.action, LocalCommandAction.cancel);
      expect(intent.consumesInput, isTrue);
    },
  );

  test('classifies command body parse source before resolving intents', () {
    const parser = LocalCommandBodyParser();

    final prefixed = parser.parse(
      'navi, support',
      commandWord: 'navi',
      commandMode: false,
      fromVoice: true,
    );
    final commandModeVoice = parser.parse(
      'support',
      commandWord: 'navi',
      commandMode: true,
      fromVoice: true,
    );
    final typedCommandMode = parser.parse(
      'support',
      commandWord: 'navi',
      commandMode: true,
      fromVoice: false,
    );

    expect(prefixed?.body, 'support');
    expect(prefixed?.source, LocalCommandBodySource.prefixed);
    expect(commandModeVoice?.body, 'support');
    expect(commandModeVoice?.source, LocalCommandBodySource.commandModeVoice);
    expect(typedCommandMode, isNull);
  });

  test('replays command prefix boundary decisions explicitly', () {
    const parser = LocalCommandBodyParser();

    final emptyCommandWord = parser.scanCommandPrefix(
      'navi cancel',
      commandWord: ' ',
    );
    final wordMismatch = parser.scanCommandPrefix(
      'hello navi',
      commandWord: 'navi',
    );
    final missingBoundary = parser.scanCommandPrefix(
      'navicancel',
      commandWord: 'navi',
    );
    final punctuationBoundary = parser.scanCommandPrefix(
      'navi?! cancel',
      commandWord: 'navi',
    );

    expect(emptyCommandWord.matched, isFalse);
    expect(
      emptyCommandWord.rejectionReason,
      LocalCommandPrefixRejectionReason.emptyCommandWord,
    );
    expect(
      wordMismatch.rejectionReason,
      LocalCommandPrefixRejectionReason.wordMismatch,
    );
    expect(
      missingBoundary.rejectionReason,
      LocalCommandPrefixRejectionReason.missingBoundary,
    );
    expect(punctuationBoundary.matched, isTrue);
    expect(punctuationBoundary.body, 'cancel');
  });

  test('requires an explicit command-word boundary outside voice mode', () {
    final prefixedWord = resolver.resolve(
      raw: 'navicancel',
      commandWord: 'navi',
      commandMode: false,
      fromVoice: false,
      profileSwitchingEnabled: true,
      contacts: contacts,
    );
    final typedCommandMode = resolver.resolve(
      raw: 'support',
      commandWord: 'navi',
      commandMode: true,
      fromVoice: false,
      profileSwitchingEnabled: true,
      contacts: contacts,
    );

    expect(prefixedWord.action, LocalCommandAction.none);
    expect(typedCommandMode.action, LocalCommandAction.none);
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

  test('exposes normalized reserved built-in command words', () {
    expect(localCommandBuiltinWords.keys, [
      'cancel',
      'stop',
      'settings',
      'help',
    ]);
    expect(
      localCommandBuiltinFromNormalizedBody('settings'),
      LocalCommandBuiltin.settings,
    );
    expect(localCommandBuiltinFromNormalizedBody('settings please'), isNull);
    expect(
      localCommandHelpMessage('hey'),
      'Voice commands: hey <profile>, cancel, stop, settings, help.',
    );
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

  test('profile command aliases expose server-qualified contacts', () {
    final names = localCommandContactNames(
      const NavivoxProfileContact(
        serverId: 'office-1',
        profileId: 'mineru',
        displayName: 'Mineru',
        serverLabel: 'Office Gateway',
        health: NavivoxProfileHealth.online,
        latestPreview: 'Ready',
      ),
      normalize: resolver.normalize,
    );

    expect(
      names,
      containsAll(['mineru', 'office 1 mineru', 'office gateway mineru']),
    );
  });

  test('reserved built-in words take precedence over profile names', () {
    final intent = resolver.resolve(
      raw: 'navi settings',
      commandWord: 'navi',
      commandMode: false,
      fromVoice: false,
      profileSwitchingEnabled: true,
      contacts: const [
        NavivoxProfileContact(
          serverId: 'office',
          profileId: 'settings',
          displayName: 'settings',
          serverLabel: 'office',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
        ),
      ],
    );

    expect(intent.action, LocalCommandAction.openSettings);
    expect(intent.target, isNull);
  });

  test('server-qualified profile commands select one duplicate contact', () {
    final intent = resolver.resolve(
      raw: 'navi office mineru',
      commandWord: 'navi',
      commandMode: false,
      fromVoice: false,
      profileSwitchingEnabled: true,
      contacts: const [
        NavivoxProfileContact(
          serverId: 'home',
          profileId: 'mineru',
          displayName: 'Mineru',
          serverLabel: 'home',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
        ),
        NavivoxProfileContact(
          serverId: 'office',
          profileId: 'mineru',
          displayName: 'Mineru',
          serverLabel: 'office',
          health: NavivoxProfileHealth.online,
          latestPreview: 'Ready',
        ),
      ],
    );

    expect(intent.action, LocalCommandAction.switchProfile);
    expect(intent.target?.serverId, 'office');
    expect(intent.target?.profileId, 'mineru');
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

  test(
    'does not match punctuation-only command bodies to symbol-only names',
    () {
      final intent = resolver.resolve(
        raw: 'navi @@@',
        commandWord: 'navi',
        commandMode: false,
        fromVoice: true,
        profileSwitchingEnabled: true,
        contacts: const [
          NavivoxProfileContact(
            serverId: 'office',
            profileId: 'bot',
            displayName: '🤖',
            serverLabel: 'office',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Ready',
          ),
        ],
      );

      expect(intent.action, LocalCommandAction.unknown);
      expect(intent.message, 'Voice command not recognized: @@@.');
    },
  );
}
