import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hermes Desktop parity roadmap keeps physical mic gate strict', () {
    final text = File(
      'docs/product/hermes-desktop-parity-roadmap.md',
    ).readAsStringSync();

    for (final snippet in [
      'required physical-mic evidence separate',
      'required real spoken\n  physical-audio/provider/TTS/re-arm receipt',
      'Readiness audit blocks on the missing human-spoken Android microphone receipt',
      'build/receipts/android-live-mic-smoke.json',
      'proves real physical mic,\n  provider reply, TTS, and re-arm',
      'automated\n  receipts physical mic evidence',
      'strict readiness keeps the real spoken-audio blocker open',
    ]) {
      expect(text, contains(snippet), reason: snippet);
    }

    for (final staleSnippet in [
      'without\nrequiring a human speaker in the strict readiness loop',
      'optional hardware/audio evidence',
      'Readiness audit no longer blocks on a human-spoken Android microphone receipt',
      'strict readiness blocks without asking for a human speaker',
    ]) {
      expect(text, isNot(contains(staleSnippet)), reason: staleSnippet);
    }
  });
}
