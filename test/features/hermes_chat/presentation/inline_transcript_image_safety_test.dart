import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/presentation/inline_transcript_image_safety.dart';

void main() {
  test('accepts bounded PNG, JPEG, GIF, and WebP images', () {
    final images = <String, Uint8List>{
      'image/png': base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      'image/jpeg': _jpeg(width: 1, height: 1),
      'image/gif': _gif(width: 1, height: 1, frames: 1),
      'image/webp': _webpStatic(width: 1, height: 1),
    };

    for (final entry in images.entries) {
      expect(
        isSafeInlineTranscriptImage(entry.value, entry.key),
        isTrue,
        reason: entry.key,
      );
    }
  });

  test('requires the declared MIME to match the detected format', () {
    expect(
      isSafeInlineTranscriptImage(
        _gif(width: 1, height: 1, frames: 1),
        'image/png',
      ),
      isFalse,
    );
  });

  test('rejects excessive dimensions in every supported format', () {
    final images = <String, Uint8List>{
      'image/png': _png(width: 8193, height: 1),
      'image/jpeg': _jpeg(width: 8193, height: 1),
      'image/gif': _gif(width: 8193, height: 1, frames: 1),
      'image/webp': _webpStatic(width: 8193, height: 1),
    };

    for (final entry in images.entries) {
      expect(
        isSafeInlineTranscriptImage(entry.value, entry.key),
        isFalse,
        reason: entry.key,
      );
    }
  });

  test('rejects APNG frame counts that disagree with frame controls', () {
    expect(
      isSafeInlineTranscriptImage(
        _png(width: 1, height: 1, declaredFrames: 1, frameControls: 61),
        'image/png',
      ),
      isFalse,
    );
  });

  test('animated WebP requires an ANIM chunk', () {
    expect(
      isSafeInlineTranscriptImage(
        _webpAnimated(width: 1, height: 1, frames: 1, includeAnim: false),
        'image/webp',
      ),
      isFalse,
    );
  });

  test('rejects excessive GIF and WebP animation frames', () {
    expect(
      isSafeInlineTranscriptImage(
        _gif(width: 1, height: 1, frames: 61),
        'image/gif',
      ),
      isFalse,
    );
    expect(
      isSafeInlineTranscriptImage(
        _webpAnimated(width: 1, height: 1, frames: 61),
        'image/webp',
      ),
      isFalse,
    );
  });

  test('rejects excessive cumulative animation pixels', () {
    expect(
      isSafeInlineTranscriptImage(
        _gif(
          width: 4096,
          height: 4096,
          frames: 5,
          frameWidth: 4096,
          frameHeight: 4096,
        ),
        'image/gif',
      ),
      isFalse,
    );
  });

  test('rejects GIF frames larger than their logical screen', () {
    expect(
      isSafeInlineTranscriptImage(
        _gif(
          width: 1,
          height: 1,
          frames: 1,
          frameWidth: 65535,
          frameHeight: 65535,
        ),
        'image/gif',
      ),
      isFalse,
    );
  });

  test('rejects JPEG data truncated after its frame header', () {
    final bytes = _jpeg(width: 1, height: 1);

    expect(
      isSafeInlineTranscriptImage(
        Uint8List.sublistView(bytes, 0, bytes.length - 14),
        'image/jpeg',
      ),
      isFalse,
    );
  });

  test('rejects repeated WebP canvas headers and empty animation frames', () {
    final canvas = _riffChunk('VP8X', [
      0x02,
      0,
      0,
      0,
      ..._little24(0),
      ..._little24(0),
    ]);
    expect(
      isSafeInlineTranscriptImage(_webp([canvas, canvas]), 'image/webp'),
      isFalse,
    );
    expect(
      isSafeInlineTranscriptImage(
        _webpAnimated(width: 1, height: 1, frames: 1, emptyFrames: true),
        'image/webp',
      ),
      isFalse,
    );
  });
}

Uint8List _png({
  required int width,
  required int height,
  int? declaredFrames,
  int frameControls = 0,
}) {
  final bytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  _pngChunk(bytes, 'IHDR', [
    ..._big32(width),
    ..._big32(height),
    8,
    6,
    0,
    0,
    0,
  ]);
  if (declaredFrames != null) {
    _pngChunk(bytes, 'acTL', [..._big32(declaredFrames), ..._big32(0)]);
  }
  for (var index = 0; index < frameControls; index++) {
    _pngChunk(bytes, 'fcTL', List<int>.filled(26, 0));
  }
  _pngChunk(bytes, 'IEND', const []);
  return Uint8List.fromList(bytes);
}

void _pngChunk(List<int> target, String type, List<int> payload) {
  target
    ..addAll(_big32(payload.length))
    ..addAll(ascii.encode(type))
    ..addAll(payload)
    ..addAll(const [0, 0, 0, 0]);
}

Uint8List _jpeg({required int width, required int height}) =>
    Uint8List.fromList([
      0xff,
      0xd8,
      0xff,
      0xc0,
      0,
      17,
      8,
      ..._big16(height),
      ..._big16(width),
      3,
      1,
      0x11,
      0,
      2,
      0x11,
      0,
      3,
      0x11,
      0,
      0xff,
      0xda,
      0,
      12,
      3,
      1,
      0,
      2,
      0,
      3,
      0,
      0,
      63,
      0,
      0,
      0xff,
      0xd9,
    ]);

Uint8List _gif({
  required int width,
  required int height,
  required int frames,
  int frameWidth = 1,
  int frameHeight = 1,
}) {
  final bytes = <int>[
    ...ascii.encode('GIF89a'),
    ..._little16(width),
    ..._little16(height),
    0,
    0,
    0,
  ];
  for (var index = 0; index < frames; index++) {
    bytes.addAll([
      0x2c,
      0,
      0,
      0,
      0,
      ..._little16(frameWidth),
      ..._little16(frameHeight),
      0,
      2,
      1,
      0,
      0,
    ]);
  }
  bytes.add(0x3b);
  return Uint8List.fromList(bytes);
}

Uint8List _webpStatic({required int width, required int height}) {
  final bits = (width - 1) | ((height - 1) << 14);
  return _webp([
    _riffChunk('VP8L', [0x2f, ..._little32(bits)]),
  ]);
}

Uint8List _webpAnimated({
  required int width,
  required int height,
  required int frames,
  bool includeAnim = true,
  bool emptyFrames = false,
}) {
  final chunks = <List<int>>[
    _riffChunk('VP8X', [
      0x02,
      0,
      0,
      0,
      ..._little24(width - 1),
      ..._little24(height - 1),
    ]),
    if (includeAnim) _riffChunk('ANIM', const [0, 0, 0, 0, 0, 0]),
    for (var index = 0; index < frames; index++)
      _riffChunk(
        'ANMF',
        emptyFrames
            ? const []
            : [
                0,
                0,
                0,
                0,
                0,
                0,
                ..._little24(width - 1),
                ..._little24(height - 1),
                0,
                0,
                0,
                0,
                ..._riffChunk('VP8L', [
                  0x2f,
                  ..._little32((width - 1) | ((height - 1) << 14)),
                ]),
              ],
      ),
  ];
  return _webp(chunks);
}

Uint8List _webp(List<List<int>> chunks) {
  final body = <int>[
    ...ascii.encode('WEBP'),
    for (final chunk in chunks) ...chunk,
  ];
  return Uint8List.fromList([
    ...ascii.encode('RIFF'),
    ..._little32(body.length),
    ...body,
  ]);
}

List<int> _riffChunk(String type, List<int> payload) => [
  ...ascii.encode(type),
  ..._little32(payload.length),
  ...payload,
  if (payload.length.isOdd) 0,
];

List<int> _big16(int value) => [value >> 8, value & 0xff];
List<int> _little16(int value) => [value & 0xff, value >> 8];
List<int> _big32(int value) => [
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];
List<int> _little24(int value) => [
  value & 0xff,
  (value >> 8) & 0xff,
  (value >> 16) & 0xff,
];
List<int> _little32(int value) => [
  value & 0xff,
  (value >> 8) & 0xff,
  (value >> 16) & 0xff,
  (value >> 24) & 0xff,
];
