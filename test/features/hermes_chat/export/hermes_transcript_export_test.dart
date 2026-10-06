import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/export/hermes_transcript_export.dart';
import 'package:wing/features/hermes_chat/export/hermes_transcript_export_unsupported.dart';

void main() {
  for (final format in HermesTranscriptExportFormat.values) {
    test(
      '$format preserves Unicode UTF-8, inert source and immutable bytes',
      () {
        const text = '日本語 😀 é\n<script>not executed</script>\n**source**';
        final snapshot = HermesTranscriptExport(text, format);
        expect(snapshot.bytes, utf8.encode(text));
        expect(utf8.decode(snapshot.bytes), text);
        expect(() => snapshot.bytes[0] = 0, throwsUnsupportedError);
        expect(snapshot.filename, matches(r'^hermes-transcript\.(txt|md)$'));
        expect(
          snapshot.mimeType,
          format == HermesTranscriptExportFormat.text
              ? 'text/plain;charset=utf-8'
              : 'text/markdown;charset=utf-8',
        );
      },
    );
  }
  test('exact byte limit allowed; over-limit fails without truncation', () {
    expect(
      HermesTranscriptExport(
        'x' * hermesTranscriptExportByteLimit,
        HermesTranscriptExportFormat.text,
      ).bytes.length,
      hermesTranscriptExportByteLimit,
    );
    expect(
      () => HermesTranscriptExport(
        'x' * (hermesTranscriptExportByteLimit + 1),
        HermesTranscriptExportFormat.text,
      ),
      throwsA(isA<HermesTranscriptExportTooLarge>()),
    );
  });
  test('multibyte output bound is bytes not UTF-16 characters', () {
    expect(
      () => HermesTranscriptExport(
        '日' * (hermesTranscriptExportByteLimit ~/ 3 + 1),
        HermesTranscriptExportFormat.markdown,
      ),
      throwsA(isA<HermesTranscriptExportTooLarge>()),
    );
  });
  test(
    'native platform never claims a download or invokes a write callback',
    () async {
      final saver = createTranscriptSaver();
      expect(saver.supported, isFalse);
      expect(
        await saver.save(
          HermesTranscriptExport(
            'synthetic',
            HermesTranscriptExportFormat.text,
          ),
          canWrite: () => throw StateError('must not write'),
        ),
        HermesTranscriptExportResult.unsupported,
      );
    },
  );
}
