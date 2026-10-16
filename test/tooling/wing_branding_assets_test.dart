import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'approved Wing artwork has correct transparency in each consumer',
    () async {
      final manifest =
          jsonDecode(
                File(
                  'assets/branding/wing-logo-provenance.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      const original =
          'dec52fa872aa4c09e5c5bdfd7e0ae0b550e07846cdde581da8a38f1506a13cc5';
      const transparent =
          '414eff510d686e28c54dd09e24b9d2b5b969528903817e3a8c144b62b5199dd2';
      expect(manifest['source_sha256'], original);
      expect(
        sha256
            .convert(File(manifest['source'] as String).readAsBytesSync())
            .toString(),
        original,
      );
      expect(manifest['transparent_master_sha256'], transparent);
      expect(
        sha256
            .convert(
              File(manifest['transparent_master'] as String).readAsBytesSync(),
            )
            .toString(),
        transparent,
      );
      final outputs = (manifest['outputs'] as List)
          .cast<Map<String, dynamic>>();
      expect(outputs, hasLength(38));
      expect(outputs.map((o) => o['path']).toSet(), hasLength(38));
      for (final output in outputs) {
        final path = output['path'] as String;
        final bytes = File(path).readAsBytesSync();
        expect(
          sha256.convert(bytes).toString(),
          output['sha256'],
          reason: path,
        );
        if (path.endsWith('.ico')) {
          expect(bytes.take(4), [0, 0, 1, 0], reason: path);
          expect(
            ByteData.sublistView(bytes).getUint16(4, Endian.little),
            (output['sizes'] as List).length,
            reason: path,
          );
          continue;
        }
        final codec = await ui.instantiateImageCodec(bytes);
        final image = (await codec.getNextFrame()).image;
        try {
          expect([image.width, image.height], output['size'], reason: path);
          final rgba = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          for (final pixel in [
            0,
            image.width - 1,
            (image.height - 1) * image.width,
            image.width * image.height - 1,
          ]) {
            final opaque = output['alpha'] == 'opaque';
            expect(
              rgba.getUint8(pixel * 4 + 3),
              opaque ? 255 : 0,
              reason: path,
            );
            if (opaque) {
              expect(
                [for (var c = 0; c < 3; c++) rgba.getUint8(pixel * 4 + c)],
                manifest['opaque_background_rgb'],
                reason: path,
              );
            }
          }
        } finally {
          image.dispose();
          codec.dispose();
        }
      }
      expect(
        File('README.md').readAsStringSync(),
        contains('src="assets/branding/wing-logo-256.png"'),
      );
      expect(
        File('docs/README.md').readAsStringSync(),
        contains('src="../assets/branding/wing-logo-256.png"'),
      );
      expect(
        File('site/index.html').readAsStringSync(),
        contains('src="assets/app-icon.png"'),
      );
    },
  );
}
