import 'hermes_transcript_export.dart';

HermesTranscriptSaver createTranscriptSaver() => _UnsupportedTranscriptSaver();

class _UnsupportedTranscriptSaver implements HermesTranscriptSaver {
  @override
  bool get supported => false;

  @override
  Future<HermesTranscriptExportResult> save(
    HermesTranscriptExport snapshot, {
    required bool Function() canWrite,
  }) async => HermesTranscriptExportResult.unsupported;
}
