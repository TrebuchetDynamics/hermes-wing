import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/composer/attachments/hermes_image_attachment_normalizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('oversized static image is re-encoded below the outbound cap', () async {
    final input = await _pngWithLargeAncillaryChunk();
    const targetBytes = 24 * 1024;
    expect(input.length, greaterThan(targetBytes));

    final normalized = await normalizeHermesImageAttachment(
      bytes: input,
      mimeType: 'image/png',
      name: 'phone-photo.png',
      targetBytes: targetBytes,
      maxInputBytes: 128 * 1024,
    );

    expect(normalized, isNotNull);
    expect(normalized!.bytes.length, lessThanOrEqualTo(targetBytes));
    expect(normalized.mimeType, 'image/png');
    expect(normalized.name, 'phone-photo.png');
  });
}

Future<Uint8List> _pngWithLargeAncillaryChunk() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 128, 128),
    ui.Paint()..color = const ui.Color(0xff336699),
  );
  final image = await recorder.endRecording().toImage(128, 128);
  final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final png = encoded!.buffer.asUint8List(
    encoded.offsetInBytes,
    encoded.lengthInBytes,
  );
  final payload = Uint8List(64 * 1024);
  final chunkType = Uint8List.fromList(const [0x77, 0x69, 0x4e, 0x47]);
  final chunkLength = ByteData(4)..setUint32(0, payload.length);
  final checksum = ByteData(4)..setUint32(0, _pngCrc32(chunkType, payload));
  final result = BytesBuilder(copy: false)
    ..add(png.sublist(0, png.length - 12))
    ..add(chunkLength.buffer.asUint8List())
    ..add(chunkType)
    ..add(payload)
    ..add(checksum.buffer.asUint8List())
    ..add(png.sublist(png.length - 12));
  return result.takeBytes();
}

int _pngCrc32(Uint8List type, Uint8List payload) {
  final table = List<int>.generate(256, (index) {
    var value = index;
    for (var bit = 0; bit < 8; bit++) {
      value = value & 1 == 1 ? 0xedb88320 ^ (value >> 1) : value >> 1;
    }
    return value;
  });
  var crc = 0xffffffff;
  for (final byte in type) {
    crc = table[(crc ^ byte) & 0xff] ^ (crc >> 8);
  }
  for (final byte in payload) {
    crc = table[(crc ^ byte) & 0xff] ^ (crc >> 8);
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
