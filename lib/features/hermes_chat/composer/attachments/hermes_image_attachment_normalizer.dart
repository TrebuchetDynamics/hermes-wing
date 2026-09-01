import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../presentation/inline_transcript_image_safety.dart';
import 'hermes_attachment_content.dart';

const maxImageAttachmentInputBytes = 32 * 1024 * 1024;
const _maxNormalizationAttempts = 8;
const _minimumUsefulImageDimension = 64;

final class NormalizedHermesImageAttachment {
  const NormalizedHermesImageAttachment({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;
}

Future<NormalizedHermesImageAttachment?> normalizeHermesImageAttachment({
  required Uint8List bytes,
  required String mimeType,
  required String name,
  int targetBytes = maxImageAttachmentBytes,
  int maxInputBytes = maxImageAttachmentInputBytes,
}) async {
  if (bytes.isEmpty || targetBytes <= 0 || bytes.length > maxInputBytes) {
    return null;
  }
  if (bytes.length <= targetBytes) {
    return NormalizedHermesImageAttachment(
      name: name,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  final metadata = inlineTranscriptImageMetadata(bytes, mimeType);
  if (metadata == null ||
      metadata.frames != 1 ||
      metadata.width < _minimumUsefulImageDimension ||
      metadata.height < _minimumUsefulImageDimension) {
    return null;
  }

  var scale = math.min(
    math.sqrt(targetBytes / bytes.length),
    maxInlineTranscriptDecodeDimension /
        math.max(metadata.width, metadata.height),
  );
  scale = math.min(1, scale);
  for (var attempt = 0; attempt < _maxNormalizationAttempts; attempt++) {
    final width = (metadata.width * scale).floor();
    final height = (metadata.height * scale).floor();
    if (width < _minimumUsefulImageDimension ||
        height < _minimumUsefulImageDimension) {
      return null;
    }

    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: width,
        targetHeight: height,
      );
      if (codec.frameCount != 1) return null;
      final frame = await codec.getNextFrame();
      image = frame.image;
      final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
      if (encoded == null) return null;
      final candidate = Uint8List.fromList(
        encoded.buffer.asUint8List(
          encoded.offsetInBytes,
          encoded.lengthInBytes,
        ),
      );
      if (candidate.length <= targetBytes) {
        return NormalizedHermesImageAttachment(
          name: _pngAttachmentName(name),
          bytes: candidate,
          mimeType: 'image/png',
        );
      }
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
    scale *= 0.75;
  }
  return null;
}

String _pngAttachmentName(String name) {
  final dot = name.lastIndexOf('.');
  final stem = dot > 0 ? name.substring(0, dot) : name;
  return '$stem.png';
}
