import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_managed_files.dart';
import 'package:wing/features/hermes_chat/files/hermes_managed_file_save.dart';
import 'package:wing/features/hermes_chat/files/hermes_managed_file_save_io.dart'
    as native;

final class _DiskIO extends IOOverrides {}

class _SwapOnOpenFile extends Fake implements File {
  _SwapOnOpenFile(this.file, this.swap, {this.beforeRename});
  final File file;
  final Future<void> Function() swap;
  final Future<void> Function()? beforeRename;
  @override
  String get path => file.path;
  @override
  Uri get uri => file.uri;
  @override
  Directory get parent => file.parent;
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async {
    await swap();
    return file.open(mode: mode);
  }

  @override
  Future<File> rename(String path) async {
    await beforeRename?.call();
    return file.rename(path);
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) =>
      file.openRead(start, end);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const picker = MethodChannel('plugins.flutter.io/file_selector');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory root;
  late File destination;
  final pickerCalls = <MethodCall>[];
  setUp(() async {
    root = await Directory.systemTemp.createTemp('wing-managed-save-');
    destination = File('${root.path}/chosen.bin');
    pickerCalls.clear();
    messenger.setMockMethodCallHandler(picker, (call) async {
      pickerCalls.add(call);
      return destination.path;
    });
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(picker, null);
    await root.delete(recursive: true);
  });

  test(
    'save success requires exact text or binary readback and a sanitized basename',
    () async {
      for (final bytes in [
        [104, 105, 10],
        [0, 255, 128],
      ]) {
        final saver = createManagedFileSaver();
        expect(
          await saver.save(
            Uint8List.fromList(bytes),
            filename: '../../bad\\name\u202E.txt',
            isCurrent: () => true,
            transfer: HermesManagedFileTransfer(),
            confirmOverwrite: () async => true,
          ),
          HermesManagedFileSaveResult.verified,
        );
        expect(await destination.readAsBytes(), bytes);
        expect(
          (pickerCalls.last.arguments as Map)['suggestedName'],
          '_.._bad_name_.txt',
        );
      }
    },
  );

  test(
    'Linux refuses a linked destination and preserves files without current write consent',
    () async {
      final previous = File('${root.path}/previous');
      await previous.writeAsBytes([9]);
      await Link(destination.path).create(previous.path);
      final saver = createManagedFileSaver();
      Future<HermesManagedFileSaveResult> save(
        Future<bool> Function() confirm, {
        bool Function()? current,
      }) => saver.save(
        Uint8List.fromList([1]),
        filename: 'note.txt',
        isCurrent: current ?? () => true,
        transfer: HermesManagedFileTransfer(),
        confirmOverwrite: confirm,
      );
      expect(await save(() async => true), HermesManagedFileSaveResult.failed);
      expect(await previous.readAsBytes(), [9]);
      await Link(destination.path).delete();
      await destination.writeAsBytes([9]);
      expect(
        await save(() async => false),
        HermesManagedFileSaveResult.cancelled,
      );
      var current = true;
      expect(
        await save(() async {
          current = false;
          return true;
        }, current: () => current),
        HermesManagedFileSaveResult.cancelled,
      );
      expect(await destination.readAsBytes(), [9]);
    },
  );

  test(
    'Linux destination swap during opening cannot redirect an overwrite',
    () async {
      final previous = File('${root.path}/previous');
      await previous.writeAsBytes([9]);
      await destination.writeAsBytes([8]);
      var swapped = false;
      final disk = _DiskIO();
      final result = await IOOverrides.runZoned(
        () => createManagedFileSaver().save(
          Uint8List.fromList([1]),
          filename: 'note.txt',
          isCurrent: () => true,
          transfer: HermesManagedFileTransfer(),
          confirmOverwrite: () async => true,
        ),
        createFile: (path) => _SwapOnOpenFile(disk.createFile(path), () async {
          if (swapped) return;
          swapped = true;
          await destination.delete();
          await Link(destination.path).create(previous.path);
        }),
      );
      expect(swapped, isTrue);
      expect(await previous.readAsBytes(), [9]);
      expect(result, HermesManagedFileSaveResult.verified);
      expect(await destination.readAsBytes(), [1]);
    },
  );

  test(
    'Linux cancellation escapes a stalled open without letting it overwrite a retry',
    () async {
      await destination.writeAsBytes([9]);
      final started = Completer<void>(), release = Completer<void>();
      String? oldStaging;
      final removed = root.watch().firstWhere(
        (event) => event is FileSystemDeleteEvent && event.path == oldStaging,
      );
      final transfer = HermesManagedFileTransfer();
      final disk = _DiskIO();
      final pending = IOOverrides.runZoned(
        () => createManagedFileSaver().save(
          Uint8List.fromList([1]),
          filename: 'one.bin',
          isCurrent: () => true,
          transfer: transfer,
          confirmOverwrite: () async => true,
        ),
        createFile: (path) => _SwapOnOpenFile(disk.createFile(path), () async {
          if (started.isCompleted) return;
          oldStaging = disk.createFile(path).parent.path;
          started.complete();
          await release.future;
        }),
      );
      await started.future;
      transfer.cancel();
      expect(
        await pending.timeout(const Duration(seconds: 5)),
        HermesManagedFileSaveResult.cancelled,
      );
      expect(
        await createManagedFileSaver().save(
          Uint8List.fromList([2]),
          filename: 'two.bin',
          isCurrent: () => true,
          transfer: HermesManagedFileTransfer(),
          confirmOverwrite: () async => true,
        ),
        HermesManagedFileSaveResult.verified,
      );
      release.complete();
      await removed.timeout(const Duration(seconds: 5));
      expect(await destination.readAsBytes(), [2]);
    },
  );

  test(
    'Linux unsettled publication reserves its destination across cancellation',
    () async {
      final started = Completer<void>(), release = Completer<void>();
      String? oldStaging;
      final removed = root.watch().firstWhere(
        (event) => event is FileSystemDeleteEvent && event.path == oldStaging,
      );
      final disk = _DiskIO();
      final transfer = HermesManagedFileTransfer();
      final pending = IOOverrides.runZoned(
        () => createManagedFileSaver().save(
          Uint8List.fromList([1]),
          filename: 'one.bin',
          isCurrent: () => true,
          transfer: transfer,
          confirmOverwrite: () async => true,
        ),
        createFile: (path) => _SwapOnOpenFile(
          disk.createFile(path),
          () async {},
          beforeRename: () async {
            oldStaging = disk.createFile(path).parent.path;
            started.complete();
            await release.future;
          },
        ),
      );
      Future<HermesManagedFileSaveResult> retry() =>
          createManagedFileSaver().save(
            Uint8List.fromList([2]),
            filename: 'two.bin',
            isCurrent: () => true,
            transfer: HermesManagedFileTransfer(),
            confirmOverwrite: () async => true,
          );
      await started.future;
      transfer.cancel();
      expect(
        await pending.timeout(const Duration(seconds: 5)),
        HermesManagedFileSaveResult.cancelled,
      );
      expect(await retry(), HermesManagedFileSaveResult.failed);
      release.complete();
      await removed.timeout(const Duration(seconds: 5));
      expect(await retry(), HermesManagedFileSaveResult.verified);
      expect(await destination.readAsBytes(), [2]);
    },
  );

  test(
    'Android cancelled document choice or stale owner never writes',
    () async {
      const documents = MethodChannel(
        'com.trebuchetdynamics.hermes.wing/managed_file_save',
      );
      final calls = <String>[];
      var current = true;
      var choose = false;
      messenger.setMockMethodCallHandler(documents, (call) async {
        calls.add(call.method);
        if (call.method == 'choose') {
          current = !choose;
          return choose;
        }
        if (call.method == 'writeAndReadBack') {
          fail('No write after rejected choice');
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(documents, null));
      for (choose in [false, true]) {
        current = true;
        expect(
          await native.createAndroidManagedFileSaver().save(
            Uint8List.fromList([1]),
            filename: '../name.txt',
            isCurrent: () => current,
            transfer: HermesManagedFileTransfer(),
            confirmOverwrite: () async => false,
          ),
          HermesManagedFileSaveResult.cancelled,
        );
      }
      expect(calls, ['choose', 'release', 'choose', 'release']);
    },
  );

  test(
    'Android stalled write cancellation releases its identity and permits explicit retry',
    () async {
      const documents = MethodChannel(
        'com.trebuchetdynamics.hermes.wing/managed_file_save',
      );
      final started = Completer<void>(), stalled = Completer<Uint8List>();
      final writes = <int>[], cancelled = <int>[], released = <int>[];
      messenger.setMockMethodCallHandler(documents, (call) async {
        final args = call.arguments as Map;
        final id = args['id'] as int;
        if (call.method == 'choose') return true;
        if (call.method == 'cancel') cancelled.add(id);
        if (call.method == 'release') released.add(id);
        if (call.method == 'writeAndReadBack') {
          writes.add(id);
          if (writes.length == 1) {
            started.complete();
            return stalled.future;
          }
          return Uint8List.fromList([2]);
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(documents, null));
      final transfer = HermesManagedFileTransfer();
      final saver = native.createAndroidManagedFileSaver();
      final result = saver.save(
        Uint8List.fromList([1]),
        filename: 'one.bin',
        isCurrent: () => true,
        transfer: transfer,
        confirmOverwrite: () async => false,
      );
      await started.future;
      transfer.cancel();
      expect(
        await result.timeout(const Duration(seconds: 5)),
        HermesManagedFileSaveResult.cancelled,
      );
      expect(cancelled, [writes.single]);
      expect(released, [writes.single]);
      expect(
        await saver.save(
          Uint8List.fromList([2]),
          filename: 'two.bin',
          isCurrent: () => true,
          transfer: HermesManagedFileTransfer(),
          confirmOverwrite: () async => false,
        ),
        HermesManagedFileSaveResult.verified,
      );
      expect(writes.toSet(), hasLength(2));
      stalled.complete(Uint8List.fromList([1]));
    },
  );

  test(
    'cancel, denial, corrupt readback and owner loss never claim a save',
    () async {
      for (final cause in ['cancel', 'denied', 'corrupt', 'owner', 'picker']) {
        var current = true;
        final transfer = HermesManagedFileTransfer();
        final saver = HermesManagedFileSaver(
          supported: true,
          writeAndReadBack: (name, source, canWrite, transfer, confirm) async {
            if (cause == 'cancel') transfer.cancel();
            if (cause == 'owner') current = false;
            if (cause == 'denied') throw StateError('synthetic denial');
            if (cause == 'picker') return null;
            return Uint8List.fromList(cause == 'corrupt' ? [2] : [1]);
          },
        );
        expect(
          await saver.save(
            Uint8List.fromList([1]),
            filename: 'note.txt',
            isCurrent: () => current,
            transfer: transfer,
            confirmOverwrite: () async => false,
          ),
          isNot(HermesManagedFileSaveResult.verified),
        );
      }
    },
  );
}
