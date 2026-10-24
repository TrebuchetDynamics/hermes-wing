import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../../../core/hermes/client/hermes_managed_files.dart';
import 'hermes_managed_file_save.dart';

const _documents = MethodChannel(
  'com.trebuchetdynamics.hermes.wing/managed_file_save',
);
int _documentOperation = 0;
// A submitted rename cannot be cancelled. Keep its destination reserved until
// settlement, even if the caller has already received cancellation/timeout.
final _linuxPublications = <String>{};

HermesManagedFileSaver createManagedFileSaver() => Platform.isAndroid
    ? createAndroidManagedFileSaver()
    : HermesManagedFileSaver(
        supported: Platform.isLinux,
        writeAndReadBack: _linuxSave,
      );

HermesManagedFileSaver createAndroidManagedFileSaver() =>
    const HermesManagedFileSaver(
      supported: true,
      writeAndReadBack: _androidSave,
    );

Future<Uint8List?> _linuxSave(
  String filename,
  Uint8List bytes,
  bool Function() current,
  HermesManagedFileTransfer transfer,
  Future<bool> Function() confirmOverwrite,
) async {
  final location = await getSaveLocation(suggestedName: filename);
  if (location == null || !current()) return null;
  // Consent covers replacement at write time, including a file created while
  // the dialog was open. Never expose or retain the chosen private path.
  if (!await confirmOverwrite() || !current()) return null;
  RandomAccessFile? handle;
  var finished = false;
  unawaited(
    transfer.whenCancelled.then((_) async {
      if (!finished) {
        try {
          await handle?.close();
        } catch (_) {
          /* A pending syscall still owns this handle. */
        }
      }
    }),
  );
  Future<Uint8List?> writeAndRead() async {
    Directory? staging;
    String? publication;
    try {
      final type = await FileSystemEntity.type(
        location.path,
        followLinks: false,
      );
      if (type != FileSystemEntityType.file &&
          type != FileSystemEntityType.notFound) {
        throw const FileSystemException('Destination must be a regular file');
      }
      if (!current()) return null;
      final file = File(location.path);
      // A private same-directory staging file is the only truncating open.
      // Atomic rename replaces the destination entry, never a raced symlink's target.
      staging = await file.parent.createTemp('.wing-download-');
      final staged = File('${staging.path}/bytes');
      if (!current()) return null;
      final output = handle = await staged.open(mode: FileMode.write);
      for (var offset = 0; offset < bytes.length; offset += 64 * 1024) {
        if (!current()) return null;
        await output.writeFrom(
          bytes,
          offset,
          (offset + 64 * 1024).clamp(0, bytes.length),
        );
      }
      await output.flush();
      await output.close();
      handle = null;
      if (!current()) return null;
      final parent = await file.parent.resolveSymbolicLinks();
      if (!current()) return null;
      final destination = '$parent/${file.uri.pathSegments.last}';
      if (!_linuxPublications.add(destination)) {
        throw const FileSystemException(
          'Previous destination publication is unsettled',
        );
      }
      publication = destination;
      await staged.rename(file.path);
      if (!current()) return null;
      final input = handle = await file.open();
      final readback = BytesBuilder(copy: false);
      while (current()) {
        final chunk = await input.read(64 * 1024);
        if (chunk.isEmpty) return readback.takeBytes();
        if (readback.length + chunk.length >
            HermesManagedFilesSession.maximumDownloadBytes) {
          throw const FileSystemException(
            'Saved file exceeds the download bound',
          );
        }
        readback.add(chunk);
      }
      return null;
    } finally {
      if (publication != null) _linuxPublications.remove(publication);
      try {
        await handle?.close();
      } catch (_) {
        /* Cancellation may already have closed it. */
      }
      handle = null;
      if (staging != null) await staging.delete(recursive: true);
    }
  }

  try {
    return await Future.any<Uint8List?>([
      writeAndRead(),
      transfer.whenCancelled.then((_) => null),
    ]).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        transfer.cancel();
        throw TimeoutException('Local save deadline exceeded');
      },
    );
  } finally {
    finished = true;
  }
}

Future<Uint8List?> _androidSave(
  String filename,
  Uint8List bytes,
  bool Function() current,
  HermesManagedFileTransfer transfer,
  Future<bool> Function() confirmOverwrite,
) async {
  final id = ++_documentOperation;
  var finished = false;
  unawaited(
    transfer.whenCancelled.then((_) async {
      if (!finished) {
        try {
          await _documents.invokeMethod<void>('cancel', {'id': id});
        } catch (_) {
          /* No success receipt is possible. */
        }
      }
    }),
  );
  try {
    final chosen = await _documents.invokeMethod<bool>('choose', {
      'id': id,
      'name': filename,
    });
    if (chosen != true || !current()) return null;
    return await Future.any<Uint8List?>([
      _documents.invokeMethod<Uint8List>('writeAndReadBack', {
        'id': id,
        'bytes': bytes,
      }),
      transfer.whenCancelled.then((_) => null),
    ]).timeout(const Duration(seconds: 30));
  } finally {
    finished = true;
    await _documents.invokeMethod<void>('release', {'id': id});
  }
}
