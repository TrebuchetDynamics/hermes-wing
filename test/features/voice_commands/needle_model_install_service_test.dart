import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice_commands/core/needle_model_install_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('needle_spike_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('installedModelDir is null before any install', () async {
    final service = NeedleModelInstallService(supportDirectory: tempDir);
    expect(await service.installedModelDir(), isNull);
  });

  test('extraction resolves a flat zip to the extract dir', () async {
    final zip = _zipWith({'config.json': '{}', 'weights.bin': 'xx'});
    final service = NeedleModelInstallService(supportDirectory: tempDir);
    final dir = await service.installFromZipBytes(zip);
    expect(File('$dir/config.json').existsSync(), isTrue);
    expect(await service.installedModelDir(), dir);
  });

  test('extraction descends into a single wrapper directory', () async {
    final zip = _zipWith({
      'needle-cq4/config.json': '{}',
      'needle-cq4/weights.bin': 'xx',
    });
    final service = NeedleModelInstallService(supportDirectory: tempDir);
    final dir = await service.installFromZipBytes(zip);
    expect(dir, endsWith('needle-cq4'));
    expect(File('$dir/config.json').existsSync(), isTrue);
    expect(await service.installedModelDir(), dir);
  });

  test('empty zip fails installation and leaves no marker', () async {
    final zip = _zipWith({});
    final service = NeedleModelInstallService(supportDirectory: tempDir);
    await expectLater(service.installFromZipBytes(zip), throwsStateError);
    expect(await service.installedModelDir(), isNull);
  });
}

List<int> _zipWith(Map<String, String> files) {
  final archive = Archive();
  files.forEach((path, content) {
    archive.addFile(ArchiveFile(path, content.length, content.codeUnits));
  });
  return ZipEncoder().encode(archive);
}
