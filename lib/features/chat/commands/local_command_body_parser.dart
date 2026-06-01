enum LocalCommandBodySource { prefixed, commandModeVoice }

enum LocalCommandPrefixRejectionReason {
  emptyCommandWord,
  wordMismatch,
  missingBoundary,
}

class LocalCommandPrefixScan {
  const LocalCommandPrefixScan._({this.body, this.rejectionReason});

  const LocalCommandPrefixScan.matched(String body) : this._(body: body);

  const LocalCommandPrefixScan.rejected(
    LocalCommandPrefixRejectionReason reason,
  ) : this._(rejectionReason: reason);

  final String? body;
  final LocalCommandPrefixRejectionReason? rejectionReason;

  bool get matched => body != null;
}

class LocalCommandBodyParse {
  const LocalCommandBodyParse({required this.body, required this.source});

  final String body;
  final LocalCommandBodySource source;
}

class LocalCommandBodyParser {
  const LocalCommandBodyParser();

  LocalCommandBodyParse? parse(
    String raw, {
    required String commandWord,
    required bool commandMode,
    required bool fromVoice,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final prefix = scanCommandPrefix(text, commandWord: commandWord);
    if (prefix.matched) {
      return LocalCommandBodyParse(
        body: prefix.body!,
        source: LocalCommandBodySource.prefixed,
      );
    }
    if (commandMode && fromVoice) {
      return LocalCommandBodyParse(
        body: text,
        source: LocalCommandBodySource.commandModeVoice,
      );
    }
    return null;
  }

  String? commandBody(
    String raw, {
    required String commandWord,
    required bool commandMode,
    required bool fromVoice,
  }) {
    return parse(
      raw,
      commandWord: commandWord,
      commandMode: commandMode,
      fromVoice: fromVoice,
    )?.body;
  }

  LocalCommandPrefixScan scanCommandPrefix(
    String text, {
    required String commandWord,
  }) {
    final word = commandWord.trim().toLowerCase();
    if (word.isEmpty) {
      return const LocalCommandPrefixScan.rejected(
        LocalCommandPrefixRejectionReason.emptyCommandWord,
      );
    }

    final lower = text.trim().toLowerCase();
    if (lower == word) {
      return const LocalCommandPrefixScan.matched('');
    }
    if (!lower.startsWith(word)) {
      return const LocalCommandPrefixScan.rejected(
        LocalCommandPrefixRejectionReason.wordMismatch,
      );
    }

    final separator = text.trim().substring(word.length);
    final bodyStart = _commandBodyStart(separator);
    if (bodyStart == null) {
      return const LocalCommandPrefixScan.rejected(
        LocalCommandPrefixRejectionReason.missingBoundary,
      );
    }
    return LocalCommandPrefixScan.matched(
      separator.substring(bodyStart).trim(),
    );
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
