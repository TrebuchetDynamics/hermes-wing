import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'offline_whisper_engine.dart';

class SherpaWhisperModelFiles {
  const SherpaWhisperModelFiles({
    required this.modelId,
    required this.encoderPath,
    required this.decoderPath,
    required this.tokensPath,
  });

  final String modelId;
  final String encoderPath;
  final String decoderPath;
  final String tokensPath;
}

sherpa.OfflineRecognizerConfig buildSherpaWhisperConfig({
  required SherpaWhisperModelFiles files,
  required String? language,
  required int numThreads,
}) => sherpa.OfflineRecognizerConfig(
  feat: const sherpa.FeatureConfig(sampleRate: 16000, featureDim: 80),
  model: sherpa.OfflineModelConfig(
    whisper: sherpa.OfflineWhisperModelConfig(
      encoder: files.encoderPath,
      decoder: files.decoderPath,
      language: language ?? '',
      task: 'transcribe',
    ),
    tokens: files.tokensPath,
    numThreads: numThreads,
    debug: false,
    provider: 'cpu',
    modelType: 'whisper',
  ),
);

/// Native sherpa-onnx Whisper adapter used inside the dedicated worker.
class SherpaWhisperRuntime implements OfflineWhisperRuntime {
  SherpaWhisperRuntime({
    required this.files,
    this.numThreads = 2,
    String? initialLanguage,
  }) : _language = initialLanguage {
    _ensureBindings();
    _recognizer = _createRecognizer(initialLanguage);
  }

  final SherpaWhisperModelFiles files;
  final int numThreads;
  String? _language;
  late sherpa.OfflineRecognizer _recognizer;
  bool _disposed = false;

  static bool _bindingsInitialized = false;

  static void _ensureBindings() {
    if (_bindingsInitialized) return;
    sherpa.initBindings();
    _bindingsInitialized = true;
  }

  sherpa.OfflineRecognizer _createRecognizer(String? language) =>
      sherpa.OfflineRecognizer(
        buildSherpaWhisperConfig(
          files: files,
          language: language,
          numThreads: numThreads,
        ),
      );

  @override
  Future<OfflineWhisperResult> transcribe({
    required Float32List samples,
    required int sampleRate,
    required String? language,
  }) async {
    if (_disposed) throw StateError('Sherpa Whisper runtime is disposed.');
    if (sampleRate != 16000) {
      throw ArgumentError.value(sampleRate, 'sampleRate', 'must be 16000');
    }
    if (language != _language) {
      _recognizer.free();
      _language = language;
      _recognizer = _createRecognizer(language);
    }
    final stream = _recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
      _recognizer.decode(stream);
      final result = _recognizer.getResult(stream);
      return OfflineWhisperResult(
        text: result.text.trim(),
        language: result.lang.trim(),
      );
    } finally {
      stream.free();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _recognizer.free();
  }
}

final class SherpaWhisperWorkerException implements Exception {
  const SherpaWhisperWorkerException(this.message);

  final String message;

  @override
  String toString() => 'SherpaWhisperWorkerException: $message';
}

/// Persistent worker-isolate runtime. Native model loading and decode never run
/// on Flutter's UI/lifecycle isolate.
final class IsolatedSherpaWhisperRuntime implements OfflineWhisperRuntime {
  IsolatedSherpaWhisperRuntime._(
    this._isolate,
    this._commands,
    this._workerExited,
    this._exitSubscription,
    this._exitPort,
  );

  final Isolate _isolate;
  final SendPort _commands;
  final Future<void> _workerExited;
  final StreamSubscription<dynamic> _exitSubscription;
  final ReceivePort _exitPort;
  final Set<ReceivePort> _pendingResponses = <ReceivePort>{};
  int _nextRequest = 0;
  bool _disposed = false;

  static Future<IsolatedSherpaWhisperRuntime> start({
    required SherpaWhisperModelFiles files,
    int numThreads = 2,
  }) async {
    final ready = ReceivePort();
    final errors = ReceivePort();
    final exited = ReceivePort();
    final completion = Completer<SendPort>();
    final workerExited = Completer<void>();
    Isolate? isolate;
    var retainedExitOwnership = false;

    final readySubscription = ready.listen((dynamic message) {
      if (completion.isCompleted) return;
      if (message is SendPort) {
        completion.complete(message);
      } else {
        completion.completeError(
          const SherpaWhisperWorkerException(
            'The offline speech model could not be initialized.',
          ),
        );
      }
    });
    final errorSubscription = errors.listen((dynamic _) {
      if (!completion.isCompleted) {
        completion.completeError(
          const SherpaWhisperWorkerException(
            'The offline speech model could not be initialized.',
          ),
        );
      }
    });
    final exitSubscription = exited.listen((dynamic _) {
      if (!workerExited.isCompleted) workerExited.complete();
      if (!completion.isCompleted) {
        completion.completeError(
          const SherpaWhisperWorkerException(
            'The offline speech model could not be initialized.',
          ),
        );
      }
    });

    try {
      isolate = await Isolate.spawn<Map<String, Object?>>(
        _sherpaWhisperWorkerMain,
        <String, Object?>{
          'ready': ready.sendPort,
          'modelId': files.modelId,
          'encoder': files.encoderPath,
          'decoder': files.decoderPath,
          'tokens': files.tokensPath,
          'numThreads': numThreads,
        },
        onError: errors.sendPort,
        onExit: exited.sendPort,
        errorsAreFatal: true,
        debugName: 'wing-whisper-worker',
      );
      final commands = await completion.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw const SherpaWhisperWorkerException(
          'The offline speech model initialization timed out.',
        ),
      );
      retainedExitOwnership = true;
      return IsolatedSherpaWhisperRuntime._(
        isolate,
        commands,
        workerExited.future,
        exitSubscription,
        exited,
      );
    } catch (error, stackTrace) {
      if (isolate != null) {
        isolate.kill(priority: Isolate.immediate);
        // A startup failure does not return a runtime for the shared owner to
        // release later. Retain the exit port and fail closed here until the
        // worker has demonstrably released its native model mappings.
        await workerExited.future;
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      await readySubscription.cancel();
      await errorSubscription.cancel();
      ready.close();
      errors.close();
      if (!retainedExitOwnership) {
        await exitSubscription.cancel();
        exited.close();
      }
    }
  }

  @override
  Future<OfflineWhisperResult> transcribe({
    required Float32List samples,
    required int sampleRate,
    required String? language,
  }) async {
    if (_disposed) throw StateError('Whisper worker is disposed.');
    final response = ReceivePort();
    _pendingResponses.add(response);
    final request = ++_nextRequest;
    final bytes = Uint8List.view(
      samples.buffer,
      samples.offsetInBytes,
      samples.lengthInBytes,
    );
    _commands.send(<String, Object?>{
      'type': 'transcribe',
      'id': request,
      'sampleRate': sampleRate,
      'language': language,
      'samples': TransferableTypedData.fromList(<Uint8List>[bytes]),
      'reply': response.sendPort,
    });
    try {
      late final dynamic message;
      try {
        message = await response.first;
      } catch (_) {
        if (_disposed) {
          throw const SherpaWhisperWorkerException(
            'The offline speech operation was cancelled.',
          );
        }
        rethrow;
      }
      if (message is! Map ||
          message['id'] != request ||
          message['ok'] != true) {
        throw const SherpaWhisperWorkerException(
          'The offline speech model could not decode this utterance.',
        );
      }
      return OfflineWhisperResult(
        text: message['text'] as String? ?? '',
        language: message['language'] as String? ?? '',
      );
    } finally {
      _pendingResponses.remove(response);
      response.close();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final response = ReceivePort();
    _commands.send(<String, Object?>{
      'type': 'dispose',
      'reply': response.sendPort,
    });
    try {
      await response.first.timeout(const Duration(seconds: 1));
    } catch (_) {
      // A blocked native decode is force-terminated below after caller-side
      // generation ownership has already been invalidated.
    } finally {
      response.close();
      for (final pending in _pendingResponses.toList(growable: false)) {
        pending.close();
      }
      _pendingResponses.clear();
      _isolate.kill(priority: Isolate.immediate);
    }
    // Isolate.kill only requests termination. Keep exit ownership alive and
    // fail closed until onExit proves native model mappings are gone.
    await _workerExited;
    try {
      await _exitSubscription.cancel();
    } finally {
      _exitPort.close();
    }
  }
}

Future<void> _sherpaWhisperWorkerMain(Map<String, Object?> bootstrap) async {
  final ready = bootstrap['ready']! as SendPort;
  final commands = ReceivePort();
  late final SherpaWhisperRuntime runtime;
  try {
    runtime = SherpaWhisperRuntime(
      files: SherpaWhisperModelFiles(
        modelId: bootstrap['modelId']! as String,
        encoderPath: bootstrap['encoder']! as String,
        decoderPath: bootstrap['decoder']! as String,
        tokensPath: bootstrap['tokens']! as String,
      ),
      numThreads: bootstrap['numThreads']! as int,
    );
    ready.send(commands.sendPort);
  } catch (_) {
    ready.send(const <String, Object?>{'type': 'initialization-error'});
    commands.close();
    return;
  }

  await for (final dynamic raw in commands) {
    if (raw is! Map) continue;
    final reply = raw['reply'];
    if (reply is! SendPort) continue;
    if (raw['type'] == 'dispose') {
      await runtime.dispose();
      reply.send(const <String, Object?>{'ok': true});
      commands.close();
      return;
    }
    if (raw['type'] != 'transcribe') continue;
    final id = raw['id'];
    try {
      final bytes = (raw['samples']! as TransferableTypedData)
          .materialize()
          .asUint8List();
      final result = await runtime.transcribe(
        samples: Float32List.view(
          bytes.buffer,
          bytes.offsetInBytes,
          bytes.lengthInBytes ~/ Float32List.bytesPerElement,
        ),
        sampleRate: raw['sampleRate']! as int,
        language: raw['language'] as String?,
      );
      reply.send(<String, Object?>{
        'id': id,
        'ok': true,
        'text': result.text,
        'language': result.language,
      });
    } catch (_) {
      reply.send(<String, Object?>{'id': id, 'ok': false});
    }
  }
}
