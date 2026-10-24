import 'package:flutter/foundation.dart';

import '../../../core/hermes/client/hermes_managed_files.dart';
import 'hermes_managed_file_save_unsupported.dart'
    if (dart.library.io) 'hermes_managed_file_save_io.dart'
    as platform;

enum HermesManagedFileSaveResult { verified, cancelled, failed }

HermesManagedFileSaver createManagedFileSaver() =>
    platform.createManagedFileSaver();

/// Native destinations return bounded readback, not a download-start receipt.
class HermesManagedFileSaver {
  const HermesManagedFileSaver({
    required this.supported,
    required this.writeAndReadBack,
  });
  final bool supported;
  final Future<Uint8List?> Function(
    String filename,
    Uint8List bytes,
    bool Function() canWrite,
    HermesManagedFileTransfer transfer,
    Future<bool> Function() confirmOverwrite,
  )
  writeAndReadBack;

  Future<HermesManagedFileSaveResult> save(
    Uint8List bytes, {
    required String filename,
    required bool Function() isCurrent,
    required HermesManagedFileTransfer transfer,
    required Future<bool> Function() confirmOverwrite,
  }) async {
    bool current() => !transfer.isCancelled && isCurrent();
    if (!current()) return HermesManagedFileSaveResult.cancelled;
    if (!supported ||
        bytes.length > HermesManagedFilesSession.maximumDownloadBytes) {
      return HermesManagedFileSaveResult.failed;
    }
    var name = filename
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceFirst(RegExp(r'^[.\-]+'), '');
    if (name.length > 120) name = name.substring(0, 120);
    name = name.replaceFirst(RegExp(r'[. ]+$'), '');
    if (name.isEmpty ||
        RegExp(
          r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)',
          caseSensitive: false,
        ).hasMatch(name)) {
      name = 'download.bin';
    }
    try {
      final readback = await writeAndReadBack(
        name,
        bytes,
        current,
        transfer,
        confirmOverwrite,
      );
      if (!current() || readback == null) {
        return HermesManagedFileSaveResult.cancelled;
      }
      return listEquals(bytes, readback)
          ? HermesManagedFileSaveResult.verified
          : HermesManagedFileSaveResult.failed;
    } catch (_) {
      return current()
          ? HermesManagedFileSaveResult.failed
          : HermesManagedFileSaveResult.cancelled;
    }
  }
}
