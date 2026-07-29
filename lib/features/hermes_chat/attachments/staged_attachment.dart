import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The single attachment staged in the composer, waiting to be sent.
///
/// Hermes accepts one attachment per turn and an image and a text file are
/// mutually exclusive, so this is a union rather than parallel nullable fields:
/// staging one kind cannot leave the other half-set.
@immutable
sealed class StagedAttachment {
  const StagedAttachment({required this.name});

  /// File name shown in the composer and sent alongside the turn.
  final String name;

  /// Data URL for an image turn, or null when this is a text attachment.
  String? get imageDataUrl;

  /// Decoded text for a text turn, or null when this is an image.
  String? get textContent;
}

/// An image staged for the next turn, identified by its magic bytes.
@immutable
class StagedImageAttachment extends StagedAttachment {
  const StagedImageAttachment({
    required super.name,
    required this.bytes,
    required this.mimeType,
  });

  final Uint8List bytes;

  /// Sniffed image type, never a declared or extension-derived one.
  final String mimeType;

  @override
  String get imageDataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';

  @override
  String? get textContent => null;
}

/// A UTF-8 text file staged for the next turn.
@immutable
class StagedTextAttachment extends StagedAttachment {
  const StagedTextAttachment({required super.name, required this.content});

  final String content;

  @override
  String? get imageDataUrl => null;

  @override
  String get textContent => content;
}
