import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'hermes_transcript_export.dart';

HermesTranscriptSaver createTranscriptSaver() => _BrowserTranscriptSaver();

class _BrowserTranscriptSaver implements HermesTranscriptSaver {
  @override
  bool get supported => true;

  @override
  Future<HermesTranscriptExportResult> save(
    HermesTranscriptExport snapshot, {
    required bool Function() canWrite,
  }) async {
    if (!canWrite()) return HermesTranscriptExportResult.cancelled;
    // No await before click: retain explicit browser user activation. This is
    // a download request, not proof that the browser/OS persisted the file.
    final blob = web.Blob(
      [snapshot.bytes.toJS].toJS,
      web.BlobPropertyBag(type: snapshot.mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = snapshot.filename;
    try {
      web.document.body!.appendChild(anchor);
      anchor.click();
    } finally {
      anchor.remove();
      // Let the browser consume the download before releasing its memory URL.
      Future<void>.delayed(const Duration(seconds: 30), () {
        web.URL.revokeObjectURL(url);
      });
    }
    return HermesTranscriptExportResult.downloadStarted;
  }
}
