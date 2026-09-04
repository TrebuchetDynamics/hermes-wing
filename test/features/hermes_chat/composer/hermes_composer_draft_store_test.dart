import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/composer/hermes_composer_draft_store.dart';
import 'package:wing/features/hermes_chat/composer/attachments/staged_attachment.dart';

void main() {
  const a = (gatewayId: 'g', profileId: 'p', sessionId: 'a');
  const b = (gatewayId: 'g', profileId: 'p', sessionId: 'b');
  test('late send completion cannot clear or restore over newer input', () {
    final store = HermesComposerDraftStore();
    store.activate(a);
    store.update(
      a,
      text: 'first',
      attachment: const StagedTextAttachment(
        name: 'a.txt',
        content: 'synthetic',
      ),
    );
    final sent = store.captureForSubmission(a);
    expect(store.read(a).text, isEmpty);
    store.update(
      a,
      text: 'newer',
      attachment: const StagedTextAttachment(
        name: 'b.txt',
        content: 'synthetic',
      ),
    );
    expect(store.restoreSubmission(sent), isFalse);
    expect(store.clearIfGeneration(a, sent.draft.generation), isFalse);
    expect(store.read(a).text, 'newer');
    expect(store.read(a).attachment?.name, 'b.txt');
  });
  test('failed send restores only untouched empty generation', () {
    final store = HermesComposerDraftStore()..activate(a);
    store.update(a, text: 'draft', attachment: null);
    final sent = store.captureForSubmission(a);
    expect(store.restoreSubmission(sent), isTrue);
    expect(store.read(a).text, 'draft');
    expect(store.restoreSubmission(sent), isFalse);
  });
  test('session switching retains text and attachment together', () {
    final store = HermesComposerDraftStore()..activate(a);
    const attachment = StagedTextAttachment(
      name: 'a.txt',
      content: 'synthetic',
    );
    store.update(a, text: 'draft', attachment: attachment);
    store.activate(b);
    expect(store.read(b).attachment, isNull);
    store.activate(a);
    expect(store.read(a).text, 'draft');
    expect(store.read(a).attachment, same(attachment));
  });
  test('attachment budget evicts inactive bytes with a visible marker', () {
    final store = HermesComposerDraftStore(maxRetainedAttachmentBytes: 2)
      ..activate(a);
    store.update(
      a,
      text: 'keep text',
      attachment: const StagedTextAttachment(name: 'a.txt', content: 'large'),
    );
    store.activate(b);
    expect(store.read(a).attachment, isNull);
    expect(store.read(a).attachmentEvicted, isTrue);
    expect(store.read(a).text, 'keep text');
  });
  test(
    'entry eviction does not let an old submission overwrite a new draft',
    () {
      final store = HermesComposerDraftStore(maxEntries: 1)..activate(a);
      store.update(a, text: 'old', attachment: null);
      final sent = store.captureForSubmission(a);
      store.activate(b);
      store.update(b, text: 'other', attachment: null);
      store.activate(a);
      expect(store.restoreSubmission(sent), isFalse);
    },
  );
  test('text bound preserves complete grapheme clusters', () {
    final store = HermesComposerDraftStore(maxCharacters: 2)..activate(a);
    store.update(a, text: '👩‍💻aZ', attachment: null);
    expect(store.read(a).text, '👩‍💻a');
  });
}
