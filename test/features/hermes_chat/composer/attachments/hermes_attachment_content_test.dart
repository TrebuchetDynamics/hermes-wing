import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/composer/attachments/hermes_attachment_content.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

const _png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
const _jpeg = [0xff, 0xd8, 0xff];
const _gif = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61];

void main() {
  group('supportedImageMimeType', () {
    test('recognizes the four accepted image formats', () {
      expect(supportedImageMimeType(_bytes(_png)), 'image/png');
      expect(supportedImageMimeType(_bytes(_jpeg)), 'image/jpeg');
      expect(supportedImageMimeType(_bytes(_gif)), 'image/gif');
      expect(
        supportedImageMimeType(
          _bytes([
            0x52, 0x49, 0x46, 0x46, // RIFF
            0x00, 0x00, 0x00, 0x00, // size
            0x57, 0x45, 0x42, 0x50, // WEBP
          ]),
        ),
        'image/webp',
      );
    });

    test('rejects unsupported and empty payloads', () {
      expect(supportedImageMimeType(Uint8List(0)), isNull);
      expect(supportedImageMimeType(_bytes([0x25, 0x50, 0x44, 0x46])), isNull);
      expect(supportedImageMimeType(_bytes(List.filled(32, 0x00))), isNull);
    });

    test('does not read past the end of a truncated header', () {
      for (var length = 0; length < _png.length; length++) {
        expect(
          supportedImageMimeType(_bytes(_png.sublist(0, length))),
          isNull,
          reason: 'a $length-byte PNG prefix must not be claimed or throw',
        );
      }
      expect(supportedImageMimeType(_bytes([0xff, 0xd8])), isNull);
      expect(supportedImageMimeType(_bytes([0x47, 0x49, 0x46, 0x38])), isNull);
    });

    test('a RIFF container that is not WebP stays unsupported', () {
      expect(
        supportedImageMimeType(
          _bytes([
            0x52, 0x49, 0x46, 0x46, // RIFF
            0x00, 0x00, 0x00, 0x00,
            0x41, 0x56, 0x49, 0x20, // AVI
          ]),
        ),
        isNull,
      );
    });

    test('classifies by content, not by a lying extension', () {
      expect(supportedImageMimeType(_bytes(_png)), 'image/png');
      expect(isTextAttachment(name: 'payload.png'), isFalse);
    });
  });

  group('isTextAttachment', () {
    test('accepts any declared text mime type regardless of name', () {
      expect(isTextAttachment(name: 'blob', mimeType: 'text/plain'), isTrue);
      expect(isTextAttachment(name: 'blob', mimeType: 'TEXT/MARKDOWN'), isTrue);
    });

    test('falls back to the extension allowlist', () {
      expect(isTextAttachment(name: 'notes.md'), isTrue);
      expect(isTextAttachment(name: 'main.dart'), isTrue);
      expect(isTextAttachment(name: 'REPORT.CSV'), isTrue);
      expect(isTextAttachment(name: 'archive.zip'), isFalse);
      expect(isTextAttachment(name: 'clip.mp4'), isFalse);
    });

    test('treats an extensionless name as its own extension', () {
      expect(isTextAttachment(name: 'Dockerfile'), isTrue);
      expect(isTextAttachment(name: 'Makefile'), isTrue);
      expect(isTextAttachment(name: 'randombinary'), isFalse);
    });

    test('a trailing dot falls back to the whole name', () {
      expect(isTextAttachment(name: 'dockerfile.'), isFalse);
      expect(isTextAttachment(name: 'notes.'), isFalse);
    });

    test('a non-text mime type still allows an allowlisted extension', () {
      expect(
        isTextAttachment(name: 'data.json', mimeType: 'application/json'),
        isTrue,
      );
    });
  });

  group('size limits', () {
    test('match the documented Hermes composer limits', () {
      expect(maxImageAttachmentBytes, 10 * 1024 * 1024);
      expect(maxTextAttachmentBytes, 256 * 1024);
      expect(maxTextAttachmentBytes, lessThan(maxImageAttachmentBytes));
    });
  });
}
