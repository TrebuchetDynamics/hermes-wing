import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hermes_transcript_export_unsupported.dart'
    if (dart.library.io) 'hermes_transcript_export_io.dart'
    if (dart.library.js_interop) 'hermes_transcript_export_web.dart'
    as platform;

// Local UTF-8 export bytes only; not an Agent artifact/file API.
const hermesTranscriptExportByteLimit = 4 * 1024 * 1024;

enum HermesTranscriptExportFormat { text, markdown, json }

enum HermesTranscriptExportResult {
  downloadStarted,
  saved,
  cancelled,
  unsupported,
}

class HermesTranscriptExportTooLarge implements Exception {
  const HermesTranscriptExportTooLarge();
}

class HermesTranscriptExport {
  HermesTranscriptExport(String transcript, this.format) {
    if (transcript.length > hermesTranscriptExportByteLimit) {
      throw const HermesTranscriptExportTooLarge();
    }
    final encoded = utf8.encode(transcript);
    if (encoded.length > hermesTranscriptExportByteLimit) {
      throw const HermesTranscriptExportTooLarge();
    }
    bytes = Uint8List.fromList(encoded).asUnmodifiableView();
  }

  final HermesTranscriptExportFormat format;
  late final Uint8List bytes;
  String get extension => switch (format) {
    HermesTranscriptExportFormat.text => 'txt',
    HermesTranscriptExportFormat.markdown => 'md',
    HermesTranscriptExportFormat.json => 'json',
  };
  String get filename => format == HermesTranscriptExportFormat.json
      ? 'hermes-session.json'
      : 'hermes-transcript.$extension';
  String get mimeType => switch (format) {
    HermesTranscriptExportFormat.text => 'text/plain;charset=utf-8',
    HermesTranscriptExportFormat.markdown => 'text/markdown;charset=utf-8',
    HermesTranscriptExportFormat.json => 'application/json',
  };
}

abstract interface class HermesTranscriptSaver {
  bool get supported;

  /// Check immediately before writing; a dismissed/disposed owner cannot write.
  /// Linux requires explicit destination/replacement consent; absence cancels.
  Future<HermesTranscriptExportResult> save(
    HermesTranscriptExport snapshot, {
    required bool Function() canWrite,
    Future<bool> Function()? confirmOverwrite,
  });
}

final hermesTranscriptSaverProvider = Provider<HermesTranscriptSaver>(
  (_) => platform.createTranscriptSaver(),
);
