import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'local_wing_link_process.dart';

const _maximumOutputBytes = 256 * 1024;

String localAppExecutablePath() => Platform.resolvedExecutable;

Future<LocalWingLinkProcessResult> runLocalWingLink(
  String executable,
  List<String> arguments,
) async {
  if (!Platform.isLinux) {
    return const LocalWingLinkProcessResult(exitCode: 126);
  }
  final process = await Process.start(
    executable,
    arguments,
    runInShell: false,
    mode: ProcessStartMode.normal,
  );
  try {
    final output = await Future.wait([
      _collectBounded(process.stdout),
      _collectBounded(process.stderr),
    ]);
    final exitCode = await process.exitCode;
    return LocalWingLinkProcessResult(
      exitCode: exitCode,
      stdout: utf8.decode(output[0], allowMalformed: true),
      stderr: utf8.decode(output[1], allowMalformed: true),
    );
  } on StateError {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
    return const LocalWingLinkProcessResult(exitCode: 125);
  }
}

Future<LocalWingLinkSetupOperation> startLocalWingLinkSetup(
  String executable,
  LocalWingLinkProgressCallback onProgress,
) async {
  if (!Platform.isLinux) return _UnavailableSetupOperation();
  final process = await Process.start(
    executable,
    const ['setup', '--json-lines'],
    runInShell: false,
    mode: ProcessStartMode.normal,
  );
  return _IOSetupOperation(process, onProgress);
}

class _UnavailableSetupOperation implements LocalWingLinkSetupOperation {
  @override
  Future<LocalWingLinkProcessResult> get result async =>
      const LocalWingLinkProcessResult(exitCode: 126);

  @override
  Future<void> cancel() async {}
}

class _IOSetupOperation implements LocalWingLinkSetupOperation {
  _IOSetupOperation(this._process, this._onProgress) {
    _result = _collect();
  }

  final Process _process;
  final LocalWingLinkProgressCallback _onProgress;
  late final Future<LocalWingLinkProcessResult> _result;
  bool _cancelled = false;

  @override
  Future<LocalWingLinkProcessResult> get result => _result;

  Future<LocalWingLinkProcessResult> _collect() async {
    var bytes = 0;
    String? terminalJson;
    var invalidOutput = false;
    final stderrFuture = _collectBounded(_process.stderr);
    try {
      await for (final line
          in _process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        bytes += utf8.encode(line).length + 1;
        if (bytes > _maximumOutputBytes) throw StateError('output bound');
        final Object? decoded;
        try {
          decoded = jsonDecode(line);
        } on FormatException {
          invalidOutput = true;
          continue;
        }
        if (decoded is! Map<String, dynamic> ||
            decoded['protocol_version'] != 1) {
          invalidOutput = true;
          continue;
        }
        final event = decoded['event'];
        if (event is Map<String, dynamic>) {
          final percent = event['percent'];
          _onProgress(
            LocalWingLinkProgress(
              phase: event['phase']?.toString() ?? '',
              message: event['message']?.toString() ?? '',
              percent: percent is num ? percent.toInt().clamp(0, 100) : 0,
            ),
          );
        }
        if (decoded['result'] is Map) terminalJson = line;
      }
      final exitCode = await _process.exitCode;
      final stderr = await stderrFuture;
      return LocalWingLinkProcessResult(
        exitCode: _cancelled ? 130 : (invalidOutput ? 125 : exitCode),
        stdout: terminalJson ?? '',
        stderr: utf8.decode(stderr, allowMalformed: true),
      );
    } on StateError {
      _process.kill(ProcessSignal.sigkill);
      await _process.exitCode;
      await stderrFuture;
      return const LocalWingLinkProcessResult(exitCode: 125);
    }
  }

  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    if (!_process.kill(ProcessSignal.sigterm)) return;
    await Future.any([
      _process.exitCode,
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);
    _process.kill(ProcessSignal.sigkill);
  }
}

Future<List<int>> _collectBounded(Stream<List<int>> stream) async {
  final bytes = <int>[];
  await for (final chunk in stream) {
    if (bytes.length + chunk.length > _maximumOutputBytes) {
      throw StateError('Wing Link output exceeded the local bound');
    }
    bytes.addAll(chunk);
  }
  return bytes;
}
