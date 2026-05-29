import '../../../core/channel/navivox_channel.dart';

enum LocalCommandAction {
  none,
  enterCommandMode,
  cancel,
  stop,
  openSettings,
  showMessage,
  switchProfile,
  disambiguateProfile,
  profileSwitchingDisabled,
  unknown,
}

class LocalCommandIntent {
  const LocalCommandIntent._({
    required this.action,
    this.body,
    this.message,
    this.target,
  });

  const LocalCommandIntent.none() : this._(action: LocalCommandAction.none);

  const LocalCommandIntent.enterCommandMode()
    : this._(action: LocalCommandAction.enterCommandMode);

  const LocalCommandIntent.cancel()
    : this._(
        action: LocalCommandAction.cancel,
        message: 'Cancel requested. Started side effects may still exist.',
      );

  const LocalCommandIntent.stop()
    : this._(
        action: LocalCommandAction.stop,
        message: 'Stop requested. Started side effects may still exist.',
      );

  const LocalCommandIntent.openSettings()
    : this._(action: LocalCommandAction.openSettings);

  LocalCommandIntent.help(String commandWord)
    : this._(
        action: LocalCommandAction.showMessage,
        message:
            'Voice commands: $commandWord <profile>, cancel, stop, settings, help.',
      );

  const LocalCommandIntent.profileSwitchingDisabled()
    : this._(
        action: LocalCommandAction.profileSwitchingDisabled,
        message: 'Voice profile switching is disabled.',
      );

  LocalCommandIntent.switchProfile(NavivoxProfileContact target)
    : this._(
        action: LocalCommandAction.switchProfile,
        target: target,
        message: 'Switched to ${target.displayName}.',
      );

  LocalCommandIntent.disambiguateProfile(String body)
    : this._(
        action: LocalCommandAction.disambiguateProfile,
        body: body,
        message: 'Choose one profile named ${body.trim()}.',
      );

  LocalCommandIntent.unknown(String body)
    : this._(
        action: LocalCommandAction.unknown,
        body: body,
        message: 'Voice command not recognized: ${body.trim()}.',
      );

  final LocalCommandAction action;
  final String? body;
  final String? message;
  final NavivoxProfileContact? target;

  bool get consumesInput => action != LocalCommandAction.none;
}

class LocalCommandResolver {
  const LocalCommandResolver();

  LocalCommandIntent resolve({
    required String raw,
    required String commandWord,
    required bool commandMode,
    required bool fromVoice,
    required bool profileSwitchingEnabled,
    required List<NavivoxProfileContact> contacts,
  }) {
    final body = commandBody(
      raw,
      commandWord: commandWord,
      commandMode: commandMode,
      fromVoice: fromVoice,
    );
    if (body == null) return const LocalCommandIntent.none();
    if (body.isEmpty) return const LocalCommandIntent.enterCommandMode();

    final normalized = normalize(body);
    return switch (normalized) {
      'cancel' => const LocalCommandIntent.cancel(),
      'stop' => const LocalCommandIntent.stop(),
      'settings' => const LocalCommandIntent.openSettings(),
      'help' => LocalCommandIntent.help(commandWord.trim().toLowerCase()),
      _ => _resolveProfileCommand(
        body: body,
        normalized: normalized,
        profileSwitchingEnabled: profileSwitchingEnabled,
        contacts: contacts,
      ),
    };
  }

  String? commandBody(
    String raw, {
    required String commandWord,
    required bool commandMode,
    required bool fromVoice,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final word = commandWord.trim().toLowerCase();
    if (word.isEmpty) return null;
    final lower = text.toLowerCase();
    if (commandMode && fromVoice && !_startsWithCommandWord(lower, word)) {
      return text;
    }
    if (!_startsWithCommandWord(lower, word)) return null;
    return text.length == word.length ? '' : text.substring(word.length).trim();
  }

  LocalCommandIntent _resolveProfileCommand({
    required String body,
    required String normalized,
    required bool profileSwitchingEnabled,
    required List<NavivoxProfileContact> contacts,
  }) {
    if (!profileSwitchingEnabled) {
      return const LocalCommandIntent.profileSwitchingDisabled();
    }
    final matches = contacts
        .where((contact) => _contactCommandNames(contact).contains(normalized))
        .toList(growable: false);
    if (matches.length == 1) {
      return LocalCommandIntent.switchProfile(matches.single);
    }
    if (matches.length > 1) {
      return LocalCommandIntent.disambiguateProfile(body);
    }
    return LocalCommandIntent.unknown(body);
  }

  Set<String> _contactCommandNames(NavivoxProfileContact contact) {
    return {normalize(contact.profileId), normalize(contact.displayName)};
  }

  bool _startsWithCommandWord(String lower, String commandWord) {
    if (lower == commandWord) {
      return true;
    }
    return lower.startsWith('$commandWord ');
  }

  String normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
