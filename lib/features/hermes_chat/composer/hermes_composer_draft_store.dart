import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'attachments/staged_attachment.dart';

typedef HermesComposerDraftKey = ({
  String gatewayId,
  String? profileId,
  String sessionId,
});

@immutable
class HermesComposerDraft {
  const HermesComposerDraft({
    this.text = '',
    this.attachment,
    this.generation = 0,
    this.attachmentEvicted = false,
  });

  final String text;
  final StagedAttachment? attachment;
  final int generation;
  final bool attachmentEvicted;
}

@immutable
class HermesComposerSubmission {
  const HermesComposerSubmission(this.key, this.draft, this.emptyGeneration);
  final HermesComposerDraftKey key;
  final HermesComposerDraft draft;
  final int emptyGeneration;
}

/// Process-local presentation state. Generations never repeat after eviction.
class HermesComposerDraftStore {
  HermesComposerDraftStore({
    this.maxEntries = 64,
    this.maxCharacters = 64 * 1024,
    this.maxRetainedAttachmentBytes = 16 * 1024 * 1024,
  }) : assert(maxEntries > 0),
       assert(maxCharacters > 0),
       assert(maxRetainedAttachmentBytes >= 0);

  final int maxEntries;
  final int maxCharacters;
  final int maxRetainedAttachmentBytes;
  final _drafts = <HermesComposerDraftKey, HermesComposerDraft>{};
  HermesComposerDraftKey? _active;
  int _generation = 0;

  HermesComposerDraft read(HermesComposerDraftKey key) =>
      _drafts[key] ?? const HermesComposerDraft();

  void activate(HermesComposerDraftKey? key) {
    _active = key;
    if (key != null && _drafts.containsKey(key)) {
      final draft = _drafts.remove(key)!;
      _drafts[key] = draft;
    }
    _trim();
  }

  void update(
    HermesComposerDraftKey key, {
    required String text,
    required StagedAttachment? attachment,
  }) {
    final old = read(key);
    final bounded = text.characters.take(maxCharacters).join();
    if (old.text == bounded && identical(old.attachment, attachment)) return;
    _put(
      key,
      HermesComposerDraft(
        text: bounded,
        attachment: attachment,
        generation: ++_generation,
      ),
    );
  }

  bool clearIfGeneration(HermesComposerDraftKey key, int generation) {
    if (!_drafts.containsKey(key) || read(key).generation != generation) {
      return false;
    }
    _put(key, HermesComposerDraft(generation: ++_generation));
    return true;
  }

  HermesComposerSubmission captureForSubmission(HermesComposerDraftKey key) {
    final draft = read(key);
    final emptyGeneration = ++_generation;
    _put(key, HermesComposerDraft(generation: emptyGeneration));
    return HermesComposerSubmission(key, draft, emptyGeneration);
  }

  bool restoreSubmission(HermesComposerSubmission submission) {
    if (!_drafts.containsKey(submission.key) ||
        read(submission.key).generation != submission.emptyGeneration) {
      return false;
    }
    _put(
      submission.key,
      HermesComposerDraft(
        text: submission.draft.text,
        attachment: submission.draft.attachment,
        generation: ++_generation,
      ),
    );
    return true;
  }

  void clear() {
    _drafts.clear();
    _active = null;
    _generation++;
  }

  void forgetWhere(bool Function(HermesComposerDraftKey key) matches) {
    _drafts.removeWhere((key, _) => matches(key));
    _generation++;
  }

  void _put(HermesComposerDraftKey key, HermesComposerDraft draft) {
    _drafts.remove(key);
    _drafts[key] = draft;
    _trim();
  }

  void _trim() {
    while (_drafts.length > maxEntries) {
      final key = _drafts.keys.firstWhere((key) => key != _active);
      _drafts.remove(key);
    }
    var retained = 0;
    for (final key in _drafts.keys.toList().reversed) {
      if (key == _active) continue;
      final draft = _drafts[key]!;
      final bytes = switch (draft.attachment) {
        StagedImageAttachment(:final bytes) => bytes.length,
        StagedTextAttachment(:final content) => utf8.encode(content).length,
        null => 0,
      };
      if (retained + bytes <= maxRetainedAttachmentBytes) {
        retained += bytes;
      } else {
        _drafts[key] = HermesComposerDraft(
          text: draft.text,
          generation: ++_generation,
          attachmentEvicted: true,
        );
      }
    }
  }
}
