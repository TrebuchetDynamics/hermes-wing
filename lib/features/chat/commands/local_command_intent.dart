import '../../../core/channel/navivox_channel.dart';
import 'local_command_profile_matcher.dart';

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

class _CommandPrefixMatch {
  const _CommandPrefixMatch({required this.body});

  final String body;
}

class _CommandBodyParser {
  const _CommandBodyParser();

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

    final prefix = _matchCommandPrefix(text, word);
    if (commandMode && fromVoice && prefix == null) {
      return text;
    }
    return prefix?.body;
  }

  _CommandPrefixMatch? _matchCommandPrefix(String text, String commandWord) {
    final lower = text.toLowerCase();
    if (lower == commandWord) {
      return const _CommandPrefixMatch(body: '');
    }
    if (!lower.startsWith(commandWord)) return null;
    if (text.length == commandWord.length) {
      return const _CommandPrefixMatch(body: '');
    }

    final separator = text.substring(commandWord.length);
    final bodyStart = _commandBodyStart(separator);
    if (bodyStart == null) return null;
    return _CommandPrefixMatch(body: separator.substring(bodyStart).trim());
  }

  int? _commandBodyStart(String separatorAndBody) {
    for (var index = 0; index < separatorAndBody.length; index += 1) {
      final codeUnit = separatorAndBody.codeUnitAt(index);
      if (_isCommandWordSeparator(codeUnit)) continue;
      return index == 0 ? null : index;
    }
    return separatorAndBody.isEmpty ? null : separatorAndBody.length;
  }

  bool _isCommandWordSeparator(int codeUnit) {
    return codeUnit == 0x20 || // space
        codeUnit == 0x09 || // tab
        codeUnit == 0x0a || // line feed
        codeUnit == 0x0d || // carriage return
        codeUnit == 0x2c || // comma
        codeUnit == 0x2e || // period
        codeUnit == 0x3a || // colon
        codeUnit == 0x3b || // semicolon
        codeUnit == 0x21 || // exclamation mark
        codeUnit == 0x3f; // question mark
  }
}

class LocalCommandResolver {
  const LocalCommandResolver();

  final _CommandBodyParser _commandBodyParser = const _CommandBodyParser();

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
    return _commandBodyParser.commandBody(
      raw,
      commandWord: commandWord,
      commandMode: commandMode,
      fromVoice: fromVoice,
    );
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
    if (normalized.isEmpty) return LocalCommandIntent.unknown(body);

    final matches = _matchingProfileCommandContacts(
      normalized: normalized,
      contacts: contacts,
    );
    if (matches.length == 1) {
      return LocalCommandIntent.switchProfile(matches.single);
    }
    if (matches.length > 1) {
      return LocalCommandIntent.disambiguateProfile(body);
    }
    return LocalCommandIntent.unknown(body);
  }

  List<NavivoxProfileContact> _matchingProfileCommandContacts({
    required String normalized,
    required List<NavivoxProfileContact> contacts,
  }) {
    return matchingLocalCommandContacts(
      normalized: normalized,
      contacts: contacts,
      normalize: normalize,
    );
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
