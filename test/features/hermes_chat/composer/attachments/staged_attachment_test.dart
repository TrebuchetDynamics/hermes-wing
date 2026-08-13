import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/composer/attachments/staged_attachment.dart';

void main() {
  test('an image sends as a data URL carrying its sniffed type', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final attachment = StagedImageAttachment(
      name: 'photo.png',
      bytes: bytes,
      mimeType: 'image/png',
    );

    expect(
      attachment.imageDataUrl,
      'data:image/png;base64,${base64Encode(bytes)}',
    );
    expect(attachment.name, 'photo.png');
  });

  test('an image is never mistaken for text', () {
    final attachment = StagedImageAttachment(
      name: 'photo.png',
      bytes: Uint8List(0),
      mimeType: 'image/png',
    );

    expect(attachment.textContent, isNull);
  });

  test('a text file sends its decoded content and no data URL', () {
    const attachment = StagedTextAttachment(
      name: 'notes.md',
      content: 'alpha\nbeta',
    );

    expect(attachment.textContent, 'alpha\nbeta');
    expect(attachment.imageDataUrl, isNull);
    expect(attachment.name, 'notes.md');
  });

  test('an empty image still produces a well-formed data URL', () {
    final attachment = StagedImageAttachment(
      name: 'empty.gif',
      bytes: Uint8List(0),
      mimeType: 'image/gif',
    );

    expect(attachment.imageDataUrl, 'data:image/gif;base64,');
  });

  test('the union admits exactly one staged kind at a time', () {
    final StagedAttachment image = StagedImageAttachment(
      name: 'photo.png',
      bytes: Uint8List.fromList([0]),
      mimeType: 'image/png',
    );
    const StagedAttachment text = StagedTextAttachment(
      name: 'notes.md',
      content: 'alpha',
    );

    for (final attachment in [image, text]) {
      final isImage = attachment.imageDataUrl != null;
      final isText = attachment.textContent != null;
      expect(
        isImage != isText,
        isTrue,
        reason: '${attachment.name} must be exactly one kind',
      );
    }
  });

  test('the mime type is carried verbatim, not re-derived from the name', () {
    final attachment = StagedImageAttachment(
      name: 'screenshot.jpg',
      bytes: Uint8List.fromList([0xff]),
      mimeType: 'image/webp',
    );

    expect(
      attachment.imageDataUrl,
      startsWith('data:image/webp;'),
      reason: 'content sniffing wins over a misleading extension',
    );
  });
}
