import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/export/hermes_transcript_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const picker = MethodChannel('plugins.flutter.io/file_selector');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory root;
  late HermesTranscriptSaver saver;
  final calls = <MethodCall>[];
  Future<String?> Function()? choose;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wing-transcript-test-');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    saver = container.read(hermesTranscriptSaverProvider);
    calls.clear();
    choose = null;
    messenger.setMockMethodCallHandler(picker, (call) async {
      calls.add(call);
      expect(call.method, 'getSavePath');
      return choose == null ? null : await choose!();
    });
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(picker, null);
    await root.delete(recursive: true);
  });

  for (final format in HermesTranscriptExportFormat.values) {
    test(
      'Linux $format writes exact immutable UTF-8 after selection',
      () async {
        expect(saver.supported, isTrue);
        final snapshot = HermesTranscriptExport(
          'Synthetic 日本語 😀\n**inert**',
          format,
        );
        final file = File('${root.path}/${snapshot.filename}');
        choose = () async => file.path;
        final result = await saver.save(snapshot, canWrite: () => true);
        expect(result.name, 'saved');
        expect(
          await file.readAsBytes(),
          utf8.encode('Synthetic 日本語 😀\n**inert**'),
        );
        final arguments = calls.single.arguments as Map;
        expect(arguments['suggestedName'], snapshot.filename);
        expect(arguments['initialDirectory'], isNull);
        expect((arguments['acceptedTypeGroups'] as List).single['extensions'], [
          format == HermesTranscriptExportFormat.text ? 'txt' : 'md',
        ]);
      },
    );
  }

  test('cancellation and stale intent before picker do not write', () async {
    final snapshot = HermesTranscriptExport(
      'Synthetic',
      HermesTranscriptExportFormat.text,
    );
    expect(
      await saver.save(snapshot, canWrite: () => false),
      HermesTranscriptExportResult.cancelled,
    );
    expect(calls, isEmpty);
    expect(
      await saver.save(snapshot, canWrite: () => true),
      HermesTranscriptExportResult.cancelled,
    );
    expect(calls, hasLength(1));
    expect(await root.list().toList(), isEmpty);
  });

  test(
    'owner change during real platform wait cannot overwrite selected file',
    () async {
      final file = File('${root.path}/hermes-transcript.txt');
      await file.writeAsString('Existing synthetic file');
      final gate = Completer<String?>();
      choose = () => gate.future;
      var current = true;
      final pending = saver.save(
        HermesTranscriptExport('Old owner', HermesTranscriptExportFormat.text),
        canWrite: () => current,
      );
      await Future<void>.delayed(Duration.zero);
      current = false;
      gate.complete(file.path);
      expect(await pending, HermesTranscriptExportResult.cancelled);
      expect(await file.readAsString(), 'Existing synthetic file');
    },
  );

  test(
    'picker and filesystem errors propagate without persistence success',
    () async {
      final snapshot = HermesTranscriptExport(
        'Synthetic',
        HermesTranscriptExportFormat.text,
      );
      choose = () async => throw PlatformException(code: 'synthetic');
      await expectLater(
        saver.save(snapshot, canWrite: () => true),
        throwsA(isA<PlatformException>()),
      );
      choose = () async => '${root.path}/missing/target.txt';
      await expectLater(
        saver.save(snapshot, canWrite: () => true),
        throwsA(isA<FileSystemException>()),
      );
      expect(await root.list().toList(), isEmpty);
    },
  );
}
