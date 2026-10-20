import 'dart:io';

import 'package:file_selector/file_selector.dart';

import 'hermes_transcript_export.dart';
import 'hermes_transcript_export_unsupported.dart' as unsupported;

HermesTranscriptSaver createTranscriptSaver() => Platform.isLinux
    ? _LinuxTranscriptSaver()
    : unsupported.createTranscriptSaver();

class _LinuxTranscriptSaver implements HermesTranscriptSaver {
  @override
  bool get supported => true;

  @override
  Future<HermesTranscriptExportResult> save(
    HermesTranscriptExport snapshot, {
    required bool Function() canWrite,
    Future<bool> Function()? confirmOverwrite,
  }) async {
    if (!canWrite()) return HermesTranscriptExportResult.cancelled;
    final location = await getSaveLocation(
      suggestedName: snapshot.filename,
      acceptedTypeGroups: [
        XTypeGroup(
          extensions: [snapshot.extension],
          mimeTypes: [snapshot.mimeType.split(';').first],
        ),
      ],
    );
    // The native picker may outlive the conversation or screen. Its selected
    // path stays local and is never retained in preferences or diagnostics.
    if (location == null || !canWrite()) {
      return HermesTranscriptExportResult.cancelled;
    }
    // file_selector_linux does not promise overwrite confirmation. Ask for
    // replacement consent even for a new path: another process could create it
    // before saveTo opens it. Consent covers the destination at write time;
    // never pass its private path into UI or logs.
    if (!canWrite() || !(await confirmOverwrite?.call() ?? false)) {
      return HermesTranscriptExportResult.cancelled;
    }
    if (!canWrite()) return HermesTranscriptExportResult.cancelled;
    await XFile.fromData(
      snapshot.bytes,
      mimeType: snapshot.mimeType,
      name: snapshot.filename,
    ).saveTo(location.path);
    return HermesTranscriptExportResult.saved;
  }
}
