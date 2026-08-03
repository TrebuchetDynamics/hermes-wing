import '../../../../core/protocol/voice_unavailable_reason.dart';

class SpeechToTextSnapshot {
  const SpeechToTextSnapshot({
    required this.words,
    required this.confidence,
    required this.finalResult,
  });

  final String words;
  final double confidence;
  final bool finalResult;
}

bool isTerminalSpeechToTextStatus(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == 'done' || normalized == 'notlistening';
}

SpeechToTextSnapshot? latestUsableSpeechToTextTranscript({
  required SpeechToTextSnapshot? current,
  required SpeechToTextSnapshot candidate,
}) {
  if (candidate.words.trim().isEmpty) return current;
  return candidate;
}

SpeechToTextSnapshot completionSpeechToTextTranscript({
  required SpeechToTextSnapshot terminalSnapshot,
  required SpeechToTextSnapshot? latestUsableSnapshot,
}) {
  if (terminalSnapshot.words.trim().isNotEmpty) return terminalSnapshot;
  return latestUsableSnapshot ?? terminalSnapshot;
}

String speechToTextDeviceUnavailableReasonFromMessage(String message) {
  final signal = SpeechToTextAvailabilityMessageSignal.fromMessage(message);
  if (signal.indicatesPermissionDenied) {
    return microphonePermissionDeniedReason;
  }
  if (signal.indicatesLanguageUnavailable) {
    return deviceSttLanguageUnavailableReason;
  }
  return deviceSttUnavailableReason;
}

class SpeechToTextAvailabilityMessageSignal {
  SpeechToTextAvailabilityMessageSignal._({
    required this.normalized,
    required this.compact,
  });

  factory SpeechToTextAvailabilityMessageSignal.fromMessage(String message) {
    final normalized = message.trim().toLowerCase();
    return SpeechToTextAvailabilityMessageSignal._(
      normalized: normalized,
      compact: normalized.replaceAll(RegExp(r'[^a-z0-9]'), ''),
    );
  }

  final String normalized;
  final String compact;

  /// Android reports a missing or unsupported offline language distinctly,
  /// and on-device-only capture cannot fall back to a network recognizer.
  bool get indicatesLanguageUnavailable {
    return normalized.contains('language_unavailable') ||
        normalized.contains('language_not_supported');
  }

  bool get indicatesPermissionDenied {
    return normalized.contains('permission') ||
        normalized.contains('denied') ||
        normalized.contains('not authorized') ||
        compact.contains('notallowed') ||
        compact.contains('unauthorized');
  }
}
