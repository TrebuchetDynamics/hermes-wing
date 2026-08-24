import 'dart:typed_data';

const maxInlineTranscriptImageDimension = 8192;
const maxInlineTranscriptImagePixels = 16 * 1024 * 1024;
const maxInlineTranscriptAnimationFrames = 60;
const maxInlineTranscriptAnimationPixels = 64 * 1024 * 1024;
const maxInlineTranscriptAggregatePixels = 32 * 1024 * 1024;
const maxInlineTranscriptDecodeDimension = 2048;

InlineTranscriptImageMetadata? inlineTranscriptImageMetadata(
  Uint8List bytes,
  String mimeType,
) {
  final metadata = switch (mimeType.toLowerCase()) {
    'image/png' => _pngMetadata(bytes),
    'image/jpeg' => _jpegMetadata(bytes),
    'image/gif' => _gifMetadata(bytes),
    'image/webp' => _webpMetadata(bytes),
    _ => null,
  };
  if (metadata == null ||
      metadata.width <= 0 ||
      metadata.height <= 0 ||
      metadata.width > maxInlineTranscriptImageDimension ||
      metadata.height > maxInlineTranscriptImageDimension ||
      metadata.frames <= 0 ||
      metadata.frames > maxInlineTranscriptAnimationFrames) {
    return null;
  }
  final pixels = metadata.width * metadata.height;
  return pixels <= maxInlineTranscriptImagePixels &&
          metadata.animationPixels <= maxInlineTranscriptAnimationPixels
      ? metadata
      : null;
}

bool isSafeInlineTranscriptImage(Uint8List bytes, String mimeType) =>
    inlineTranscriptImageMetadata(bytes, mimeType) != null;

InlineTranscriptImageMetadata? _pngMetadata(Uint8List bytes) {
  if (bytes.length < 24 ||
      !_matches(bytes, 0, const [
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]) ||
      _uint32Big(bytes, 8) != 13 ||
      !_matches(bytes, 12, const [0x49, 0x48, 0x44, 0x52])) {
    return null;
  }
  final width = _uint32Big(bytes, 16);
  final height = _uint32Big(bytes, 20);
  int? declaredFrames;
  var frameControls = 0;
  var offset = 8;
  var foundEnd = false;
  while (offset + 12 <= bytes.length) {
    final length = _uint32Big(bytes, offset);
    final chunkEnd = offset + 12 + length;
    if (chunkEnd > bytes.length) return null;
    if (_matches(bytes, offset + 4, const [0x61, 0x63, 0x54, 0x4c])) {
      if (length != 8 || declaredFrames != null) return null;
      declaredFrames = _uint32Big(bytes, offset + 8);
    }
    if (_matches(bytes, offset + 4, const [0x66, 0x63, 0x54, 0x4c])) {
      if (length != 26) return null;
      frameControls++;
      if (frameControls > maxInlineTranscriptAnimationFrames) return null;
    }
    if (_matches(bytes, offset + 4, const [0x49, 0x45, 0x4e, 0x44])) {
      if (length != 0 || chunkEnd != bytes.length) return null;
      foundEnd = true;
      break;
    }
    offset = chunkEnd;
  }
  if (!foundEnd) return null;
  final frames = declaredFrames ?? 1;
  if (declaredFrames == null && frameControls != 0) return null;
  if (declaredFrames != null &&
      (declaredFrames <= 0 || declaredFrames != frameControls)) {
    return null;
  }
  return InlineTranscriptImageMetadata(
    width: width,
    height: height,
    frames: frames,
    animationPixels: width * height * frames,
  );
}

InlineTranscriptImageMetadata? _jpegMetadata(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) return null;
  var offset = 2;
  int? width;
  int? height;
  var scanning = false;
  while (offset < bytes.length) {
    if (scanning) {
      if (bytes[offset++] != 0xff) continue;
      while (offset < bytes.length && bytes[offset] == 0xff) {
        offset++;
      }
      if (offset >= bytes.length) return null;
      final marker = bytes[offset++];
      if (marker == 0x00 || (marker >= 0xd0 && marker <= 0xd7)) continue;
      if (marker != 0xd9 || offset != bytes.length) return null;
      return InlineTranscriptImageMetadata(
        width: width!,
        height: height!,
        frames: 1,
        animationPixels: width * height,
      );
    }

    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset++;
    }
    if (offset >= bytes.length) return null;
    final marker = bytes[offset++];
    if (marker == 0xd9 || marker == 0x00) return null;
    if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (offset + 2 > bytes.length) return null;
    final length = _uint16Big(bytes, offset);
    if (length < 2 || offset + length > bytes.length) return null;
    if (_jpegStartOfFrameMarkers.contains(marker)) {
      if (length < 7 || width != null || height != null) return null;
      width = _uint16Big(bytes, offset + 5);
      height = _uint16Big(bytes, offset + 3);
    }
    if (marker == 0xda) {
      if (width == null || height == null || length < 6) return null;
      scanning = true;
    }
    offset += length;
  }
  return null;
}

const _jpegStartOfFrameMarkers = {
  0xc0,
  0xc1,
  0xc2,
  0xc3,
  0xc5,
  0xc6,
  0xc7,
  0xc9,
  0xca,
  0xcb,
  0xcd,
  0xce,
  0xcf,
};

InlineTranscriptImageMetadata? _gifMetadata(Uint8List bytes) {
  if (bytes.length < 14 ||
      (!_matches(bytes, 0, const [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) &&
          !_matches(bytes, 0, const [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]))) {
    return null;
  }
  final width = _uint16Little(bytes, 6);
  final height = _uint16Little(bytes, 8);
  var offset = 13;
  final packed = bytes[10];
  if (packed & 0x80 != 0) {
    offset += 3 * (1 << ((packed & 0x07) + 1));
  }
  if (offset > bytes.length) return null;
  var frames = 0;
  var animationPixels = 0;
  while (offset < bytes.length) {
    final block = bytes[offset];
    if (block == 0x3b) {
      return offset + 1 == bytes.length && frames > 0
          ? InlineTranscriptImageMetadata(
              width: width,
              height: height,
              frames: frames,
              animationPixels: animationPixels,
            )
          : null;
    }
    if (block == 0x21) {
      if (offset + 2 > bytes.length) return null;
      offset = _skipSubBlocks(bytes, offset + 2);
      if (offset < 0) return null;
      continue;
    }
    if (block != 0x2c || offset + 10 > bytes.length) return null;
    final frameLeft = _uint16Little(bytes, offset + 1);
    final frameTop = _uint16Little(bytes, offset + 3);
    final frameWidth = _uint16Little(bytes, offset + 5);
    final frameHeight = _uint16Little(bytes, offset + 7);
    if (frameWidth <= 0 ||
        frameHeight <= 0 ||
        frameWidth > maxInlineTranscriptImageDimension ||
        frameHeight > maxInlineTranscriptImageDimension ||
        frameLeft + frameWidth > width ||
        frameTop + frameHeight > height) {
      return null;
    }
    animationPixels += frameWidth * frameHeight;
    if (animationPixels > maxInlineTranscriptAnimationPixels) return null;
    final imagePacked = bytes[offset + 9];
    offset += 10;
    if (imagePacked & 0x80 != 0) {
      offset += 3 * (1 << ((imagePacked & 0x07) + 1));
    }
    if (offset >= bytes.length) return null;
    offset = _skipSubBlocks(bytes, offset + 1);
    if (offset < 0) return null;
    frames++;
    if (frames > maxInlineTranscriptAnimationFrames) return null;
  }
  return null;
}

InlineTranscriptImageMetadata? _webpMetadata(Uint8List bytes) {
  if (bytes.length < 20 ||
      !_matches(bytes, 0, const [0x52, 0x49, 0x46, 0x46]) ||
      !_matches(bytes, 8, const [0x57, 0x45, 0x42, 0x50]) ||
      _uint32Little(bytes, 4) + 8 != bytes.length) {
    return null;
  }
  int? width;
  int? height;
  var frames = 0;
  var animationPixels = 0;
  var animated = false;
  var foundAnimationHeader = false;
  var foundStaticImage = false;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final size = _uint32Little(bytes, offset + 4);
    final dataOffset = offset + 8;
    final chunkEnd = dataOffset + size;
    if (chunkEnd > bytes.length) return null;
    if (_matches(bytes, offset, const [0x56, 0x50, 0x38, 0x58])) {
      if (size != 10 || width != null || height != null) return null;
      animated = bytes[dataOffset] & 0x02 != 0;
      width = 1 + _uint24Little(bytes, dataOffset + 4);
      height = 1 + _uint24Little(bytes, dataOffset + 7);
    } else if (_matches(bytes, offset, const [0x56, 0x50, 0x38, 0x20])) {
      if (size < 10 ||
          foundStaticImage ||
          !_matches(bytes, dataOffset + 3, const [0x9d, 0x01, 0x2a])) {
        return null;
      }
      foundStaticImage = true;
      width ??= _uint16Little(bytes, dataOffset + 6) & 0x3fff;
      height ??= _uint16Little(bytes, dataOffset + 8) & 0x3fff;
    } else if (_matches(bytes, offset, const [0x56, 0x50, 0x38, 0x4c])) {
      if (size < 5 || foundStaticImage || bytes[dataOffset] != 0x2f) {
        return null;
      }
      foundStaticImage = true;
      final bits = _uint32Little(bytes, dataOffset + 1);
      width ??= 1 + (bits & 0x3fff);
      height ??= 1 + ((bits >> 14) & 0x3fff);
    } else if (_matches(bytes, offset, const [0x41, 0x4e, 0x4d, 0x46])) {
      if (size < 29 || width == null || height == null) return null;
      final frameLeft = 2 * _uint24Little(bytes, dataOffset);
      final frameTop = 2 * _uint24Little(bytes, dataOffset + 3);
      final frameWidth = 1 + _uint24Little(bytes, dataOffset + 6);
      final frameHeight = 1 + _uint24Little(bytes, dataOffset + 9);
      if (frameLeft + frameWidth > width || frameTop + frameHeight > height) {
        return null;
      }
      final frameDataOffset = dataOffset + 16;
      if (!_matches(bytes, frameDataOffset, const [0x56, 0x50, 0x38, 0x4c]) &&
          !_matches(bytes, frameDataOffset, const [0x56, 0x50, 0x38, 0x20])) {
        return null;
      }
      final frameDataSize = _uint32Little(bytes, frameDataOffset + 4);
      if (frameDataOffset + 8 + frameDataSize > chunkEnd) return null;
      animationPixels += frameWidth * frameHeight;
      if (animationPixels > maxInlineTranscriptAnimationPixels) return null;
      frames++;
      if (frames > maxInlineTranscriptAnimationFrames) return null;
    } else if (_matches(bytes, offset, const [0x41, 0x4e, 0x49, 0x4d])) {
      if (size != 6 || foundAnimationHeader) return null;
      foundAnimationHeader = true;
    }
    offset = chunkEnd + (size.isOdd ? 1 : 0);
  }
  if (offset != bytes.length || width == null || height == null) return null;
  if (animated) {
    if (!foundAnimationHeader || frames == 0 || foundStaticImage) return null;
  } else if (foundAnimationHeader || frames != 0 || !foundStaticImage) {
    return null;
  }
  return InlineTranscriptImageMetadata(
    width: width,
    height: height,
    frames: animated ? frames : 1,
    animationPixels: animated ? animationPixels : width * height,
  );
}

int _skipSubBlocks(Uint8List bytes, int offset) {
  while (offset < bytes.length) {
    final length = bytes[offset++];
    if (length == 0) return offset;
    offset += length;
    if (offset > bytes.length) return -1;
  }
  return -1;
}

bool _matches(Uint8List bytes, int offset, List<int> expected) {
  if (offset < 0 || offset + expected.length > bytes.length) return false;
  for (var index = 0; index < expected.length; index++) {
    if (bytes[offset + index] != expected[index]) return false;
  }
  return true;
}

int _uint16Big(Uint8List bytes, int offset) =>
    (bytes[offset] << 8) | bytes[offset + 1];

int _uint16Little(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);

int _uint24Little(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);

int _uint32Big(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

int _uint32Little(Uint8List bytes, int offset) =>
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24);

class InlineTranscriptImageMetadata {
  const InlineTranscriptImageMetadata({
    required this.width,
    required this.height,
    required this.frames,
    required this.animationPixels,
  });

  final int width;
  final int height;
  final int frames;
  final int animationPixels;
}
